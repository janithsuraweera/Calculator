import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/calculation_history.dart';

/// History panel widget showing calculation history
/// ගණනය කිරීමේ ඉතිහාසය පෙන්වන history panel widget එක
class HistoryPanel extends StatelessWidget {
  final List<CalculationHistory> history;
  final Function(String) onHistoryItemTap;
  final VoidCallback onClearHistory;

  const HistoryPanel({
    super.key,
    required this.history,
    required this.onHistoryItemTap,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, HH:mm');

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
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No calculation history',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
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
                  title: Text(
                    item.expression,
                    style: theme.textTheme.bodyMedium,
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
                        dateFormat.format(item.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  onTap: () => onHistoryItemTap(item.result),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
