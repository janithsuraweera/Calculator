import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

/// Manages haptic feedback and sound effects
class HapticSoundManager {
  static const String _hapticIntensityKey = 'haptic_intensity';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _soundThemeKey = 'sound_theme';

  // Haptic intensity levels
  static const String light = 'light';
  static const String medium = 'medium';
  static const String heavy = 'heavy';

  // Sound themes
  static const String classic = 'classic';
  static const String modern = 'modern';
  static const String minimal = 'minimal';

  /// Get haptic intensity preference
  static Future<String> getHapticIntensity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_hapticIntensityKey) ?? medium;
  }

  /// Set haptic intensity preference
  static Future<void> setHapticIntensity(String intensity) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_hapticIntensityKey, intensity);
  }

  /// Check if sound is enabled
  static Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  /// Set sound enabled/disabled
  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  /// Get sound theme
  static Future<String> getSoundTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_soundThemeKey) ?? classic;
  }

  /// Set sound theme
  static Future<void> setSoundTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundThemeKey, theme);
  }

  /// Trigger haptic feedback
  static Future<void> triggerHaptic() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    final intensity = await getHapticIntensity();

    switch (intensity) {
      case light:
        await HapticFeedback.lightImpact();
        break;
      case medium:
        await HapticFeedback.mediumImpact();
        break;
      case heavy:
        await HapticFeedback.heavyImpact();
        break;
      default:
        await HapticFeedback.mediumImpact();
    }
  }

  /// Play button click sound
  static Future<void> playClickSound() async {
    final enabled = await isSoundEnabled();
    if (!enabled) return;

    try {
      final theme = await getSoundTheme();

      // Play system sound based on theme
      switch (theme) {
        case classic:
          await SystemSound.play(SystemSoundType.click);
          break;
        case modern:
          await HapticFeedback.selectionClick();
          await SystemSound.play(SystemSoundType.click);
          break;
        case minimal:
          await HapticFeedback.selectionClick();
          break;
        default:
          await SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      // Fallback to system sound
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
