import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/couple.dart';
import '../../models/sleep_night.dart';

/// Shared text helpers for feature sleep (one place, so card / screen /
/// sheets all speak the same way).
class SleepFormat {
  const SleepFormat._();

  /// "7g 15p" · "45p".
  static String short(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) {
      return l10n.sleepMinutesShort(m);
    }
    return m == 0 ? l10n.sleepHoursShort(h) : l10n.sleepDurationShort(h, m);
  }

  /// "7 giờ 15 phút" (screen readers, edit total).
  static String long(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 && h > 0
        ? l10n.sleepHoursLong(h)
        : l10n.sleepDurationLong(h, m);
  }

  /// Locale month title, first letter capitalised ("Tháng 10 năm 2026").
  static String monthTitle(BuildContext context, DateTime month) {
    final text = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(month);
    return text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
  }

  static String time(BuildContext context, DateTime t) =>
      DateFormat.Hm(Localizations.localeOf(context).toString()).format(t);

  static String minuteOfDay(BuildContext context, int minute) =>
      time(context, DateTime(2000, 1, 1, minute ~/ 60, minute % 60));

  /// "23:40 – 06:55".
  static String range(BuildContext context, SleepNight n) =>
      '${time(context, n.bedAt)} – ${time(context, n.wakeAt)}';

  static String phase(AppLocalizations l10n, int phase) => switch (phase) {
    0 => l10n.sleepPhase0,
    1 => l10n.sleepPhase1,
    2 => l10n.sleepPhase2,
    3 => l10n.sleepPhase3,
    _ => l10n.sleepPhase4,
  };

  static String colorName(AppLocalizations l10n, String id) => switch (id) {
    'purple' => l10n.sleepColorPurple,
    'blue' => l10n.sleepColorBlue,
    'teal' => l10n.sleepColorTeal,
    'orange' => l10n.sleepColorOrange,
    'green' => l10n.sleepColorGreen,
    'magenta' => l10n.sleepColorMagenta,
    'amber' => l10n.sleepColorAmber,
    _ => l10n.sleepColorRose,
  };

  /// "Thức giấc 2 lần" / "Ngủ một mạch".
  static String awakenings(AppLocalizations l10n, SleepNight n) =>
      n.wakeUps.isEmpty
      ? l10n.sleepNoAwakenings
      : l10n.sleepAwakenings(n.wakeUps.length);

  /// "Đêm 9 → sáng 10/10" for the night that ended on [wakeKey].
  static String nightTitle(AppLocalizations l10n, String wakeKey) {
    final wake = sleepDateFromKey(wakeKey) ?? DateTime.now();
    final eve = DateTime(wake.year, wake.month, wake.day - 1);
    return l10n.sleepNightTitle('${eve.day}', '${wake.day}/${wake.month}');
  }

  /// The partner's display name, same rule as the mood card.
  static String partnerName(
    BuildContext context,
    Couple couple,
    String? myUid,
  ) {
    final iAmCreator = myUid != null && myUid == couple.createdByUserId;
    final name = (iAmCreator ? couple.person2Name : couple.person1Name).trim();
    return name.isNotEmpty ? name : context.l10n.reactionPartnerFallback;
  }
}
