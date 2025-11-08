import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/vault_manager.dart';
import '../models/vault_file.dart';
import '../models/vault_folder.dart';
import 'vault_pin_dialog.dart';

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
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isAuthenticating = true;

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
    setState(() {
      _files = files;
      _folders = folders;
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
                case 'change_pin':
                  await _changePin();
                  break;
              }
            },
            itemBuilder: (context) => [
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
          // Category filter
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
          const Divider(height: 1),
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
                : _files.isEmpty && _folders.isEmpty
                ? Center(
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
                  )
                : ListView(
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
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFile,
        child: const Icon(Icons.add),
        tooltip: 'Add File',
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
