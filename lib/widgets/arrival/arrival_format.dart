import 'package:flutter/widgets.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../models/arrival.dart';
import '../../models/couple.dart';

/// Shared wording for feature arrival (design §3.2, §4.2, §8, §15) — the Home
/// card, the manage screen and Settings print the same sentences.
abstract final class ArrivalFormat {
  /// Icon key → Iconsax (design §4.2). Home is always `home_2`.
  static IconData icon(ArrivalIcon? key, {bool home = false}) {
    if (home) return IconsaxPlusLinear.home_2;
    return switch (key ?? ArrivalIcon.pin) {
      ArrivalIcon.work => IconsaxPlusLinear.briefcase,
      ArrivalIcon.school => IconsaxPlusLinear.teacher,
      ArrivalIcon.family => IconsaxPlusLinear.people,
      ArrivalIcon.gym => IconsaxPlusLinear.weight_1,
      ArrivalIcon.cafe => IconsaxPlusLinear.coffee,
      ArrivalIcon.shop => IconsaxPlusLinear.shop,
      ArrivalIcon.pin => IconsaxPlusLinear.location,
    };
  }

  static IconData placeIcon(ArrivalPlace p) => icon(p.icon, home: p.isHome);

  /// Screen-reader name of an icon (radio group, design §4.1).
  static String iconLabel(AppLocalizations l10n, ArrivalIcon key) =>
      switch (key) {
        ArrivalIcon.work => l10n.arrivalIconWork,
        ArrivalIcon.school => l10n.arrivalIconSchool,
        ArrivalIcon.family => l10n.arrivalIconFamily,
        ArrivalIcon.gym => l10n.arrivalIconGym,
        ArrivalIcon.cafe => l10n.arrivalIconCafe,
        ArrivalIcon.shop => l10n.arrivalIconShop,
        ArrivalIcon.pin => l10n.arrivalIconPin,
      };

  /// "Nhà" for Home (localized, never stored), the typed name otherwise.
  static String placeName(AppLocalizations l10n, ArrivalPlace p) =>
      p.isHome ? l10n.arrivalHomeName : (p.name ?? '');

  /// "Đã về đến nhà" / "Đã đến Phòng gym" — `last.name` verbatim (D23).
  static String sentence(AppLocalizations l10n, ArrivalEvent e) {
    final enter = e.type == ArrivalEventType.enter;
    if (e.isHome) return enter ? l10n.arrivalEnterHome : l10n.arrivalExitHome;
    final name = (e.name ?? '').trim();
    return enter ? l10n.arrivalEnterPlace(name) : l10n.arrivalExitPlace(name);
  }

  /// Older than 3 calendar days → the card shows "Đang bật" instead (§15).
  static bool isStale(ArrivalEvent e, DateTime now) =>
      _days(e.at.toLocal(), now) > 3;

  /// Today `HH:mm` · yesterday `hôm qua HH:mm` · 2–3 days day+month `HH:mm`
  /// (day/month order from the locale).
  static String when(BuildContext context, DateTime at, DateTime now) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final local = at.toLocal();
    final time = DateFormat.Hm(locale).format(local);
    final days = _days(local, now);
    if (days <= 0) return time;
    if (days == 1) return l10n.arrivalYesterdayAt(time);
    return '${DateFormat.Md(locale).format(local)} $time';
  }

  /// "vừa xong" · "20 phút trước" · "3 giờ trước", then [when].
  static String ago(BuildContext context, DateTime at, DateTime now) {
    final l10n = AppLocalizations.of(context);
    final age = now.difference(at);
    if (age.inMinutes < 1) return l10n.loveNoteJustNow;
    if (age.inHours < 1) return l10n.loveNoteMinutesAgo(age.inMinutes);
    if (age.inHours < 24) return l10n.loveNoteHoursAgo(age.inHours);
    return when(context, at, now);
  }

  /// Day + month in the app's locale ("13/10" vi, "10/13" en — D3 i18n).
  static String shortDate(BuildContext context, DateTime d) =>
      DateFormat.Md(Localizations.localeOf(context).toString()).format(d);

  /// 1–2 names joined by " · ", 3+ → "Nhà và N nơi khác" (Lead Q1).
  static String places(AppLocalizations l10n, List<ArrivalPlace> list) {
    if (list.length >= 3) {
      final hasHome = list.any((p) => p.isHome);
      // "Nhà và N nơi khác" reads wrong without Home; count all then.
      return hasHome
          ? l10n.arrivalPlacesMany(list.length - 1)
          : list.map((p) => placeName(l10n, p)).join(' · ');
    }
    return list.map((p) => placeName(l10n, p)).join(' · ');
  }

  /// First line of a saved address ("54 Liễu Giai, P. Ngọc Hà").
  static String shortAddress(String address) {
    final parts = address.split(',').map((s) => s.trim()).toList();
    return parts.length <= 2 ? address : '${parts[0]}, ${parts[1]}';
  }

  static String partnerName(AppLocalizations l10n, Couple c, String? myUid) {
    final iAmCreator = myUid != null && myUid == c.createdByUserId;
    final name = (iAmCreator ? c.person2Name : c.person1Name).trim();
    return name.isNotEmpty ? name : l10n.reactionPartnerFallback;
  }

  static String myName(AppLocalizations l10n, Couple c, String? myUid) {
    final iAmCreator = myUid != null && myUid == c.createdByUserId;
    final name = (iAmCreator ? c.person1Name : c.person2Name).trim();
    return name.isNotEmpty ? name : l10n.sleepYou;
  }

  static int _days(DateTime at, DateTime now) => DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(at.year, at.month, at.day)).inDays;
}
