import 'package:flutter/painting.dart';

/// Per-person colour (feature sleep, 2026-10-10 — design.md "Màu riêng của mỗi
/// người"). Each member picks ONE colour that marks *their* data wherever it
/// sits next to their partner's (sleep moons, lanes, stats). Only the id is
/// persisted (`couples/{c}/sleep/{uid}.color`), never the hex, so a hex can be
/// retuned later without a migration.
///
/// All 8 are ≥ 3:1 on white (validated with `validate_palette.js`). To add a
/// colour: re-run the validator for every new pair and update [_blocked].
class PersonColor {
  const PersonColor(this.id, this.color);

  final String id;
  final Color color;
}

class PersonPalette {
  const PersonPalette._();

  static const List<PersonColor> colors = [
    PersonColor('rose', Color(0xFFFF4D6D)),
    PersonColor('purple', Color(0xFF7C5CD6)),
    PersonColor('blue', Color(0xFF1C7ED6)),
    PersonColor('teal', Color(0xFF0E9384)),
    PersonColor('orange', Color(0xFFE8590C)),
    PersonColor('green', Color(0xFF2F9E44)),
    PersonColor('magenta', Color(0xFFC2255C)),
    PersonColor('amber', Color(0xFFB7791F)),
  ];

  static List<String> get ids => [for (final c in colors) c.id];

  /// Pairs too close to tell apart (ΔE OKLab×100 < 15 for normal vision or
  /// < 6 for deuteranopia) — symmetric. Only two colours ever show together,
  /// so checking pairs is enough.
  static const Map<String, List<String>> _blocked = {
    'rose': ['orange', 'magenta'],
    'orange': ['rose', 'amber'],
    'magenta': ['rose'],
    'purple': ['blue'],
    'blue': ['purple'],
    'teal': ['green'],
    'green': ['teal', 'amber'],
    'amber': ['orange', 'green'],
  };

  static bool isValid(String? id) => id != null && _blocked.containsKey(id);

  static Color colorOf(String id) {
    for (final c in colors) {
      if (c.id == id) {
        return c.color;
      }
    }
    return colors.first.color;
  }

  /// Too similar to [other] (or the same colour).
  static bool clashes(String a, String b) =>
      a == b || (_blocked[a]?.contains(b) ?? false);

  /// Colours locked out by the partner's [partnerId] (not counting itself).
  static List<String> blockedBy(String partnerId) =>
      _blocked[partnerId] ?? const <String>[];

  /// First colour (palette order) that doesn't clash with [other].
  static String firstFreeAgainst(String? other) {
    if (!isValid(other)) {
      return colors.first.id;
    }
    return colors.firstWhere((c) => !clashes(c.id, other!)).id;
  }

  /// Rule C1 — the colours both phones actually draw. Saved choices are never
  /// overwritten; when they clash, the member whose uid sorts AFTER shows the
  /// first free colour instead, so both devices agree without a write.
  static ({String mine, String partner, bool mineAdjusted}) resolve({
    required String myUid,
    required String? myChoice,
    required String partnerUid,
    required String? partnerChoice,
  }) {
    final partner = isValid(partnerChoice)
        ? partnerChoice!
        : firstFreeAgainst(myChoice);
    var mine = isValid(myChoice) ? myChoice! : firstFreeAgainst(partner);
    var adjustedPartner = partner;
    var mineAdjusted = false;
    if (clashes(mine, partner)) {
      if (myUid.compareTo(partnerUid) > 0) {
        mine = firstFreeAgainst(partner);
        mineAdjusted = true;
      } else {
        adjustedPartner = firstFreeAgainst(mine);
      }
    }
    return (mine: mine, partner: adjustedPartner, mineAdjusted: mineAdjusted);
  }

  /// The colour lifted toward white (42%) — how a person's moon reads on the
  /// night-sky calendar card.
  static Color onSky(Color c, [double alpha = 1]) =>
      Color.fromRGBO(_lift(c.r), _lift(c.g), _lift(c.b), alpha);

  static int _lift(double channel) {
    final v = (channel * 255).round();
    return (v + (255 - v) * 0.42).round();
  }
}
