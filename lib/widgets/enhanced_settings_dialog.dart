import 'package:flutter/material.dart';
import '../services/theme_manager.dart';
import '../services/haptic_sound_manager.dart';
import '../services/vault_manager.dart';
import '../services/screenshot_detector.dart';
import '../services/cloud_backup_service.dart';
import '../models/cloud_backup_config.dart';
import 'cloud_backup_config_sheet.dart';
import 'vault_pin_dialog.dart';
import 'custom_buttons_manager.dart';

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
  late ThemeMode originalTheme;
  late int originalAccentColorIndex;
  String hapticIntensity = 'medium';
  bool soundEnabled = true;
  String soundTheme = 'classic';
  bool vaultEnabled = false;
  bool initialVaultState = false; // Track initial state to detect changes
  bool biometricEnabled = false;
  bool screenshotDetectionEnabled = false;
  bool cloudBackupEnabled = false;
  String? googleAccountEmail;
  CloudBackupConfig? _backupConfig;

  @override
  void initState() {
    super.initState();
    selectedTheme = widget.currentTheme;
    selectedAccentColorIndex = widget.currentAccentColorIndex;
    // Store original values to revert on cancel
    originalTheme = widget.currentTheme;
    originalAccentColorIndex = widget.currentAccentColorIndex;
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
    final config = await CloudBackupService.getConfig();

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
      _backupConfig = config;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        // Revert to original theme settings when dialog is dismissed
        if (selectedTheme != originalTheme) {
          await ThemeManager.setThemeMode(originalTheme);
        }
        if (selectedAccentColorIndex != originalAccentColorIndex) {
          await ThemeManager.setAccentColorIndex(originalAccentColorIndex);
        }
        navigator.pop();
      },
      child: AlertDialog(
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
                onSelectionChanged: (Set<ThemeMode> newSelection) async {
                  // Play sound effect when changing theme
                  await HapticSoundManager.playClickSound();
                  await HapticSoundManager.triggerHaptic();

                  setState(() {
                    selectedTheme = newSelection.first;
                  });

                  // Update theme in real-time (temporarily, not saved yet)
                  await ThemeManager.setThemeMode(selectedTheme);
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
                    onTap: () async {
                      // Play sound effect when clicking color
                      await HapticSoundManager.playClickSound();
                      await HapticSoundManager.triggerHaptic();

                      setState(() {
                        selectedAccentColorIndex = index;
                      });

                      // Update theme in real-time (temporarily, not saved yet)
                      await ThemeManager.setAccentColorIndex(index);
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
                    if (!mounted) return;
                    if (!hasPin) {
                      // First time setup - show PIN setup dialog
                      final result = await showDialog<bool>(
                        context: context,
                        builder: (context) =>
                            const VaultPinDialog(isSetup: true),
                      );
                      if (!mounted) return;
                      if (result == true) {
                        // Ask if user wants to enable biometric
                        final useBiometric = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Enable Biometric?'),
                            content: const Text(
                              'Do you want to use biometric authentication (fingerprint/face) to unlock the vault?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, false),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(dialogContext, true),
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                        );
                        if (!mounted) return;
                        if (useBiometric == true) {
                          final isAvailable =
                              await VaultManager.isBiometricAvailable();
                          if (isAvailable) {
                            await VaultManager.setUseBiometric(true);
                          }
                        }
                        await VaultManager.setVaultEnabled(true);
                        if (!mounted) return;
                        setState(() {
                          vaultEnabled = true;
                        });
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Vault enabled. Vault tab will appear in calculator.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      // PIN exists - just enable vault (no PIN required here)
                      await VaultManager.setVaultEnabled(true);
                      if (!mounted) return;
                      setState(() {
                        vaultEnabled = true;
                      });
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vault enabled. Vault tab will appear in calculator.',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    // Disabling vault - no password required, just hide it
                    await VaultManager.setVaultEnabled(false);
                    if (!mounted) return;
                    setState(() {
                      vaultEnabled = false;
                    });
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Vault hidden. Vault tab will be removed from calculator.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
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
                            if (!mounted) return;
                            setState(() {
                              biometricEnabled = true;
                            });
                          } else {
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
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
                          if (!mounted) return;
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
                    final initialConfig =
                        _backupConfig ?? await CloudBackupService.getConfig();
                    final config =
                        await showModalBottomSheet<CloudBackupConfig>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) => CloudBackupConfigSheet(
                            initialConfig: initialConfig,
                          ),
                        );
                    if (!mounted) return;
                    if (config == null) {
                      setState(() => cloudBackupEnabled = false);
                      return;
                    }
                    final success = await CloudBackupService.signIn(config);
                    if (success) {
                      final email =
                          await CloudBackupService.getCurrentUserEmail();
                      if (!mounted) return;
                      setState(() {
                        cloudBackupEnabled = true;
                        googleAccountEmail = email;
                        _backupConfig = config;
                      });
                      final autoBackupSuccess =
                          await CloudBackupService.backupAllData();
                      if (autoBackupSuccess && mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Backup completed successfully'),
                          ),
                        );
                      }
                    } else {
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Failed to configure cloud backup'),
                        ),
                      );
                      setState(() => cloudBackupEnabled = false);
                    }
                  } else {
                    await CloudBackupService.signOut();
                    if (!mounted) return;
                    setState(() {
                      cloudBackupEnabled = false;
                      googleAccountEmail = null;
                      _backupConfig = null;
                    });
                  }
                },
              ),
              if (cloudBackupEnabled) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.cloud_done),
                    title: Text(googleAccountEmail ?? 'Not configured'),
                    subtitle: Text(
                      'Frequency: ${_formatFrequency(_backupConfig?.frequency)} · '
                      'Wi-Fi only: ${_backupConfig?.wifiOnly == true ? 'Yes' : 'No'}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final config =
                            await showModalBottomSheet<CloudBackupConfig>(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) => CloudBackupConfigSheet(
                                initialConfig: _backupConfig,
                              ),
                            );
                        if (config == null) return;
                        final success = await CloudBackupService.signIn(config);
                        if (!success || !mounted) return;
                        setState(() {
                          _backupConfig = config;
                          googleAccountEmail = config.email;
                        });
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Cloud backup settings updated'),
                          ),
                        );
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup Now'),
                  onTap: () async {
                    final success = await CloudBackupService.backupAllData();
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Backup completed successfully'
                              : 'Backup failed',
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore from Backup'),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Restore Backup'),
                        content: const Text(
                          'This will replace all current data with the backup. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final success = await CloudBackupService.restoreData();
                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Data restored successfully'
                                : 'Restore failed',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
              const SizedBox(height: 24),

              // Custom Calculator Buttons
              _buildSectionTitle(theme, 'Custom Calculator Buttons'),
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Manage Custom Buttons'),
                subtitle: const Text(
                  'Add custom buttons to scientific calculator',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CustomButtonsManager(mode: 'scientific'),
                    ),
                  );
                  if (result == true && mounted) {
                    // Reload if needed
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Revert to original theme settings on cancel
              if (selectedTheme != originalTheme) {
                await ThemeManager.setThemeMode(originalTheme);
              }
              if (selectedAccentColorIndex != originalAccentColorIndex) {
                await ThemeManager.setAccentColorIndex(
                  originalAccentColorIndex,
                );
              }
              navigator.pop();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              // Settings are already applied in real-time, just save them now
              await ThemeManager.setThemeMode(selectedTheme);
              await ThemeManager.setAccentColorIndex(selectedAccentColorIndex);
              await HapticSoundManager.setHapticIntensity(hapticIntensity);
              await HapticSoundManager.setSoundEnabled(soundEnabled);
              await HapticSoundManager.setSoundTheme(soundTheme);
              // Vault enabled state is already saved when toggled
              // Check if vault state changed from initial state
              final vaultChanged = vaultEnabled != initialVaultState;

              if (!context.mounted) return;
              navigator.pop({
                'theme': selectedTheme,
                'accentColorIndex': selectedAccentColorIndex,
                'vaultChanged': vaultChanged, // Signal if vault state changed
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  String _formatFrequency(String? value) {
    switch (value) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'daily':
      default:
        return 'Daily';
    }
  }
}
