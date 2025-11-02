import 'package:flutter/material.dart';
import 'calculator_button.dart';

/// Calculator keypad widget with basic and scientific modes
/// Basic සහ scientific modes සහිත calculator keypad widget එක
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

    // Responsive padding and spacing
    final double padding = screenWidth < 360 ? 6.0 : 8.0;
    final double rowSpacing = screenWidth < 360 ? 6.0 : 8.0;

    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          // Scientific functions row (shown only in scientific mode)
          if (isScientificMode) ...[
            _buildScientificRow1(context),
            SizedBox(height: rowSpacing),
            _buildScientificRow2(context),
            SizedBox(height: rowSpacing),
          ],
          // Basic calculator rows
          _buildBasicRow1(context),
          SizedBox(height: rowSpacing),
          _buildBasicRow2(context),
          SizedBox(height: rowSpacing),
          _buildBasicRow3(context),
          SizedBox(height: rowSpacing),
          _buildBasicRow4(context),
          SizedBox(height: rowSpacing),
          _buildBasicRow5(context),
        ],
      ),
    );
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
        CalculatorButton(label: 'AC', onTap: () => onButtonPressed('AC')),
        CalculatorButton(
          label: 'C',
          onTap: () => onButtonPressed('C'),
          onLongPress: () => onButtonPressed('BACKSPACE'),
        ),
        CalculatorButton(label: '%', onTap: () => onButtonPressed('%')),
        CalculatorButton(label: '÷', onTap: () => onButtonPressed('÷')),
      ],
    );
  }

  // Basic row 2: 7, 8, 9, ×
  Widget _buildBasicRow2(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(label: '7', onTap: () => onButtonPressed('7')),
        CalculatorButton(label: '8', onTap: () => onButtonPressed('8')),
        CalculatorButton(label: '9', onTap: () => onButtonPressed('9')),
        CalculatorButton(label: '×', onTap: () => onButtonPressed('×')),
      ],
    );
  }

  // Basic row 3: 4, 5, 6, −
  Widget _buildBasicRow3(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(label: '4', onTap: () => onButtonPressed('4')),
        CalculatorButton(label: '5', onTap: () => onButtonPressed('5')),
        CalculatorButton(label: '6', onTap: () => onButtonPressed('6')),
        CalculatorButton(label: '−', onTap: () => onButtonPressed('−')),
      ],
    );
  }

  // Basic row 4: 1, 2, 3, +
  Widget _buildBasicRow4(BuildContext context) {
    return Row(
      children: [
        CalculatorButton(label: '1', onTap: () => onButtonPressed('1')),
        CalculatorButton(label: '2', onTap: () => onButtonPressed('2')),
        CalculatorButton(label: '3', onTap: () => onButtonPressed('3')),
        CalculatorButton(label: '+', onTap: () => onButtonPressed('+')),
      ],
    );
  }

  // Basic row 5: 0, ., =, and parentheses in scientific mode
  Widget _buildBasicRow5(BuildContext context) {
    if (isScientificMode) {
      return Row(
        children: [
          CalculatorButton(label: '(', onTap: () => onButtonPressed('(')),
          CalculatorButton(
            label: '0',
            onTap: () => onButtonPressed('0'),
            isLarge: true,
          ),
          CalculatorButton(label: ')', onTap: () => onButtonPressed(')')),
          CalculatorButton(label: '.', onTap: () => onButtonPressed('.')),
          CalculatorButton(label: '=', onTap: () => onButtonPressed('=')),
        ],
      );
    } else {
      return Row(
        children: [
          CalculatorButton(
            label: '0',
            onTap: () => onButtonPressed('0'),
            isLarge: true,
          ),
          CalculatorButton(label: '.', onTap: () => onButtonPressed('.')),
          CalculatorButton(label: '=', onTap: () => onButtonPressed('=')),
        ],
      );
    }
  }
}
