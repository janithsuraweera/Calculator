import 'package:flutter/material.dart';
import '../services/theme_manager.dart';
import '../services/haptic_sound_manager.dart';
import '../services/vault_manager.dart';
import 'vault_pin_dialog.dart';

/// Enhanced settings dialog with all advanced features
class EnhancedSettingsDialog extends StatefulWidget {
  final ThemeMode currentTheme;
  final int currentAccentColorIndex;

  const EnhancedSettingsDialog({
    super.key,
    required this.currentTheme,
    required this.currentAccentColorIndex,
  });

  @override
  State<EnhancedSettingsDialog> createState() => _EnhancedSettingsDialogState();
}

class _EnhancedSettingsDialogState extends State<EnhancedSettingsDialog> {
  late ThemeMode selectedTheme;
  late int selectedAccentColorIndex;
  String hapticIntensity = 'medium';
  bool soundEnabled = true;
  String soundTheme = 'classic';
  bool vaultEnabled = false;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.currentTheme;
    selectedAccentColorIndex = widget.currentAccentColorIndex;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final intensity = await HapticSoundManager.getHapticIntensity();
    final sound = await HapticSoundManager.isSoundEnabled();
    final theme = await HapticSoundManager.getSoundTheme();
    final vault = await VaultManager.isVaultEnabled();

    setState(() {
      hapticIntensity = intensity;
      soundEnabled = sound;
      soundTheme = theme;
      vaultEnabled = vault;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme selection
            _buildSectionTitle(theme, 'Theme'),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                ),
              ],
              selected: {selectedTheme},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                setState(() {
                  selectedTheme = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // Accent color selection
            _buildSectionTitle(theme, 'Accent Color'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(ThemeManager.accentColors.length, (
                index,
              ) {
                final color = ThemeManager.accentColors[index];
                final isSelected = index == selectedAccentColorIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAccentColorIndex = index;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.onSurface
                            : Colors.transparent,
                        width: isSelected ? 3 : 0,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: color.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Haptic feedback settings
            _buildSectionTitle(theme, 'Haptic Feedback'),
            DropdownButtonFormField<String>(
              initialValue: hapticIntensity,
              items: const [
                DropdownMenuItem(value: 'light', child: Text('Light')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'heavy', child: Text('Heavy')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    hapticIntensity = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Sound settings
            _buildSectionTitle(theme, 'Sound Effects'),
            SwitchListTile(
              title: const Text('Enable Sounds'),
              value: soundEnabled,
              onChanged: (value) {
                setState(() {
                  soundEnabled = value;
                });
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: soundTheme,
              items: const [
                DropdownMenuItem(value: 'classic', child: Text('Classic')),
                DropdownMenuItem(value: 'modern', child: Text('Modern')),
                DropdownMenuItem(value: 'minimal', child: Text('Minimal')),
              ],
              onChanged: soundEnabled
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          soundTheme = value;
                        });
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 24),

            // Vault settings
            _buildSectionTitle(theme, 'Secure Vault'),
            SwitchListTile(
              title: const Text('Enable Secure Vault'),
              subtitle: const Text('Lock sensitive files and calculations'),
              value: vaultEnabled,
              onChanged: (value) async {
                if (value) {
                  // Enabling vault - check if PIN is set
                  final hasPin = await VaultManager.hasPin();
                  if (!hasPin) {
                    // First time setup - show PIN setup dialog
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => const VaultPinDialog(isSetup: true),
                    );
                    if (result == true) {
                      // Ask if user wants to enable biometric
                      final useBiometric = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Enable Biometric?'),
                          content: const Text(
                            'Do you want to use biometric authentication (fingerprint/face) to unlock the vault?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      );
                      if (useBiometric == true) {
                        final isAvailable =
                            await VaultManager.isBiometricAvailable();
                        if (isAvailable) {
                          await VaultManager.setUseBiometric(true);
                        }
                      }
                      setState(() {
                        vaultEnabled = true;
                      });
                    }
                  } else {
                    setState(() {
                      vaultEnabled = true;
                    });
                  }
                } else {
                  // Disabling vault
                  setState(() {
                    vaultEnabled = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await ThemeManager.setThemeMode(selectedTheme);
            await ThemeManager.setAccentColorIndex(selectedAccentColorIndex);
            await HapticSoundManager.setHapticIntensity(hapticIntensity);
            await HapticSoundManager.setSoundEnabled(soundEnabled);
            await HapticSoundManager.setSoundTheme(soundTheme);
            await VaultManager.setVaultEnabled(vaultEnabled);

            if (context.mounted) {
              Navigator.of(context).pop({
                'theme': selectedTheme,
                'accentColorIndex': selectedAccentColorIndex,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
