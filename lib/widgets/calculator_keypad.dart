import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'calculator_button.dart';
import '../models/custom_button.dart';
import '../services/custom_button_manager.dart';

/// Calculator keypad widget with basic and scientific modes
class CalculatorKeypad extends StatefulWidget {
  final bool isScientificMode;
  final Function(String) onButtonPressed;

  const CalculatorKeypad({
    super.key,
    required this.isScientificMode,
    required this.onButtonPressed,
  });

  @override
  State<CalculatorKeypad> createState() => _CalculatorKeypadState();
}

class _CalculatorKeypadState extends State<CalculatorKeypad> {
  List<CustomButton> _customButtons = [];
  bool _isRadMode = true; // true for Radians, false for Degrees
  bool _isInvMode = false; // Inverse function mode
  double? _basicButtonHeight;

  @override
  void initState() {
    super.initState();
    _loadCustomButtons();
  }

  Future<void> _loadCustomButtons() async {
    final mode = widget.isScientificMode ? 'scientific' : 'basic';
    final buttons = await CustomButtonManager.getCustomButtons(mode);
    if (mounted) {
      setState(() {
        _customButtons = buttons;
      });
    }
  }

  @override
  void didUpdateWidget(CalculatorKeypad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isScientificMode != widget.isScientificMode) {
      _loadCustomButtons();
    }
  }

  late double rowSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final screenWidth = mediaQuery.size.width;
        final isPortrait = mediaQuery.orientation == Orientation.portrait;

        // Responsive padding and spacing based on orientation and screen size
        final double padding = isPortrait
            ? (screenWidth < 360 ? 4.0 : (screenWidth < 400 ? 6.0 : 8.0))
            : (screenWidth < 600 ? 4.0 : 6.0);
        rowSpacing = isPortrait
            ? (screenWidth < 360 ? 4.0 : (screenWidth < 400 ? 6.0 : 8.0))
            : (screenWidth < 600 ? 4.0 : 6.0);

        _basicButtonHeight = !widget.isScientificMode
            ? _calculateBasicButtonHeight(
                constraints.maxHeight,
                padding,
                screenWidth,
                isPortrait,
              )
            : null;

        // Build keypad grid with dark background and a floating equals button
        final keypadGrid = Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isScientificMode) ...[
                _buildScientificRow0(context), // Rad/Deg, Inv, π, e, Ans
                SizedBox(height: rowSpacing),
                _buildScientificRow1(context),
                SizedBox(height: rowSpacing),
                _buildScientificRow2(context),
                SizedBox(height: rowSpacing),
                // Custom buttons row
                if (_customButtons.isNotEmpty) ...[
                  _buildCustomButtonsRow(context),
                  SizedBox(height: rowSpacing),
                ],
              ],
              _buildBasicRow1(context, _basicButtonHeight),
              SizedBox(height: rowSpacing),
              _buildBasicRow2(context, _basicButtonHeight),
              SizedBox(height: rowSpacing),
              _buildBasicRow3(context, _basicButtonHeight),
              SizedBox(height: rowSpacing),
              _buildBasicRow4(context, _basicButtonHeight),
              SizedBox(height: rowSpacing),
              _buildBasicZeroRow(context, _basicButtonHeight),
            ],
          ),
        );

        // For scientific mode, we need space for floating equals button
        // For basic mode, equals button is in the row, so no extra padding needed
        final Widget mainArea;
        if (widget.isScientificMode) {
          // Calculate bottom padding for floating equals button in scientific mode
          final double equalsButtonSize = isPortrait
              ? (screenWidth < 360 ? 64.0 : (screenWidth < 400 ? 68.0 : 72.0))
              : (screenWidth < 600 ? 60.0 : 68.0);
          final double equalsButtonMargin = 4;
          final double bottomPadding =
              equalsButtonSize + equalsButtonMargin + padding;
          mainArea = SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: keypadGrid,
          );
        } else {
          // Basic mode: equals button is in the row, no extra padding needed
          mainArea = SingleChildScrollView(child: keypadGrid);
        }

        // Only show floating equals button in scientific mode
        if (widget.isScientificMode) {
          return Stack(
            children: [
              Positioned.fill(child: mainArea),
              Positioned(
                right: padding + 4,
                bottom: padding + 4,
                child: _buildFloatingEquals(context),
              ),
            ],
          );
        } else {
          // Basic mode: no floating button, equals is in the row
          return mainArea;
        }
      },
    );
  }

  double _calculateBasicButtonHeight(
    double maxHeight,
    double padding,
    double screenWidth,
    bool isPortrait,
  ) {
    const int rowCount = 5;
    const int spacerCount = rowCount - 1;

    // In basic mode, equals button is now in the row (not floating)
    // So we don't need to reserve extra space for it
    final double reservedSpace = (padding * 2) + (rowSpacing * spacerCount);
    final double rawSpace = maxHeight - reservedSpace;
    // Use more conservative minimum to prevent overflow
    final double minButtonHeight = 40.0; // Reduced from 44.0
    final double safeSpace = math.max(rowCount * minButtonHeight, rawSpace);
    final double perRow = safeSpace / rowCount;
    // Clamp to smaller range to fit better on small screens
    return perRow.clamp(minButtonHeight, 60.0);
  }

  // Scientific functions row 0: Rad/Deg, Inv, π, e, Ans, EXP, x!
  Widget _buildScientificRow0(BuildContext context) {
    return Row(
      children: [
        // Rad/Deg toggle button
        Expanded(
          child: CalculatorButton(
            label: _isRadMode ? 'Rad' : 'Deg',
            onTap: () {
              setState(() {
                _isRadMode = !_isRadMode;
              });
              widget.onButtonPressed(_isRadMode ? 'RAD' : 'DEG');
            },
            variant: ButtonVariant.action,
            backgroundColor: _isRadMode
                ? Theme.of(context).colorScheme.primary
                : null,
            textColor: _isRadMode
                ? Theme.of(context).colorScheme.onPrimary
                : null,
          ),
        ),
        // Inv button
        Expanded(
          child: CalculatorButton(
            label: 'Inv',
            onTap: () {
              setState(() {
                _isInvMode = !_isInvMode;
              });
              widget.onButtonPressed('INV');
            },
            variant: ButtonVariant.action,
            backgroundColor: _isInvMode
                ? Theme.of(context).colorScheme.primary
                : null,
            textColor: _isInvMode
                ? Theme.of(context).colorScheme.onPrimary
                : null,
          ),
        ),
        // π (Pi)
        Expanded(
          child: CalculatorButton(
            label: 'π',
            onTap: () => widget.onButtonPressed('π'),
            variant: ButtonVariant.operator,
          ),
        ),
        // e (Euler's number)
        Expanded(
          child: CalculatorButton(
            label: 'e',
            onTap: () => widget.onButtonPressed('e'),
            variant: ButtonVariant.operator,
          ),
        ),
        // Ans (Previous answer)
        Expanded(
          child: CalculatorButton(
            label: 'Ans',
            onTap: () => widget.onButtonPressed('ANS'),
            variant: ButtonVariant.operator,
          ),
        ),
      ],
    );
  }

  // Scientific functions row 1
  Widget _buildScientificRow1(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(
          label: 'sin',
          onTap: () => widget.onButtonPressed('sin('),
        ),
        CalculatorButton(
          label: 'cos',
          onTap: () => widget.onButtonPressed('cos('),
        ),
        CalculatorButton(
          label: 'tan',
          onTap: () => widget.onButtonPressed('tan('),
        ),
        CalculatorButton(
          label: 'ln',
          onTap: () => widget.onButtonPressed('ln('),
        ),
        CalculatorButton(
          label: 'log',
          onTap: () => widget.onButtonPressed('log('),
        ),
      ],
    );
  }

  // Custom buttons row
  Widget _buildCustomButtonsRow(BuildContext context) {
    // Group buttons into rows of 5
    final rows = <List<CustomButton>>[];
    for (int i = 0; i < _customButtons.length; i += 5) {
      rows.add(
        _customButtons.sublist(
          i,
          i + 5 > _customButtons.length ? _customButtons.length : i + 5,
        ),
      );
    }

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowSpacing),
          child: Row(
            children: row.map((button) {
              return Expanded(
                child: CalculatorButton(
                  label: button.label,
                  onTap: () => widget.onButtonPressed(button.action),
                  variant: ButtonVariant.operator,
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // Scientific functions row 2
  Widget _buildScientificRow2(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(
          label: '√',
          onTap: () => widget.onButtonPressed('sqrt('),
        ),
        CalculatorButton(
          label: 'x²',
          onTap: () => widget.onButtonPressed('^2'),
        ),
        CalculatorButton(label: 'xʸ', onTap: () => widget.onButtonPressed('^')),
        CalculatorButton(
          label: 'EXP',
          onTap: () => widget.onButtonPressed('EXP'),
        ),
        CalculatorButton(label: 'x!', onTap: () => widget.onButtonPressed('!')),
      ],
    );
  }

  // Basic row 1: AC, C, %, ÷
  Widget _buildBasicRow1(BuildContext context, double? buttonHeight) {
    return Row(
      children: [
        CalculatorButton(
          label: 'C',
          onTap: () => widget.onButtonPressed('AC'),
          variant: ButtonVariant.action,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '%',
          onTap: () => widget.onButtonPressed('%'),
          variant: ButtonVariant.operator,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '⌫',
          onTap: () => widget.onButtonPressed('C'),
          onLongPress: () => widget.onButtonPressed('BACKSPACE'),
          variant: ButtonVariant.action,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '÷',
          onTap: () => widget.onButtonPressed('÷'),
          variant: ButtonVariant.operator,
          heightOverride: buttonHeight,
        ),
      ],
    );
  }

  // Basic row 2: 7, 8, 9, ×
  Widget _buildBasicRow2(BuildContext context, double? buttonHeight) {
    return Row(
      children: [
        CalculatorButton(
          label: '7',
          onTap: () => widget.onButtonPressed('7'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '8',
          onTap: () => widget.onButtonPressed('8'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '9',
          onTap: () => widget.onButtonPressed('9'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '×',
          onTap: () => widget.onButtonPressed('×'),
          variant: ButtonVariant.operator,
          heightOverride: buttonHeight,
        ),
      ],
    );
  }

  // Basic row 3: 4, 5, 6, −
  Widget _buildBasicRow3(BuildContext context, double? buttonHeight) {
    return Row(
      children: [
        CalculatorButton(
          label: '4',
          onTap: () => widget.onButtonPressed('4'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '5',
          onTap: () => widget.onButtonPressed('5'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '6',
          onTap: () => widget.onButtonPressed('6'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '−',
          onTap: () => widget.onButtonPressed('−'),
          variant: ButtonVariant.operator,
          heightOverride: buttonHeight,
        ),
      ],
    );
  }

  // Basic row 4: 1, 2, 3, +
  Widget _buildBasicRow4(BuildContext context, double? buttonHeight) {
    return Row(
      children: [
        CalculatorButton(
          label: '1',
          onTap: () => widget.onButtonPressed('1'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '2',
          onTap: () => widget.onButtonPressed('2'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '3',
          onTap: () => widget.onButtonPressed('3'),
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '+',
          onTap: () => widget.onButtonPressed('+'),
          variant: ButtonVariant.operator,
          heightOverride: buttonHeight,
        ),
      ],
    );
  }

  Widget _buildBasicZeroRow(BuildContext context, double? buttonHeight) {
    return Row(
      children: [
        CalculatorButton(
          label: '0',
          onTap: () => widget.onButtonPressed('0'),
          isLarge: true,
          variant: ButtonVariant.digit,
          heightOverride: buttonHeight,
        ),
        CalculatorButton(
          label: '.',
          onTap: () => widget.onButtonPressed('.'),
          variant: ButtonVariant.operator,
          heightOverride: buttonHeight,
        ),
        // Equals button in the same row, horizontally aligned
        Expanded(
          child: Builder(
            builder: (context) {
              final mediaQuery = MediaQuery.of(context);
              final screenWidth = mediaQuery.size.width;
              final isPortrait = mediaQuery.orientation == Orientation.portrait;

              // Responsive sizing (same as CalculatorButton)
              final double buttonPadding = isPortrait
                  ? (screenWidth < 360 ? 2.0 : (screenWidth < 400 ? 3.0 : 4.0))
                  : (screenWidth < 600 ? 2.0 : 3.0);
              final double borderRadius = isPortrait
                  ? (screenWidth < 360
                        ? 8.0
                        : (screenWidth < 400 ? 10.0 : 12.0))
                  : (screenWidth < 600 ? 8.0 : 10.0);
              final double fontSize = isPortrait
                  ? (screenWidth < 360
                        ? 18.0
                        : (screenWidth < 400
                              ? 20.0
                              : (screenWidth < 600 ? 22.0 : 24.0)))
                  : (screenWidth < 600 ? 18.0 : 20.0);
              final double resolvedHeight =
                  buttonHeight ??
                  (isPortrait
                      ? (screenWidth < 360
                            ? 48.0
                            : (screenWidth < 400
                                  ? 56.0
                                  : (screenWidth < 600 ? 60.0 : 64.0)))
                      : (screenWidth < 600 ? 50.0 : 56.0));

              return Padding(
                padding: EdgeInsets.all(buttonPadding),
                child: Material(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(borderRadius),
                  elevation: 0,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onButtonPressed('=');
                    },
                    borderRadius: BorderRadius.circular(borderRadius),
                    child: Container(
                      height: resolvedHeight,
                      alignment: Alignment.center,
                      child: Text(
                        '=',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: fontSize,
                        ),
                        textScaler: const TextScaler.linear(1.0),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // (old basic row 5 was unused) – removed

  Widget _buildFloatingEquals(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Responsive size based on screen
    final double buttonSize = isPortrait
        ? (screenWidth < 360 ? 64.0 : (screenWidth < 400 ? 68.0 : 72.0))
        : (screenWidth < 600 ? 60.0 : 68.0);
    final double fontSize = buttonSize * 0.44; // Proportional font size

    return SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: FloatingActionButton(
        onPressed: () => widget.onButtonPressed('='),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Text(
          '=',
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
