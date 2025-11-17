import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/calculation_history.dart';
import 'step_by_step_view.dart';

/// History panel widget showing calculation history
/// History panel widget for displaying calculation history
class HistoryPanel extends StatelessWidget {
  final List<CalculationHistory> history;
  final ValueChanged<CalculationHistory> onHistoryItemTap;
  final VoidCallback onClearHistory;
  final Future<void> Function(CalculationHistory item, String? label)?
  onLabelEdit;

  const HistoryPanel({
    super.key,
    required this.history,
    required this.onHistoryItemTap,
    required this.onClearHistory,
    this.onLabelEdit,
  });

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month $day, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No calculation history',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header with clear button
        // Clear button සහිත header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'History',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: onClearHistory,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear'),
              ),
            ],
          ),
        ),
        // History list
        // History list එක
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((item.label ?? '').isNotEmpty) ...[
                        Text(
                          item.label!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      Text(item.expression, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '= ${item.result}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(item.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onLabelEdit != null)
                        IconButton(
                          tooltip: (item.label ?? '').isEmpty
                              ? 'Add name'
                              : 'Rename',
                          icon: Icon(
                            (item.label ?? '').isEmpty
                                ? Icons.label_outline
                                : Icons.label,
                          ),
                          onPressed: () => _showLabelDialog(context, item),
                        ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                  onTap: () => onHistoryItemTap(item),
                  onLongPress: () {
                    // Show step-by-step solution
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StepByStepView(historyItem: item),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showLabelDialog(
    BuildContext context,
    CalculationHistory item,
  ) async {
    if (onLabelEdit == null) return;

    final controller = TextEditingController(text: item.label ?? '');
    final result = await showDialog<_LabelDialogResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            (item.label ?? '').isEmpty ? 'Add a name' : 'Rename calculation',
          ),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'E.g. Monthly budget',
            ),
            textInputAction: TextInputAction.done,
            autofocus: true,
            onSubmitted: (_) {
              HapticFeedback.lightImpact();
              Navigator.pop(
                context,
                _LabelDialogResult(value: controller.text),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if ((item.label ?? '').isNotEmpty)
              TextButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(
                    context,
                    const _LabelDialogResult(remove: true),
                  );
                },
                child: const Text('Remove name'),
              ),
            FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(
                  context,
                  _LabelDialogResult(value: controller.text),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final nextLabel = result.remove
        ? null
        : (result.value?.trim().isEmpty ?? true ? null : result.value!.trim());

    await onLabelEdit!(item, nextLabel);
  }
}

class _LabelDialogResult {
  final String? value;
  final bool remove;

  const _LabelDialogResult({this.value, this.remove = false});
}
