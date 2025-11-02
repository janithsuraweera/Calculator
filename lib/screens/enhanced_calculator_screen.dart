import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import 'about_screen.dart';
import '../widgets/currency_converter_dialog.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_keypad.dart';
import '../widgets/history_panel.dart';
import '../widgets/enhanced_settings_dialog.dart';
import '../widgets/handwriting_input.dart';
import '../widgets/step_by_step_view.dart';
import '../widgets/ar_camera_view.dart';
import '../widgets/unit_converter_dialog.dart';
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
        horizontal: isPortrait ? 16 : 12,
        vertical: isPortrait ? 12 : 8,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Scientific/Basic Mode Toggle
          Expanded(child: _buildModeToggleButton(context, localizations)),
          SizedBox(width: isPortrait ? 16 : 8),
          // Undo Button - Prominent
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.undo,
              label: localizations.undo,
              onPressed: _undo,
              enabled: _undoStack.isNotEmpty,
            ),
          ),
          SizedBox(width: isPortrait ? 12 : 8),
          // Redo Button - Prominent
          Expanded(
            child: _buildActionButton(
              context,
              icon: Icons.redo,
              label: localizations.redo,
              onPressed: _redo,
              enabled: _redoStack.isNotEmpty,
            ),
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

    return InkWell(
      onTap: _toggleScientificMode,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          color: _isScientificMode ? null : colorScheme.surfaceContainerHighest,
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
            const SizedBox(width: 10),
            Text(
              _isScientificMode
                  ? localizations.scientificMode
                  : localizations.basicMode,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: _isScientificMode
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
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

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: enabled
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

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
          child: Stack(
            children: [
              Column(
                children: [
                  // Display
                  CalculatorDisplay(
                    expression: _expression,
                    result: _result,
                    isError: _isError,
                  ),
                  // Quick Action Bar - Scientific/Basic toggle, Undo/Redo
                  _buildQuickActionBar(context, localizations),
                  // Handwriting input overlay
                  if (_showHandwriting)
                    Container(
                      padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
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
                        padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
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
                          text: screenWidth < 360
                              ? null
                              : localizations.display,
                        ),
                        Tab(
                          icon: const Icon(Icons.history),
                          text: screenWidth < 360
                              ? null
                              : localizations.history,
                        ),
                        Tab(
                          icon: const Icon(Icons.lock),
                          text: screenWidth < 360 ? null : 'Vault',
                        ),
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
                            onUnitConverterPressed: _showUnitConverter,
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
                              if (snapshot.hasData &&
                                  snapshot.data!.isNotEmpty) {
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
            case 'step':
              setState(() {
                _showStepByStep = !_showStepByStep;
              });
              break;
            case 'currency':
              showDialog(
                context: context,
                builder: (context) => const CurrencyConverterDialog(),
              );
              break;
            case 'settings':
              _showSettings(context, localizations);
              break;
            case 'about':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
              break;
            case 'handwriting':
              setState(() {
                _showHandwriting = !_showHandwriting;
              });
              break;
            case 'ar':
              _showARMode(context);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'step',
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                const Text('Step-by-Step'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'currency',
            child: Row(
              children: [
                const Icon(Icons.currency_exchange, size: 20),
                const SizedBox(width: 8),
                const Text('Currency Converter'),
              ],
            ),
          ),
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
            value: 'handwriting',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 20),
                const SizedBox(width: 8),
                const Text('Handwriting Input'),
              ],
            ),
          ),
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
            case 'handwriting':
              setState(() {
                _showHandwriting = !_showHandwriting;
              });
              break;
            case 'ar':
              _showARMode(context);
              break;
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'handwriting',
            child: Row(
              children: [
                const Icon(Icons.edit, size: 20),
                const SizedBox(width: 8),
                const Text('Handwriting Input'),
              ],
            ),
          ),
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

  /// Show unit converter dialog
  void _showUnitConverter(String category) {
    final value = double.tryParse(
      _result == '0' || _result == 'Error' ? '' : _result,
    );
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EnhancedSettingsDialog(
        currentTheme: currentTheme,
        currentAccentColorIndex: currentAccentColorIndex,
      ),
    );

    if (result != null && mounted) {
      await ThemeManager.setThemeMode(result['theme'] as ThemeMode);
      await ThemeManager.setAccentColorIndex(result['accentColorIndex'] as int);
      // Close dialog first
      if (!mounted) return;
      Navigator.of(context).pop();
      // Force rebuild by popping and pushing to trigger MaterialApp rebuild
      // The main app's listener will detect the change within 500ms
      // But we trigger immediate rebuild here to avoid black screen
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          // The main app listener should have updated by now
          // If not, we can force a rebuild by navigating
          final route = ModalRoute.of(context);
          if (route != null && route.isCurrent) {
            // Small delay to ensure settings are saved and main app updates
            // No need to navigate - just let the listener handle it
          }
        }
      });
    }
  }
}
