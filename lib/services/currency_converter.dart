import 'dart:convert';
import 'package:http/http.dart' as http;

/// Currency converter service for real-time exchange rates
class CurrencyConverter {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  /// Get exchange rate between two currencies
  static Future<double?> getExchangeRate(
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      if (fromCurrency == toCurrency) return 1.0;

      final url = Uri.parse('$_baseUrl/$fromCurrency');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final rate = rates[toCurrency] as num?;
        return rate?.toDouble();
      }
      return null;
    } catch (e) {
      // Fallback to common rates if API fails
      return _getFallbackRate(fromCurrency, toCurrency);
    }
  }

  /// Fallback rates (approximate values)
  static double? _getFallbackRate(String from, String to) {
    // Common currency pairs with approximate rates
    final commonRates = {
      'USD_EUR': 0.85,
      'USD_GBP': 0.73,
      'USD_JPY': 110.0,
      'USD_INR': 75.0,
      'USD_LKR': 200.0,
      'EUR_USD': 1.18,
      'EUR_GBP': 0.86,
      'GBP_USD': 1.37,
      'GBP_EUR': 1.16,
    };

    final key = '${from}_$to';
    return commonRates[key];
  }

  /// Convert amount from one currency to another
  static Future<double?> convert(
    double amount,
    String fromCurrency,
    String toCurrency,
  ) async {
    final rate = await getExchangeRate(fromCurrency, toCurrency);
    if (rate != null) {
      return amount * rate;
    }
    return null;
  }

  /// Available currencies
  static const List<String> currencies = [
    'USD', // US Dollar
    'EUR', // Euro
    'GBP', // British Pound
    'JPY', // Japanese Yen
    'INR', // Indian Rupee
    'LKR', // Sri Lankan Rupee
    'AUD', // Australian Dollar
    'CAD', // Canadian Dollar
    'CHF', // Swiss Franc
    'CNY', // Chinese Yuan
    'PKR', // Pakistani Rupee
    'BDT', // Bangladeshi Taka
    'NPR', // Nepalese Rupee
    'MVR', // Maldivian Rufiyaa
  ];

  /// Get currency symbol
  static String getCurrencySymbol(String currency) {
    const symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'INR': '₹',
      'LKR': 'Rs',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'CHF': 'CHF',
      'CNY': '¥',
      'PKR': 'Rs',
      'BDT': '৳',
      'NPR': 'Rs',
      'MVR': 'Rf',
    };
    return symbols[currency] ?? currency;
  }
}
