import 'package:flutter/services.dart';
import 'calculator_engine.dart';

/// Manages clipboard integration for auto-calculation
class ClipboardManager {
  /// Check clipboard for mathematical expressions and calculate
  static Future<String?> checkAndCalculate() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null) return null;

      final text = clipboardData!.text!.trim();

      // Check if clipboard contains numbers or mathematical expressions
      if (_isMathematicalExpression(text)) {
        final result = CalculatorEngine.evaluate(text);
        return result;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if text looks like a mathematical expression
  static bool _isMathematicalExpression(String text) {
    // Simple heuristic: contains numbers and operators
    final hasNumbers = RegExp(r'\d').hasMatch(text);
    final hasOperators = RegExp(r'[+\-*/×÷^()]').hasMatch(text);

    return hasNumbers && (hasOperators || text.length > 3);
  }

  /// Copy result to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
