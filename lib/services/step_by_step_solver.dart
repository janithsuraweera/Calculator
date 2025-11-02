import 'calculator_engine.dart';

/// Step-by-step calculation solver
/// Provides detailed breakdown of calculation steps
class StepByStepSolver {
  /// Solve expression with step-by-step breakdown
  static List<CalculationStep> solve(String expression) {
    final steps = <CalculationStep>[];

    try {
      if (expression.isEmpty) return steps;

      // Initial expression
      steps.add(
        CalculationStep(
          step: 1,
          description: 'Original expression',
          expression: expression,
        ),
      );

      // Replace display symbols
      String processed = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.141592653589793')
          .replaceAll('−', '-')
          .replaceAll('e', '2.718281828459045');

      steps.add(
        CalculationStep(
          step: 2,
          description: 'Convert symbols to operators',
          expression: processed,
        ),
      );

      // Handle parentheses first
      while (processed.contains('(')) {
        final openIndex = processed.lastIndexOf('(');
        final closeIndex = processed.indexOf(')', openIndex);

        if (closeIndex == -1) break;

        final subExpression = processed.substring(openIndex + 1, closeIndex);
        final subResult = CalculatorEngine.evaluate(subExpression);

        if (subResult != null) {
          steps.add(
            CalculationStep(
              step: steps.length + 1,
              description: 'Evaluate parentheses: $subExpression',
              expression: subExpression,
              result: subResult,
            ),
          );

          processed =
              processed.substring(0, openIndex) +
              subResult +
              processed.substring(closeIndex + 1);

          steps.add(
            CalculationStep(
              step: steps.length + 1,
              description: 'After parentheses evaluation',
              expression: processed,
            ),
          );
        } else {
          break;
        }
      }

      // Handle exponents
      while (processed.contains('^')) {
        // Extract base and exponent
        // This is simplified - full implementation would parse properly
        steps.add(
          CalculationStep(
            step: steps.length + 1,
            description: 'Handle exponentiation',
            expression: processed,
          ),
        );
        break; // Simplified for now
      }

      // Final evaluation
      final finalResult = CalculatorEngine.evaluate(expression);
      if (finalResult != null) {
        steps.add(
          CalculationStep(
            step: steps.length + 1,
            description: 'Final result',
            expression: expression,
            result: finalResult,
          ),
        );
      }
    } catch (e) {
      steps.add(
        CalculationStep(
          step: steps.length + 1,
          description: 'Error occurred',
          expression: expression,
          result: 'Error',
        ),
      );
    }

    return steps;
  }
}

/// Represents a single step in calculation
class CalculationStep {
  final int step;
  final String description;
  final String expression;
  final String? result;

  CalculationStep({
    required this.step,
    required this.description,
    required this.expression,
    this.result,
  });
}
