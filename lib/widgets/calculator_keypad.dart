import 'package:flutter/material.dart';
import 'calculator_button.dart';

/// Calculator keypad widget with basic and scientific modes
class CalculatorKeypad extends StatelessWidget {
  final bool isScientificMode;
  final Function(String) onButtonPressed;

  const CalculatorKeypad({
    super.key,
    required this.isScientificMode,
    required this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Responsive padding and spacing based on orientation
    final double padding = isPortrait
        ? (screenWidth < 360 ? 6.0 : 8.0)
        : (screenWidth < 600 ? 4.0 : 6.0);
    final double rowSpacing = isPortrait
        ? (screenWidth < 360 ? 6.0 : 8.0)
        : (screenWidth < 600 ? 4.0 : 6.0);

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
          if (isScientificMode) ...[
            _buildScientificRow1(context),
            SizedBox(height: rowSpacing),
            _buildScientificRow2(context),
            SizedBox(height: rowSpacing),
          ],
          _buildBasicRow1(context),
          SizedBox(height: rowSpacing),
          _buildBasicRow2(context),
          SizedBox(height: rowSpacing),
          _buildBasicRow3(context),
          SizedBox(height: rowSpacing),
          _buildBasicRow4(context),
          SizedBox(height: rowSpacing),
          // Bottom row without equals (equals will float)
          Row(
            children: [
              CalculatorButton(
                label: '0',
                onTap: () => onButtonPressed('0'),
                isLarge: true,
                variant: ButtonVariant.digit,
              ),
              CalculatorButton(
                label: '.',
                onTap: () => onButtonPressed('.'),
                variant: ButtonVariant.operator,
              ),
              // Spacer to reserve space under the floating equals button
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );

    // Always scroll to prevent overflow on small screens and add bottom
    // padding so the floating equals button doesn't cover content
    final content = Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 88 + padding),
          child: keypadGrid,
        ),
        // Floating big equals button
        Positioned(
          right: padding + 4,
          bottom: padding + 4,
          child: _buildFloatingEquals(context),
        ),
      ],
    );
    return content;
  }

  // Scientific functions row 1
  Widget _buildScientificRow1(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(label: 'sin', onTap: () => onButtonPressed('sin(')),
        CalculatorButton(label: 'cos', onTap: () => onButtonPressed('cos(')),
        CalculatorButton(label: 'tan', onTap: () => onButtonPressed('tan(')),
        CalculatorButton(label: 'ln', onTap: () => onButtonPressed('ln(')),
        CalculatorButton(label: 'log', onTap: () => onButtonPressed('log(')),
      ],
    );
  }

  // Scientific functions row 2
  Widget _buildScientificRow2(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(label: '√', onTap: () => onButtonPressed('sqrt(')),
        CalculatorButton(label: 'x²', onTap: () => onButtonPressed('^2')),
        CalculatorButton(label: 'xʸ', onTap: () => onButtonPressed('^')),
        CalculatorButton(label: 'eˣ', onTap: () => onButtonPressed('exp(')),
        CalculatorButton(label: '!', onTap: () => onButtonPressed('!')),
      ],
    );
  }

  // Basic row 1: AC, C, %, ÷
  Widget _buildBasicRow1(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(
          label: 'C',
          onTap: () => onButtonPressed('AC'),
          variant: ButtonVariant.action,
        ),
        CalculatorButton(
          label: '%',
          onTap: () => onButtonPressed('%'),
          variant: ButtonVariant.operator,
        ),
        CalculatorButton(
          label: '⌫',
          onTap: () => onButtonPressed('C'),
          onLongPress: () => onButtonPressed('BACKSPACE'),
          variant: ButtonVariant.action,
        ),
        CalculatorButton(
          label: '÷',
          onTap: () => onButtonPressed('÷'),
          variant: ButtonVariant.operator,
        ),
      ],
    );
  }

  // Basic row 2: 7, 8, 9, ×
  Widget _buildBasicRow2(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(
          label: '7',
          onTap: () => onButtonPressed('7'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '8',
          onTap: () => onButtonPressed('8'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '9',
          onTap: () => onButtonPressed('9'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '×',
          onTap: () => onButtonPressed('×'),
          variant: ButtonVariant.operator,
        ),
      ],
    );
  }

  // Basic row 3: 4, 5, 6, −
  Widget _buildBasicRow3(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(
          label: '4',
          onTap: () => onButtonPressed('4'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '5',
          onTap: () => onButtonPressed('5'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '6',
          onTap: () => onButtonPressed('6'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '−',
          onTap: () => onButtonPressed('−'),
          variant: ButtonVariant.operator,
        ),
      ],
    );
  }

  // Basic row 4: 1, 2, 3, +
  Widget _buildBasicRow4(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(
          label: '1',
          onTap: () => onButtonPressed('1'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '2',
          onTap: () => onButtonPressed('2'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '3',
          onTap: () => onButtonPressed('3'),
          variant: ButtonVariant.digit,
        ),
        CalculatorButton(
          label: '+',
          onTap: () => onButtonPressed('+'),
          variant: ButtonVariant.operator,
        ),
      ],
    );
  }

  // Basic row 5: 0, ., =, and parentheses in scientific mode
  Widget _buildBasicRow5(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildFloatingEquals(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: FloatingActionButton(
        onPressed: () => onButtonPressed('='),
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Text(
          '=',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
