// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Calculator';

  @override
  String get display => 'Display';

  @override
  String get clear => 'C';

  @override
  String get allClear => 'AC';

  @override
  String get basicMode => 'Basic';

  @override
  String get scientificMode => 'Scientific';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get language => 'Language';

  @override
  String get noHistory => 'No calculation history';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get error => 'Error';

  @override
  String get undo => 'Undo';

  @override
  String get redo => 'Redo';
}
