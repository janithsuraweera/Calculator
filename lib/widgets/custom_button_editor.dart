import 'package:flutter/material.dart';
import '../models/custom_button.dart';

/// Dialog for editing custom calculator buttons
class CustomButtonEditor extends StatefulWidget {
  final CustomButton? button;
  final String mode;

  const CustomButtonEditor({super.key, this.button, required this.mode});

  @override
  State<CustomButtonEditor> createState() => _CustomButtonEditorState();
}

class _CustomButtonEditorState extends State<CustomButtonEditor> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _actionController = TextEditingController();
  String _selectedMode = 'scientific';
  int _order = 0;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.mode;
    if (widget.button != null) {
      _labelController.text = widget.button!.label;
      _actionController.text = widget.button!.action;
      _selectedMode = widget.button!.mode;
      _order = widget.button!.order;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _actionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.button != null ? 'Edit Button' : 'Add Custom Button'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Button Label',
                hintText: 'e.g., sec, csc, cot',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _actionController,
              decoration: const InputDecoration(
                labelText: 'Action',
                hintText: 'e.g., sec(, csc(, cot(',
                border: OutlineInputBorder(),
                helperText: 'What to insert when button is pressed',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMode,
              decoration: const InputDecoration(
                labelText: 'Mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'scientific',
                  child: Text('Scientific'),
                ),
                DropdownMenuItem(value: 'basic', child: Text('Basic')),
                DropdownMenuItem(value: 'all', child: Text('All Modes')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMode = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Order',
                hintText: '0',
                border: OutlineInputBorder(),
                helperText: 'Lower numbers appear first',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                _order = int.tryParse(value) ?? 0;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_labelController.text.trim().isEmpty ||
                _actionController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            Navigator.pop(context, {
              'label': _labelController.text.trim(),
              'action': _actionController.text.trim(),
              'mode': _selectedMode,
              'order': _order,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
