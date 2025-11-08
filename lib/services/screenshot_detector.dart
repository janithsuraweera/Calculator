import 'package:flutter/material.dart';
import '../services/notes_manager.dart';

/// Detects screenshots and shows notes
/// Note: Screenshot detection requires platform-specific implementation
class ScreenshotDetector {
  static bool _isEnabled = false;
  static BuildContext? _context;

  /// Initialize screenshot detection
  static void initialize(BuildContext context) {
    _context = context;
    // Platform-specific screenshot detection would be implemented here
    // For now, this is a placeholder
  }

  /// Enable/disable screenshot detection
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if enabled
  static bool isEnabled() {
    return _isEnabled;
  }

  /// Handle screenshot detection (called by platform channel)
  static Future<void> onScreenshotDetected() async {
    if (!_isEnabled || _context == null) return;
    final context = _context!;
    // Get notes with reminders
    final notes = await NotesManager.getNotes(onlyWithReminders: true);

    if (notes.isEmpty) return;

    // Show dialog with notes
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reminder Notes'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return ListTile(
                  leading: Icon(
                    note.isReminderDue
                        ? Icons.notifications_active
                        : Icons.notifications,
                    color: note.isReminderDue ? Colors.red : Colors.blue,
                  ),
                  title: Text(note.title),
                  subtitle: Text(
                    note.reminderDate != null
                        ? 'Reminder: ${note.reminderDate!.toLocal().toString().split('.')[0]}'
                        : note.content,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// Dispose
  static void dispose() {
    _context = null;
  }
}
