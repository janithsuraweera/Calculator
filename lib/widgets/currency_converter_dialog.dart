import 'package:flutter/material.dart';
import '../services/currency_converter.dart';

/// Currency converter dialog widget
class CurrencyConverterDialog extends StatefulWidget {
  const CurrencyConverterDialog({super.key});

  @override
  State<CurrencyConverterDialog> createState() =>
      _CurrencyConverterDialogState();
}

class _CurrencyConverterDialogState extends State<CurrencyConverterDialog> {
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _amount = 0;
  double? _convertedAmount;
  bool _isLoading = false;

  final TextEditingController _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Convert currency
  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
      }
      return;
    }

    setState(() {
      _amount = amount;
      _isLoading = true;
      _convertedAmount = null;
    });

    final result = await CurrencyConverter.convert(
      amount,
      _fromCurrency,
      _toCurrency,
    );

    setState(() {
      _isLoading = false;
      _convertedAmount = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Currency Converter'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: CurrencyConverter.getCurrencySymbol(_fromCurrency),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // From currency
            DropdownButtonFormField<String>(
              value: _fromCurrency,
              decoration: InputDecoration(
                labelText: 'From Currency',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: CurrencyConverter.currencies.map((currency) {
                return DropdownMenuItem(value: currency, child: Text(currency));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _fromCurrency = value;
                    _convertedAmount = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Swap button
            IconButton(
              icon: const Icon(Icons.swap_vert),
              onPressed: () {
                setState(() {
                  final temp = _fromCurrency;
                  _fromCurrency = _toCurrency;
                  _toCurrency = temp;
                  _convertedAmount = null;
                });
              },
            ),

            // To currency
            DropdownButtonFormField<String>(
              value: _toCurrency,
              decoration: InputDecoration(
                labelText: 'To Currency',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: CurrencyConverter.currencies.map((currency) {
                return DropdownMenuItem(value: currency, child: Text(currency));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _toCurrency = value;
                    _convertedAmount = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Convert button
            FilledButton.icon(
              onPressed: _isLoading ? null : _convert,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.compare_arrows),
              label: Text(_isLoading ? 'Converting...' : 'Convert'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),

            // Result
            if (_convertedAmount != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${CurrencyConverter.getCurrencySymbol(_toCurrency)} ${_convertedAmount!.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Exchange Rate: ${(_convertedAmount! / _amount).toStringAsFixed(4)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
