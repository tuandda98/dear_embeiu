import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../l10n/app_l10n.dart';
import '../l10n/app_localizations.dart';
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
    if (locale == null) {
      // "Theo hệ thống": MaterialApp does not re-run localeResolutionCallback
      // when its locale goes back to null, so resolve here like main.dart does
      // — otherwise AppL10n (widget bridge, reminders) keeps the old language.
      final device = WidgetsBinding.instance.platformDispatcher.locale;
      final resolved = AppLocalizations.supportedLocales.firstWhere(
        (l) => l.languageCode == device.languageCode,
        orElse: () => AppLocalizations.supportedLocales.first,
      );
      AppL10n.setLocale(resolved);
      Intl.defaultLocale = resolved.languageCode;
    }
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
