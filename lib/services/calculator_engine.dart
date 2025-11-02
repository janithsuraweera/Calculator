import 'package:math_expressions/math_expressions.dart';

/// Calculator engine for evaluating mathematical expressions
class CalculatorEngine {
  /// Evaluate an infix mathematical expression
  /// Supports: +, -, *, /, parentheses, decimals, and scientific functions
  static String? evaluate(String expression) {
    try {
      if (expression.isEmpty) return null;

      // Replace display symbols with math symbols
      String processed = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('−', '-'); // Replace minus sign

      // Handle scientific functions - convert to math_expressions format
      processed = _processScientificFunctions(processed);

      // Create parser and context with standard math functions
      final p = GrammarParser();
      ContextModel cm = ContextModel();

      // Bind constants - math_expressions uses Number for numeric values
      cm.bindVariableName('pi', Number(3.141592653589793));
      cm.bindVariableName('e', Number(2.718281828459045));

      // Note: math_expressions library handles standard functions automatically
      // Functions like sin, cos, tan, log, ln, sqrt, exp are built-in

      // Parse the expression
      Expression exp = p.parse(processed);

      // Evaluate the expression
      double result = exp.evaluate(EvaluationType.REAL, cm);

      // Format result - remove trailing zeros and unnecessary decimal point
      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        // Remove trailing zeros
        String resultStr = result.toString();
        if (resultStr.contains('.')) {
          resultStr = resultStr.replaceAll(RegExp(r'0+$'), '');
          resultStr = resultStr.replaceAll(RegExp(r'\.$'), '');
        }
        return resultStr;
      }
    } catch (e) {
      return null; // Return null on error
    }
  }

  /// Process scientific functions in expression
  static String _processScientificFunctions(String expression) {
    // For now, we'll let math_expressions handle function parsing
    // The functions will be bound in the ContextModel

    return expression;
  }

  /// Validate if expression can be evaluated
  static bool isValid(String expression) {
    if (expression.isEmpty) return false;
    try {
      String processed = expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', 'pi')
          .replaceAll('e', 'e');
      final p = GrammarParser();
      ContextModel cm = ContextModel();
      cm.bindVariableName('pi', Number(3.141592653589793));
      cm.bindVariableName('e', Number(2.718281828459045));
      p.parse(processed);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Evaluate scientific function
  static String? evaluateScientific(String function, String value) {
    try {
      double numValue = double.parse(value);
      double result;

      // Convert degrees to radians for trigonometric functions
      double radians = numValue * (3.141592653589793 / 180);

      switch (function.toLowerCase()) {
        case 'sin':
          result = _sin(radians);
          break;
        case 'cos':
          result = _cos(radians);
          break;
        case 'tan':
          result = _tan(radians);
          break;
        case 'log':
          result = numValue <= 0 ? double.nan : _log10(numValue);
          break;
        case 'ln':
          result = numValue <= 0 ? double.nan : _ln(numValue);
          break;
        case 'sqrt':
          result = numValue < 0 ? double.nan : _sqrt(numValue);
          break;
        case 'exp':
          result = _exp(numValue);
          break;
        case 'factorial':
          if (numValue < 0 || numValue != numValue.toInt() || numValue > 170) {
            return null;
          }
          result = _factorial(numValue.toInt()).toDouble();
          break;
        default:
          return null;
      }

      if (result.isNaN || result.isInfinite) {
        return null;
      }

      // Format result
      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        String resultStr = result.toString();
        if (resultStr.contains('.')) {
          resultStr = resultStr.replaceAll(RegExp(r'0+$'), '');
          resultStr = resultStr.replaceAll(RegExp(r'\.$'), '');
        }
        return resultStr;
      }
    } catch (e) {
      return null;
    }
  }

  /// Evaluate power function (x^y)
  /// Power function evaluate කිරීම
  static String? evaluatePower(String base, String exponent) {
    try {
      double baseValue = double.parse(base);
      double expValue = double.parse(exponent);
      double result = _pow(baseValue, expValue);

      if (result.isNaN || result.isInfinite) {
        return null;
      }

      // Format result
      if (result == result.toInt()) {
        return result.toInt().toString();
      } else {
        String resultStr = result.toString();
        if (resultStr.contains('.')) {
          resultStr = resultStr.replaceAll(RegExp(r'0+$'), '');
          resultStr = resultStr.replaceAll(RegExp(r'\.$'), '');
        }
        return resultStr;
      }
    } catch (e) {
      return null;
    }
  }

  // Mathematical function implementations
  // ගණිතමය function implementations

  /// Sine function (in radians)
  static double _sin(double x) {
    x = x % (2 * 3.141592653589793);
    double result = 0;
    double term = x;
    for (int i = 1; i <= 15; i++) {
      result += term;
      term = -term * x * x / ((2 * i) * (2 * i + 1));
    }
    return result;
  }

  /// Cosine function (in radians)
  static double _cos(double x) {
    x = x % (2 * 3.141592653589793);
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 15; i++) {
      term = -term * x * x / ((2 * i - 1) * (2 * i));
      result += term;
    }
    return result;
  }

  /// Tangent function (in radians)
  static double _tan(double x) {
    double s = _sin(x);
    double c = _cos(x);
    return c == 0 ? double.infinity : s / c;
  }

  /// Natural logarithm
  static double _ln(double x) {
    if (x <= 0) return double.nan;
    double y = (x - 1) / (x + 1);
    double result = 0;
    double term = y;
    for (int i = 1; i <= 100; i += 2) {
      result += term / i;
      term *= y * y;
    }
    return 2 * result;
  }

  /// Base-10 logarithm
  static double _log10(double x) {
    return _ln(x) / 2.302585092994046;
  }

  /// Square root
  static double _sqrt(double x) {
    if (x < 0) return double.nan;
    if (x == 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// Exponential function
  static double _exp(double x) {
    double result = 1;
    double term = 1;
    for (int i = 1; i <= 50; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  /// Power function
  static double _pow(double base, double exponent) {
    if (base == 0 && exponent < 0) return double.infinity;
    if (base < 0 && exponent != exponent.toInt()) return double.nan;
    return _exp(_ln(base.abs()) * exponent) *
        (base < 0 && exponent.toInt() % 2 != 0 ? -1 : 1);
  }

  /// Factorial
  static int _factorial(int n) {
    if (n <= 1) return 1;
    int result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }
}
