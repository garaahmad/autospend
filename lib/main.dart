import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:notification_listener_service/notification_listener_service.dart'
    as nls;
import 'package:autospend/services/database_service.dart';
import 'package:autospend/services/background_service.dart';
import 'package:autospend/providers/settings_provider.dart';
import 'package:autospend/utils/translations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'package:autospend/services/huggingface_service.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Start background service without awaiting
  BackgroundServiceManager.initializeService()
      .then((_) {
        debugPrint("Background service initialized");
      })
      .catchError((e) {
        debugPrint("Failed to initialize background service: $e");
      });

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const AutoSpendApp(),
    ),
  );
}

class AutoSpendApp extends StatelessWidget {
  const AutoSpendApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AutoSpend AI',
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        textTheme: GoogleFonts.outfitTextTheme().copyWith(
          titleLarge: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          bodyMedium: GoogleFonts.cairo(),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0E17),
        cardColor: const Color(0xFF1B1A23),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF1B1A23),
          background: const Color(0xFF0F0E17),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
            .copyWith(
              titleLarge: GoogleFonts.cairo(
                textStyle: ThemeData.dark().textTheme.titleLarge,
                fontWeight: FontWeight.bold,
              ),
              bodyMedium: GoogleFonts.cairo(
                textStyle: ThemeData.dark().textTheme.bodyMedium,
              ),
            ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DashboardScreen(),
    const TransactionsHistoryScreen(),
    const ReportsScreen(),
    const SettingsSheet(isScreen: true),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.locale.languageCode;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Colors.deepPurpleAccent,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white38
            : Colors.black38,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_filled),
            label: AppTranslations.get('home', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: AppTranslations.get('history', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart),
            label: AppTranslations.get('reports', lang),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: AppTranslations.get('settings', lang),
          ),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isServiceRunning = false;
  List<TransactionModel> _transactions = [];
  double _todayTotal = 0;
  double _monthlyTotal = 0;
  final _databaseService = DatabaseService();
  final _aiService = HuggingFaceService();
  Timer? _refreshTimer;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadTransactions();

    FlutterBackgroundService().on('update').listen((event) {
      if (mounted) {
        _loadTransactions();
        if (event != null && event.containsKey('last_merchant')) {
          _showToast(
            event['last_merchant'] as String,
            (event['last_amount'] as num).toDouble(),
          );
        }
      }
    });

    // Auto-refresh every 5 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) _loadTransactions();
    });

    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'autospend' && uri.host == 'parse') {
      final content = uri.queryParameters['content'];
      if (content != null && content.isNotEmpty) {
        print('iOS Deep Link Received: $content');

        // Show a loading indicator for the user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Processing iOS Transaction...')),
          );
        }

        final analysis = await _aiService.analyzeNotification(content);

        if (analysis != null && analysis['is_banking'] == true) {
          final transaction = TransactionModel(
            merchant: analysis['merchant'] ?? 'Unknown',
            amount: (analysis['amount'] as num?)?.toDouble() ?? 0.0,
            currency: analysis['currency'] ?? 'ILS',
            category: analysis['category'] ?? 'أخرى',
            date: DateTime.now().toIso8601String(),
            originalText: content,
            cardDigits: analysis['card_digits']?.toString(),
          );

          await _databaseService.insertTransaction(transaction);
          _loadTransactions();

          if (mounted) {
            _showToast(transaction.merchant, transaction.amount);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _showToast(String merchant, double amount) {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final lang = settings.locale.languageCode;
    final message = AppTranslations.get('transaction_detected', lang)
        .replaceFirst('{merchant}', merchant)
        .replaceFirst('{amount}', amount.toString());

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        backgroundColor: Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _checkServiceStatus() async {
    final running = await FlutterBackgroundService().isRunning();
    if (mounted) {
      setState(() {
        _isServiceRunning = running;
      });
    }
  }

  Future<void> _loadTransactions() async {
    final data = await _databaseService.getTransactions();
    final today = await _databaseService.getTodayTotal();
    final monthly = await _databaseService.getMonthlyTotal();

    final prefs = await SharedPreferences.getInstance();
    final lastClearStr = prefs.getString('last_home_clear');
    DateTime? lastClear;
    if (lastClearStr != null) {
      lastClear = DateTime.parse(lastClearStr);
    }

    final filteredData = data.where((tx) {
      if (lastClear == null) return true;
      final txDate = DateTime.parse(tx.date);
      return txDate.isAfter(lastClear);
    }).toList();

    if (mounted) {
      setState(() {
        _transactions = filteredData;
        _todayTotal = today;
        _monthlyTotal = monthly;
      });
    }
  }

  Future<void> _toggleService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();

    if (isRunning) {
      service.invoke("stopService");
    } else {
      bool hasPermission =
          await nls.NotificationListenerService.isPermissionGranted();
      if (!hasPermission) {
        final granted =
            await nls.NotificationListenerService.requestPermission();
        if (!granted) {
          if (mounted) {
            final settings = context.read<SettingsProvider>();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppTranslations.get(
                    'permission_required',
                    settings.locale.languageCode,
                  ),
                ),
              ),
            );
          }
          return;
        }
      }

      await Permission.notification.request();

      final notificationGranted = await Permission.notification.isGranted;
      if (!notificationGranted && mounted) {
        final settings = context.read<SettingsProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              settings.locale.languageCode == 'ar'
                  ? 'يرجى تفعيل إذن الإشعارات لاستلام التنبيهات'
                  : 'Please enable notification permission to receive alerts',
            ),
          ),
        );
        // We don't return here because the main functionality (reading other apps' notifications)
        // works via the Listener Service permission, not this standard runtime permission.
        // This permission is only for *posting* our own notifications.
      }

      await service.startService();
    }

    if (mounted) {
      setState(() {
        _isServiceRunning = !isRunning;
      });
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.locale.languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppTranslations.get('smart_dashboard', lang),
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurpleAccent,
          ),
        ),

        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        backgroundColor: const Color(0xFF1B1A23),
        color: Colors.deepPurpleAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildStatusCard(lang),
              const SizedBox(height: 24),
              _buildSpendingHeader(lang),
              const SizedBox(height: 16),
              _buildSummaryGrid(lang),
              const SizedBox(height: 32),
              _buildRecentHeader(lang),
              const SizedBox(height: 16),
              _buildTransactionList(lang),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAllTransactions() async {
    final settings = context.read<SettingsProvider>();
    final lang = settings.locale.languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1A23),
        title: Text(
          AppTranslations.get('delete_all', lang),
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          lang == 'ar'
              ? 'هل أنت متأكد من حذف جميع العمليات؟ لا يمكن التراجع عن هذا الإجراء.'
              : 'Are you sure you want to delete all transactions? This action cannot be undone.',
          style: GoogleFonts.cairo(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppTranslations.get('close', lang),
              style: const TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppTranslations.get('delete_all', lang),
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'last_home_clear',
        DateTime.now().toIso8601String(),
      );
      await _loadTransactions();
    }
  }

  Widget _buildSpendingHeader(String lang) {
    return Text(
      AppTranslations.get('spending_summary', lang),
      style: GoogleFonts.cairo(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
      ),
    );
  }

  Widget _buildRecentHeader(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppTranslations.get('recent_transactions', lang),
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
        IconButton(
          onPressed: _deleteAllTransactions,
          icon: const Icon(
            Icons.delete_outline,
            color: Colors.redAccent,
            size: 24,
          ),
          tooltip: AppTranslations.get('delete_all', lang),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(String lang) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: AppTranslations.get('today', lang),
            amount: _todayTotal,

            lang: lang,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: AppTranslations.get('this_month', lang),
            amount: _monthlyTotal,
            lang: lang,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required String lang,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: Colors.deepPurpleAccent.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            child: Text(
              '${amount.toStringAsFixed(0)} ر.س',
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTransactionList(String lang) {
    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                AppTranslations.get('no_transactions', lang),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white38
                      : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _transactions
          .take(5)
          .map((tx) => _buildTransactionCard(tx, lang))
          .toList(),
    );
  }

  Widget _buildStatusCard(String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isServiceRunning
              ? [const Color(0xFF6200EE), const Color(0xFF3700B3)]
              : [const Color(0xFF2C2C34), const Color(0xFF1B1A23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF6200EE,
            ).withOpacity(_isServiceRunning ? 0.3 : 0),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AutoSpend AI',
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isServiceRunning
                      ? Colors.greenAccent
                      : Colors.redAccent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_isServiceRunning)
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 2,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isServiceRunning
                ? AppTranslations.get('monitoring_active', lang)
                : AppTranslations.get('monitoring_inactive', lang),
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _toggleService,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppTranslations.get(
                      _isServiceRunning
                          ? 'stop_monitoring'
                          : 'start_monitoring',
                      lang,
                    ),
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx, String lang) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C34) : const Color(0xFFF1F3F5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            sharedGetCategoryIcon(tx.category),
            color: Colors.deepPurpleAccent,
            size: 24,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tx.merchant,
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _formatDate(tx.date, lang),
                  style: GoogleFonts.cairo(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sharedGetTranslatedCategory(tx.category, lang),
                      style: GoogleFonts.cairo(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(
          '${tx.amount.toStringAsFixed(1)} ر.س',
          style: GoogleFonts.cairo(
            color: const Color(0xFF00E676),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        onTap: () => showClassificationDialog(
          context: context,
          tx: tx,
          lang: lang,
          databaseService: _databaseService,
          onUpdate: _loadTransactions,
        ),
      ),
    );
  }

  String _formatDate(String dateStr, String lang) {
    try {
      final dateTime = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime).inDays;

      String dayPart;
      if (difference == 0 && now.day == dateTime.day) {
        dayPart = lang == 'ar' ? 'اليوم' : 'Today';
      } else if (difference == 1 ||
          (difference == 0 && now.day != dateTime.day)) {
        dayPart = lang == 'ar' ? 'أمس' : 'Yesterday';
      } else {
        dayPart = DateFormat('yyyy/MM/dd').format(dateTime);
      }

      final timePart = DateFormat.jm(lang).format(dateTime);
      return lang == 'ar' ? '$dayPart، $timePart' : '$dayPart, $timePart';
    } catch (e) {
      return dateStr;
    }
  }
}

// Reusable classification helper methods
Future<void> showClassificationDialog({
  required BuildContext context,
  required TransactionModel tx,
  required String lang,
  required DatabaseService databaseService,
  required VoidCallback onUpdate,
  bool updateAllForMerchant = false,
}) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> customCategories =
      prefs.getStringList('custom_categories') ?? [];

  // Core categories
  final defaultCategories = [
    AppTranslations.get('food', lang),
    AppTranslations.get('shopping', lang),
    AppTranslations.get('fuel', lang),
    AppTranslations.get('transfer', lang),
    AppTranslations.get('other', lang),
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final allCategories = [...defaultCategories, ...customCategories];

        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppTranslations.get('classify_transaction', lang),
                      style: GoogleFonts.cairo(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${tx.merchant} - ${tx.amount} ${tx.currency}',
                  style: GoogleFonts.cairo(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: allCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == allCategories.length) {
                        return ListTile(
                          leading: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.greenAccent,
                          ),
                          title: Text(
                            AppTranslations.get('add_custom_category', lang),
                            style: GoogleFonts.cairo(color: Colors.greenAccent),
                          ),
                          onTap: () async {
                            final newCat = await showAddCategoryDialog(
                              context,
                              lang,
                            );
                            if (newCat != null && newCat.isNotEmpty) {
                              customCategories.add(newCat);
                              await prefs.setStringList(
                                'custom_categories',
                                customCategories,
                              );
                              setModalState(() {});
                            }
                          },
                        );
                      }

                      final category = allCategories[index];
                      return ListTile(
                        leading: Icon(
                          sharedGetCategoryIcon(category),
                          color: tx.category == category
                              ? Colors.deepPurpleAccent
                              : Colors.grey,
                        ),
                        title: Text(
                          category,
                          style: GoogleFonts.cairo(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        trailing: tx.category == category
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.deepPurpleAccent,
                              )
                            : null,
                        onTap: () async {
                          if (updateAllForMerchant) {
                            await databaseService.updateMerchantCategory(
                              tx.merchant,
                              category,
                            );
                          } else {
                            await databaseService.updateTransactionCategory(
                              tx.id!,
                              category,
                            );
                          }
                          Navigator.pop(context);
                          onUpdate();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

Future<String?> showAddCategoryDialog(BuildContext context, String lang) async {
  String newCategory = "";
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1B1A23),
      title: Text(
        AppTranslations.get('new_category', lang),
        style: GoogleFonts.cairo(color: Colors.white),
      ),
      content: TextField(
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: AppTranslations.get('category_name', lang),
          hintStyle: const TextStyle(color: Colors.white38),
        ),
        onChanged: (val) => newCategory = val,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppTranslations.get('close', lang)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, newCategory),
          child: Text(AppTranslations.get('save', lang)),
        ),
      ],
    ),
  );
}

IconData sharedGetCategoryIcon(String category) {
  final cat = category.toLowerCase();
  if (cat.contains('food') ||
      cat.contains('طعام') ||
      cat.contains('dessert') ||
      cat.contains('ice'))
    return Icons.shopping_basket;
  if (cat.contains('gas') || cat.contains('fuel') || cat.contains('وقود'))
    return Icons.local_gas_station;
  if (cat.contains('shop') || cat.contains('market') || cat.contains('تسوق'))
    return Icons.shopping_cart;
  if (cat.contains('transfer') || cat.contains('تحويل'))
    return Icons.swap_horiz;
  return Icons.payments_outlined;
}

String sharedGetTranslatedCategory(String category, String lang) {
  switch (category.toLowerCase()) {
    case 'طعام':
    case 'food':
      return AppTranslations.get('food', lang);
    case 'تسوق':
    case 'shopping':
      return AppTranslations.get('shopping', lang);
    case 'وقود':
    case 'fuel':
      return AppTranslations.get('fuel', lang);
    case 'تحويل':
    case 'transfer':
      return AppTranslations.get('transfer', lang);
    default:
      return category;
  }
}

class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});

  @override
  State<TransactionsHistoryScreen> createState() =>
      _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  final _databaseService = DatabaseService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllTransactions();
  }

  Future<void> _loadAllTransactions() async {
    final data = await _databaseService.getTransactions();
    if (mounted) {
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.locale.languageCode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppTranslations.get('history', lang),
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllTransactions,
              backgroundColor: const Color(0xFF1B1A23),
              color: Colors.deepPurpleAccent,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    const SizedBox(height: 32),
                    ..._buildGroupedTransactionList(lang),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildGroupedTransactionList(String lang) {
    if (_transactions.isEmpty) {
      return [
        Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long,
                size: 48,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : Colors.black12,
              ),
              const SizedBox(height: 16),
              Text(
                AppTranslations.get('no_transactions', lang),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white38
                      : Colors.black38,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final groups = <String, List<TransactionModel>>{};
    for (var tx in _transactions) {
      if (!groups.containsKey(tx.merchant)) {
        groups[tx.merchant] = [];
      }
      groups[tx.merchant]!.add(tx);
    }

    final sortedMerchants = groups.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    final widgets = <Widget>[];

    for (var merchant in sortedMerchants) {
      final txList = groups[merchant]!;
      final totalAmount = txList.fold<double>(
        0,
        (sum, item) => sum + item.amount,
      );
      final latestTx = txList.first; // Use first for category/icon

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF2C2C34)
                    : const Color(0xFFF1F3F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                sharedGetCategoryIcon(latestTx.category),
                color: Colors.deepPurpleAccent,
                size: 24,
              ),
            ),
            title: Text(
              merchant,
              style: GoogleFonts.cairo(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              '${txList.length} ${lang == 'ar' ? 'عمليات' : 'transactions'}',
              style: GoogleFonts.cairo(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black38,
                fontSize: 12,
              ),
            ),
            trailing: Text(
              '${totalAmount.toStringAsFixed(1)} ر.س',
              style: GoogleFonts.cairo(
                color: const Color(0xFF00E676),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            onTap: () => showClassificationDialog(
              context: context,
              tx: latestTx,
              lang: lang,
              databaseService: _databaseService,
              onUpdate: _loadAllTransactions,
              updateAllForMerchant: true,
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

class SettingsSheet extends StatelessWidget {
  final bool isScreen;
  const SettingsSheet({super.key, this.isScreen = false});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.locale.languageCode;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppTranslations.get('settings', lang),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingItem(
            context,
            icon: Icons.language,
            title: AppTranslations.get('language', lang),
            trailing: DropdownButton<String>(
              value: lang,
              dropdownColor: Theme.of(context).cardColor,
              underline: const SizedBox(),
              onChanged: (val) {
                if (val != null) {
                  settings.setLocale(Locale(val));
                  if (!isScreen) Navigator.pop(context);
                }
              },
              items: [
                DropdownMenuItem(
                  value: 'ar',
                  child: Text(
                    AppTranslations.get('arabic', lang),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'en',
                  child: Text(
                    AppTranslations.get('english', lang),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).dividerColor),
          _buildSettingItem(
            context,
            icon: Theme.of(context).brightness == Brightness.dark
                ? Icons.dark_mode
                : Icons.light_mode,
            title: AppTranslations.get('theme', lang),
            trailing: Switch(
              value: settings.themeMode == ThemeMode.dark,
              onChanged: (val) {
                settings.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
              },
            ),
          ),
          if (Platform.isIOS) ...[
            Divider(color: Theme.of(context).dividerColor),
            _buildSettingItem(
              context,
              icon: Icons.ios_share,
              title: AppTranslations.get('setup_ios', lang),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black38,
              ),
              onTap: () => _showIOSGuide(context, lang),
            ),
          ],
        ],
      ),
    );

    if (isScreen) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Icon(
            Icons.settings,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
          title: Text(
            AppTranslations.get('settings', lang),
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ),
        body: content,
      );
    }

    return content;
  }

  void _showIOSGuide(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1A23),
        title: Text(
          AppTranslations.get('setup_ios_title', lang),
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTranslations.get('ios_step_1', lang),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                AppTranslations.get('ios_step_2', lang),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                AppTranslations.get('ios_step_3', lang),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              const Text(
                'autospend://parse?content={text}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: Colors.deepPurpleAccent,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.get('close', lang)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurpleAccent),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _databaseService = DatabaseService();
  Map<String, double> _categoryData = {};
  List<TransactionModel> _allTransactions = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final transactions = await _databaseService.getTransactions();
    print('📊 Loaded ${transactions.length} transactions from database');

    final Map<String, double> temp = {};
    for (var tx in transactions) {
      temp[tx.category] = (temp[tx.category] ?? 0) + tx.amount;
      print(
        'Transaction: ${tx.merchant} - ${tx.amount} ${tx.currency} - ${tx.category}',
      );
    }

    if (mounted) {
      setState(() {
        _allTransactions = transactions;
        _categoryData = temp;
        _isLoading = false;
      });
      print(
        '✅ State updated: ${_allTransactions.length} transactions, ${_categoryData.length} categories',
      );
    }
  }

  Future<void> _exportToExcel() async {
    // Check if we have data
    if (_allTransactions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لا توجد معاملات للتصدير!\nNo transactions to export!',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isExporting = true);

    try {
      // Create Excel file
      var excel = excel_lib.Excel.createExcel();

      // Rename the default Sheet1 to Transactions
      // This allows us to work with the default sheet instead of deleting/creating
      if (excel.sheets.containsKey('Sheet1')) {
        excel.rename('Sheet1', 'Transactions');
      }

      // Get the sheet (it should exist now as 'Transactions')
      var sheet = excel['Transactions'];

      // Add headers
      sheet.cell(excel_lib.CellIndex.indexByString('A1')).value =
          excel_lib.TextCellValue('التاجر / Merchant');
      sheet.cell(excel_lib.CellIndex.indexByString('B1')).value =
          excel_lib.TextCellValue('المبلغ / Amount');
      sheet.cell(excel_lib.CellIndex.indexByString('C1')).value =
          excel_lib.TextCellValue('العملة / Currency');
      sheet.cell(excel_lib.CellIndex.indexByString('D1')).value =
          excel_lib.TextCellValue('التصنيف / Category');
      sheet.cell(excel_lib.CellIndex.indexByString('E1')).value =
          excel_lib.TextCellValue('التاريخ / Date');
      sheet.cell(excel_lib.CellIndex.indexByString('F1')).value =
          excel_lib.TextCellValue('البطاقة / Card');

      // Style headers
      final headerStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 12,
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('#4A148C'),
        fontColorHex: excel_lib.ExcelColor.white,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );

      for (var col in ['A1', 'B1', 'C1', 'D1', 'E1', 'F1']) {
        sheet.cell(excel_lib.CellIndex.indexByString(col)).cellStyle =
            headerStyle;
      }

      // Add transaction data
      int row = 2;
      for (var tx in _allTransactions) {
        sheet.cell(excel_lib.CellIndex.indexByString('A$row')).value =
            excel_lib.TextCellValue(tx.merchant);
        sheet.cell(excel_lib.CellIndex.indexByString('B$row')).value =
            excel_lib.DoubleCellValue(tx.amount);
        sheet.cell(excel_lib.CellIndex.indexByString('C$row')).value =
            excel_lib.TextCellValue(tx.currency);
        sheet.cell(excel_lib.CellIndex.indexByString('D$row')).value =
            excel_lib.TextCellValue(tx.category);
        sheet.cell(excel_lib.CellIndex.indexByString('E$row')).value =
            excel_lib.TextCellValue(tx.date);
        sheet.cell(excel_lib.CellIndex.indexByString('F$row')).value =
            excel_lib.TextCellValue(tx.cardDigits ?? 'N/A');

        // Add simple styling to data rows for readability
        if (row % 2 == 0) {
          // Optional: You could add alternate row coloring here if desired
        }
        row++;
      }
      print('✅ Added ${row - 2} transaction rows to Excel');

      // Create Summary sheet
      var summarySheet = excel['Summary'];
      summarySheet.cell(excel_lib.CellIndex.indexByString('A1')).value =
          excel_lib.TextCellValue('التصنيف / Category');
      summarySheet.cell(excel_lib.CellIndex.indexByString('B1')).value =
          excel_lib.TextCellValue('الإجمالي / Total');
      summarySheet.cell(excel_lib.CellIndex.indexByString('A1')).cellStyle =
          headerStyle;
      summarySheet.cell(excel_lib.CellIndex.indexByString('B1')).cellStyle =
          headerStyle;

      int summaryRow = 2;
      _categoryData.forEach((category, amount) {
        summarySheet
            .cell(excel_lib.CellIndex.indexByString('A$summaryRow'))
            .value = excel_lib.TextCellValue(
          category,
        );
        summarySheet
            .cell(excel_lib.CellIndex.indexByString('B$summaryRow'))
            .value = excel_lib.DoubleCellValue(
          amount,
        );
        summaryRow++;
      });
      print('✅ Added ${summaryRow - 2} summary rows to Excel');

      // Save file
      final directory = await getExternalStorageDirectory();
      // Ensure we have a valid directory
      if (directory == null) {
        throw Exception('Could not access external storage directory');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/AutoSpend_Report_$timestamp.xlsx';
      final file = File(filePath);

      // Encode to bytes and save
      var fileBytes = excel.encode();
      if (fileBytes != null) {
        await file.create(recursive: true);
        await file.writeAsBytes(fileBytes);
        print(
          '✅ Excel file successfully written to: $filePath (${fileBytes.length} bytes)',
        );

        if (mounted) {
          setState(() => _isExporting = false);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم حفظ التقرير بنجاح ✓\nSaved: $filePath',
                style: GoogleFonts.cairo(),
              ),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'فتح / Open',
                textColor: Colors.white,
                onPressed: () => OpenFile.open(filePath),
              ),
              duration: const Duration(seconds: 10),
            ),
          );
        }
      } else {
        throw Exception('Failed to encode Excel file (bytes check failed)');
      }
    } catch (e, stackTrace) {
      print('❌ Export Error: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التصدير: $e', style: GoogleFonts.cairo()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lang = settings.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppTranslations.get('reports', lang),
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      floatingActionButton: _categoryData.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isExporting ? null : _exportToExcel,
              backgroundColor: Colors.deepPurpleAccent,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.file_download, color: Colors.white),
              label: Text(
                lang == 'ar' ? 'تصدير Excel' : 'Export Excel',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categoryData.isEmpty
          ? Center(
              child: Text(
                AppTranslations.get('no_transactions', lang),
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _categoryData.length,
              itemBuilder: (context, index) {
                final category = _categoryData.keys.elementAt(index);
                final amount = _categoryData[category]!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2C2C34)
                              : const Color(0xFFF1F3F5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(category),
                          color: Colors.deepPurpleAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              AppTranslations.get('total_spent', lang),
                              style: GoogleFonts.cairo(
                                color: isDark ? Colors.white38 : Colors.black38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${amount.toStringAsFixed(1)} ر.س',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF00E676),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('food') ||
        cat.contains('طعام') ||
        cat.contains('dessert') ||
        cat.contains('ice'))
      return Icons.shopping_basket;
    if (cat.contains('gas') || cat.contains('fuel') || cat.contains('وقود'))
      return Icons.local_gas_station;
    if (cat.contains('shop') || cat.contains('market') || cat.contains('تسوق'))
      return Icons.shopping_cart;
    if (cat.contains('transfer') || cat.contains('تحويل'))
      return Icons.swap_horiz;
    return Icons.payments_outlined;
  }
}
