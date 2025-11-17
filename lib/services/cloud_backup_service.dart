import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/notes_manager.dart';
import '../services/history_manager.dart';
import '../models/cloud_backup_config.dart';

/// Google Cloud backup service
/// Note: Requires google_sign_in and firebase_storage packages
/// For now, this provides a basic structure
class CloudBackupService {
  static bool _isSignedIn = false;
  static String? _userEmail;
  static const String _configKey = 'cloud_backup_config';
  static const String _signedInKey = 'cloud_backup_signed_in';

  /// Configure and enable cloud backup
  static Future<bool> signIn(CloudBackupConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configKey, jsonEncode(config.toJson()));
      await prefs.setBool(_signedInKey, true);
      _isSignedIn = true;
      _userEmail = config.email;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signedInKey);
    await prefs.remove(_configKey);
    _isSignedIn = false;
    _userEmail = null;
  }

  /// Check if signed in
  static Future<bool> isSignedIn() async {
    if (_isSignedIn) return true;
    final prefs = await SharedPreferences.getInstance();
    final signedIn = prefs.getBool(_signedInKey) ?? false;
    if (signedIn) {
      final configJson = prefs.getString(_configKey);
      if (configJson != null) {
        final config = CloudBackupConfig.fromJson(
          jsonDecode(configJson) as Map<String, dynamic>,
        );
        _userEmail = config.email;
      }
      _isSignedIn = true;
    }
    return signedIn;
  }

  /// Get current user
  static Future<String?> getCurrentUserEmail() async {
    if (_userEmail != null) return _userEmail;
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);
    if (configJson == null) return null;
    final config = CloudBackupConfig.fromJson(
      jsonDecode(configJson) as Map<String, dynamic>,
    );
    _userEmail = config.email;
    return _userEmail;
  }

  static Future<CloudBackupConfig?> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString(_configKey);
    if (configJson == null) return null;
    return CloudBackupConfig.fromJson(
      jsonDecode(configJson) as Map<String, dynamic>,
    );
  }

  /// Backup all data to Google Cloud
  static Future<bool> backupAllData() async {
    try {
      if (!await isSignedIn()) {
        return false;
      }

      // Collect all data
      final config = await getConfig();
      final includeNotes = config?.includeNotes ?? true;
      final includeHistory = config?.includeHistory ?? true;
      final notes = includeNotes ? await NotesManager.getNotes() : [];
      final history = includeHistory
          ? await HistoryManager.getHistoryAsync()
          : [];
      final prefs = await SharedPreferences.getInstance();

      // Get all preferences
      final allPrefs = <String, dynamic>{};
      final keys = prefs.getKeys();
      for (final key in keys) {
        final value = prefs.get(key);
        if (value != null) {
          allPrefs[key] = value;
        }
      }

      final backupData = {
        'notes': notes.map((n) => n.toJson()).toList(),
        'history': history.map((h) => h.toJson()).toList(),
        'preferences': allPrefs,
        'backupDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'config': config?.toJson(),
      };

      // Convert to JSON
      final jsonData = jsonEncode(backupData);

      // Upload to Firebase Storage
      // Note: Requires firebase_storage package
      // final storage = FirebaseStorage.instance;
      // final fileName = 'calculator_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      // final ref = storage.ref().child('backups/$fileName');
      // await ref.putData(bytes, SettableMetadata(...));

      // For now, save locally as backup
      final prefsInstance = await SharedPreferences.getInstance();
      await prefsInstance.setString('cloud_backup_data', jsonData);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Restore data from Google Cloud
  static Future<bool> restoreData() async {
    try {
      if (!await isSignedIn()) {
        return false;
      }

      // Restore from local backup for now
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('cloud_backup_data');
      if (jsonData == null) return false;

      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;

      // Restore notes
      if (backupData.containsKey('notes')) {
        // Notes restoration would be implemented here
        // For now, notes are managed separately
      }

      // Restore history
      if (backupData.containsKey('history')) {
        // History restoration would be implemented here
        // final historyJson = backupData['history'] as List;
        // for (final item in historyJson) {
        //   final history = CalculationHistory.fromJson(item as Map<String, dynamic>);
        //   await HistoryManager.saveCalculation(history.expression, history.result);
        // }
      }

      // Restore preferences
      if (backupData.containsKey('preferences')) {
        final prefs = await SharedPreferences.getInstance();
        final preferences = backupData['preferences'] as Map<String, dynamic>;
        for (final entry in preferences.entries) {
          final key = entry.key;
          final value = entry.value;
          if (value is String) {
            await prefs.setString(key, value);
          } else if (value is int) {
            await prefs.setInt(key, value);
          } else if (value is bool) {
            await prefs.setBool(key, value);
          } else if (value is double) {
            await prefs.setDouble(key, value);
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
