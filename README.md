# AutoSpend AI 💰🤖

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.7-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.7-0175C2?style=for-the-badge&logo=dart)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)

**تطبيق ذكي لتتبع المصروفات تلقائياً باستخدام الذكاء الاصطناعي**

[العربية](#-نظرة-عامة) | [English](#-overview)

</div>

---

## 📱 نظرة عامة

**AutoSpend AI** هو تطبيق Flutter متطور يستخدم الذكاء الاصطناعي لتتبع مصروفاتك المالية تلقائياً من خلال تحليل إشعارات البنوك والرسائل النصية. يوفر التطبيق لوحة تحكم ذكية، تقارير مفصلة، ونظام تصنيف متقدم للمعاملات المالية.

### ✨ المميزات الرئيسية

- 🔄 **مراقبة تلقائية**: تتبع المعاملات المالية تلقائياً من إشعارات البنوك
- 🤖 **ذكاء اصطناعي متقدم**: استخدام نموذج Llama 3.2 لتحليل المعاملات واستخراج البيانات
- 📊 **تقارير شاملة**: عرض تفصيلي للمصروفات حسب التاجر والفئة
- 📑 **تصدير للبيانات**: إمكانية تصدير جميع التقارير والمعاملات لملف Excel
- 🏷️ **تصنيف ذكي**: تصنيف تلقائي للمعاملات مع إمكانية إضافة فئات مخصصة
- 🌙 **واجهة عصرية**: تصميم Material 3 مع دعم الوضع الليلي
- 🌐 **دعم متعدد اللغات**: واجهة كاملة بالعربية والإنجليزية
- 💾 **قاعدة بيانات محلية**: تخزين آمن للبيانات باستخدام SQLite
- 🔔 **خدمة خلفية**: عمل مستمر في الخلفية لالتقاط الإشعارات
- 🔗 **Deep Links**: دعم iOS Shortcuts للإضافة السريعة للمعاملات

---

## 🎯 حالات الاستخدام

- **للأفراد**: تتبع المصروفات الشخصية وإدارة الميزانية
- **للعائلات**: مراقبة النفقات العائلية وتحليل أنماط الإنفاق
- **للمستقلين**: تتبع نفقات العمل والمشاريع
- **للطلاب**: إدارة المصروف الشهري ومراقبة الإنفاق

---

## 🛠️ التقنيات المستخدمة

### Frontend & UI
- **Flutter 3.10.7** - إطار عمل تطوير التطبيقات
- **Material Design 3** - نظام التصميم
- **Google Fonts** - خطوط Cairo و Outfit
- **Provider** - إدارة الحالة

### AI & Backend
- **Hugging Face API** - واجهة برمجية للذكاء الاصطناعي
- **Llama 3.2 3B Instruct** - نموذج اللغة الكبير لتحليل المعاملات
- **Google Generative AI** - دعم إضافي للذكاء الاصطناعي

### Data & Storage
- **SQLite (sqflite)** - قاعدة بيانات محلية
- **SharedPreferences** - تخزين الإعدادات
- **Excel** - لتصدير البيانات والتقارير
- **Path Provider** - إدارة مسارات الملفات

### Services & Permissions
- **Flutter Background Service** - خدمة العمل في الخلفية
- **Notification Listener Service** - الاستماع للإشعارات
- **Permission Handler** - إدارة الأذونات
- **App Links** - Deep linking للتكامل مع iOS Shortcuts

### Localization
- **flutter_localizations** - دعم اللغات المتعددة
- **intl** - تنسيق التواريخ والأرقام

---

## 📦 البنية المعمارية

```
lib/
├── main.dart                          # نقطة الدخول الرئيسية
├── providers/
│   └── settings_provider.dart        # إدارة الإعدادات والحالة
├── services/
│   ├── background_service.dart       # خدمة العمل في الخلفية
│   ├── database_service.dart         # إدارة قاعدة البيانات
│   └── huggingface_service.dart      # تكامل الذكاء الاصطناعي
└── utils/
    └── translations.dart             # ملفات الترجمة
```

### الشاشات الرئيسية

1. **DashboardScreen** - لوحة التحكم الرئيسية
   - عرض حالة المراقبة
   - ملخص المصروفات اليومية والشهرية
   - آخر 5 معاملات

2. **TransactionsHistoryScreen** - سجل المعاملات
   - عرض جميع المعاملات مجمعة حسب التاجر
   - إجمالي المبلغ لكل تاجر
   - إمكانية حذف المعاملات

3. **ReportsScreen** - التقارير والإحصائيات
   - تقارير تفصيلية حسب الفئة
   - رسوم بيانية للإنفاق
   - تحليل الأنماط
   - **جديد**: تصدير التقرير لملف Excel

4. **SettingsScreen** - الإعدادات
   - تبديل اللغة (عربي/إنجليزي)
   - تبديل الوضع الليلي/النهاري
   - إدارة الأذونات

---

## 🚀 البدء

### المتطلبات الأساسية

- Flutter SDK 3.10.7 أو أحدث
- Dart SDK 3.10.7 أو أحدث
- Android Studio / VS Code
- حساب Hugging Face (للحصول على API Token)

### التثبيت

1. **استنساخ المشروع**
```bash
git clone https://github.com/garaahmad/autospend.git
cd autospend
```

2. **تثبيت الحزم**
```bash
flutter pub get
```

3. **إعداد Hugging Face API**
   - قم بإنشاء حساب على [Hugging Face](https://huggingface.co/)
   - احصل على API Token من [Settings > Access Tokens](https://huggingface.co/settings/tokens)
   - افتح ملف `lib/services/huggingface_service.dart`
   - استبدل `_token` بالـ Token الخاص بك:
   ```dart
   final String _token = 'YOUR_HUGGINGFACE_TOKEN_HERE';
   ```

4. **تشغيل التطبيق**
```bash
flutter run
```

---

## ⚙️ الإعدادات والأذونات

### Android

يحتاج التطبيق للأذونات التالية (مُعرّفة في `AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

للتكامل مع iOS Shortcuts:

1. افتح تطبيق **Shortcuts** على iPhone
2. أنشئ Shortcut جديد
3. أضف إجراء "Get Text from Input"
4. أضف إجراء "Open URL"
5. استخدم الصيغة: `autospend://parse?content=[النص]`

---

## 🔧 كيفية العمل

### 1. التقاط الإشعارات
```dart
// background_service.dart
NotificationListenerService.notificationsStream.listen((event) {
  // معالجة الإشعار
});
```

### 2. تحليل النص بالذكاء الاصطناعي
```dart
// huggingface_service.dart
final analysis = await analyzeNotification(notificationText);
// النتيجة: {
//   "is_banking": true,
//   "merchant": "Starbucks",
//   "amount": 25.5,
//   "currency": "SAR",
//   "category": "Coffee & Drinks"
// }
```

### 3. حفظ المعاملة
```dart
// database_service.dart
await insertTransaction(TransactionModel(
  merchant: analysis['merchant'],
  amount: analysis['amount'],
  currency: analysis['currency'],
  category: analysis['category'],
  date: DateTime.now().toIso8601String(),
));
```

### 4. عرض البيانات
- تحديث تلقائي كل 5 ثوانٍ
- إشعارات فورية للمعاملات الجديدة
- تجميع حسب التاجر والفئة

---

## 📊 نموذج البيانات

### TransactionModel

```dart
class TransactionModel {
  final int? id;
  final String merchant;        // اسم التاجر
  final double amount;          // المبلغ
  final String currency;        // العملة (SAR, USD, etc.)
  final String category;        // الفئة
  final String date;            // التاريخ (ISO 8601)
  final String originalText;    // النص الأصلي
  final String? cardDigits;     // آخر 4 أرقام من البطاقة
}
```

---

## 🎨 التصميم والواجهة

### نظام الألوان

**الوضع النهاري:**
- Background: `#F8F9FA`
- Card: `#FFFFFF`
- Primary: `Deep Purple Accent`

**الوضع الليلي:**
- Background: `#0F0E17`
- Card: `#1B1A23`
- Primary: `Deep Purple Accent`

### الخطوط
- **Cairo**: للنصوص العربية
- **Outfit**: للنصوص الإنجليزية

---

## 🌍 الترجمة

التطبيق يدعم اللغتين العربية والإنجليزية بشكل كامل:

```dart
// utils/translations.dart
static final Map<String, Map<String, String>> _translations = {
  'home': {'ar': 'الرئيسية', 'en': 'Home'},
  'history': {'ar': 'السجل', 'en': 'History'},
  'reports': {'ar': 'التقارير', 'en': 'Reports'},
  // ...
};
```

---

## 🔒 الأمان والخصوصية

- ✅ **تخزين محلي فقط**: جميع البيانات تُحفظ على الجهاز
- ✅ **تعقيم البيانات**: إزالة البيانات الحساسة قبل إرسالها للـ AI
- ✅ **لا توجد خوادم خارجية**: باستثناء Hugging Face API للتحليل
- ✅ **أذونات محدودة**: طلب الأذونات الضرورية فقط

```dart
String sanitizeData(String text) {
  return text.replaceAll(RegExp(r'\d{10,}'), '[SENSITIVE DATA]');
}
```

---

## 📈 خطط التطوير المستقبلية

- [ ] دعم المزيد من البنوك والعملات
- [x] تصدير التقارير بصيغة PDF/Excel
- [ ] رسوم بيانية تفاعلية
- [ ] تنبيهات ذكية عند تجاوز الميزانية
- [ ] مزامنة سحابية (اختيارية)
- [ ] دعم الفواتير والإيصالات المصورة
- [ ] تكامل مع تطبيقات المحاسبة

---

## 🤝 المساهمة

نرحب بالمساهمات! إذا كنت ترغب في المساهمة:

1. Fork المشروع
2. أنشئ فرع للميزة الجديدة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push للفرع (`git push origin feature/AmazingFeature`)
5. افتح Pull Request

---

## 🐛 الإبلاغ عن المشاكل

إذا واجهت أي مشكلة، يرجى فتح [Issue](https://github.com/garaahmad/autospend/issues) مع:
- وصف المشكلة
- خطوات إعادة إنتاج المشكلة
- لقطات شاشة (إن أمكن)
- معلومات الجهاز ونظام التشغيل

---

## 📄 الترخيص

هذا المشروع مرخص تحت رخصة MIT - انظر ملف [LICENSE](LICENSE) للتفاصيل.

---

## 👨‍💻 المطور

**Ahmad Gara**
- GitHub: [@garaahmad](https://github.com/garaahmad)

---

## 🙏 شكر وتقدير

- [Flutter Team](https://flutter.dev/) - إطار العمل الرائع
- [Hugging Face](https://huggingface.co/) - منصة الذكاء الاصطناعي
- [Meta AI](https://ai.meta.com/) - نموذج Llama 3.2
- [Google Fonts](https://fonts.google.com/) - الخطوط المستخدمة

---

## 📞 الدعم

إذا كان لديك أي استفسار:
- افتح [Issue](https://github.com/garaahmad/autospend/issues)
- تواصل عبر GitHub

---

<div align="center">

**صُنع بـ ❤️ باستخدام Flutter**

⭐ إذا أعجبك المشروع، لا تنسَ إعطائه نجمة!

</div>

---

# 🌐 English Version

## 📱 Overview

**AutoSpend AI** is an advanced Flutter application that uses artificial intelligence to automatically track your financial expenses by analyzing bank notifications and SMS messages. The app provides a smart dashboard, detailed reports, and an advanced transaction classification system.

### ✨ Key Features

- 🔄 **Automatic Monitoring**: Automatically track financial transactions from bank notifications
- 🤖 **Advanced AI**: Uses Llama 3.2 model for transaction analysis and data extraction
- 📊 **Comprehensive Reports**: Detailed expense view by merchant and category
- 📑 **Data Export**: Ability to export all reports and transactions to an Excel file
- 🏷️ **Smart Classification**: Automatic transaction categorization with custom categories
- 🌙 **Modern Interface**: Material 3 design with dark mode support
- 🌐 **Multi-language Support**: Full interface in Arabic and English
- 💾 **Local Database**: Secure data storage using SQLite
- 🔔 **Background Service**: Continuous background operation to capture notifications
- 🔗 **Deep Links**: iOS Shortcuts support for quick transaction addition

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.7 or newer
- Dart SDK 3.10.7 or newer
- Android Studio / VS Code
- Hugging Face account (for API Token)

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/garaahmad/autospend.git
cd autospend
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup Hugging Face API**
   - Create an account on [Hugging Face](https://huggingface.co/)
   - Get your API Token from [Settings > Access Tokens](https://huggingface.co/settings/tokens)
   - Open `lib/services/huggingface_service.dart`
   - Replace `_token` with your token:
   ```dart
   final String _token = 'YOUR_HUGGINGFACE_TOKEN_HERE';
   ```

4. **Run the app**
```bash
flutter run
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Developer

**Ahmad Gara**
- GitHub: [@garaahmad](https://github.com/garaahmad)

---

<div align="center">

**Made with ❤️ using Flutter**

⭐ If you like this project, don't forget to give it a star!

</div>
