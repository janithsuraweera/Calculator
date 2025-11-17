import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'about_screen.dart';
import '../widgets/currency_converter_dialog.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/history_panel.dart';
import '../widgets/enhanced_settings_dialog.dart';
// Removed handwriting input import
// Removed step-by-step view import
import '../widgets/ar_camera_view.dart';
import '../widgets/unit_converter_dialog.dart';
import '../widgets/unit_converter_menu.dart';
import '../widgets/vault_browser.dart';
import '../widgets/vault_pin_dialog.dart';
import '../widgets/notes_list_view.dart';
import '../services/calculator_engine.dart';
import '../services/screenshot_detector.dart';
import '../services/history_manager.dart';
import '../services/theme_manager.dart';
import '../services/clipboard_manager.dart';
import '../services/vault_manager.dart';
import '../services/haptic_sound_manager.dart';
import '../models/calculation_history.dart';

/// Enhanced calculator screen with all advanced features
class EnhancedCalculatorScreen extends StatefulWidget {
  const EnhancedCalculatorScreen({super.key});

  @override
  State<EnhancedCalculatorScreen> createState() =>
      _EnhancedCalculatorScreenState();
}

class _EnhancedCalculatorScreenState extends State<EnhancedCalculatorScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String _expression = '';
  String _result = '0';
  bool _isScientificMode = false;
  bool _isError = false;
  bool _isRadMode = true; // true for Radians, false for Degrees
  bool _isInvMode = false; // Inverse function mode
  String? _lastAnswer; // Store last answer for Ans button
  // Removed handwriting overlay state
  // Removed step-by-step toggle state

  // Undo/Redo stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  List<CalculationHistory> _history = [];
  int _selectedTabIndex = 0;
  late TabController _tabController;
  bool _vaultEnabled = false;

  // Gesture detection
  double _lastSwipeX = 0;
  double _lastSwipeY = 0;

  // Key for CalculatorKeypad to force reload when custom buttons change
  Key _keypadKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // Start with 3 tabs (Display, History, Notes). Vault will be added if enabled.
    // On app start, vault is always hidden (auto-hide on app close).
    // User can enable it from settings.
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadHistory();
    _checkClipboard();
    // Ensure vault is hidden on app start
    VaultManager.setVaultEnabled(false);
    _loadVaultFlag();
    // Initialize screenshot detector
    ScreenshotDetector.initialize(context);
    // Add lifecycle observer to auto-hide vault when app closes
    WidgetsBinding.instance.addObserver(this);
  }

  // Removed didChangeDependencies - it was causing unnecessary reloads
  // Vault flag will reload when settings dialog closes via callback

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Auto-hide vault when app goes to background or is closed
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _autoHideVault();
    }
  }

  /// Auto-hide vault when app is closed or goes to background
  Future<void> _autoHideVault() async {
    // Always hide vault when app goes to background or closes
    await VaultManager.setVaultEnabled(false);
    if (mounted && _vaultEnabled) {
      setState(() {
        _vaultEnabled = false;
        // Update tab controller to remove vault tab
        final newLen = 3; // Display, History, Notes
        if (_tabController.length != newLen) {
          final oldIndex = _selectedTabIndex.clamp(0, newLen - 1);
          _tabController.dispose();
          _tabController = TabController(
            length: newLen,
            vsync: this,
            initialIndex: oldIndex,
          );
          _tabController.addListener(() {
            setState(() {
              _selectedTabIndex = _tabController.index;
            });
          });
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    // Reset orientation lock when disposing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  /// Check clipboard for expressions
  Future<void> _checkClipboard() async {
    final result = await ClipboardManager.checkAndCalculate();
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Clipboard: $result'),
          action: SnackBarAction(
            label: 'Use',
            onPressed: () {
              setState(() {
                _expression = result;
                _evaluateExpression();
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _loadVaultFlag() async {
    // Load vault state - on app start it will be false (auto-hide on close)
    // But if user enables from settings, it will be true
    final enabled = await VaultManager.isVaultEnabled();
    if (!mounted) return;
    setState(() {
      _vaultEnabled = enabled;
      final newLen = _vaultEnabled
          ? 4
          : 3; // Display, History, Notes, Vault (if enabled)
      if (_tabController.length != newLen) {
        final oldIndex = _selectedTabIndex.clamp(0, newLen - 1);
        _tabController.dispose();
        _tabController = TabController(
          length: newLen,
          vsync: this,
          initialIndex: oldIndex,
        );
        _tabController.addListener(() {
          setState(() {
            _selectedTabIndex = _tabController.index;
          });
        });
      }
    });
  }

  /// Load calculation history
  Future<void> _loadHistory() async {
    final history = await HistoryManager.getHistoryAsync();
    setState(() {
      _history = history;
    });
  }

  /// Save state for undo/redo
  void _saveState() {
    _undoStack.add(_expression);
    _redoStack.clear();
  }

  /// Undo last action
  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_expression);
      setState(() {
        _expression = _undoStack.removeLast();
        _result = '0';
        _isError = false;
      });
      HapticSoundManager.triggerHaptic();
    }
  }

  /// Redo last undone action
  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_expression);
      setState(() {
        _expression = _redoStack.removeLast();
        _result = '0';
        _isError = false;
      });
      HapticSoundManager.triggerHaptic();
    }
  }

  /// Handle gesture swipe start
  void _handleSwipeStart(DragStartDetails details) {
    _lastSwipeX = details.localPosition.dx;
    _lastSwipeY = details.localPosition.dy;
  }

  /// Handle gesture swipe update
  void _handleSwipeUpdate(DragUpdateDetails details) {
    _lastSwipeX = details.localPosition.dx;
    _lastSwipeY = details.localPosition.dy;
  }

  /// Handle gesture swipe end
  void _handleSwipeEnd(DragEndDetails details) {
    final deltaX = _lastSwipeX;
    final deltaY = _lastSwipeY;

    // Swipe right - redo (simplified detection)
    if (deltaX > 200) {
      _redo();
    }
    // Swipe left - undo
    else if (deltaX < 50) {
      _undo();
    }
    // Swipe down - clear
    else if (deltaY > 200) {
      setState(() {
        _saveState();
        _expression = '';
        _result = '0';
      });
      HapticSoundManager.triggerHaptic();
    }
  }

  /// Handle button press
  Future<void> _onButtonPressed(String button) async {
    // Play sound if enabled
    await HapticSoundManager.playClickSound();
    await HapticSoundManager.triggerHaptic();

    String? originalExpression;
    String? calcResult;

    setState(() {
      _isError = false;

      switch (button) {
        case 'AC':
          _saveState();
          _expression = '';
          _result = '0';
          break;

        case 'C':
          _saveState();
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            if (_expression.isEmpty) {
              _result = '0';
            } else {
              _evaluateExpression();
            }
          } else {
            _result = '0';
          }
          break;

        case 'BACKSPACE':
          _saveState();
          if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
            if (_expression.isEmpty) {
              _result = '0';
            } else {
              _evaluateExpression();
            }
          }
          break;

        case '=':
          if (_expression.isNotEmpty) {
            _saveState();
            originalExpression = _expression;
            final evalResult = CalculatorEngine.evaluate(
              _expression,
              isRadMode: _isRadMode,
            );
            if (evalResult != null) {
              calcResult = evalResult;
              _result = calcResult!;
              _lastAnswer = calcResult; // Store for Ans button
              _expression = calcResult!;
            } else {
              _result = 'Error';
              _isError = true;
            }
          }
          break;

        case 'RAD':
          setState(() {
            _isRadMode = true;
          });
          break;

        case 'DEG':
          setState(() {
            _isRadMode = false;
          });
          break;

        case 'INV':
          setState(() {
            _isInvMode = !_isInvMode;
          });
          break;

        case 'ANS':
          if (_lastAnswer != null) {
            _expression += _lastAnswer!;
            _evaluateExpression();
          }
          break;

        case 'π':
          _expression += 'π';
          _evaluateExpression();
          break;

        case 'e':
          _expression += 'e';
          _evaluateExpression();
          break;

        case 'EXP':
          _expression += 'E';
          _evaluateExpression();
          break;

        case 'sin(':
          if (_isInvMode) {
            _expression += 'arcsin(';
          } else {
            _expression += 'sin(';
          }
          _evaluateExpression();
          break;

        case 'cos(':
          if (_isInvMode) {
            _expression += 'arccos(';
          } else {
            _expression += 'cos(';
          }
          _evaluateExpression();
          break;

        case 'tan(':
          if (_isInvMode) {
            _expression += 'arctan(';
          } else {
            _expression += 'tan(';
          }
          _evaluateExpression();
          break;

        case 'ln(':
        case 'log(':
        case 'sqrt(':
        case 'exp(':
          _saveState();
          final funcName = button.replaceAll('(', '');
          _expression += '$funcName(';
          break;

        case '^2':
          _saveState();
          if (_expression.isNotEmpty) {
            try {
              final regex = RegExp(r'(\d+\.?\d*)$');
              final match = regex.firstMatch(_expression);
              if (match != null) {
                final numStr = match.group(1)!;
                final num = double.parse(numStr);
                final squared = (num * num).toString();
                _expression =
                    _expression.substring(
                      0,
                      _expression.length - numStr.length,
                    ) +
                    squared;
              } else {
                _expression += '^2';
              }
            } catch (e) {
              _expression += '^2';
            }
          }
          break;

        case '^':
          _saveState();
          _expression += '^';
          break;

        case '!':
          _saveState();
          if (_expression.isNotEmpty) {
            try {
              final regex = RegExp(r'(\d+\.?\d*)$');
              final match = regex.firstMatch(_expression);
              if (match != null) {
                final numStr = match.group(1)!;
                final factResult = CalculatorEngine.evaluateScientific(
                  'factorial',
                  numStr,
                  isRadMode: _isRadMode,
                );
                if (factResult != null) {
                  _expression =
                      _expression.substring(
                        0,
                        _expression.length - numStr.length,
                      ) +
                      factResult;
                }
              }
            } catch (e) {
              // Error handling
            }
          }
          break;

        case '%':
          _saveState();
          if (_expression.isNotEmpty) {
            _expression += '/100';
            _evaluateExpression();
          }
          break;

        default:
          _saveState();
          // Handle operators specially
          if (_isOperator(button)) {
            // If expression is empty, only allow minus for negative numbers
            if (_expression.isEmpty) {
              if (button == '−' || button == '-') {
                _expression = button;
              }
            }
            // If expression ends with an operator
            else if (_endsWithOperator(_expression)) {
              final lastChar = _expression[_expression.length - 1];
              // If same operator is pressed, don't add another (do nothing)
              if (lastChar == button ||
                  (lastChar == '−' && button == '-') ||
                  (lastChar == '-' && button == '−')) {
                // Do nothing, keep expression as is
              } else {
                // Different operator - replace it
                _expression =
                    _expression.substring(0, _expression.length - 1) + button;
              }
            }
            // If expression is just a number (result from =), use that number with operator
            else {
              _expression += button;
            }
          } else {
            // For numbers and other characters, just append
            _expression += button;
          }
          _evaluateExpression();
          break;
      }
    });

    // Save to history and vault after state update
    if (originalExpression != null && calcResult != null) {
      await HistoryManager.saveCalculation(originalExpression!, calcResult!);
      final vaultEnabled = await VaultManager.isVaultEnabled();
      if (vaultEnabled) {
        await VaultManager.saveToVault(originalExpression!, calcResult!);
      }
      _loadHistory();
    }
  }

  /// Evaluate expression and update result
  void _evaluateExpression() {
    if (_expression.isEmpty) {
      _result = '0';
      return;
    }

    // If expression ends with operator, show last valid result
    if (_endsWithOperator(_expression)) {
      // Try to evaluate without the trailing operator
      final exprWithoutOp = _expression.substring(0, _expression.length - 1);
      if (exprWithoutOp.isNotEmpty) {
        final evalResult = CalculatorEngine.evaluate(
          exprWithoutOp,
          isRadMode: _isRadMode,
        );
        if (evalResult != null) {
          _result = evalResult;
          _isError = false;
          return;
        }
      }
      // If can't evaluate, keep showing current result
      return;
    }

    final evalResult = CalculatorEngine.evaluate(
      _expression,
      isRadMode: _isRadMode,
    );
    if (evalResult != null) {
      _result = evalResult;
      _isError = false;
    } else {
      // Don't show error, keep last valid result if available
      if (_result == '0' || _result == 'Error') {
        _result = '0';
      }
    }
  }

  /// Check if a button is an operator
  bool _isOperator(String value) {
    const operators = ['+', '−', '×', '÷', '^', '-'];
    return operators.contains(value);
  }

  /// Check if expression ends with an operator
  bool _endsWithOperator(String value) {
    if (value.isEmpty) return false;
    final last = value[value.length - 1];
    return _isOperator(last);
  }

  /// Handle history item tap
  void _onHistoryItemTap(CalculationHistory item) {
    setState(() {
      _saveState();
      _expression = item.expression;
      _result = item.result;
      _isError = false;
    });
    setState(() {
      _selectedTabIndex = 0;
    });
  }

  /// Clear history
  Future<void> _clearHistory() async {
    await HistoryManager.clearHistory();
    setState(() {
      _history = [];
    });
  }

  Future<void> _onHistoryLabelEdit(
    CalculationHistory item,
    String? label,
  ) async {
    await HistoryManager.updateHistoryLabel(item.timestamp, label);
    await _loadHistory();
  }

  /// Toggle scientific mode
  void _toggleScientificMode() {
    setState(() {
      _isScientificMode = !_isScientificMode;
      // Auto-rotate to landscape when scientific mode is enabled
      if (_isScientificMode) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        // Lock to portrait when basic mode
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
    HapticSoundManager.triggerHaptic();
  }

  /// Build quick action bar with Scientific/Basic toggle and Undo/Redo buttons
  Widget _buildQuickActionBar(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final isPortrait = mediaQuery.orientation == Orientation.portrait;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPortrait ? 14 : 10,
        vertical: isPortrait ? 8 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.5),
            colorScheme.surfaceContainerHighest,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.4),
            width: 2.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildModeToggleButton(context, localizations),
          SizedBox(width: isPortrait ? 8 : 6),
          // Unit converter quick button
          _buildActionButton(
            context,
            icon: Icons.swap_horiz,
            label: 'Units',
            onPressed: () => showUnitConverterMenu(context, _showUnitConverter),
            enabled: true,
          ),
          SizedBox(width: isPortrait ? 8 : 6),
          _buildActionButton(
            context,
            icon: Icons.currency_exchange,
            label: 'Currency',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const CurrencyConverterDialog(),
              );
            },
            enabled: true,
          ),
          if (_vaultEnabled) ...[
            SizedBox(width: isPortrait ? 8 : 6),
            _buildActionButton(
              context,
              icon: Icons.lock,
              label: 'Vault',
              onPressed: () async {
                // Authenticate before opening vault
                final authenticated = await _authenticateVault();
                if (authenticated && mounted) {
                  setState(() {
                    // Jump to last tab (vault)
                    _selectedTabIndex = (_tabController.length - 1).clamp(
                      0,
                      _tabController.length - 1,
                    );
                  });
                }
              },
              enabled: true,
            ),
          ],
          // SizedBox(width: isPortrait ? 10 : 6),
          // // Step-by-step toggle quick button
          // _buildActionButton(
          //   context,
          //   icon: Icons.info_outline,
          //   label: 'Steps',
          //   onPressed: () {
          //     setState(() {
          //       _showStepByStep = !_showStepByStep;
          //     });
          //   },
          //   enabled: _expression.isNotEmpty,
          // ),
          // SizedBox(width: isPortrait ? 10 : 6),
          // // Handwriting input quick toggle
          // _buildActionButton(
          //   context,
          //   icon: Icons.edit,
          //   label: 'Write',
          //   onPressed: () {
          //     setState(() {
          //       _showHandwriting = !_showHandwriting;
          //     });
          //   },
          //   enabled: true,
          // ),
          SizedBox(width: isPortrait ? 8 : 6),
          _buildActionButton(
            context,
            icon: Icons.undo,
            label: localizations.undo,
            onPressed: _undo,
            enabled: _undoStack.isNotEmpty,
          ),
          SizedBox(width: isPortrait ? 8 : 6),
          _buildActionButton(
            context,
            icon: Icons.redo,
            label: localizations.redo,
            onPressed: _redo,
            enabled: _redoStack.isNotEmpty,
          ),
        ],
      ),
    );
  }

  /// Build mode toggle button
  Widget _buildModeToggleButton(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final bool compact = mediaQuery.size.width < 380;

    return Expanded(
      child: InkWell(
        onTap: _toggleScientificMode,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: compact ? 8 : 10,
          ),
          decoration: BoxDecoration(
            gradient: _isScientificMode
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: _isScientificMode
                ? null
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isScientificMode
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: _isScientificMode ? 2.5 : 1.5,
            ),
            boxShadow: _isScientificMode
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isScientificMode ? Icons.science : Icons.calculate,
                color: _isScientificMode
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                size: 22,
              ),
              // Text label hidden: icon-only quick action
            ],
          ),
        ),
      ),
    );
  }

  /// Build action button (Undo/Redo) - Enhanced for better visibility
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.secondaryContainer,
                      colorScheme.secondaryContainer.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            color: enabled
                ? null
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: enabled
                  ? colorScheme.secondary.withValues(alpha: 0.6)
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: enabled ? 2 : 1,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: colorScheme.secondary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.3),
                size: 22,
              ),
              // Text label hidden: icon-only quick action
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    // Desired tabs for current state
    final List<Tab> tabs = [
      Tab(
        icon: const Icon(Icons.calculate),
        text: screenWidth < 360 ? null : localizations.display,
      ),
      Tab(
        icon: const Icon(Icons.history),
        text: screenWidth < 360 ? null : localizations.history,
      ),
      Tab(
        icon: const Icon(Icons.note),
        text: screenWidth < 360 ? null : 'Notes',
      ),
      if (_vaultEnabled)
        Tab(
          icon: const Icon(Icons.lock),
          text: screenWidth < 360 ? null : 'Vault',
        ),
    ];
    // Until async flag updates controller length, only show as many tabs
    // as the controller currently manages to avoid mismatch.
    final int effectiveLen = _tabController.length.clamp(1, tabs.length);
    final List<Tab> displayedTabs = tabs.sublist(0, effectiveLen);
    final int clampedIndex = _selectedTabIndex.clamp(0, effectiveLen - 1);
    if (clampedIndex != _selectedTabIndex) {
      // Keep index in range without recreating the controller in build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedTabIndex = clampedIndex;
        });
      });
    }

    return GestureDetector(
      onPanStart: _handleSwipeStart,
      onPanUpdate: _handleSwipeUpdate,
      onPanEnd: _handleSwipeEnd,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SMARTCALC'),
          // Hide some actions on smaller screens to save space
          actions: screenWidth < 600
              ? _buildCompactAppBarActions(context, localizations)
              : _buildFullAppBarActions(context, localizations),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Display
              CalculatorDisplay(
                expression: _expression,
                result: _result,
                isError: _isError,
              ),
              // Quick Action Bar - Scientific/Basic toggle, Undo/Redo
              _buildQuickActionBar(context, localizations),
              // Handwriting input overlay removed
              // Tabs
              TabBar(controller: _tabController, tabs: displayedTabs),
              // Tab content
              Expanded(
                child: IndexedStack(
                  index: _selectedTabIndex,
                  children: [
                    // Calculator tab
                    CalculatorKeypad(
                      key: _keypadKey,
                      isScientificMode: _isScientificMode,
                      onButtonPressed: _onButtonPressed,
                    ),
                    // History tab
                    HistoryPanel(
                      history: _history,
                      onHistoryItemTap: _onHistoryItemTap,
                      onClearHistory: _clearHistory,
                      onLabelEdit: _onHistoryLabelEdit,
                    ),
                    // Notes tab
                    const NotesListView(),
                    // Vault tab (if enabled)
                    if (_vaultEnabled) const VaultBrowser(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build compact app bar actions for smaller screens
  List<Widget> _buildCompactAppBarActions(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return [
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: 'More',
        onSelected: (value) {
          switch (value) {
            case 'settings':
              _showSettings(context, localizations);
              break;
            case 'about':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
              break;
            case 'ar':
              _showARMode(context);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                Text(localizations.settings),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'about',
            child: Row(
              children: [
                const Icon(Icons.info, size: 20),
                const SizedBox(width: 8),
                const Text('About & Help'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'ar',
            child: Row(
              children: [
                const Icon(Icons.camera_alt, size: 20),
                const SizedBox(width: 8),
                const Text('AR Mode'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Build full app bar actions for larger screens - Only essential features
  List<Widget> _buildFullAppBarActions(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return [
      // Currency Converter
      IconButton(
        icon: const Icon(Icons.currency_exchange),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CurrencyConverterDialog(),
          );
        },
        tooltip: 'Currency Converter',
      ),
      // Settings
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () => _showSettings(context, localizations),
        tooltip: localizations.settings,
      ),
      // About & Help
      IconButton(
        icon: const Icon(Icons.info),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        },
        tooltip: 'About & Help',
      ),
      // More options menu
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        tooltip: 'More Options',
        onSelected: (value) {
          switch (value) {
            case 'ar':
              _showARMode(context);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'ar',
            child: Row(
              children: [
                const Icon(Icons.camera_alt, size: 20),
                const SizedBox(width: 8),
                const Text('AR Mode'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  /// Show AR mode
  Future<void> _showARMode(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARCameraView(onExpressionRecognized: (expr) {}),
      ),
    );
    if (result != null && result is String && mounted) {
      setState(() {
        _expression = result;
        _evaluateExpression();
      });
    }
  }

  /// Authenticate vault access
  Future<bool> _authenticateVault() async {
    final hasPin = await VaultManager.hasPin();
    if (!hasPin) {
      // First time setup - show PIN setup dialog
      if (!mounted) return false;
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => const VaultPinDialog(isSetup: true),
      );
      if (!mounted) return false;
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
        if (!mounted) return false;
        if (useBiometric == true) {
          final isAvailable = await VaultManager.isBiometricAvailable();
          if (isAvailable) {
            await VaultManager.setUseBiometric(true);
          }
        }
        return true;
      }
      return false;
    }

    // Authenticate with PIN or biometric
    if (!mounted) return false;
    final authenticated = await showDialog<bool>(
      context: context,
      builder: (context) => const VaultPinDialog(isSetup: false),
    );
    return authenticated ?? false;
  }

  /// Show unit converter dialog
  void _showUnitConverter(String category) {
    final value = double.tryParse(
      _result == '0' || _result == 'Error' ? '' : _result,
    );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) =>
          UnitConverterDialog(category: category, initialValue: value),
    );
  }

  /// Show settings dialog
  Future<void> _showSettings(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    if (!mounted) return;

    final currentTheme = Theme.of(context).brightness == Brightness.dark
        ? ThemeMode.dark
        : ThemeMode.light;
    final currentAccentColorIndex = await ThemeManager.getAccentColorIndex();

    if (!mounted) return;
    // Load vault flag before showing settings
    await _loadVaultFlag();
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EnhancedSettingsDialog(
        currentTheme: currentTheme,
        currentAccentColorIndex: currentAccentColorIndex,
      ),
    );

    if (result != null && mounted) {
      await ThemeManager.setThemeMode(result['theme'] as ThemeMode);
      await ThemeManager.setAccentColorIndex(result['accentColorIndex'] as int);
      // Reload vault flag if vault state changed
      if (result['vaultChanged'] == true) {
        await _loadVaultFlag();
      }
      // Reload calculator keypad to show new custom buttons
      setState(() {
        _keypadKey = UniqueKey();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    }
  }
}
