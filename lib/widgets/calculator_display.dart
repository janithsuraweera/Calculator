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
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Responsive sizing based on screen dimensions
    // Use smaller sizes for smaller screens
    final double padding = screenWidth < 360
        ? 16.0
        : (screenWidth < 600 ? 20.0 : 24.0);
    final double expressionFontSize = screenWidth < 360
        ? 18.0
        : (screenWidth < 600 ? 20.0 : 24.0);
    final double resultFontSize = screenWidth < 360
        ? 36.0
        : (screenWidth < 600 ? 42.0 : 48.0);

    // Adjust height based on screen size, ensuring it's not too large on small screens
    final double displayHeight = screenHeight < 700
        ? (screenHeight * 0.25).clamp(150.0, 200.0)
        : (screenHeight * 0.3).clamp(200.0, 250.0);

    return Container(
      height: displayHeight,
      padding: EdgeInsets.all(padding),
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
          if (expression.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: padding * 0.33),
              child: Text(
                expression,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: expressionFontSize,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textScaleFactor: 1.0, // Prevent system font scaling
              ),
            ),
          // Result display
          Text(
            result.isEmpty ? '0' : result,
            style: theme.textTheme.displayMedium?.copyWith(
              color: isError ? colorScheme.error : colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: resultFontSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaleFactor: 1.0, // Prevent system font scaling
          ),
        ],
      ),
    );
  }
}
