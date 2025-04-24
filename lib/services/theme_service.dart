import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  // Keys for shared preferences
  static const String _themePreferenceKey = 'theme_preference';
  static const String _useDynamicColorsKey = 'use_dynamic_colors';

  // Theme mode options
  static const String _lightTheme = 'light';
  static const String _darkTheme = 'dark';
  static const String _systemTheme = 'system';

  // Singleton instance
  static final ThemeService _instance = ThemeService._internal();

  // Factory constructor
  factory ThemeService() => _instance;

  // Internal constructor
  ThemeService._internal();

  // Get the current theme mode from shared preferences
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themePreference = prefs.getString(_themePreferenceKey) ?? _systemTheme;

    switch (themePreference) {
      case _lightTheme:
        return ThemeMode.light;
      case _darkTheme:
        return ThemeMode.dark;
      case _systemTheme:
      default:
        return ThemeMode.system;
    }
  }

  // Save the theme mode to shared preferences
  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themePreference;

    switch (themeMode) {
      case ThemeMode.light:
        themePreference = _lightTheme;
        break;
      case ThemeMode.dark:
        themePreference = _darkTheme;
        break;
      case ThemeMode.system:
      default:
        themePreference = _systemTheme;
        break;
    }

    await prefs.setString(_themePreferenceKey, themePreference);
  }

  // Get whether to use dynamic colors
  Future<bool> getUseDynamicColors() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useDynamicColorsKey) ?? true;
  }

  // Save whether to use dynamic colors
  Future<void> setUseDynamicColors(bool useDynamicColors) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useDynamicColorsKey, useDynamicColors);
  }

  // Get theme mode as a string for display
  String getThemeModeString(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
      default:
        return 'System';
    }
  }
}
