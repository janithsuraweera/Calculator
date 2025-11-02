/// Unit converter service for length, area, volume, time, temperature, and weight
class UnitConverter {
  /// Convert length
  static double? convertLength(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    // Convert to meters first
    final inMeters = _lengthToMeters(value, fromUnit);
    if (inMeters == null) return null;

    // Convert from meters to target unit
    return _metersToLength(inMeters, toUnit);
  }

  /// Convert length to meters
  static double? _lengthToMeters(double value, String unit) {
    switch (unit) {
      case 'mm': // millimeter
        return value / 1000;
      case 'cm': // centimeter
        return value / 100;
      case 'm': // meter
        return value;
      case 'km': // kilometer
        return value * 1000;
      case 'in': // inch
        return value * 0.0254;
      case 'ft': // foot
        return value * 0.3048;
      case 'yd': // yard
        return value * 0.9144;
      case 'mi': // mile
        return value * 1609.34;
      default:
        return null;
    }
  }

  /// Convert meters to target unit
  static double? _metersToLength(double meters, String unit) {
    switch (unit) {
      case 'mm':
        return meters * 1000;
      case 'cm':
        return meters * 100;
      case 'm':
        return meters;
      case 'km':
        return meters / 1000;
      case 'in':
        return meters / 0.0254;
      case 'ft':
        return meters / 0.3048;
      case 'yd':
        return meters / 0.9144;
      case 'mi':
        return meters / 1609.34;
      default:
        return null;
    }
  }

  /// Convert area
  static double? convertArea(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    // Convert to square meters first
    final inSqMeters = _areaToSqMeters(value, fromUnit);
    if (inSqMeters == null) return null;

    return _sqMetersToArea(inSqMeters, toUnit);
  }

  /// Convert area to square meters
  static double? _areaToSqMeters(double value, String unit) {
    switch (unit) {
      case 'm²': // square meter
        return value;
      case 'km²': // square kilometer
        return value * 1000000;
      case 'cm²': // square centimeter
        return value / 10000;
      case 'mm²': // square millimeter
        return value / 1000000;
      case 'in²': // square inch
        return value * 0.00064516;
      case 'ft²': // square foot
        return value * 0.092903;
      case 'yd²': // square yard
        return value * 0.836127;
      case 'ac': // acre
        return value * 4046.86;
      case 'ha': // hectare
        return value * 10000;
      default:
        return null;
    }
  }

  /// Convert square meters to target unit
  static double? _sqMetersToArea(double sqMeters, String unit) {
    switch (unit) {
      case 'm²':
        return sqMeters;
      case 'km²':
        return sqMeters / 1000000;
      case 'cm²':
        return sqMeters * 10000;
      case 'mm²':
        return sqMeters * 1000000;
      case 'in²':
        return sqMeters / 0.00064516;
      case 'ft²':
        return sqMeters / 0.092903;
      case 'yd²':
        return sqMeters / 0.836127;
      case 'ac':
        return sqMeters / 4046.86;
      case 'ha':
        return sqMeters / 10000;
      default:
        return null;
    }
  }

  /// Convert volume
  static double? convertVolume(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    // Convert to liters first
    final inLiters = _volumeToLiters(value, fromUnit);
    if (inLiters == null) return null;

    return _litersToVolume(inLiters, toUnit);
  }

  /// Convert volume to liters
  static double? _volumeToLiters(double value, String unit) {
    switch (unit) {
      case 'L': // liter
        return value;
      case 'mL': // milliliter
        return value / 1000;
      case 'm³': // cubic meter
        return value * 1000;
      case 'cm³': // cubic centimeter
        return value / 1000;
      case 'fl oz': // fluid ounce (US)
        return value * 0.0295735;
      case 'cup': // cup (US)
        return value * 0.236588;
      case 'pt': // pint (US)
        return value * 0.473176;
      case 'qt': // quart (US)
        return value * 0.946353;
      case 'gal': // gallon (US)
        return value * 3.78541;
      default:
        return null;
    }
  }

  /// Convert liters to target unit
  static double? _litersToVolume(double liters, String unit) {
    switch (unit) {
      case 'L':
        return liters;
      case 'mL':
        return liters * 1000;
      case 'm³':
        return liters / 1000;
      case 'cm³':
        return liters * 1000;
      case 'fl oz':
        return liters / 0.0295735;
      case 'cup':
        return liters / 0.236588;
      case 'pt':
        return liters / 0.473176;
      case 'qt':
        return liters / 0.946353;
      case 'gal':
        return liters / 3.78541;
      default:
        return null;
    }
  }

  /// Convert time
  static double? convertTime(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    // Convert to seconds first
    final inSeconds = _timeToSeconds(value, fromUnit);
    if (inSeconds == null) return null;

    return _secondsToTime(inSeconds, toUnit);
  }

  /// Convert time to seconds
  static double? _timeToSeconds(double value, String unit) {
    switch (unit) {
      case 's': // second
        return value;
      case 'min': // minute
        return value * 60;
      case 'h': // hour
        return value * 3600;
      case 'd': // day
        return value * 86400;
      case 'wk': // week
        return value * 604800;
      case 'mo': // month (30 days)
        return value * 2592000;
      case 'yr': // year (365 days)
        return value * 31536000;
      default:
        return null;
    }
  }

  /// Convert seconds to target unit
  static double? _secondsToTime(double seconds, String unit) {
    switch (unit) {
      case 's':
        return seconds;
      case 'min':
        return seconds / 60;
      case 'h':
        return seconds / 3600;
      case 'd':
        return seconds / 86400;
      case 'wk':
        return seconds / 604800;
      case 'mo':
        return seconds / 2592000;
      case 'yr':
        return seconds / 31536000;
      default:
        return null;
    }
  }

  /// Convert temperature
  static double? convertTemperature(
    double value,
    String fromUnit,
    String toUnit,
  ) {
    if (fromUnit == toUnit) return value;

    // Convert to Celsius first
    final inCelsius = _temperatureToCelsius(value, fromUnit);
    if (inCelsius == null) return null;

    return _celsiusToTemperature(inCelsius, toUnit);
  }

  /// Convert temperature to Celsius
  static double? _temperatureToCelsius(double value, String unit) {
    switch (unit) {
      case '°C': // Celsius
        return value;
      case '°F': // Fahrenheit
        return (value - 32) * 5 / 9;
      case 'K': // Kelvin
        return value - 273.15;
      case '°R': // Rankine
        return (value - 491.67) * 5 / 9;
      default:
        return null;
    }
  }

  /// Convert Celsius to target unit
  static double? _celsiusToTemperature(double celsius, String unit) {
    switch (unit) {
      case '°C':
        return celsius;
      case '°F':
        return (celsius * 9 / 5) + 32;
      case 'K':
        return celsius + 273.15;
      case '°R':
        return (celsius * 9 / 5) + 491.67;
      default:
        return null;
    }
  }

  /// Convert weight
  static double? convertWeight(double value, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return value;

    // Convert to kilograms first
    final inKg = _weightToKg(value, fromUnit);
    if (inKg == null) return null;

    return _kgToWeight(inKg, toUnit);
  }

  /// Convert weight to kilograms
  static double? _weightToKg(double value, String unit) {
    switch (unit) {
      case 'mg': // milligram
        return value / 1000000;
      case 'g': // gram
        return value / 1000;
      case 'kg': // kilogram
        return value;
      case 't': // metric ton
        return value * 1000;
      case 'oz': // ounce
        return value * 0.0283495;
      case 'lb': // pound
        return value * 0.453592;
      case 'st': // stone
        return value * 6.35029;
      default:
        return null;
    }
  }

  /// Convert kilograms to target unit
  static double? _kgToWeight(double kg, String unit) {
    switch (unit) {
      case 'mg':
        return kg * 1000000;
      case 'g':
        return kg * 1000;
      case 'kg':
        return kg;
      case 't':
        return kg / 1000;
      case 'oz':
        return kg / 0.0283495;
      case 'lb':
        return kg / 0.453592;
      case 'st':
        return kg / 6.35029;
      default:
        return null;
    }
  }

  /// Available units for each category
  static const Map<String, List<String>> units = {
    'length': ['mm', 'cm', 'm', 'km', 'in', 'ft', 'yd', 'mi'],
    'area': ['mm²', 'cm²', 'm²', 'km²', 'in²', 'ft²', 'yd²', 'ac', 'ha'],
    'volume': ['mL', 'L', 'cm³', 'm³', 'fl oz', 'cup', 'pt', 'qt', 'gal'],
    'time': ['s', 'min', 'h', 'd', 'wk', 'mo', 'yr'],
    'temperature': ['°C', '°F', 'K', '°R'],
    'weight': ['mg', 'g', 'kg', 't', 'oz', 'lb', 'st'],
  };

  /// Get unit labels for display
  static Map<String, String> getUnitLabels() {
    // Return unit labels map
    return {
      // Length
      'mm': 'Millimeter',
      'cm': 'Centimeter',
      'm': 'Meter',
      'km': 'Kilometer',
      'in': 'Inch',
      'ft': 'Foot',
      'yd': 'Yard',
      'mi': 'Mile',
      // Area
      'mm²': 'Square Millimeter',
      'cm²': 'Square Centimeter',
      'm²': 'Square Meter',
      'km²': 'Square Kilometer',
      'in²': 'Square Inch',
      'ft²': 'Square Foot',
      'yd²': 'Square Yard',
      'ac': 'Acre',
      'ha': 'Hectare',
      // Volume
      'mL': 'Milliliter',
      'L': 'Liter',
      'cm³': 'Cubic Centimeter',
      'm³': 'Cubic Meter',
      'fl oz': 'Fluid Ounce',
      'cup': 'Cup',
      'pt': 'Pint',
      'qt': 'Quart',
      'gal': 'Gallon',
      // Time
      's': 'Second',
      'min': 'Minute',
      'h': 'Hour',
      'd': 'Day',
      'wk': 'Week',
      'mo': 'Month',
      'yr': 'Year',
      // Temperature
      '°C': 'Celsius',
      '°F': 'Fahrenheit',
      'K': 'Kelvin',
      '°R': 'Rankine',
      // Weight
      'mg': 'Milligram',
      'g': 'Gram',
      'kg': 'Kilogram',
      't': 'Metric Ton',
      'oz': 'Ounce',
      'lb': 'Pound',
      'st': 'Stone',
    };
  }
}
