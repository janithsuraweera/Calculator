import 'package:flutter/material.dart';
import '../models/custom_button.dart';
import '../services/custom_button_manager.dart';
import 'custom_button_editor.dart';

/// Screen for managing custom calculator buttons
class CustomButtonsManager extends StatefulWidget {
  final String mode;

  const CustomButtonsManager({super.key, required this.mode});

  @override
  State<CustomButtonsManager> createState() => _CustomButtonsManagerState();
}

class _CustomButtonsManagerState extends State<CustomButtonsManager> {
  List<CustomButton> _buttons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadButtons();
  }

  Future<void> _loadButtons() async {
    setState(() => _isLoading = true);
    final buttons = await CustomButtonManager.getCustomButtons(widget.mode);
    setState(() {
      _buttons = buttons;
      _isLoading = false;
    });
  }

  Future<void> _addButton() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CustomButtonEditor(mode: widget.mode),
    );

    if (result != null) {
      final button = CustomButton(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: result['label'] as String,
        action: result['action'] as String,
        mode: result['mode'] as String,
        order: result['order'] as int,
      );
      await CustomButtonManager.saveCustomButton(button);
      _loadButtons();
    }
  }

  Future<void> _editButton(CustomButton button) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          CustomButtonEditor(button: button, mode: widget.mode),
    );

    if (result != null) {
      final updatedButton = button.copyWith(
        label: result['label'] as String,
        action: result['action'] as String,
        mode: result['mode'] as String,
        order: result['order'] as int,
      );
      await CustomButtonManager.saveCustomButton(updatedButton);
      _loadButtons();
    }
  }

  Future<void> _deleteButton(CustomButton button) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Button'),
        content: Text('Delete "${button.label}" button?'),
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
      await CustomButtonManager.deleteCustomButton(button.id);
      _loadButtons();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Custom Calculator Buttons')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buttons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No custom buttons',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add a custom button',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _buttons.length,
              itemBuilder: (context, index) {
                final button = _buttons[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.calculate, color: colorScheme.primary),
                    title: Text(button.label),
                    subtitle: Text(
                      'Action: ${button.action}\nMode: ${button.mode}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editButton(button),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteButton(button),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addButton,
        child: const Icon(Icons.add),
      ),
    );
  }
}
