import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_history.dart';

/// Manager for calculation history storage and retrieval
/// ගණනය කිරීමේ ඉතිහාසය store කිරීම සහ retrieve කිරීම සඳහා manager එක
class HistoryManager {
  static const String _historyKey = 'calculation_history';
  static const int _maxHistorySize = 100; // Maximum number of history entries

  /// Save calculation to history
  /// ගණනය කිරීම history එකට save කිරීම
  static Future<void> saveCalculation(String expression, String result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = getHistoryList(prefs);

      // Create new history entry
      // නව history entry එකක් create කිරීම
      final newEntry = CalculationHistory(
        expression: expression,
        result: result,
        timestamp: DateTime.now(),
      );

      // Add to beginning of list
      // List එකේ මුලට add කිරීම
      historyList.insert(0, newEntry);

      // Limit history size
      // History size limit කිරීම
      if (historyList.length > _maxHistorySize) {
        historyList.removeRange(_maxHistorySize, historyList.length);
      }

      // Save to preferences
      // Preferences වලට save කිරීම
      final jsonList = historyList.map((e) => e.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error silently
      // Error handle කිරීම silently
    }
  }

  /// Get all history entries
  /// History entries සියල්ල retrieve කිරීම
  static List<CalculationHistory> getHistory() {
    try {
      final prefs = SharedPreferences.getInstance();
      return getHistoryList(prefs as SharedPreferences);
    } catch (e) {
      return [];
    }
  }

  /// Get history list from preferences
  /// Preferences වලින් history list එක retrieve කිරීම
  static List<CalculationHistory> getHistoryList(SharedPreferences prefs) {
    try {
      final historyJson = prefs.getString(_historyKey);
      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(historyJson);
      return jsonList
          .map(
            (json) => CalculationHistory.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all history
  /// History සියල්ල clear කිරීම
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get history asynchronously
  /// History asynchronous වශයෙන් retrieve කිරීම
  static Future<List<CalculationHistory>> getHistoryAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return getHistoryList(prefs);
    } catch (e) {
      return [];
    }
  }
}
