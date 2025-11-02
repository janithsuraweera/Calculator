import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calculator button widget with haptic feedback
/// Haptic feedback සහිත calculator button widget එක
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

    // Default colors based on button type
    // Button type එක අනුව default colors
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
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          elevation: 0,
          child: InkWell(
            onTap: () {
              // Haptic feedback on tap
              // Tap කිරීමේදී haptic feedback
              HapticFeedback.lightImpact();
              onTap?.call();
            },
            onLongPress: () {
              // Haptic feedback on long press
              // Long press කිරීමේදී haptic feedback
              HapticFeedback.mediumImpact();
              onLongPress?.call();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 64,
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: txtColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
