import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/analytics_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const _boxName = 'app_settings';
  static const _localeKey = 'locale';

  Locale? _locale;
  Locale? get locale => _locale;

  /// [initialLocale] is the locale already read from Hive in `main()` before
  /// the first frame (Gap D — prevents a flash of the wrong language on cold
  /// start). Pass null to follow the system language.
  LocaleProvider({Locale? initialLocale}) : _locale = initialLocale;

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final box = await Hive.openBox<String>(_boxName);
    if (locale == null) {
      await box.delete(_localeKey);
    } else {
      await box.put(_localeKey, locale.languageCode);
    }
    notifyListeners();

    // Analytics — Gap G (`language_changed`) + the app_locale user property.
    final code = locale == null ? 'system' : locale.languageCode;
    AnalyticsService.instance
      ..logLanguageChanged(code)
      ..setAppLocale(code);
  }

  Future<void> useSystemLocale() => setLocale(null);
}
