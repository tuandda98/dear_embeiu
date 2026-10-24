import 'package:flutter/material.dart';

import 'app_localizations.dart';

/// Non-widget access to the active [AppLocalizations].
///
/// Services, providers, models and background isolates don't carry a
/// [BuildContext], so they can't reach the localizations through
/// `AppLocalizations.of(context)`. They read localized strings through
/// [AppL10n.strings] instead.
///
/// [MyApp]'s `localeResolutionCallback` calls [setLocale] with the locale the
/// widget tree actually resolves (including when following the system locale),
/// keeping this layer in sync with what the user sees.
class AppL10n {
  AppL10n._();

  static AppLocalizations _current =
      lookupAppLocalizations(const Locale('en'));

  /// The localizations for the currently resolved locale. Defaults to English
  /// until [setLocale] runs for the first time.
  static AppLocalizations get strings => _current;

  /// Switch the active locale used by [strings].
  ///
  /// Falls back to English for any locale the app doesn't support, so this is
  /// always safe to call with whatever locale MaterialApp resolves.
  static void setLocale(Locale locale) {
    try {
      _current = lookupAppLocalizations(locale);
    } catch (_) {
      _current = lookupAppLocalizations(const Locale('en'));
    }
  }
}
