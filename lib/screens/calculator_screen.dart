import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/history_panel.dart';
import '../widgets/enhanced_settings_dialog.dart';
import '../services/vault_manager.dart';
import '../services/calculator_engine.dart';
import '../services/history_manager.dart';
import '../services/theme_manager.dart';
import '../models/calculation_history.dart';

/// Main calculator screen
/// මූලික calculator screen එක
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  String _expression = '';
  String _result = '0';
  String _lastValidResult = '0';
  bool _isScientificMode = false;
  bool _isError = false;

  // Undo/Redo stacks
  // Undo/Redo stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  List<CalculationHistory> _history = [];
  int _selectedTabIndex = 0;
  late TabController _tabController;
  bool _vaultEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _loadHistory();
    _loadVaultFlag();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load calculation history
  /// ගණනය කිරීමේ ඉතිහාසය load කිරීම
  Future<void> _loadHistory() async {
    final history = await HistoryManager.getHistoryAsync();
    setState(() {
      _history = history;
    });
  }

  Future<void> _loadVaultFlag() async {
    final enabled = await VaultManager.isVaultEnabled();
    if (!mounted) return;
    setState(() {
      _vaultEnabled = enabled;
      final newLen = _vaultEnabled ? 3 : 2;
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

  /// Save state for undo/redo
  /// Undo/redo සඳහා state save කිරීම
  void _saveState() {
    _undoStack.add(_expression);
    _redoStack.clear(); // Clear redo stack when new action is performed
  }

  /// Undo last action
  /// අවසාන action එක undo කිරීම
  void _undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add(_expression);
      setState(() {
        _expression = _undoStack.removeLast();
        _result = '0';
        _isError = false;
      });
    }
  }

  /// Redo last undone action
  /// අවසාන undone action එක redo කිරීම
  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_expression);
      setState(() {
        _expression = _redoStack.removeLast();
        _result = '0';
        _isError = false;
      });
    }
  }

  /// Handle button press
  /// Button press handle කිරීම
  void _onButtonPressed(String button) {
    setState(() {
      _isError = false;

      switch (button) {
        case 'AC':
          // All Clear - reset everything
          // All Clear - සියල්ල reset කිරීම
          _saveState();
          _expression = '';
          _result = '0';
          _lastValidResult = '0';
          break;

        case 'C':
          // Clear last entry
          // අවසාන entry එක clear කිරීම
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
          // Backspace on long press
          // Long press කිරීමේදී backspace
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
          // Evaluate expression
          // Expression evaluate කිරීම
          if (_expression.isNotEmpty) {
            _saveState();
            final originalExpression = _expression;
            final evalResult = CalculatorEngine.evaluate(_expression);
            if (evalResult != null) {
              final calcResult = evalResult;
              _result = calcResult;
              _expression = calcResult;
              _lastValidResult = calcResult;
              // Save to history with original expression
              // Original expression සමඟ history එකට save කිරීම
              HistoryManager.saveCalculation(
                originalExpression,
                calcResult,
              ).then((_) {
                _loadHistory();
              });
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
          // Scientific functions
          // විද්‍යාත්මක functions
          _saveState();
          // Get function name without parenthesis
          // Parenthesis නැතිව function name එක ගැනීම
          final funcName = button.replaceAll('(', '');
          _expression += '$funcName(';
          break;

        case '^2':
          // Square
          // Square
          _saveState();
          if (_expression.isNotEmpty) {
            // Extract last number and square it
            // අවසාන number එක extract කර square කිරීම
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
          // Power
          // Power
          _saveState();
          _expression += '^';
          break;

        case '!':
          // Factorial
          // Factorial
          _saveState();
          if (_expression.isNotEmpty) {
            // Extract last number for factorial
            // Factorial සඳහා අවසාන number එක extract කිරීම
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
          // Percentage
          // Percentage
          _saveState();
          if (_expression.isNotEmpty) {
            _expression += '/100';
            _evaluateExpression();
          }
          break;

        default:
          // Regular buttons (numbers, operators, etc.)
          // Regular buttons (numbers, operators, etc.)
          _saveState();
          if (_isOperator(button)) {
            if (_expression.isEmpty) {
              if (button == '−') {
                _expression = button;
              }
            } else if (_endsWithOperator(_expression)) {
              _expression =
                  _expression.substring(0, _expression.length - 1) + button;
            } else {
              _expression += button;
            }
          } else {
            _expression += button;
          }
          // Auto-evaluate for real-time preview (optional)
          // Real-time preview සඳහා auto-evaluate (optional)
          // _evaluateExpression();
          break;
      }

      // Update result if expression changed
      // Expression change වුවහොත් result update කිරීම
      if (button != '=' && _expression.isNotEmpty) {
        _evaluateExpression();
      }
    });
  }

  /// Evaluate expression and update result
  /// Expression evaluate කර result update කිරීම
  void _evaluateExpression() {
    if (_expression.isEmpty) {
      _result = '0';
      _lastValidResult = '0';
      return;
    }
    if (_endsWithOperator(_expression)) {
      _result = _lastValidResult;
      return;
    }

    final evalResult = CalculatorEngine.evaluate(_expression);
    if (evalResult != null) {
      _result = evalResult;
      _lastValidResult = evalResult;
      _isError = false;
    } else {
      _result = _lastValidResult;
      // Don't show error until equals is pressed
    }
  }

  /// Handle history item tap
  /// History item tap handle කිරීම
  void _onHistoryItemTap(CalculationHistory item) {
    setState(() {
      _saveState();
      _expression = item.expression;
      _result = item.result;
      _lastValidResult = item.result;
      _isError = false;
    });
    // Switch to calculator tab
    // Calculator tab එකට switch කිරීම
    setState(() {
      _selectedTabIndex = 0;
    });
  }

  /// Clear history
  /// History clear කිරීම
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
  /// Scientific mode toggle කිරීම
  void _toggleScientificMode() {
    setState(() {
      _isScientificMode = !_isScientificMode;
    });
  }

  bool _isOperator(String value) {
    const operators = ['+', '−', '×', '÷', '^'];
    return operators.contains(value);
  }

  bool _endsWithOperator(String value) {
    if (value.isEmpty) return false;
    final last = value[value.length - 1];
    return _isOperator(last);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    // Keep controller length and tabs in sync to avoid startup mismatches
    final List<Tab> tabs = [
      Tab(icon: const Icon(Icons.calculate), text: localizations.display),
      Tab(icon: const Icon(Icons.history), text: localizations.history),
      if (_vaultEnabled) const Tab(icon: Icon(Icons.lock), text: 'Vault'),
    ];
    if (_tabController.length != tabs.length) {
      final newLen = tabs.length;
      final newIndex = _selectedTabIndex.clamp(0, newLen - 1);
      _tabController.dispose();
      _tabController = TabController(
        length: newLen,
        vsync: this,
        initialIndex: newIndex,
      );
      _tabController.addListener(() {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          // Mode toggle button
          // Mode toggle button
          IconButton(
            icon: Icon(_isScientificMode ? Icons.calculate : Icons.science),
            onPressed: _toggleScientificMode,
            tooltip: _isScientificMode
                ? localizations.basicMode
                : localizations.scientificMode,
          ),
          // Undo button
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _undo,
            tooltip: localizations.undo,
          ),
          // Redo button
          // Redo button
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redo,
            tooltip: localizations.redo,
          ),
          // Settings button
          // Settings button
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
                await _loadVaultFlag();
              }
            },
            tooltip: localizations.settings,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Display
            // Display
            CalculatorDisplay(
              expression: _expression,
              result: _result,
              isError: _isError,
            ),
            // Tabs for Calculator and History
            // Calculator සහ History tabs
            TabBar(controller: _tabController, tabs: tabs),
            // Tab content
            // Tab content
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  // Calculator tab
                  // Calculator tab
                  CalculatorKeypad(
                    isScientificMode: _isScientificMode,
                    onButtonPressed: _onButtonPressed,
                  ),
                  // History tab
                  // History tab
                  HistoryPanel(
                    history: _history,
                    onHistoryItemTap: _onHistoryItemTap,
                    onClearHistory: _clearHistory,
                    onLabelEdit: _onHistoryLabelEdit,
                    onHistoryChanged:
                        _loadHistory, // Reload history when reordered
                  ),
                  if (_vaultEnabled)
                    FutureBuilder<List<CalculationHistory>>(
                      future: VaultManager.getVaultEntries(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final data = snapshot.data ?? [];
                        if (data.isEmpty) {
                          return const Center(child: Text('Vault is empty'));
                        }
                        return HistoryPanel(
                          history: data,
                          onHistoryItemTap: _onHistoryItemTap,
                          onClearHistory: () async {
                            await VaultManager.clearVault();
                            if (mounted) setState(() {});
                          },
                          onLabelEdit: null,
                          onHistoryChanged:
                              null, // Vault doesn't need reordering
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
