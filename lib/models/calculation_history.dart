/// Calculation history model
/// ගණනය කිරීමේ ඉතිහාසයේ data model එක
class CalculationHistory {
  final String expression;
  final String result;
  final DateTime timestamp;

  CalculationHistory({
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  /// Convert to JSON for storage
  /// JSON format එකට convert කිරීම storage සඳහා
  Map<String, dynamic> toJson() {
    return {
      'expression': expression,
      'result': result,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  /// JSON එකෙන් object එකක් create කිරීම
  factory CalculationHistory.fromJson(Map<String, dynamic> json) {
    return CalculationHistory(
      expression: json['expression'] as String,
      result: json['result'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
