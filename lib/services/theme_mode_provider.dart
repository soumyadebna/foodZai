import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_service.dart';

class ThemeModeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  static const String _themeModeKey = 'theme_mode';

  ThemeMode get themeMode => _themeMode;

  ThemeModeProvider() {
    _loadThemeMode();
  }

  // Load theme mode from shared preferences
  Future<void> _loadThemeMode() async {
    try {
      // Use ThemeService to get the theme mode
      final mode = await ThemeService.getThemeMode();

      if (_themeMode != mode) {
        _themeMode = mode;
        notifyListeners();
        debugPrint('Theme mode loaded: $_themeMode');
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
      // Default to system theme if there's an error
      _themeMode = ThemeMode.system;
    }
  }

  // Set theme mode and save to shared preferences
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      // Use ThemeService to save the theme mode
      await ThemeService.setThemeMode(mode);
      debugPrint('Theme mode set to: $_themeMode');
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  // Toggle between light and dark mode
  Future<void> toggleThemeMode() async {
    final newMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  // Set dark mode specifically
  Future<void> setDarkMode(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  // Check if dark mode is active
  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      // Get system brightness
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Force refresh the theme mode from storage
  Future<void> refreshThemeMode() async {
    await _loadThemeMode();
  }

  // Static method to get the provider from context
  static ThemeModeProvider of(BuildContext context) {
    return Provider.of<ThemeModeProvider>(context, listen: false);
  }
}
