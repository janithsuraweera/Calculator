import 'package:flutter/material.dart';

/// Calculator display widget
/// Calculator display widget එක
class CalculatorDisplay extends StatelessWidget {
  final String expression;
  final String result;
  final bool isError;

  const CalculatorDisplay({
    super.key,
    required this.expression,
    required this.result,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expression display
          // Expression display කිරීම
          if (expression.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                expression,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 24,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Result display
          // Result display කිරීම
          Text(
            result.isEmpty ? '0' : result,
            style: theme.textTheme.displayMedium?.copyWith(
              color: isError ? colorScheme.error : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 48,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
