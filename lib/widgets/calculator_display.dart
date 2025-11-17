import 'package:flutter/material.dart';

/// Calculator display widget
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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Responsive sizing based on orientation
    final double padding = isPortrait
        ? (screenWidth < 360 ? 16.0 : (screenWidth < 600 ? 20.0 : 24.0))
        : (screenWidth < 600 ? 12.0 : 16.0);
    // Expression is LARGE (shows input calculation)
    final double expressionFontSize = isPortrait
        ? (screenWidth < 360 ? 36.0 : (screenWidth < 600 ? 42.0 : 48.0))
        : (screenWidth < 600 ? 28.0 : 32.0);
    // Result is SMALL (shows final answer)
    final double resultFontSize = isPortrait
        ? (screenWidth < 360 ? 18.0 : (screenWidth < 600 ? 20.0 : 24.0))
        : (screenWidth < 600 ? 16.0 : 18.0);

    // Adjust height based on orientation and screen size
    // Reduce height so the keypad has more space and avoids overflow
    final double displayHeight = isPortrait
        ? (screenHeight < 700
              ? (screenHeight * 0.20).clamp(120.0, 170.0)
              : (screenHeight * 0.22).clamp(150.0, 190.0))
        : (screenWidth < 600 ? 100.0 : 120.0); // Smaller in landscape

    return Container(
      height: displayHeight,
      padding: EdgeInsets.all(padding),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.surface, colorScheme.surfaceContainerHighest],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expression display (LARGE - top area)
          // Shows the full expression including operators (e.g., "12+3+6-8")
          if (expression.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: padding * 0.4),
              child: Text(
                expression,
                style: theme.textTheme.displayMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: expressionFontSize,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                textScaler: const TextScaler.linear(1.0),
              ),
            ),
          // Result display (SMALL - bottom area)
          // Shows only the calculated result, no operators (e.g., "13")
          // Uses accent color to distinguish from expression
          Text(
            result.isEmpty ? '0' : result,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isError
                  ? colorScheme.error
                  : colorScheme.primary, // Use primary/accent color for result
              fontWeight: FontWeight.normal,
              fontSize: resultFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            textScaler: const TextScaler.linear(1.0),
          ),
        ],
      ),
    );
  }
}
