import 'package:shared_preferences/shared_preferences.dart';

/// Premium manager for handling premium features and activation
class PremiumManager {
  static const String _premiumKey = 'premium_status';
  static const String _premiumCodeKey = 'premium_code';

  // Valid premium codes (you can add more)
  static const List<String> _validCodes = [
    '1234jhs',
    'SMARTCALC2024',
    'PREMIUM2024',
  ];

  /// Check if premium is activated
  static Future<bool> isPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_premiumKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Activate premium with code
  static Future<bool> activatePremium(String code) async {
    try {
      // Normalize code (remove spaces, convert to lowercase)
      final normalizedCode = code.trim().toLowerCase();

      // Check if code is valid
      final isValid = _validCodes.any(
        (validCode) => validCode.toLowerCase() == normalizedCode,
      );

      if (!isValid) {
        return false;
      }

      // Save premium status and code
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, true);
      await prefs.setString(_premiumCodeKey, normalizedCode);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deactivate premium (for testing)
  static Future<void> deactivatePremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_premiumKey, false);
      await prefs.remove(_premiumCodeKey);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get premium code (if activated)
  static Future<String?> getPremiumCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_premiumCodeKey);
    } catch (e) {
      return null;
    }
  }

  /// Validate a premium code format (without activating)
  static bool isValidCodeFormat(String code) {
    return code.trim().isNotEmpty && code.length >= 4;
  }
}
