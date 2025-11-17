import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculation_history.dart';

/// Manager for calculation history storage and retrieval

class HistoryManager {
  static const String _historyKey = 'calculation_history';
  static const int _maxHistorySize = 100; // Maximum number of history entries

  /// Save calculation to history

  static Future<void> saveCalculation(
    String expression,
    String result, {
    String? label,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = getHistoryList(prefs);

      // Create new history entry

      final newEntry = CalculationHistory(
        expression: expression,
        result: result,
        timestamp: DateTime.now(),
        label: label,
      );

      // Add to beginning of list

      historyList.insert(0, newEntry);

      // Limit history size

      if (historyList.length > _maxHistorySize) {
        historyList.removeRange(_maxHistorySize, historyList.length);
      }

      // Save to preferences

      final jsonList = historyList.map((e) => e.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get all history entries

  static List<CalculationHistory> getHistory() {
    try {
      final prefs = SharedPreferences.getInstance();
      return getHistoryList(prefs as SharedPreferences);
    } catch (e) {
      return [];
    }
  }

  /// Get history list from preferences

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

  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get history asynchronously

  static Future<List<CalculationHistory>> getHistoryAsync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return getHistoryList(prefs);
    } catch (e) {
      return [];
    }
  }

  /// Update the label associated with a history entry identified by timestamp
  static Future<void> updateHistoryLabel(
    DateTime timestamp,
    String? label,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = getHistoryList(prefs);
      final index = historyList.indexWhere(
        (item) => item.timestamp.isAtSameMomentAs(timestamp),
      );
      if (index == -1) return;

      final entry = historyList[index];
      historyList[index] = CalculationHistory(
        expression: entry.expression,
        result: entry.result,
        timestamp: entry.timestamp,
        label: label,
      );

      final jsonList = historyList.map((e) => e.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Move history item up (towards the top of the list)
  static Future<bool> moveItemUp(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = getHistoryList(prefs);
      final index = historyList.indexWhere(
        (item) => item.timestamp.isAtSameMomentAs(timestamp),
      );
      if (index == -1 || index == 0) return false; // Already at top

      // Swap with item above
      final temp = historyList[index];
      historyList[index] = historyList[index - 1];
      historyList[index - 1] = temp;

      final jsonList = historyList.map((e) => e.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Move history item down (towards the bottom of the list)
  static Future<bool> moveItemDown(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyList = getHistoryList(prefs);
      final index = historyList.indexWhere(
        (item) => item.timestamp.isAtSameMomentAs(timestamp),
      );
      if (index == -1 || index == historyList.length - 1) {
        return false; // Already at bottom
      }

      // Swap with item below
      final temp = historyList[index];
      historyList[index] = historyList[index + 1];
      historyList[index + 1] = temp;

      final jsonList = historyList.map((e) => e.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
      return true;
    } catch (e) {
      return false;
    }
  }
}
