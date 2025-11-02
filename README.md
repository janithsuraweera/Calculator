# Calculator - ගණකය

Modern Material Design calculator app built with Flutter.

**Author:** Janith Suraweera

## Features (විශේෂාංග)

### Basic Operations (මූලික ක්‍රියාකාරකම්)
- ✅ Addition (+), Subtraction (−), Multiplication (×), Division (÷)
- ✅ Parentheses support
- ✅ Operator precedence
- ✅ Decimal number support
- ✅ Infix expression evaluation

### Scientific Functions (විද්‍යාත්මක Functions)
- ✅ Trigonometric: sin, cos, tan
- ✅ Logarithms: log (base 10), ln (natural log)
- ✅ Power functions: x², xʸ
- ✅ Square root (√)
- ✅ Exponential (eˣ)
- ✅ Factorial (!)

### Additional Features (අමතර විශේෂාංග)
- ✅ Calculation history with persistent storage
- ✅ Undo/Redo functionality
- ✅ Basic and Scientific modes
- ✅ Light and Dark themes
- ✅ Customizable accent colors (10 colors)
- ✅ Sinhala localization with English fallback
- ✅ Haptic feedback on button presses
- ✅ Long-press support (e.g., backspace on C button)
- ✅ Modern Material Design 3 UI

## Installation (ස්ථාපනය)

### Prerequisites (අවශ්‍යතා)
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Steps (පියවර)
1. Clone or download this repository
2. Navigate to the project directory
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate localization files:
   ```bash
   flutter gen-l10n
   ```
5. Run the app:
   ```bash
   flutter run
   ```

## Usage (භාවිතය)

### Basic Calculator (මූලික ගණකය)
1. Use number buttons (0-9) to enter numbers
2. Use operators (+, −, ×, ÷) for calculations
3. Press '=' to evaluate
4. Press 'C' to clear last entry
5. Press 'AC' to clear all
6. Long-press 'C' for backspace

### Scientific Calculator (විද්‍යාත්මක ගණකය)
1. Toggle scientific mode using the icon in the app bar
2. Access scientific functions (sin, cos, tan, log, ln, sqrt, exp, factorial)
3. Use parentheses for complex expressions
4. Use power operator (^) for exponentiation

### History (ඉතිහාසය)
1. Switch to History tab to view past calculations
2. Tap any history item to reuse the result
3. Clear history using the "Clear" button

### Settings (සැකසීම්)
1. Tap the settings icon in the app bar
2. Choose between Light and Dark themes
3. Select an accent color
4. Settings are automatically saved

### Undo/Redo (අපසාරය/නැවත කරන්න)
- Use the undo button (↶) to revert last action
- Use the redo button (↷) to redo undone action

## Project Structure (ව්‍යාපෘති ව්‍යුහය)

```
lib/
├── main.dart                 # Main app entry point
├── models/
│   └── calculation_history.dart  # History data model
├── screens/
│   └── calculator_screen.dart    # Main calculator screen
├── services/
│   ├── calculator_engine.dart    # Calculation logic
│   ├── history_manager.dart       # History storage
│   └── theme_manager.dart         # Theme management
├── widgets/
│   ├── calculator_button.dart    # Button widget
│   ├── calculator_display.dart   # Display widget
│   ├── calculator_keypad.dart    # Keypad widget
│   ├── history_panel.dart         # History panel
│   └── settings_dialog.dart       # Settings dialog
└── l10n/
    ├── app_en.arb                # English translations
    └── app_si.arb                # Sinhala translations
```

## Dependencies (Dependencies)

- `flutter`: Flutter SDK
- `flutter_localizations`: Localization support
- `math_expressions`: Mathematical expression evaluation
- `shared_preferences`: Persistent storage for history and settings
- `intl`: Internationalization (included with flutter_localizations)
- `cupertino_icons`: iOS-style icons

## Localization (Localization)

The app supports two languages:
- **Sinhala (si)**: Default language
- **English (en)**: Fallback language

Localization files are located in `lib/l10n/`:
- `app_en.arb`: English translations
- `app_si.arb`: Sinhala translations

## Code Quality (කේත ගුණාත්මකභාවය)

- ✅ Null-safe code (Dart null safety)
- ✅ Modular architecture
- ✅ Well-commented code (English and Sinhala comments)
- ✅ Maintainable structure
- ✅ Material Design 3 compliance

## License (බලපත්‍රය)

This project is developed by Janith Suraweera.

## Notes (සටහන්)

- Calculations are performed using the `math_expressions` library
- History is stored locally using `shared_preferences`
- Theme preferences are persisted across app restarts
- All UI text supports both Sinhala and English
- The app follows Material Design 3 guidelines

## Troubleshooting (ගැටළු විසඳීම)

### Localization not working
- Run `flutter gen-l10n` to generate localization files
- Ensure `l10n.yaml` exists in the project root

### Dependencies not found
- Run `flutter pub get` to install dependencies
- Ensure you're using Flutter SDK 3.9.2 or higher

### Build errors
- Clean the project: `flutter clean`
- Get dependencies again: `flutter pub get`
- Rebuild: `flutter run`

---

**Made with ❤️ by Janith Suraweera**
