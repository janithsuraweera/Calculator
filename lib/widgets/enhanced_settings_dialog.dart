import 'package:flutter/material.dart';
import '../services/theme_manager.dart';
import '../services/haptic_sound_manager.dart';
import '../services/vault_manager.dart';
import '../services/screenshot_detector.dart';
import '../services/cloud_backup_service.dart';
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
  bool initialVaultState = false; // Track initial state to detect changes
  bool biometricEnabled = false;
  bool screenshotDetectionEnabled = false;
  bool cloudBackupEnabled = false;
  String? googleAccountEmail;

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
    // Load actual vault state (will be false on app start, but can be enabled)
    final vault = await VaultManager.isVaultEnabled();
    final biometric = await VaultManager.getUseBiometric();
    final screenshot = ScreenshotDetector.isEnabled();
    final cloudBackup = await CloudBackupService.isSignedIn();
    final email = await CloudBackupService.getCurrentUserEmail();

    setState(() {
      hapticIntensity = intensity;
      soundEnabled = sound;
      soundTheme = theme;
      vaultEnabled = vault;
      initialVaultState = vault; // Store initial state
      biometricEnabled = biometric;
      screenshotDetectionEnabled = screenshot;
      cloudBackupEnabled = cloudBackup;
      googleAccountEmail = email;
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
              title: const Text('Show Secure Vault'),
              subtitle: const Text(
                'Show vault tab in calculator. PIN will be required when accessing vault.',
              ),
              value: vaultEnabled,
              onChanged: (value) async {
                if (value) {
                  // Enabling vault - check if PIN is set, if not setup PIN
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
                      await VaultManager.setVaultEnabled(true);
                      setState(() {
                        vaultEnabled = true;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vault enabled. Vault tab will appear in calculator.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } else {
                    // PIN exists - just enable vault (no PIN required here)
                    await VaultManager.setVaultEnabled(true);
                    setState(() {
                      vaultEnabled = true;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vault enabled. Vault tab will appear in calculator.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } else {
                  // Disabling vault - no password required, just hide it
                  await VaultManager.setVaultEnabled(false);
                  setState(() {
                    vaultEnabled = false;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vault hidden. Vault tab will be removed from calculator.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                }
                // Always signal vault changed when toggled
                // This will be handled in the Save button
              },
            ),
            const SizedBox(height: 24),

            // Biometric authentication
            _buildSectionTitle(theme, 'Biometric Authentication'),
            SwitchListTile(
              title: const Text('Enable Biometric'),
              subtitle: const Text('Use fingerprint or face ID'),
              value: biometricEnabled,
              onChanged: vaultEnabled
                  ? (value) async {
                      if (value) {
                        final isAvailable =
                            await VaultManager.isBiometricAvailable();
                        if (isAvailable) {
                          await VaultManager.setUseBiometric(true);
                          setState(() {
                            biometricEnabled = true;
                          });
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Biometric authentication is not available on this device',
                                ),
                              ),
                            );
                          }
                        }
                      } else {
                        await VaultManager.setUseBiometric(false);
                        setState(() {
                          biometricEnabled = false;
                        });
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 24),

            // Screenshot detection
            _buildSectionTitle(theme, 'Screenshot Detection'),
            SwitchListTile(
              title: const Text('Enable Screenshot Detection'),
              subtitle: const Text(
                'Show reminder notes when screenshot is taken',
              ),
              value: screenshotDetectionEnabled,
              onChanged: (value) {
                ScreenshotDetector.setEnabled(value);
                setState(() {
                  screenshotDetectionEnabled = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Google Cloud Backup
            _buildSectionTitle(theme, 'Cloud Backup'),
            SwitchListTile(
              title: const Text('Google Cloud Backup'),
              subtitle: Text(
                googleAccountEmail != null
                    ? 'Signed in as: $googleAccountEmail'
                    : 'Backup all data to Google Cloud',
              ),
              value: cloudBackupEnabled,
              onChanged: (value) async {
                if (value) {
                  // Sign in
                  try {
                    final success = await CloudBackupService.signIn();
                    if (success) {
                      final email =
                          await CloudBackupService.getCurrentUserEmail();
                      setState(() {
                        cloudBackupEnabled = true;
                        googleAccountEmail = email;
                      });
                      // Auto backup
                      await CloudBackupService.backupAllData();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Backup completed successfully'),
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to sign in to Google'),
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Google Cloud backup is not available: ${e.toString()}',
                          ),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                    setState(() {
                      cloudBackupEnabled = false;
                    });
                  }
                } else {
                  // Sign out
                  await CloudBackupService.signOut();
                  setState(() {
                    cloudBackupEnabled = false;
                    googleAccountEmail = null;
                  });
                }
              },
            ),
            if (cloudBackupEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup Now'),
                onTap: () async {
                  final success = await CloudBackupService.backupAllData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Backup completed successfully'
                              : 'Backup failed',
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore from Backup'),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Restore Backup'),
                      content: const Text(
                        'This will replace all current data with the backup. Continue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Restore'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    final success = await CloudBackupService.restoreData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Data restored successfully'
                                : 'Restore failed',
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
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
            // Vault enabled state is already saved when toggled
            // Check if vault state changed from initial state
            final vaultChanged = vaultEnabled != initialVaultState;

            if (context.mounted) {
              Navigator.of(context).pop({
                'theme': selectedTheme,
                'accentColorIndex': selectedAccentColorIndex,
                'vaultChanged': vaultChanged, // Signal if vault state changed
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
