import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/enhanced_calculator_screen.dart';
import 'services/theme_manager.dart';

/// Main entry point of the Calculator application
/// Author: Janith Suraweera
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme settings
  // Theme settings initialize කිරීම
  await _initializeApp();

  runApp(const CalculatorApp());
}

/// Initialize app settings
/// App settings initialize කිරීම
Future<void> _initializeApp() async {
  // Any initialization code can go here
  // Any initialization code මෙතන add කළ හැක
}

/// Main calculator application widget
/// මූලික calculator application widget එක
class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.light;
  int _accentColorIndex = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
  }

  /// Load theme settings from storage
  /// Storage වලින් theme settings load කිරීම
  Future<void> _loadThemeSettings() async {
    final themeMode = await ThemeManager.getThemeMode();
    final accentColorIndex = await ThemeManager.getAccentColorIndex();

    setState(() {
      _themeMode = themeMode;
      _accentColorIndex = accentColorIndex;
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show loading indicator while initializing
      // Initialize වන අතරතුර loading indicator පෙන්වීම
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final accentColor = ThemeManager.getAccentColor(_accentColorIndex);
    final themeData = ThemeManager.buildThemeData(_themeMode, accentColor);

    return MaterialApp(
      title: 'Calculator',
      // Enable localization
      // Localization enable කිරීම
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('si', ''), // Sinhala
      ],
      // Set default locale
      // Default locale set කිරීම
      locale: const Locale('si', ''), // Default to Sinhala
      theme: themeData,
      darkTheme: themeData,
      themeMode: _themeMode,
      home: const EnhancedCalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
