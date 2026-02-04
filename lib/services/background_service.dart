import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:autospend/services/database_service.dart';
import 'package:autospend/services/huggingface_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundServiceManager {
  static const String notificationChannelId = 'autospend_channel';
  static const String notificationChannelName = 'AutoSpend AI Service';

  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    // Create Notification Channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      notificationChannelId,
      notificationChannelName,
      description: 'يقوم برصد إشعارات البنوك لتحليلها',
      importance: Importance.high,
      playSound: true,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: notificationChannelId,
        initialNotificationTitle: 'AutoSpend AI',
        initialNotificationContent: 'جاري البدء في رصد الإشعارات...',
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(),
    );
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Ensure background isolate can communicate with plugins
  WidgetsFlutterBinding.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final databaseService = DatabaseService();
  final aiService = HuggingFaceService();

  print("Background Service: onStart beginning...");

  // Delay slightly to ensure native side is ready
  await Future.delayed(const Duration(seconds: 2));

  // Process existing notifications on startup
  try {
    final activeNotifications =
        await NotificationListenerService.getActiveNotifications();
    print("Found ${activeNotifications.length} active notifications on start");

    for (final event in activeNotifications) {
      final title = event.title ?? "";
      final content = event.content ?? "";
      final package = event.packageName ?? "unknown";
      if (title.isNotEmpty || content.isNotEmpty) {
        final fullText = "$title $content".trim();
        print("Processing Active Notification: [$package] $fullText");
        await _handleNotification(
          fullText,
          aiService,
          databaseService,
          service,
          packageName: package,
        );
      }
    }
  } catch (e) {
    print('Error processing active notifications: $e');
  }

  // Listen to future notification events
  NotificationListenerService.notificationsStream.listen((event) async {
    final title = event.title ?? "";
    final content = event.content ?? "";
    final packageName = event.packageName ?? "unknown";

    print("--- RAW NOTIFICATION ARRIVED ---");
    print("Package: $packageName");
    print("Title: $title");
    print("Content: $content");
    print("--------------------------------");

    if (content.isEmpty && title.isEmpty) {
      print("Empty notification skipped.");
      return;
    }

    // Combine title and content for better context
    final fullText = "$title $content".trim();

    await _handleNotification(
      fullText,
      aiService,
      databaseService,
      service,
      packageName: packageName,
    );
  });

  // Heartbeat to prove service is alive
  Timer.periodic(const Duration(minutes: 1), (timer) {
    print("Background Service Heartbeat: ${DateTime.now()}");
  });
}

Future<void> _handleNotification(
  String content,
  HuggingFaceService aiService,
  DatabaseService databaseService,
  ServiceInstance service, {
  String? packageName,
}) async {
  print("Handling notification from: $packageName");
  try {
    final prefs = await SharedPreferences.getInstance();
    final whitelist = prefs.getStringList('banking_packages') ?? [];

    // Keyword check
    final bankingKeywords = [
      'حوالة',
      'تحويل',
      'مبلغ',
      'شيكل',
      'ILS',
      'SAR',
      'ريال',
      'مدى',
      'mada',
      'نقاط بيع',
      'شراء',
      'خصم',
      'إيداع',
      'سحب',
      'رصيد',
      'BOP',
      'Bank',
      'بنك',
      'مصرف',
      'عملية',
      'بطاقة',
      'Atheer',
      'أثير',
      'Pay',
    ];

    // Package Blacklist (Never analyze these packages)
    final blacklist = [
      'android',
      'com.android.systemui',
      'com.google.android.apps.restore',
      'com.sec.android.app.myfiles',
      // 'com.google.android.gm', // Removed to allow bank emails
      // 'com.google.android.apps.messaging', // Removed to allow bank SMS
      'com.android.vending',
    ];

    if (packageName != null && blacklist.contains(packageName)) {
      print("Skipping AI analysis: Package is blacklisted ($packageName)");
      return;
    }

    bool hasKeyword = bankingKeywords.any((kw) => content.contains(kw));
    bool isWhitelisted = packageName != null && whitelist.contains(packageName);

    // Skip if neither whitelisted nor contains keywords
    if (!isWhitelisted && !hasKeyword) {
      print(
        "Skipping AI analysis: No keywords found and package not whitelisted ($packageName)",
      );
      return;
    }

    print(
      "LOCAL FILTER PASSED: Banking keywords or whitelist found. Triggering AI analysis...",
    );
    print("Content Length: ${content.length} characters");
    print(
      "Analyzing content via AI (Reason: ${isWhitelisted ? 'Whitelisted' : 'Keyword found'}): $content",
    );
    final analysis = await aiService.analyzeNotification(content);

    if (analysis != null && analysis['is_banking'] == true) {
      // Add to whitelist if not already there
      if (packageName != null && !whitelist.contains(packageName)) {
        whitelist.add(packageName);
        await prefs.setStringList('banking_packages', whitelist);
        print("Whitelisted new banking package: $packageName");
      }

      if (analysis.containsKey('amount')) {
        print(
          "Transaction Analysis Passed: ${analysis['merchant']} - ${analysis['amount']}",
        );
        final transaction = TransactionModel(
          merchant: analysis['merchant'] ?? 'Unknown',
          amount: (analysis['amount'] as num?)?.toDouble() ?? 0.0,
          currency: analysis['currency'] ?? 'ILS',
          category: analysis['category'] ?? 'أخرى',
          date: DateTime.now().toIso8601String(),
          originalText: content,
          cardDigits: analysis['card_digits']?.toString(),
        );

        await databaseService.insertTransaction(transaction);
        print("SUCCESS: Transaction Saved to Database");

        // Notify UI
        service.invoke('update', {
          'last_merchant': transaction.merchant,
          'last_amount': transaction.amount,
        });
      }
    } else {
      print("AI confirmed this is NOT a banking transaction.");
    }
  } catch (e) {
    print('Background Process Error: $e');
  }
}
