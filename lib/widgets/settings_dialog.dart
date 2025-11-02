import 'package:flutter/material.dart';
import '../services/theme_manager.dart';

/// Settings dialog for theme and accent color selection
/// Theme සහ accent color selection සඳහා settings dialog එක
class SettingsDialog extends StatefulWidget {
  final ThemeMode currentTheme;
  final int currentAccentColorIndex;

  const SettingsDialog({
    super.key,
    required this.currentTheme,
    required this.currentAccentColorIndex,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late ThemeMode selectedTheme;
  late int selectedAccentColorIndex;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.currentTheme;
    selectedAccentColorIndex = widget.currentAccentColorIndex;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme selection
            // Theme selection
            Text(
              'Theme',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                ),
              ],
              selected: {selectedTheme},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                setState(() {
                  selectedTheme = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            // Accent color selection
            // Accent color selection
            Text(
              'Accent Color',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(ThemeManager.accentColors.length, (
                index,
              ) {
                final color = ThemeManager.accentColors[index];
                final isSelected = index == selectedAccentColorIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAccentColorIndex = index;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.onSurface
                            : Colors.transparent,
                        width: isSelected ? 3 : 0,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'theme': selectedTheme,
              'accentColorIndex': selectedAccentColorIndex,
            });
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
