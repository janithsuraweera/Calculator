import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calculator button widget with haptic feedback
enum ButtonVariant { digit, operator, action, equals }

class CalculatorButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLarge;
  final ButtonVariant? variant;
  final double? heightOverride;

  const CalculatorButton({
    super.key,
    required this.label,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.textColor,
    this.isLarge = false,
    this.variant,
    this.heightOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Responsive sizing based on orientation and screen size
    // Smaller buttons in landscape to fit more content
    final double buttonPadding = isPortrait
        ? (screenWidth < 360 ? 2.0 : (screenWidth < 400 ? 3.0 : 4.0))
        : (screenWidth < 600 ? 2.0 : 3.0);
    final double buttonHeight = isPortrait
        ? (screenWidth < 360
              ? 48.0
              : (screenWidth < 400 ? 56.0 : (screenWidth < 600 ? 60.0 : 64.0)))
        : (screenWidth < 600 ? 50.0 : 56.0);
    final double fontSize = isPortrait
        ? (screenWidth < 360
              ? 18.0
              : (screenWidth < 400 ? 20.0 : (screenWidth < 600 ? 22.0 : 24.0)))
        : (screenWidth < 600 ? 18.0 : 20.0);
    final double borderRadius = isPortrait
        ? (screenWidth < 360 ? 8.0 : (screenWidth < 400 ? 10.0 : 12.0))
        : (screenWidth < 600 ? 8.0 : 10.0);

    // Default colors based on button type / variant
    // Based on image: Numbers white, Operators green, Clear red
    Color resolveBg() {
      if (backgroundColor != null) return backgroundColor!;
      switch (variant) {
        case ButtonVariant.equals:
          return const Color(0xFF25D366); // green for equals
        case ButtonVariant.operator:
          return colorScheme.surfaceContainerHigh; // Background for operators
        case ButtonVariant.action:
          // Check if it's Clear button (C or AC)
          if (label == 'C' || label == 'AC') {
            return colorScheme.surfaceContainerHigh; // Background for red text
          }
          return colorScheme
              .surfaceContainerHigh; // Background for other actions
        case ButtonVariant.digit:
        default:
          return colorScheme.surfaceContainerHighest; // Background for numbers
      }
    }

    Color resolveFg() {
      if (textColor != null) return textColor!;

      // Clear button (C) should be red
      if (label == 'C' || label == 'AC') {
        return Colors.red;
      }

      // Operators should be green
      if (variant == ButtonVariant.operator) {
        return Colors.green;
      }

      // Backspace (⌫) should be green
      if (label == '⌫') {
        return Colors.green;
      }

      // Equals button should be white
      if (variant == ButtonVariant.equals) {
        return Colors.white;
      }

      // Numbers (digits) should be white
      if (variant == ButtonVariant.digit) {
        return Colors.white;
      }

      // Default
      return colorScheme.onSurface;
    }

    final Color bgColor = resolveBg();
    final Color txtColor = resolveFg();

    final double resolvedHeight = heightOverride ?? buttonHeight;
    final double resolvedFontSize = heightOverride != null
        ? math.max(16.0, math.min(fontSize, resolvedHeight * 0.45))
        : fontSize;
    final bool useCompactPadding =
        heightOverride != null && heightOverride! < buttonHeight;
    final double resolvedPadding = useCompactPadding
        ? buttonPadding * 0.8
        : buttonPadding;

    return Expanded(
      flex: isLarge ? 2 : 1,
      child: Padding(
        padding: EdgeInsets.all(resolvedPadding),
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
              height: resolvedHeight,
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w500,
                  fontSize: resolvedFontSize,
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
