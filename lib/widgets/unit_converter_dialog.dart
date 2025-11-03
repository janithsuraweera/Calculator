import 'package:flutter/material.dart';
import '../services/unit_converter.dart';

/// Unit converter dialog widget
class UnitConverterDialog extends StatefulWidget {
  final String category;
  final double? initialValue;

  const UnitConverterDialog({
    super.key,
    required this.category,
    this.initialValue,
  });

  @override
  State<UnitConverterDialog> createState() => _UnitConverterDialogState();
}

class _UnitConverterDialogState extends State<UnitConverterDialog> {
  String? _fromUnit;
  String? _toUnit;
  double? _convertedValue;
  final TextEditingController _valueController = TextEditingController();

  /// Get unit labels
  Map<String, String> get _unitLabels => UnitConverter.getUnitLabels();

  @override
  void initState() {
    super.initState();
    final units = UnitConverter.units[widget.category];
    if (units != null && units.isNotEmpty) {
      _fromUnit = units[0];
      _toUnit = units.length > 1 ? units[1] : units[0];
    }
    if (widget.initialValue != null) {
      _valueController.text = widget.initialValue!.toString();
      _convert();
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  /// Convert units
  void _convert() {
    final value = double.tryParse(_valueController.text);
    if (value == null || _fromUnit == null || _toUnit == null) {
      setState(() {
        _convertedValue = null;
      });
      return;
    }

    double? result;
    switch (widget.category) {
      case 'length':
        result = UnitConverter.convertLength(value, _fromUnit!, _toUnit!);
        break;
      case 'area':
        result = UnitConverter.convertArea(value, _fromUnit!, _toUnit!);
        break;
      case 'volume':
        result = UnitConverter.convertVolume(value, _fromUnit!, _toUnit!);
        break;
      case 'time':
        result = UnitConverter.convertTime(value, _fromUnit!, _toUnit!);
        break;
      case 'temperature':
        result = UnitConverter.convertTemperature(value, _fromUnit!, _toUnit!);
        break;
      case 'weight':
        result = UnitConverter.convertWeight(value, _fromUnit!, _toUnit!);
        break;
    }

    setState(() {
      _convertedValue = result;
    });
  }

  /// Swap units
  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _convertedValue = null;
    });
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final units = UnitConverter.units[widget.category] ?? [];

    return AlertDialog(
      title: Text('${widget.category.toUpperCase()} Converter'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Value input
            TextField(
              controller: _valueController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _convert(),
              decoration: InputDecoration(
                labelText: 'Value',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixText: _fromUnit,
              ),
            ),
            const SizedBox(height: 16),

            // From unit
            DropdownButtonFormField<String>(
              initialValue: _fromUnit,
              decoration: InputDecoration(
                labelText: 'From',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: units.map((unit) {
                final label = _unitLabels[unit] ?? unit;
                return DropdownMenuItem(
                  value: unit,
                  child: Text('$label ($unit)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _fromUnit = value;
                  _convertedValue = null;
                });
                _convert();
              },
            ),
            const SizedBox(height: 16),

            // Swap button
            IconButton(
              icon: const Icon(Icons.swap_vert),
              onPressed: _swapUnits,
              tooltip: 'Swap Units',
            ),

            // To unit
            DropdownButtonFormField<String>(
              initialValue: _toUnit,
              decoration: InputDecoration(
                labelText: 'To',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: units.map((unit) {
                final label = _unitLabels[unit] ?? unit;
                return DropdownMenuItem(
                  value: unit,
                  child: Text('$label ($unit)'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _toUnit = value;
                  _convertedValue = null;
                });
                _convert();
              },
            ),
            const SizedBox(height: 16),

            // Result
            if (_convertedValue != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_convertedValue!.toStringAsFixed(6).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '')} $_toUnit',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
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
