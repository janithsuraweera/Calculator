import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/history_panel.dart';
import '../widgets/enhanced_settings_dialog.dart';
import '../widgets/handwriting_input.dart';
import '../widgets/step_by_step_view.dart';
import '../widgets/floating_calculator.dart';
import '../widgets/ar_camera_view.dart';
import '../services/calculator_engine.dart';
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
    with SingleTickerProviderStateMixin {
  String _expression = '';
  String _result = '0';
  bool _isScientificMode = false;
  bool _isError = false;
  bool _showHandwriting = false;
  bool _showStepByStep = false;
  bool _showFloating = false;

  // Undo/Redo stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  List<CalculationHistory> _history = [];
  int _selectedTabIndex = 0;
  late TabController _tabController;

  // Gesture detection
  double _lastSwipeX = 0;
  double _lastSwipeY = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadHistory();
    _checkClipboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    await HapticSoundManager.triggerHaptic();
    await HapticSoundManager.playClickSound();

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
            final evalResult = CalculatorEngine.evaluate(_expression);
            if (evalResult != null) {
              calcResult = evalResult;
              _result = calcResult!;
              _expression = calcResult!;
            } else {
              _result = 'Error';
              _isError = true;
            }
          }
          break;

        case 'sin(':
        case 'cos(':
        case 'tan(':
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
          _expression += button;
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

    final evalResult = CalculatorEngine.evaluate(_expression);
    if (evalResult != null) {
      _result = evalResult;
      _isError = false;
    } else {
      _result = '0';
    }
  }

  /// Handle history item tap
  void _onHistoryItemTap(String result) {
    setState(() {
      _saveState();
      _expression = result;
      _result = result;
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

  /// Toggle scientific mode
  void _toggleScientificMode() {
    setState(() {
      _isScientificMode = !_isScientificMode;
    });
    HapticSoundManager.triggerHaptic();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return GestureDetector(
      onPanStart: _handleSwipeStart,
      onPanUpdate: _handleSwipeUpdate,
      onPanEnd: _handleSwipeEnd,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calculator'),
          actions: [
            // Handwriting mode
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _showHandwriting = !_showHandwriting;
                });
              },
              tooltip: 'Handwriting Input',
            ),
            // Step-by-step mode
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                setState(() {
                  _showStepByStep = !_showStepByStep;
                });
              },
              tooltip: 'Step-by-Step',
            ),
            // AR mode
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ARCameraView(onExpressionRecognized: (expr) {}),
                  ),
                );
                if (result != null && result is String) {
                  setState(() {
                    _expression = result;
                    _evaluateExpression();
                  });
                }
              },
              tooltip: 'AR Mode',
            ),
            // Floating calculator
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                setState(() {
                  _showFloating = !_showFloating;
                });
              },
              tooltip: 'Floating Calculator',
            ),
            // Mode toggle
            IconButton(
              icon: Icon(_isScientificMode ? Icons.calculate : Icons.science),
              onPressed: _toggleScientificMode,
              tooltip: _isScientificMode
                  ? localizations.basicMode
                  : localizations.scientificMode,
            ),
            // Undo
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _undo,
              tooltip: localizations.undo,
            ),
            // Redo
            IconButton(
              icon: const Icon(Icons.redo),
              onPressed: _redo,
              tooltip: localizations.redo,
            ),
            // Settings
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                if (!mounted) return;

                final currentTheme =
                    Theme.of(context).brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light;
                final currentAccentColorIndex =
                    await ThemeManager.getAccentColorIndex();

                if (!mounted) return;
                final result = await showDialog<Map<String, dynamic>>(
                  // ignore: use_build_context_synchronously
                  context: context,
                  builder: (context) => EnhancedSettingsDialog(
                    currentTheme: currentTheme,
                    currentAccentColorIndex: currentAccentColorIndex,
                  ),
                );

                if (result != null && mounted) {
                  await ThemeManager.setThemeMode(result['theme'] as ThemeMode);
                  await ThemeManager.setAccentColorIndex(
                    result['accentColorIndex'] as int,
                  );
                  // Theme will be updated by the parent widget
                }
              },
              tooltip: localizations.settings,
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Display
                CalculatorDisplay(
                  expression: _expression,
                  result: _result,
                  isError: _isError,
                ),
                // Handwriting input overlay
                if (_showHandwriting)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: HandwritingInput(
                      onExpressionRecognized: (expr) {
                        setState(() {
                          _expression = expr;
                          _evaluateExpression();
                          _showHandwriting = false;
                        });
                      },
                    ),
                  ),
                // Step-by-step view
                if (_showStepByStep && _expression.isNotEmpty)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: StepByStepView(expression: _expression),
                    ),
                  ),
                // Tabs
                if (!_showStepByStep)
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.calculate),
                        text: localizations.display,
                      ),
                      Tab(
                        icon: const Icon(Icons.history),
                        text: localizations.history,
                      ),
                      Tab(icon: const Icon(Icons.lock), text: 'Vault'),
                    ],
                  ),
                // Tab content
                if (!_showStepByStep)
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTabIndex,
                      children: [
                        // Calculator tab
                        CalculatorKeypad(
                          isScientificMode: _isScientificMode,
                          onButtonPressed: _onButtonPressed,
                        ),
                        // History tab
                        HistoryPanel(
                          history: _history,
                          onHistoryItemTap: _onHistoryItemTap,
                          onClearHistory: _clearHistory,
                        ),
                        // Vault tab
                        FutureBuilder<List<CalculationHistory>>(
                          future: VaultManager.getVaultEntries(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              return HistoryPanel(
                                history: snapshot.data!,
                                onHistoryItemTap: _onHistoryItemTap,
                                onClearHistory: () async {
                                  await VaultManager.clearVault();
                                },
                              );
                            }
                            return Center(child: Text('Vault is empty'));
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Floating calculator overlay
            if (_showFloating)
              Positioned(top: 100, right: 20, child: FloatingCalculator()),
          ],
        ),
      ),
    );
  }
}
