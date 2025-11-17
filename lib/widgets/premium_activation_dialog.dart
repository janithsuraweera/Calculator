import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/premium_manager.dart';
import '../services/haptic_sound_manager.dart';

/// Dialog for activating premium features with code
class PremiumActivationDialog extends StatefulWidget {
  const PremiumActivationDialog({super.key});

  @override
  State<PremiumActivationDialog> createState() =>
      _PremiumActivationDialogState();
}

class _PremiumActivationDialogState extends State<PremiumActivationDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await PremiumManager.isPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
    }
  }

  Future<void> _activatePremium() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a premium code';
      });
      return;
    }

    if (!PremiumManager.isValidCodeFormat(code)) {
      setState(() {
        _errorMessage = 'Invalid code format';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await HapticSoundManager.triggerHaptic();

    final success = await PremiumManager.activatePremium(code);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      await HapticSoundManager.playClickSound();
      await HapticSoundManager.triggerHaptic();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium activated successfully! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid premium code. Please try again.';
      });
      await HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 28),
          const SizedBox(width: 8),
          const Text('Premium Activation'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isPremium) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Premium is already activated!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Enter your premium code to unlock all features:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Premium Code',
                hintText: 'Enter code (e.g., 1234jhs)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.vpn_key),
                errorText: _errorMessage,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _activatePremium(),
              enabled: !_isLoading && !_isPremium,
            ),
            const SizedBox(height: 8),
            Text(
              'Premium features include:\n'
              '• Unlimited history\n'
              '• Advanced themes\n'
              '• Export calculations\n'
              '• Priority support\n'
              '• Ad-free experience',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (!_isPremium)
          FilledButton(
            onPressed: _isLoading ? null : _activatePremium,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Activate'),
          ),
      ],
    );
  }
}

