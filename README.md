# AutoSpend AI - Project Documentation & Design Brief

## 🚀 Project Overview
**AutoSpend AI** is a smart, automated expense tracker for Android. It eliminates the need for manual data entry by intercepting banking notifications (SMS, WhatsApp, and banking apps) and using **Artificial Intelligence** to extract transaction details in real-time.

---

## 🛠 Core Advantages & Features
The application is fully functional with the following "Advantages":

1.  **AI Interception Engine**: Integrated with **Hugging Face Llama 3.2** to analyze complex Arabic and English notification text.
2.  **Proactive Monitoring**: A robust background service (`FlutterBackgroundService`) that runs 24/7 without draining battery.
3.  **Smart Keyword Filtering**: Local logic that filters out non-financial notifications (OTPs, personal messages) before they even reach the AI, ensuring privacy and cost-efficiency.
4.  **Dynamic Whitelisting**: Automatically identifies and whitelists "Banking Apps" based on successful transaction detection.
5.  **Localized Experience**: Built-in support for **Arabic (RTL)** and **English (LTR)**, with a specific focus on regional banks (like BOP).
6.  **Data Persistence**: Secure local storage using SQLite for all captured transactions.
7.  **Real-time UI**: Instant "Toasts" and list refreshes when a new spending is detected in the background.

---

## 🎨 Design Brief (For UI/UX AI)
The next phase is a **Visual Overhaul**. I need a design that matches the "Premium AI" nature of the app.

### 1. Style Direction
- **Modern & Sleek**: Material 3 / Glassmorphism inspired.
- **Color Palette**: Sophisticated Deep Purple, Emerald Green (for amounts), and Slate Greys.
- **Animations**: Subtle micro-interactions for service toggles and transaction entries.

### 2. Key Screen Requirements
- **Dashboard**:
    - A prominent "Monitoring Status" card that clearly shows if the service is Active or Inactive.
    - An "Expense Summary" section (Today/This Month).
    - A scrollable list of "Recent Transactions".
- **Transaction Item**:
    - Clear Merchant name.
    - Large, readable Amount and Currency (e.g., 50 ILS).
    - Category icon (Shopping, Food, Transfer, etc.).
    - Relative timestamp (e.g., "2 mins ago").
- **Settings**:
    - Clean toggle for Dark/Light mode.
    - Language selector (Arabic/English).
    - Whitelisted apps management.

---

## 🏗 Technical Stack
- **Framework**: Flutter (Dart)
- **AI Engine**: Hugging Face Inference API (Llama 3.2 3B Instruct)
- **Database**: SQLite (sqflite)
- **Background Handling**: flutter_background_service + notification_listener_service

---

## 📖 Current Project Structure (For Context)
- `lib/services/background_service.dart`: The brain of the background monitoring.
- `lib/services/huggingface_service.dart`: The AI integration module.
- `lib/services/database_service.dart`: Handles local transaction storage.
- `lib/main.dart`: The core UI logic (currently functional, awaiting design).
- `lib/utils/translations.dart`: Multi-language string management.
