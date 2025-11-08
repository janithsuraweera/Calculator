import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/custom_button.dart';

/// Manager for custom calculator buttons
class CustomButtonManager {
  static const String _buttonsKey = 'custom_buttons';
  static const String _modesKey = 'custom_modes';

  /// Get all custom buttons for a specific mode
  static Future<List<CustomButton>> getCustomButtons(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buttonsJson = prefs.getString(_buttonsKey);

      if (buttonsJson == null || buttonsJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(buttonsJson);
      List<CustomButton> buttons = jsonList
          .map((json) => CustomButton.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter by mode
      buttons = buttons
          .where((b) => b.mode == mode || b.mode == 'all')
          .toList();

      // Sort by order
      buttons.sort((a, b) => a.order.compareTo(b.order));

      return buttons;
    } catch (e) {
      return [];
    }
  }

  /// Get all custom buttons
  static Future<List<CustomButton>> getAllCustomButtons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buttonsJson = prefs.getString(_buttonsKey);

      if (buttonsJson == null || buttonsJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(buttonsJson);
      List<CustomButton> buttons = jsonList
          .map((json) => CustomButton.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by order
      buttons.sort((a, b) => a.order.compareTo(b.order));

      return buttons;
    } catch (e) {
      return [];
    }
  }

  /// Save custom button
  static Future<bool> saveCustomButton(CustomButton button) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buttonsJson = prefs.getString(_buttonsKey);
      List<CustomButton> buttons = [];

      if (buttonsJson != null && buttonsJson.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(buttonsJson);
        buttons = jsonList
            .map((json) => CustomButton.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Check if button with same ID exists
      final index = buttons.indexWhere((b) => b.id == button.id);
      if (index != -1) {
        buttons[index] = button;
      } else {
        buttons.add(button);
      }

      final jsonList = buttons.map((b) => b.toJson()).toList();
      await prefs.setString(_buttonsKey, jsonEncode(jsonList));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete custom button
  static Future<bool> deleteCustomButton(String buttonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final buttonsJson = prefs.getString(_buttonsKey);

      if (buttonsJson == null || buttonsJson.isEmpty) {
        return false;
      }

      final List<dynamic> jsonList = jsonDecode(buttonsJson);
      List<CustomButton> buttons = jsonList
          .map((json) => CustomButton.fromJson(json as Map<String, dynamic>))
          .toList();

      buttons.removeWhere((b) => b.id == buttonId);
      final jsonList2 = buttons.map((b) => b.toJson()).toList();
      await prefs.setString(_buttonsKey, jsonEncode(jsonList2));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get custom modes
  static Future<List<String>> getCustomModes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modesJson = prefs.getString(_modesKey);

      if (modesJson == null || modesJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(modesJson);
      return jsonList.map((m) => m as String).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save custom mode
  static Future<bool> saveCustomMode(String modeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modes = await getCustomModes();

      if (!modes.contains(modeName)) {
        modes.add(modeName);
        await prefs.setString(_modesKey, jsonEncode(modes));
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete custom mode
  static Future<bool> deleteCustomMode(String modeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modes = await getCustomModes();

      modes.remove(modeName);
      await prefs.setString(_modesKey, jsonEncode(modes));

      // Also delete all buttons for this mode
      final buttons = await getAllCustomButtons();
      for (final button in buttons) {
        if (button.mode == modeName) {
          await deleteCustomButton(button.id);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
