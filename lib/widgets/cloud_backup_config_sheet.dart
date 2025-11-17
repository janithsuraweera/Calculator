import 'package:flutter/material.dart';

import '../models/cloud_backup_config.dart';

class CloudBackupConfigSheet extends StatefulWidget {
  final CloudBackupConfig? initialConfig;

  const CloudBackupConfigSheet({super.key, this.initialConfig});

  @override
  State<CloudBackupConfigSheet> createState() => _CloudBackupConfigSheetState();
}

class _CloudBackupConfigSheetState extends State<CloudBackupConfigSheet> {
  late TextEditingController _emailController;
  String _frequency = 'daily';
  bool _wifiOnly = true;
  bool _includeHistory = true;
  bool _includeNotes = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: widget.initialConfig?.email ?? '',
    );
    _frequency = widget.initialConfig?.frequency ?? 'daily';
    _wifiOnly = widget.initialConfig?.wifiOnly ?? true;
    _includeHistory = widget.initialConfig?.includeHistory ?? true;
    _includeNotes = widget.initialConfig?.includeNotes ?? true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cloud Backup Settings',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Google Account Email',
                hintText: 'name@example.com',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Backup Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _frequency = value);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Wi-Fi only'),
              subtitle: const Text('Upload backups only on Wi-Fi'),
              value: _wifiOnly,
              onChanged: (value) => setState(() => _wifiOnly = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Calculation History'),
              value: _includeHistory,
              onChanged: (value) => setState(() => _includeHistory = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include Notes'),
              value: _includeNotes,
              onChanged: (value) => setState(() => _includeNotes = value),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() != true) return;
                    Navigator.pop(
                      context,
                      CloudBackupConfig(
                        email: _emailController.text.trim(),
                        frequency: _frequency,
                        wifiOnly: _wifiOnly,
                        includeHistory: _includeHistory,
                        includeNotes: _includeNotes,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
