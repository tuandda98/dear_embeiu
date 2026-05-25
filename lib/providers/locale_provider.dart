import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocaleProvider extends ChangeNotifier {
  static const _boxName = 'app_settings';
  static const _localeKey = 'locale';

  Locale? _locale;
  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final box = await Hive.openBox<String>(_boxName);
    final saved = box.get(_localeKey);
    if (saved != null && saved.isNotEmpty) {
      _locale = Locale(saved);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final box = await Hive.openBox<String>(_boxName);
    if (locale == null) {
      await box.delete(_localeKey);
    } else {
      await box.put(_localeKey, locale.languageCode);
    }
    notifyListeners();
  }

  Future<void> useSystemLocale() => setLocale(null);
}
