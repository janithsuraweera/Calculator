import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:convert';
import '../models/calculation_history.dart';

/// Manages secure vault for sensitive calculations
class VaultManager {
  static const String _vaultKey = 'secure_vault';
  static const String _vaultEnabledKey = 'vault_enabled';
  static final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if vault is enabled
  static Future<bool> isVaultEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vaultEnabledKey) ?? false;
  }

  /// Enable/disable vault
  static Future<void> setVaultEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vaultEnabledKey, enabled);
  }

  /// Check if device supports biometric authentication
  static Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user (PIN or biometric)
  static Future<bool> authenticate() async {
    try {
      final isAvailable = await isBiometricAvailable();

      if (isAvailable) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to access secure vault',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        return authenticated;
      }

      // Fallback to PIN if biometric not available
      // PIN authentication would be implemented separately
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Save calculation to vault
  static Future<void> saveToVault(String expression, String result) async {
    final authenticated = await authenticate();
    if (!authenticated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final vaultJson = prefs.getString(_vaultKey);
      List<CalculationHistory> vaultList = [];

      if (vaultJson != null && vaultJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(vaultJson);
        vaultList = jsonList
            .map(
              (json) =>
                  CalculationHistory.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      final newEntry = CalculationHistory(
        expression: expression,
        result: result,
        timestamp: DateTime.now(),
      );

      vaultList.insert(0, newEntry);

      // Limit vault size
      if (vaultList.length > 50) {
        vaultList.removeRange(50, vaultList.length);
      }

      final jsonList = vaultList.map((e) => e.toJson()).toList();
      await prefs.setString(_vaultKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get vault entries (requires authentication)
  static Future<List<CalculationHistory>> getVaultEntries() async {
    final authenticated = await authenticate();
    if (!authenticated) return [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final vaultJson = prefs.getString(_vaultKey);

      if (vaultJson == null || vaultJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(vaultJson);
      return jsonList
          .map(
            (json) => CalculationHistory.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear vault
  static Future<void> clearVault() async {
    final authenticated = await authenticate();
    if (!authenticated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vaultKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
