# AutoSpend AI 💰🤖

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.7-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.10.7-0175C2?style=for-the-badge&logo=dart)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)

**Smart Expense Tracker Powered by Artificial Intelligence**

</div>

---

## 📱 Overview

**AutoSpend AI** is a cutting-edge Flutter application that leverages Artificial Intelligence to automatically track your financial expenses by analyzing bank notifications and SMS messages. The app provides a smart dashboard, detailed reports, and an advanced transaction classification system, giving you complete control over your financial life without manual data entry.

### ✨ Key Features

- 🔄 **Automatic Monitoring**: Seamlessly tracks financial transactions from bank SMS and notifications.
- 🤖 **Advanced AI Analysis**: Utilizes the **Llama 3.2** model to precisely parse transactions and extract metadata.
- 📊 **Comprehensive Reports**: Visualizes spending habits by merchant, category, and time period.
- 📑 **Excel Export**: detailed export of all transactions and reports to Excel spreadsheets.
- 🏷️ **Smart Classification**: Automatically categorizes transactions with support for custom user-defined categories.
- 🌙 **Modern Design**: Sleek Material 3 interface with full Dark Mode support.
- 🌐 **Multi-Language**: Fully localized interface in **English** and **Arabic**.
- 💾 **Local First**: Secure, offline-first architecture using SQLite for data privacy.
- 🔔 **Background Service**: Continuous background operation ensures no transaction is missed.
- 🔗 **Deep Linking**: iOS Shortcuts integration for quick manual entry via voice or text.

---

## 🎯 Use Cases

- **Individuals**: Effortless personal expense tracking and budget management.
- **Families**: Monitor household spending and analyze collective financial patterns.
- **Freelancers**: Separate and track business-related expenses automatically.
- **Students**: Manage monthly allowances and monitor discretionary spending.

---

## 🛠️ Technology Stack

### Frontend & UI
- **Flutter 3.10.7**: Core cross-platform framework.
- **Material Design 3**: Modern UI component system.
- **Google Fonts (Outfit & Cairo)**: Premium typography.
- **Provider**: Efficient state management.

### AI & Backend
- **Hugging Face API**: Gateway to Large Language Models.
- **Llama 3.2 3B Instruct**: The core intelligence for text analysis.
- **Google Generative AI**: Supplementary AI capabilities.

### Data & Storage
- **SQLite (sqflite)**: Robust local relational database.
- **SharedPreferences**: Lightweight key-value storage for settings.
- **Excel**: Library for generating spreadsheet reports.

### Services & System
- **Flutter Background Service**: Manages persistent background execution.
- **Notification Listener Service**: Captures incoming notification data.
- **Permission Handler**: Manages Android/iOS permissions.
- **App Links**: Handles deep linking for iOS shortcuts.

---

## 📦 Project Architecture

```
lib/
├── main.dart                          # Application Entry Point & Core Logic
├── providers/
│   └── settings_provider.dart        # State Management (Theme, Locale)
├── services/
│   ├── background_service.dart       # Background Process Manager
│   ├── database_service.dart         # SQLite Database Controller
│   └── huggingface_service.dart      # AI Integration Service
└── utils/
    └── translations.dart             # Localization Resources
```

### Key Screens

1.  **DashboardScreen**: The command center. Displays live monitoring status, daily/monthly summaries, and recent activity.
2.  **TransactionsHistoryScreen**: A consolidated view of spending history, grouped by merchant for cleaner tracking.
3.  **ReportsScreen**: Analytical view with categorical breakdowns and one-click Excel export.
4.  **SettingsScreen**: Configuration for themes, language, and system permissions.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.7+
- Dart SDK 3.10.7+
- Android Studio / VS Code
- Hugging Face Account (for API Token)

### Installation

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/garaahmad/autospend.git
    cd autospend
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Configure AI Service**
    - Obtain an API Token from [Hugging Face Settings](https://huggingface.co/settings/tokens).
    - Open `lib/services/huggingface_service.dart`.
    - Replace the placeholder with your token:
      ```dart
      final String _token = 'YOUR_HUGGINGFACE_TOKEN_HERE';
      ```

4.  **Run the App**
    ```bash
    flutter run
    ```

---

## ⚙️ Configuration & Permissions

### Android

The app requires specific permissions to function effectively (configured in `AndroidManifest.xml`):

```xml
<uses-permission android:name="android.permission.RECEIVE_SMS" />
<uses-permission android:name="android.permission.READ_SMS" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS Setup

To utilize the **iOS Shortcuts** integration:
1.  Open the **Shortcuts** app.
2.  Create a new shortcut.
3.  Add "Get Text from Input".
4.  Add "Open URL" with the scheme: `autospend://parse?content=[Input]`.

---

## 🔧 How It Works

1.  **Capture**: The background service intercepts relevant notifications or SMS.
2.  **Analyze**: The text is securely sent to the Llama 3.2 model via Hugging Face.
    ```dart
    // Returns: { "is_banking": true, "merchant": "Uber", "amount": 15.50 ... }
    ```
3.  **Process**: The app validates the data, extracts amounts, currencies, and categories.
4.  **Store**: Data is encrypted and saved to the local SQLite database.
5.  **Notify**: The UI updates instantly via Streams to reflect the new balance.

---

## 🔒 Privacy & Security

- **Local Storage**: Your financial data never leaves your device (except for anonymized analysis).
- **Data Sanitization**: Sensitive information (like account numbers) is redacted before AI processing.
- **Minimal Permissions**: We only request what is strictly necessary for the app to function.

---

## 📈 Future Roadmap

- [ ] Support for multi-currency wallets.
- [ ] Advanced graphical charts and trend analysis.
- [ ] Budget limit alerts and smart financial insights.
- [ ] Optional cloud backup integration.
- [ ] Receipt scanning and OCR support.

---

## 🤝 Contributing

Contributions are welcome!
1.  Fork the project.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes.
4.  Push to the branch.
5.  Open a Pull Request.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👨‍💻 Developer

**Ahmad Gara**
- GitHub: [@garaahmad](https://github.com/garaahmad)

---

<div align="center">

**Made with ❤️ using Flutter**

⭐ Star this repo if you find it useful!

</div>
# autospendP
