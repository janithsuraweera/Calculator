import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/vault_note.dart';

/// Manager for main notes (outside vault)
class NotesManager {
  static const String _notesKey = 'main_notes';

  /// Save note
  static Future<VaultNote?> saveNote(
    String title,
    String content, {
    DateTime? reminderDate,
    List<String> tags = const [],
  }) async {
    try {
      final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      final note = VaultNote(
        id: noteId,
        title: title,
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        reminderDate: reminderDate,
        tags: tags,
      );

      await _saveNoteMetadata(note);
      return note;
    } catch (e) {
      return null;
    }
  }

  /// Update note
  static Future<bool> updateNote(VaultNote note) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);

      if (notesJson == null || notesJson.isEmpty) {
        return false;
      }

      final List<dynamic> jsonList = jsonDecode(notesJson);
      List<VaultNote> notes = jsonList
          .map((json) => VaultNote.fromJson(json as Map<String, dynamic>))
          .toList();

      final index = notes.indexWhere((n) => n.id == note.id);
      if (index == -1) return false;

      notes[index] = note.copyWith(updatedAt: DateTime.now());
      final jsonList2 = notes.map((n) => n.toJson()).toList();
      await prefs.setString(_notesKey, jsonEncode(jsonList2));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Save note metadata
  static Future<void> _saveNoteMetadata(VaultNote note) async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getString(_notesKey);
    List<VaultNote> notes = [];

    if (notesJson != null && notesJson.isNotEmpty) {
      final List<dynamic> jsonList = jsonDecode(notesJson);
      notes = jsonList
          .map((json) => VaultNote.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    notes.add(note);
    final jsonList = notes.map((n) => n.toJson()).toList();
    await prefs.setString(_notesKey, jsonEncode(jsonList));
  }

  /// Get all notes
  static Future<List<VaultNote>> getNotes({
    bool onlyWithReminders = false,
    String? searchQuery,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);

      if (notesJson == null || notesJson.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(notesJson);
      List<VaultNote> notes = jsonList
          .map((json) => VaultNote.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter by reminders
      if (onlyWithReminders) {
        notes = notes.where((n) => n.hasReminder).toList();
      }

      // Filter by search query
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        notes = notes.where((note) {
          return note.title.toLowerCase().contains(query) ||
              note.content.toLowerCase().contains(query) ||
              note.tags.any((tag) => tag.toLowerCase().contains(query));
        }).toList();
      }

      // Sort by reminder date (due first) or created date
      notes.sort((a, b) {
        if (a.hasReminder && b.hasReminder) {
          return a.reminderDate!.compareTo(b.reminderDate!);
        } else if (a.hasReminder) {
          return -1;
        } else if (b.hasReminder) {
          return 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });

      return notes;
    } catch (e) {
      return [];
    }
  }

  /// Delete note
  static Future<bool> deleteNote(String noteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);

      if (notesJson == null || notesJson.isEmpty) {
        return false;
      }

      final List<dynamic> jsonList = jsonDecode(notesJson);
      List<VaultNote> notes = jsonList
          .map((json) => VaultNote.fromJson(json as Map<String, dynamic>))
          .toList();

      notes.removeWhere((n) => n.id == noteId);
      final jsonList2 = notes.map((n) => n.toJson()).toList();
      await prefs.setString(_notesKey, jsonEncode(jsonList2));

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Export all data for Google Cloud backup
  static Future<Map<String, dynamic>> exportAllData() async {
    try {
      final notes = await getNotes();

      return {
        'notes': notes.map((n) => n.toJson()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      return {};
    }
  }
}
