import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../services/vault_manager.dart';
import '../models/vault_file.dart';
import '../models/vault_folder.dart';
import '../models/vault_note.dart';
import 'vault_pin_dialog.dart';
import 'note_editor.dart';

/// Vault browser screen with folders, files, and categories
class VaultBrowser extends StatefulWidget {
  const VaultBrowser({super.key});

  @override
  State<VaultBrowser> createState() => _VaultBrowserState();
}

class _VaultBrowserState extends State<VaultBrowser> {
  String? _currentFolderId;
  VaultFileType? _selectedCategory;
  bool _showHidden = false;
  List<VaultFile> _files = [];
  List<VaultFolder> _folders = [];
  List<VaultNote> _notes = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;
  int _selectedViewIndex = 0; // 0: Files, 1: Notes

  @override
  void initState() {
    super.initState();
    _authenticateAndLoad();
  }

  Future<void> _authenticateAndLoad() async {
    setState(() => _isAuthenticating = true);
    final hasPin = await VaultManager.hasPin();
    if (!hasPin) {
      // No PIN set - show setup
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const VaultPinDialog(isSetup: true),
      );
      if (result == true && mounted) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
        _loadData();
      } else if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isAuthenticating = false;
        });
      }
    } else {
      // Authenticate
      final authenticated = await showDialog<bool>(
        context: context,
        builder: (context) => const VaultPinDialog(isSetup: false),
      );
      if (authenticated == true && mounted) {
        setState(() {
          _isAuthenticated = true;
          _isAuthenticating = false;
        });
        _loadData();
      } else if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isAuthenticating = false;
        });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final files = await VaultManager.getVaultFiles(
      folderId: _currentFolderId,
      type: _selectedCategory,
      includeHidden: _showHidden,
    );
    final folders = await VaultManager.getVaultFolders(
      parentFolderId: _currentFolderId,
      includeHidden: _showHidden,
    );
    final notes = await VaultManager.getVaultNotes(
      folderId: _currentFolderId,
      includeHidden: _showHidden,
    );
    setState(() {
      _files = files;
      _folders = folders;
      _notes = notes;
      _isLoading = false;
    });
  }

  Future<void> _addFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final platformFile in result.files) {
          if (platformFile.path != null) {
            final file = File(platformFile.path!);
            if (await file.exists()) {
              await VaultManager.saveFileToVault(
                file,
                _currentFolderId,
                isHidden: false,
              );
            }
          }
        }
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Files added to vault')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding file: $e')));
      }
    }
  }

  Future<void> _createFolder() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter folder name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, nameController.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await VaultManager.createFolder(result, parentFolderId: _currentFolderId);
      _loadData();
    }
  }

  Future<void> _deleteFile(VaultFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await VaultManager.deleteFile(file.id);
      _loadData();
    }
  }

  Future<void> _toggleFileVisibility(VaultFile file) async {
    await VaultManager.toggleFileVisibility(file.id);
    _loadData();
  }

  void _navigateToFolder(VaultFolder? folder) {
    setState(() {
      _currentFolderId = folder?.id;
    });
    _loadData();
  }

  void _filterByCategory(VaultFileType? type) {
    setState(() {
      _selectedCategory = type;
    });
    _loadData();
  }

  Future<void> _changePin() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const VaultPinDialog(isChangePin: true),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PIN changed successfully')));
    }
  }

  Future<void> _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          folderId: _currentFolderId, // Vault note (secret note)
          onSaved: _loadData,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _editNote(VaultNote note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditor(
          note: note,
          folderId: _currentFolderId,
          onSaved: _loadData,
        ),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteNote(VaultNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await VaultManager.deleteNote(note.id);
      _loadData();
    }
  }

  Future<void> _backupToGmail() async {
    try {
      final emailBody = await VaultManager.exportNotesToEmail();
      if (emailBody.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No notes to backup')));
        }
        return;
      }

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: '', // User will enter their email
        queryParameters: {
          'subject':
              'Vault Notes Backup - ${DateTime.now().toString().split(' ')[0]}',
          'body': emailBody,
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening email client...')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email client')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error backing up: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentFolderId == null ? 'Vault' : 'Folder'),
        leading: _currentFolderId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _navigateToFolder(null),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(_showHidden ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _showHidden = !_showHidden);
              _loadData();
            },
            tooltip: _showHidden ? 'Hide hidden files' : 'Show hidden files',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'add_file':
                  _addFile();
                  break;
                case 'create_folder':
                  _createFolder();
                  break;
                case 'add_note':
                  _addNote();
                  break;
                case 'backup_gmail':
                  await _backupToGmail();
                  break;
                case 'change_pin':
                  await _changePin();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (_selectedViewIndex == 0) ...[
                const PopupMenuItem(
                  value: 'add_file',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Add File'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'create_folder',
                  child: Row(
                    children: [
                      Icon(Icons.folder),
                      SizedBox(width: 8),
                      Text('Create Folder'),
                    ],
                  ),
                ),
              ],
              if (_selectedViewIndex == 1) ...[
                const PopupMenuItem(
                  value: 'add_note',
                  child: Row(
                    children: [
                      Icon(Icons.note_add),
                      SizedBox(width: 8),
                      Text('Add Secret Note'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'backup_gmail',
                  child: Row(
                    children: [
                      Icon(Icons.email),
                      SizedBox(width: 8),
                      Text('Backup to Gmail'),
                    ],
                  ),
                ),
              ],
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'change_pin',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset),
                    SizedBox(width: 8),
                    Text('Change PIN'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs for Files/Notes
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(context, 'Files', Icons.folder, 0),
                ),
                Expanded(
                  child: _buildTabButton(context, 'Notes', Icons.note, 1),
                ),
              ],
            ),
          ),
          // Category filter (only for Files view)
          if (_selectedViewIndex == 0)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip(context, 'All', null, Icons.grid_view),
                  _buildCategoryChip(
                    context,
                    'Photos',
                    VaultFileType.photo,
                    Icons.image,
                  ),
                  _buildCategoryChip(
                    context,
                    'Videos',
                    VaultFileType.video,
                    Icons.video_library,
                  ),
                  _buildCategoryChip(
                    context,
                    'Audio',
                    VaultFileType.audio,
                    Icons.audio_file,
                  ),
                  _buildCategoryChip(
                    context,
                    'Documents',
                    VaultFileType.document,
                    Icons.description,
                  ),
                ],
              ),
            ),
          if (_selectedViewIndex == 0) const Divider(height: 1),
          // Content
          Expanded(
            child: _isAuthenticating
                ? const Center(child: CircularProgressIndicator())
                : !_isAuthenticated
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 64,
                          color: colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Vault is locked',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _authenticateAndLoad,
                          child: const Text('Unlock Vault'),
                        ),
                      ],
                    ),
                  )
                : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedViewIndex == 0
                ? _buildFilesView()
                : _buildNotesView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedViewIndex == 0 ? _addFile : _addNote,
        child: Icon(_selectedViewIndex == 0 ? Icons.add : Icons.note_add),
        tooltip: _selectedViewIndex == 0 ? 'Add File' : 'Add Note',
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    String label,
    IconData icon,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedViewIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedViewIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_files.isEmpty && _folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Vault is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add files or create folders',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Folders
        if (_folders.isNotEmpty) ...[
          Text(
            'Folders',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._folders.map((folder) => _buildFolderTile(folder)),
          const SizedBox(height: 16),
        ],
        // Files
        if (_files.isNotEmpty) ...[
          Text(
            'Files',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._files.map((file) => _buildFileTile(file)),
        ],
      ],
    );
  }

  Widget _buildNotesView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No secret notes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to create a secret note',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [..._notes.map((note) => _buildNoteTile(note))],
    );
  }

  Widget _buildNoteTile(VaultNote note) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          note.hasReminder
              ? (note.isReminderDue
                    ? Icons.notifications_active
                    : Icons.notifications)
              : Icons.note,
          color: note.isReminderDue ? colorScheme.error : colorScheme.primary,
          size: 40,
        ),
        title: Text(note.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note.content.length > 100
                  ? '${note.content.substring(0, 100)}...'
                  : note.content,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (note.hasReminder)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: note.isReminderDue
                          ? colorScheme.errorContainer
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      note.isReminderDue
                          ? 'Due: ${note.reminderDate!.toLocal().toString().split('.')[0]}'
                          : 'Reminder: ${note.reminderDate!.toLocal().toString().split('.')[0]}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: note.isReminderDue
                            ? colorScheme.onErrorContainer
                            : colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
                if (note.hasReminder && note.tags.isNotEmpty)
                  const SizedBox(width: 4),
                if (note.tags.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: note.tags.take(3).map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
              ],
            ),
            if (note.isHidden)
              Text(
                'Hidden',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _editNote(note);
                break;
              case 'hide':
                await VaultManager.toggleNoteVisibility(note.id);
                _loadData();
                break;
              case 'delete':
                await _deleteNote(note);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 8), Text('Edit')],
              ),
            ),
            PopupMenuItem(
              value: 'hide',
              child: Row(
                children: [
                  Icon(note.isHidden ? Icons.visibility : Icons.visibility_off),
                  const SizedBox(width: 8),
                  Text(note.isHidden ? 'Show' : 'Hide'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _editNote(note),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    String label,
    VaultFileType? type,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedCategory == type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => _filterByCategory(type),
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildFolderTile(VaultFolder folder) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.folder, color: colorScheme.primary, size: 40),
        title: Text(folder.name),
        subtitle: Text(
          folder.isHidden ? 'Hidden' : 'Folder',
          style: theme.textTheme.bodySmall?.copyWith(
            color: folder.isHidden
                ? colorScheme.error
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'open':
                _navigateToFolder(folder);
                break;
              case 'hide':
                await VaultManager.toggleFolderVisibility(folder.id);
                _loadData();
                break;
              case 'delete':
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Folder'),
                    content: Text(
                      'Are you sure you want to delete "${folder.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await VaultManager.deleteFolder(folder.id);
                  _loadData();
                }
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'hide',
              child: Row(
                children: [
                  Icon(
                    folder.isHidden ? Icons.visibility : Icons.visibility_off,
                  ),
                  const SizedBox(width: 8),
                  Text(folder.isHidden ? 'Show' : 'Hide'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _navigateToFolder(folder),
      ),
    );
  }

  Widget _buildFileTile(VaultFile file) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String fileSize;
    if (file.size < 1024) {
      fileSize = '${file.size} B';
    } else if (file.size < 1024 * 1024) {
      fileSize = '${(file.size / 1024).toStringAsFixed(1)} KB';
    } else {
      fileSize = '${(file.size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(file.type.icon, color: colorScheme.primary, size: 40),
        title: Text(file.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${file.type.displayName} • $fileSize',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (file.isHidden)
              Text(
                'Hidden',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'open':
                // Open file - would need file viewer
                break;
              case 'hide':
                await _toggleFileVisibility(file);
                break;
              case 'delete':
                await _deleteFile(file);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'hide',
              child: Row(
                children: [
                  Icon(file.isHidden ? Icons.visibility : Icons.visibility_off),
                  const SizedBox(width: 8),
                  Text(file.isHidden ? 'Show' : 'Hide'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
