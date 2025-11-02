import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme manager for handling light/dark themes and accent colors
class ThemeManager {
  static const String _themeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _lightTheme = 'light';
  static const String _darkTheme = 'dark';

  /// Available accent colors
  static final List<Color> accentColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.pink,
    Colors.red,
    Colors.teal,
    Colors.cyan,
    Colors.indigo,
    Colors.amber,
  ];

  /// Get current theme mode
  static Future<ThemeMode> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey) ?? _lightTheme;
      return themeString == _darkTheme ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      return ThemeMode.light;
    }
  }

  /// Set theme mode
  static Future<void> setThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = mode == ThemeMode.dark ? _darkTheme : _lightTheme;
      await prefs.setString(_themeKey, themeString);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get current accent color index
  static Future<int> getAccentColorIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_accentColorKey) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Set accent color index
  static Future<void> setAccentColorIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (index >= 0 && index < accentColors.length) {
        await prefs.setInt(_accentColorKey, index);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get accent color by index
  static Color getAccentColor(int index) {
    if (index >= 0 && index < accentColors.length) {
      return accentColors[index];
    }
    return accentColors[0];
  }

  /// Build theme data
  static ThemeData buildThemeData(ThemeMode mode, Color accentColor) {
    final brightness = mode == ThemeMode.dark
        ? Brightness.dark
        : Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: brightness,
      ),
    );
  }
}
