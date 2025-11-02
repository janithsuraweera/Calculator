import 'package:flutter/material.dart';
import 'calculator_button.dart';

/// Calculator keypad widget with basic and scientific modes
class CalculatorKeypad extends StatelessWidget {
  final bool isScientificMode;
  final Function(String) onButtonPressed;
  final Function(String)? onUnitConverterPressed;

  const CalculatorKeypad({
    super.key,
    required this.isScientificMode,
    required this.onButtonPressed,
    this.onUnitConverterPressed,
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

    // Make keypad scrollable in scientific mode to prevent overflow
    final keypadContent = Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          // Unit converter row (available in both modes) - compact
          SizedBox(height: rowSpacing * 0.5),
          _buildUnitConverterRow(context, rowSpacing),
        ],
      ),
    );

    // Wrap in SingleChildScrollView to prevent overflow (both modes)
    // This allows all buttons including unit converters to fit
    return SingleChildScrollView(child: keypadContent);
  }

  // Unit converter row - compact version with expandable design
  Widget _buildUnitConverterRow(BuildContext context, double rowSpacing) {
    if (onUnitConverterPressed == null) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    // Adjust button layout based on orientation
    if (isPortrait) {
      // Portrait: 2 rows of 3 buttons each
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildUnitButton('Length', 'length', Colors.blue),
              ),
              Expanded(child: _buildUnitButton('Area', 'area', Colors.green)),
              Expanded(
                child: _buildUnitButton('Volume', 'volume', Colors.orange),
              ),
            ],
          ),
          SizedBox(height: rowSpacing * 0.5),
          Row(
            children: [
              Expanded(child: _buildUnitButton('Time', 'time', Colors.purple)),
              Expanded(
                child: _buildUnitButton('Temp', 'temperature', Colors.red),
              ),
              Expanded(
                child: _buildUnitButton('Weight', 'weight', Colors.indigo),
              ),
            ],
          ),
        ],
      );
    } else {
      // Landscape: 1 row of 6 buttons (more horizontal space)
      return Row(
        children: [
          Expanded(child: _buildUnitButton('Length', 'length', Colors.blue)),
          Expanded(child: _buildUnitButton('Area', 'area', Colors.green)),
          Expanded(child: _buildUnitButton('Volume', 'volume', Colors.orange)),
          Expanded(child: _buildUnitButton('Time', 'time', Colors.purple)),
          Expanded(child: _buildUnitButton('Temp', 'temperature', Colors.red)),
          Expanded(child: _buildUnitButton('Weight', 'weight', Colors.indigo)),
        ],
      );
    }
  }

  // Build unit converter button - simplified version
  Widget _buildUnitButton(String label, String category, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0, vertical: 3.0),
      child: Material(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        elevation: 0,
        child: InkWell(
          onTap: () => onUnitConverterPressed!(category),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              textScaler: const TextScaler.linear(1.0),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
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
