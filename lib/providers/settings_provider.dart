import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _langKey = 'language_code';
  static const String _colorKey = 'primary_color';

  ThemeMode _themeMode = ThemeMode.dark;
  Locale _locale = const Locale('ar');
  Color _primaryColor = Colors.deepPurpleAccent;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  Color get primaryColor => _primaryColor;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    final langCode = prefs.getString(_langKey);
    if (langCode != null) {
      _locale = Locale(langCode);
    }

    final colorValue = prefs.getInt(_colorKey);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, color.value);
  }

  bool get isArabic => _locale.languageCode == 'ar';
}
