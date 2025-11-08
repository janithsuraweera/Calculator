import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vault_note.dart';
import '../services/vault_manager.dart';
import '../services/notes_manager.dart';

/// Note editor widget for creating and editing notes
class NoteEditor extends StatefulWidget {
  final VaultNote? note;
  final String? folderId;
  final VoidCallback? onSaved;

  const NoteEditor({super.key, this.note, this.folderId, this.onSaved});

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  DateTime? _reminderDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _tagsController.text = widget.note!.tags.join(', ');
      _reminderDate = widget.note!.reminderDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectReminderDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _reminderDate != null
            ? TimeOfDay.fromDateTime(_reminderDate!)
            : TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _reminderDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final tags = _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (widget.note != null) {
        // Update existing note
        final updatedNote = widget.note!.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          reminderDate: _reminderDate,
          tags: tags,
        );
        // Check if it's a vault note or main note
        if (widget.folderId != null || widget.note!.folderId != null) {
          await VaultManager.updateNote(updatedNote);
        } else {
          await NotesManager.updateNote(updatedNote);
        }
      } else {
        // Create new note
        if (widget.folderId != null) {
          // Vault note
          await VaultManager.saveNoteToVault(
            _titleController.text.trim(),
            _contentController.text.trim(),
            folderId: widget.folderId,
            reminderDate: _reminderDate,
            tags: tags,
          );
        } else {
          // Main note
          await NotesManager.saveNote(
            _titleController.text.trim(),
            _contentController.text.trim(),
            reminderDate: _reminderDate,
            tags: tags,
          );
        }
      }

      if (mounted) {
        // Show success message before navigating
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  widget.note != null
                      ? 'Note updated successfully'
                      : 'Note saved successfully',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Wait a bit for user to see the message
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving note: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note != null ? 'Edit Note' : 'New Note'),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter note title',
                border: OutlineInputBorder(),
              ),
              style: theme.textTheme.titleLarge,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Reminder
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: _reminderDate != null
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                title: const Text('Reminder'),
                subtitle: Text(
                  _reminderDate != null
                      ? '${_reminderDate!.toLocal().toString().split('.')[0]}'
                      : 'No reminder set',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_reminderDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _reminderDate = null);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectReminderDate,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'Enter tags separated by commas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),

            // Content
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Enter note content',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: null,
              minLines: 10,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ),
    );
  }
}
