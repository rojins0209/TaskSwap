import 'package:flutter/material.dart';
import 'package:taskswap/services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColors = true;
  final ThemeService _themeService = ThemeService();

  ThemeProvider() {
    _loadPreferences();
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    _themeMode = await _themeService.getThemeMode();
    _useDynamicColors = await _themeService.getUseDynamicColors();
    notifyListeners();
  }

  // Get theme mode
  Future<ThemeMode> getThemeMode() async {
    return await _themeService.getThemeMode();
  }

  // Get whether to use dynamic colors
  Future<bool> getUseDynamicColors() async {
    return await _themeService.getUseDynamicColors();
  }

  // Getters
  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColors => _useDynamicColors;

  // Set theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;

    _themeMode = themeMode;
    await _themeService.setThemeMode(themeMode);
    notifyListeners();
  }

  // Toggle theme mode between light and dark
  Future<void> toggleThemeMode() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      // If system, default to light
      await setThemeMode(ThemeMode.light);
    }
  }

  // Set whether to use dynamic colors
  Future<void> setUseDynamicColors(bool useDynamicColors) async {
    if (_useDynamicColors == useDynamicColors) return;

    _useDynamicColors = useDynamicColors;
    await _themeService.setUseDynamicColors(useDynamicColors);
    notifyListeners();
  }

  // Get theme mode as a string for display
  String getThemeModeString() {
    return _themeService.getThemeModeString(_themeMode);
  }
}
