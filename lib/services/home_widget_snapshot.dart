import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../models/couple.dart';

/// What the home-screen widget shows, pre-translated (feature home-widget, D4).
///
/// Flutter owns the words, native owns the numbers: the iOS extension
/// (`ios/DearEmbeiuWidget/WidgetSnapshot.swift`) and the Android provider
/// (`android/.../widget/DayCounterWidget.kt`) recompute the day count and the
/// next milestone every day from `anniversary`, then fill `{count}` /
/// `{label}` in these templates. Renaming a key means renaming it in all
/// three places.
abstract final class HomeWidgetSnapshot {
  /// Chip text of the empty state — the brand name, never translated.
  static const String emptyChip = 'DEAR EMBEIU';

  static Map<String, String> build({
    required Couple? couple,
    required AppLocalizations l10n,
  }) {
    final lang = l10n.localeName.startsWith('vi') ? 'vi' : 'en';
    if (couple == null) {
      return {
        'state': 'empty',
        'lang': lang,
        'emptyChip': emptyChip,
        'emptyText': l10n.widgetEmptyTap,
      };
    }
    final a = couple.anniversaryDate;
    final since = DateFormat(l10n.fullDateFormat, l10n.localeName).format(a);
    return {
      'state': 'counter',
      'lang': lang,
      'anniversary': _isoDate(a),
      'name1': couple.person1Name.trim(),
      'name2': couple.person2Name.trim(),
      'daysLabel': _lowerFirst(l10n.daysTogether),
      'milestoneFmt': l10n.milestoneNextLabel('{label}'),
      'daysLeftOne': l10n.milestoneDaysLeft(1),
      'daysLeftFmt': _countTemplate(l10n.milestoneDaysLeft),
      'todayLabel': l10n.milestoneTodayLabel,
      'monthsOne': l10n.milestoneMonthsOne(1),
      'monthsFmt': _countTemplate(l10n.milestoneMonthsMany),
      'yearsOne': l10n.milestoneYearsOne(1),
      'yearsFmt': _countTemplate(l10n.milestoneYearsMany),
      'daysFmt': _countTemplate(l10n.milestoneDaysLabel),
      'sinceText': l10n.guestCounterStartFrom(since),
    };
  }

  /// Date only — the count is calendar days, like LoveTreeService.daysTogether.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  /// ICU plurals only take an int, so render with 0 and swap it for `{count}`
  /// — native fills the real number (grouped per `lang`) at render time. The
  /// generated code interpolates `$count` verbatim, so "0" is the only digit.
  static String _countTemplate(String Function(int) render) =>
      render(0).replaceFirst('0', '{count}');
}
