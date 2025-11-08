import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/vault_manager.dart';

/// PIN authentication dialog for vault
class VaultPinDialog extends StatefulWidget {
  final bool isSetup;
  final bool isChangePin;
  final VoidCallback? onSuccess;

  const VaultPinDialog({
    super.key,
    this.isSetup = false,
    this.isChangePin = false,
    this.onSuccess,
  });

  @override
  State<VaultPinDialog> createState() => _VaultPinDialogState();
}

class _VaultPinDialogState extends State<VaultPinDialog> {
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  String _pin = '';
  String _confirmPin = '';
  String _oldPin = '';
  String _firstPin = ''; // Store first PIN for comparison
  bool _isConfirming = false;
  bool _isVerifyingOldPin = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isChangePin) {
      _isVerifyingOldPin = true;
    }
  }

  @override
  void dispose() {
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onPinChanged(int index, String value) {
    // Clear error message when user starts typing
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }

    if (value.length == 1) {
      if (widget.isChangePin) {
        if (_isVerifyingOldPin) {
          _oldPin += value;
        } else if (!_isConfirming) {
          _pin += value;
        } else {
          _confirmPin += value;
        }
      } else if (widget.isSetup) {
        if (!_isConfirming) {
          _pin += value;
        } else {
          _confirmPin += value;
        }
      } else {
        _pin += value;
      }

      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // All digits entered
        if (widget.isChangePin) {
          if (_isVerifyingOldPin) {
            // Verify old PIN first
            _verifyOldPin();
          } else if (!_isConfirming) {
            // First new PIN entered, save it and move to confirm
            setState(() {
              _firstPin = _pin; // Save first PIN
              _isConfirming = true;
              _pin = '';
              for (final controller in _pinControllers) {
                controller.clear();
              }
              _focusNodes[0].requestFocus();
            });
          } else {
            // Confirm new PIN
            _verifyPin();
          }
        } else if (widget.isSetup) {
          if (!_isConfirming) {
            // First PIN entered, save it and move to confirm
            setState(() {
              _firstPin = _pin; // Save first PIN
              _isConfirming = true;
              _pin = '';
              for (final controller in _pinControllers) {
                controller.clear();
              }
              _focusNodes[0].requestFocus();
            });
          } else {
            // Confirm PIN
            _verifyPin();
          }
        } else {
          _verifyPin();
        }
      }
    } else if (value.isEmpty) {
      // Handle backspace - remove last digit
      if (widget.isChangePin) {
        if (_isVerifyingOldPin) {
          if (_oldPin.isNotEmpty) {
            _oldPin = _oldPin.substring(0, _oldPin.length - 1);
          }
        } else if (!_isConfirming) {
          if (_pin.isNotEmpty) {
            _pin = _pin.substring(0, _pin.length - 1);
          }
        } else {
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          }
        }
      } else if (widget.isSetup) {
        if (!_isConfirming) {
          if (_pin.isNotEmpty) {
            _pin = _pin.substring(0, _pin.length - 1);
          }
        } else {
          if (_confirmPin.isNotEmpty) {
            _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
          }
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }
    }
  }

  Future<void> _verifyOldPin() async {
    final isValid = await VaultManager.verifyPin(_oldPin);
    if (isValid) {
      setState(() {
        _isVerifyingOldPin = false;
        _oldPin = '';
        for (final controller in _pinControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    } else {
      setState(() {
        _errorMessage = 'Incorrect old PIN. Please try again.';
        _oldPin = '';
        for (final controller in _pinControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      });
    }
  }

  Future<void> _verifyPin() async {
    if (widget.isSetup || widget.isChangePin) {
      // Compare first PIN with confirm PIN
      if (_firstPin == _confirmPin) {
        await VaultManager.setPin(_confirmPin);
        if (mounted) {
          Navigator.pop(context, true);
          widget.onSuccess?.call();
        }
      } else {
        setState(() {
          _errorMessage = 'PINs do not match. Please try again.';
          _firstPin = '';
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
          for (final controller in _pinControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    } else {
      final isValid = await VaultManager.verifyPin(_pin);
      if (isValid) {
        if (mounted) {
          Navigator.pop(context, true);
          widget.onSuccess?.call();
        }
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _pin = '';
          for (final controller in _pinControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  Future<void> _tryBiometric() async {
    final authenticated = await VaultManager.authenticate();
    if (authenticated && mounted) {
      Navigator.pop(context, true);
      widget.onSuccess?.call();
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Biometric authentication failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String title;
    if (widget.isChangePin) {
      if (_isVerifyingOldPin) {
        title = 'Enter Old PIN';
      } else {
        title = _isConfirming ? 'Confirm New PIN' : 'Enter New PIN';
      }
    } else {
      title = widget.isSetup
          ? (_isConfirming ? 'Confirm PIN' : 'Set PIN')
          : 'Enter PIN';
    }

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: TextStyle(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              4,
              (index) => Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: TextField(
                  controller: _pinControllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  obscureText: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) => _onPinChanged(index, value),
                ),
              ),
            ),
          ),
          if (!widget.isSetup) ...[
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: VaultManager.isBiometricAvailable(),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return OutlinedButton.icon(
                    onPressed: _tryBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Use Biometric'),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
