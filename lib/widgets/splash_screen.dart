import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Splash screen widget showing logo, author name, and app version
class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _navigateToMain();
  }

  /// Load app version from package info
  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
        });
      }
    } catch (e) {
      // If version loading fails, use default
      if (mounted) {
        setState(() {
          _version = '1.0.0';
        });
      }
    }
  }

  /// Navigate to main screen after delay
  void _navigateToMain() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        widget.onFinish();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [Colors.blue.shade900, Colors.blue.shade700]
                : [Colors.blue.shade400, Colors.blue.shade200],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'lib/assets/icons/cal logo.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                  cacheWidth: 300, // Optimize image loading
                  cacheHeight: 300,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image fails to load
                    return Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.calculate,
                        size: 80,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // App Name
              Text(
                'SMARTCALC',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              // Author Name
              Text(
                'Janith Suraweera',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),

              // Version
              Text(
                'Version $_version',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 40),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
