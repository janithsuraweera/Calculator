import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calculator button widget with haptic feedback
class CalculatorButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLarge;

  const CalculatorButton({
    super.key,
    required this.label,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.textColor,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Responsive sizing
    // Smaller screens get smaller buttons
    final double buttonPadding = screenWidth < 360 ? 3.0 : 4.0;
    final double buttonHeight = screenWidth < 360
        ? 56.0
        : (screenWidth < 600 ? 60.0 : 64.0);
    final double fontSize = screenWidth < 360
        ? 20.0
        : (screenWidth < 600 ? 22.0 : 24.0);
    final double borderRadius = screenWidth < 360 ? 10.0 : 12.0;

    // Default colors based on button type
    final Color bgColor =
        backgroundColor ??
        (label == '='
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest);
    final Color txtColor =
        textColor ??
        (label == '=' ? colorScheme.onPrimary : colorScheme.onSurface);

    return Expanded(
      flex: isLarge ? 2 : 1,
      child: Padding(
        padding: EdgeInsets.all(buttonPadding),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(borderRadius),
          elevation: 0,
          child: InkWell(
            onTap: () {
              // Haptic feedback on tap
              HapticFeedback.lightImpact();
              onTap?.call();
            },
            onLongPress: () {
              // Haptic feedback on long press
              HapticFeedback.mediumImpact();
              onLongPress?.call();
            },
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              height: buttonHeight,
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w500,
                  fontSize: fontSize,
                ),
                textScaler: const TextScaler.linear(
                  1.0,
                ), // Prevent system font scaling
              ),
            ),
          ),
        ),
      ),
    );
  }
}
