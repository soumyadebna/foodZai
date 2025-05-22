import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_mode_provider.dart';

class ThemeService {
  static const String _darkModeKey = 'dark_mode';
  static const String _themeModeKey = 'theme_mode';

  // Get the current theme mode
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();

    // First check if we have a theme_mode value (preferred)
    final themeModeIndex = prefs.getInt(_themeModeKey);
    if (themeModeIndex != null && themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length) {
      return ThemeMode.values[themeModeIndex];
    }

    // Fall back to the old dark_mode boolean if theme_mode isn't set
    final isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    return isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  // Set the theme mode
  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();

    // Save using both the new and old keys for compatibility
    await prefs.setInt(_themeModeKey, themeMode.index);
    await prefs.setBool(_darkModeKey, themeMode == ThemeMode.dark);

    debugPrint('Theme mode set to: $themeMode (index: ${themeMode.index})');
  }

  // Toggle the theme mode between light and dark
  static Future<ThemeMode> toggleThemeMode() async {
    final currentMode = await getThemeMode();
    final newMode = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;

    await setThemeMode(newMode);
    debugPrint('Theme toggled from $currentMode to $newMode');

    return newMode;
  }

  // Check if dark mode is enabled
  static Future<bool> isDarkMode() async {
    final themeMode = await getThemeMode();

    if (themeMode == ThemeMode.system) {
      // For system mode, we need to check the platform brightness
      // But since we can't access the platform brightness here,
      // we'll return false and let the UI handle it
      return false;
    }

    return themeMode == ThemeMode.dark;
  }

  // Update ThemeModeProvider from saved preferences
  static Future<void> updateThemeModeProvider(ThemeModeProvider provider) async {
    final themeMode = await getThemeMode();
    provider.setThemeMode(themeMode);
  }
}
