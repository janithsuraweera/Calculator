import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/calculator_engine.dart';
import '../services/haptic_sound_manager.dart';

/// Floating mini-calculator overlay widget
class FloatingCalculator extends StatefulWidget {
  const FloatingCalculator({super.key});

  @override
  State<FloatingCalculator> createState() => _FloatingCalculatorState();
}

class _FloatingCalculatorState extends State<FloatingCalculator> {
  String _expression = '';
  String _result = '0';

  void _onButtonTap(String button) {
    HapticSoundManager.triggerHaptic();
    HapticSoundManager.playClickSound();

    setState(() {
      switch (button) {
        case 'AC':
          _expression = '';
          _result = '0';
          break;
        case 'C':
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            _evaluate();
          } else {
            _result = '0';
          }
          break;
        case '=':
          _evaluate();
          break;
        default:
          _expression += button;
          _evaluate();
          break;
      }
    });
  }

  void _evaluate() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }
    final result = CalculatorEngine.evaluate(_expression);
    _result = result ?? 'Error';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_expression.isNotEmpty)
                  Text(
                    _expression,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  _result,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Mini keypad
          Row(
            children: [
              _buildButton('7'),
              _buildButton('8'),
              _buildButton('9'),
              _buildButton('÷'),
            ],
          ),
          Row(
            children: [
              _buildButton('4'),
              _buildButton('5'),
              _buildButton('6'),
              _buildButton('×'),
            ],
          ),
          Row(
            children: [
              _buildButton('1'),
              _buildButton('2'),
              _buildButton('3'),
              _buildButton('−'),
            ],
          ),
          Row(
            children: [
              _buildButton('C'),
              _buildButton('0'),
              _buildButton('.'),
              _buildButton('+'),
            ],
          ),
          Row(
            children: [
              Expanded(child: _buildButton('AC')),
              Expanded(flex: 2, child: _buildButton('=')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: label == '='
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            onTap: () => _onButtonTap(label),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 32,
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: label == '='
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
