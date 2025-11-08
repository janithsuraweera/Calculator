import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// About/Help screen showing app information, developer details, and contact info
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  /// Load app version information
  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _version = packageInfo.version;
          _buildNumber = packageInfo.buildNumber;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _version = '1.0.0';
          _buildNumber = '1';
        });
      }
    }
  }

  /// Launch email client
  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'janithsuraweera7@gmail.com',
      query: 'subject=Calculator App Feedback',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('About & Help')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'lib/assets/icons/cal logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.calculate,
                            size: 50,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SMARTCALC',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version $_version (Build $_buildNumber)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Developer Information
            _buildSection(context, 'Developer Information', Icons.person, [
              _buildInfoRow(
                context,
                'Name',
                'Janith Suraweera',
                Icons.person_outline,
              ),
              _buildInfoRow(
                context,
                'Email',
                'janithsuraweera7@gmail.com',
                Icons.email_outlined,
                onTap: _launchEmail,
              ),
            ]),
            const SizedBox(height: 24),

            // Contact Information
            _buildSection(context, 'Contact', Icons.contact_mail, [
              _buildInfoRow(
                context,
                'Email',
                'janithsuraweera7@gmail.com',
                Icons.email,
                onTap: _launchEmail,
              ),
            ]),
            const SizedBox(height: 24),

            // App Features
            _buildSection(context, 'Features', Icons.star, [
              _buildFeatureItem(context, 'Basic & Scientific Calculator'),
              _buildFeatureItem(context, 'Calculation History'),
              _buildFeatureItem(context, 'Undo/Redo Functionality'),
              _buildFeatureItem(context, 'AR Mode (Camera Recognition)'),
              _buildFeatureItem(context, 'Unit Converter'),
              _buildFeatureItem(context, 'Currency Converter'),
              _buildFeatureItem(context, 'Secure Vault Mode'),
              _buildFeatureItem(context, 'Clipboard Support'),
              _buildFeatureItem(context, 'Dark/Light Themes'),
              _buildFeatureItem(context, 'Customizable Accent Colors'),
              _buildFeatureItem(context, 'Haptic Feedback'),
              _buildFeatureItem(context, 'Sinhala & English Support'),
            ]),
            const SizedBox(height: 24),

            // Help & Support
            _buildSection(context, 'Help & Support', Icons.help_outline, [
              _buildHelpItem(
                context,
                'How to use Basic Mode',
                'Tap numbers and operators to perform calculations. Use = to calculate result. Press C to clear last entry, AC to clear all.',
              ),
              _buildHelpItem(
                context,
                'How to use Scientific Mode',
                'Tap the science icon in the quick action bar to switch to scientific mode. Use sin, cos, tan, log, ln, sqrt, exp, factorial, and power functions.',
              ),
              _buildHelpItem(
                context,
                'Undo/Redo',
                'Use the undo/redo buttons in the quick action bar, or swipe left (undo) / right (redo) on the screen.',
              ),
              _buildHelpItem(
                context,
                'History',
                'View your calculation history in the History tab. Tap any item to reuse the result. Clear history using the Clear button.',
              ),
              _buildHelpItem(
                context,
                'AR Mode',
                'Tap the camera icon in the app bar menu to use AR mode. Point your camera at numbers or mathematical expressions to recognize and calculate them.',
              ),
              _buildHelpItem(
                context,
                'Unit Converter',
                'Tap the Units button in the quick action bar to convert between different units (length, weight, temperature, etc.).',
              ),
              _buildHelpItem(
                context,
                'Currency Converter',
                'Tap the Currency button in the quick action bar or app bar to convert between different currencies with real-time exchange rates.',
              ),
              _buildHelpItem(
                context,
                'Vault Mode',
                'Enable vault mode in settings to securely store sensitive calculations. Access vault by entering PIN (1234) or through the Vault tab.',
              ),
              _buildHelpItem(
                context,
                'Clipboard Support',
                'The app automatically detects mathematical expressions in your clipboard and offers to calculate them.',
              ),
              _buildHelpItem(
                context,
                'Themes & Colors',
                'Access settings from the app bar to switch between Light/Dark themes and choose from 10 customizable accent colors.',
              ),
            ]),
            const SizedBox(height: 24),

            // Copyright
            Center(
              child: Text(
                '© 2025 Janith Suraweera. All rights reserved.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Build a section with title
  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// Build an info row
  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }

  /// Build a feature item
  Widget _buildFeatureItem(BuildContext context, String feature) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(feature, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  /// Build a help item
  Widget _buildHelpItem(BuildContext context, String question, String answer) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
