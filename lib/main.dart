import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/enhanced_calculator_screen.dart';
import 'services/theme_manager.dart';
import 'widgets/splash_screen.dart';

/// Main entry point of the Calculator application
/// Author: Janith Suraweera
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize theme settings
  await _initializeApp();

  runApp(const CalculatorApp());
}

/// Initialize app settings
Future<void> _initializeApp() async {
  // Any initialization code can go here
}

/// Main calculator application widget
class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  ThemeMode _themeMode = ThemeMode.light;
  int _accentColorIndex = 0;
  bool _isInitialized = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadThemeSettings();
    // Listen for theme changes from settings
    _setupThemeListener();
  }

  /// Setup listener for theme changes
  void _setupThemeListener() {
    // Check for theme changes periodically
    Future.delayed(const Duration(milliseconds: 100), () {
      _checkThemeChanges();
    });
  }

  /// Update theme from settings (called externally)
  void updateTheme() {
    _loadThemeSettings();
  }

  /// Check and update theme if changed
  Future<void> _checkThemeChanges() async {
    final newThemeMode = await ThemeManager.getThemeMode();
    final newAccentColorIndex = await ThemeManager.getAccentColorIndex();

    if (mounted &&
        (newThemeMode != _themeMode ||
            newAccentColorIndex != _accentColorIndex)) {
      setState(() {
        _themeMode = newThemeMode;
        _accentColorIndex = newAccentColorIndex;
      });
    }
  }

  /// Load theme settings from storage
  Future<void> _loadThemeSettings() async {
    final themeMode = await ThemeManager.getThemeMode();
    final accentColorIndex = await ThemeManager.getAccentColorIndex();

    setState(() {
      _themeMode = themeMode;
      _accentColorIndex = accentColorIndex;
      _isInitialized = true;
    });
  }

  /// Handle splash screen finish
  void _onSplashFinish() {
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show loading indicator while initializing
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    final accentColor = ThemeManager.getAccentColor(_accentColorIndex);

    final lightTheme = ThemeManager.buildThemeData(
      ThemeMode.light,
      accentColor,
    );
    final darkTheme = ThemeManager.buildThemeData(ThemeMode.dark, accentColor);

    return MaterialApp(
      title: 'Calculator',
      // Enable localization
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
      locale: const Locale('en', ''), // Default to English
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: _showSplash
          ? SplashScreen(onFinish: _onSplashFinish)
          : const EnhancedCalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
