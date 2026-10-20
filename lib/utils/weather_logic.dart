// Pure rules of the weather feature (overview §6.2–6.3, D10, D11, D16; Home C
// §15 "thẻ tự thu còn 1 hàng"). No Flutter, no Firebase, no clock reads —
// callers pass `now` and the city's UTC offset, so every branch is unit-tested
// (test/weather_logic_test.dart). Wording lives in the ARB files (D8): these
// functions return kinds + numbers, never text.

import '../data/weather_cities.dart';
import '../models/weather.dart';

// ── Sky text group (§6.3) ───────────────────────────────────────────────────

enum WeatherSky {
  clear,
  partlyCloudy,
  cloudy,
  fog,
  lightRain,
  rain,
  heavyRain,
  thunder,
  snow,

  /// A code this build doesn't know: the UI hides the sky text (temp only).
  unknown,
}

/// MET `symbol_code` → sky group. Suffixes `_day` / `_night` /
/// `_polartwilight` are dropped; `…showers` reads like the plain code.
WeatherSky weatherSkyOf(String symbol) {
  final code = symbol.split('_').first;
  if (code.contains('thunder')) {
    return WeatherSky.thunder;
  }
  if (code.contains('snow') || code.contains('sleet')) {
    return WeatherSky.snow;
  }
  final base = code.endsWith('showers')
      ? code.substring(0, code.length - 'showers'.length)
      : code;
  switch (base) {
    case 'clearsky':
    case 'fair':
      return WeatherSky.clear;
    case 'partlycloudy':
      return WeatherSky.partlyCloudy;
    case 'cloudy':
      return WeatherSky.cloudy;
    case 'fog':
      return WeatherSky.fog;
    case 'lightrain':
      return WeatherSky.lightRain;
    case 'rain':
      return WeatherSky.rain;
    case 'heavyrain':
      return WeatherSky.heavyRain;
  }
  return WeatherSky.unknown;
}

/// Night variant of the code (clear sky → moon icon).
bool weatherSymbolIsNight(String symbol) => symbol.endsWith('_night');

// ── Condition for the rest of the day (§6.2, D10) ───────────────────────────

/// D10 thresholds — client-side, changeable without a CF deploy.
const double kWeatherRainMmPerHour = 0.5;
const int kWeatherHotC = 35;
const int kWeatherColdC = 15;

final RegExp _rainSymbol = RegExp('rain|sleet|thunder');

/// "Has rain" for one hour: ≥ 0.5 mm, or a rain / shower / thunder code.
bool weatherHourIsRainy(WeatherHour h) =>
    h.rain >= kWeatherRainMmPerHour || _rainSymbol.hasMatch(h.symbol);

enum WeatherConditionKind {
  rainNow,
  rainThisMorning,
  rainThisAfternoon,
  rainTonight,
  rainTomorrowMorning,
  hot,
  cold,

  /// Nothing worth a nudge: the card shows the sky text of the current hour.
  sky,
}

/// The nudge button under the partner's lane (D12) — one per condition group.
enum WeatherCta { umbrella, water, warm }

class WeatherCondition {
  const WeatherCondition({
    required this.kind,
    required this.temp,
    required this.sky,
    required this.night,
    required this.min,
    required this.max,
  });

  final WeatherConditionKind kind;

  /// Rounded °C of the current hour (D17).
  final int temp;

  /// Sky group + night flag of the current hour (icon, and the text for [sky]).
  final WeatherSky sky;
  final bool night;

  /// Low / high over the window ("Từ giờ tới khuya", design §9.3).
  final int min;
  final int max;

  bool get isRain => switch (kind) {
    WeatherConditionKind.rainNow ||
    WeatherConditionKind.rainThisMorning ||
    WeatherConditionKind.rainThisAfternoon ||
    WeatherConditionKind.rainTonight ||
    WeatherConditionKind.rainTomorrowMorning => true,
    _ => false,
  };

  WeatherCta? get cta {
    if (isRain) {
      return WeatherCta.umbrella;
    }
    return switch (kind) {
      WeatherConditionKind.hot => WeatherCta.water,
      WeatherConditionKind.cold => WeatherCta.warm,
      _ => null,
    };
  }
}

/// Wall clock of the city: [utc] shifted by [offset], read through the UTC
/// fields (`.hour`, `.day`) — no tz database needed here.
DateTime _wall(DateTime utc, Duration offset) => utc.toUtc().add(offset);

/// The condition from [now] to 23:59 on the city's clock ([offset] = the
/// city's UTC offset now); with under 3 hours left (22:00 or later) the window
/// stretches to 09:59 tomorrow. Priority: raining now > rain later > hot >
/// cold > sky. Null when no forecast hour falls in the window (cache too old).
WeatherCondition? weatherConditionFor(
  List<WeatherHour> hours,
  DateTime now,
  Duration offset,
) {
  final nowWall = _wall(now, offset);
  final midnight = DateTime.utc(nowWall.year, nowWall.month, nowWall.day + 1);
  final end = 24 - nowWall.hour < 3
      ? midnight.add(const Duration(hours: 10))
      : midnight;
  final from = now.toUtc().subtract(const Duration(hours: 1));
  final window = <WeatherHour>[
    for (final h in hours)
      if (h.t.isAfter(from) && _wall(h.t, offset).isBefore(end)) h,
  ]..sort((a, b) => a.t.compareTo(b.t));
  if (window.isEmpty) {
    return null;
  }

  final current = window.first;
  var min = current.temp.round();
  var max = min;
  for (final h in window) {
    final t = h.temp.round();
    if (t < min) min = t;
    if (t > max) max = t;
  }

  WeatherCondition make(WeatherConditionKind kind) => WeatherCondition(
    kind: kind,
    temp: current.temp.round(),
    sky: weatherSkyOf(current.symbol),
    night: weatherSymbolIsNight(current.symbol),
    min: min,
    max: max,
  );

  if (weatherHourIsRainy(current)) {
    return make(WeatherConditionKind.rainNow);
  }
  for (final h in window) {
    if (!weatherHourIsRainy(h)) {
      continue;
    }
    final at = _wall(h.t, offset);
    if (!at.isBefore(midnight)) {
      return make(WeatherConditionKind.rainTomorrowMorning);
    }
    return make(
      at.hour < 12
          ? WeatherConditionKind.rainThisMorning
          : at.hour < 18
          ? WeatherConditionKind.rainThisAfternoon
          : WeatherConditionKind.rainTonight,
    );
  }
  if (max >= kWeatherHotC) {
    return make(WeatherConditionKind.hot);
  }
  if (min <= kWeatherColdC ||
      window.any((h) => weatherSkyOf(h.symbol) == WeatherSky.snow)) {
    return make(WeatherConditionKind.cold);
  }
  return make(WeatherConditionKind.sky);
}

// ── Freshness (D16) ─────────────────────────────────────────────────────────

enum WeatherFreshness {
  /// ≤ 6 h: normal, "Cập nhật 07:12".
  fresh,

  /// 6–24 h: grey numbers, "Số liệu lúc …", no nudge button.
  stale,

  /// > 24 h or never loaded: "Chưa tải được thời tiết" + retry.
  none,
}

WeatherFreshness weatherFreshness(DateTime? fetchedAt, DateTime now) {
  if (fetchedAt == null) {
    return WeatherFreshness.none;
  }
  final age = now.difference(fetchedAt);
  if (age <= const Duration(hours: 6)) {
    return WeatherFreshness.fresh;
  }
  if (age <= const Duration(hours: 24)) {
    return WeatherFreshness.stale;
  }
  return WeatherFreshness.none;
}

// ── The card's shared row + compact rule ────────────────────────────────────

/// D11: partner − me in °C when the gap is ≥ 5°, else null. Positive = warmer
/// where the partner is.
int? weatherTempGap(int mine, int partner) {
  final d = partner - mine;
  return d.abs() >= 5 ? d : null;
}

/// One place on the card: the chosen city + what we know about it now.
class WeatherPlace {
  const WeatherPlace({
    required this.cityId,
    required this.freshness,
    this.condition,
  });

  final String cityId;
  final WeatherFreshness freshness;

  /// Null when no hour of the cached forecast covers the rest of today.
  final WeatherCondition? condition;

  /// Numbers good enough to act on (nudge, gap, compact row).
  bool get usable => freshness == WeatherFreshness.fresh && condition != null;
}

enum WeatherSharedRow { none, cta, gap }

/// What the row under the lanes holds (design §9.7, "Soát dễ dùng"): nothing
/// while waiting for the partner or on old / missing numbers; the nudge when
/// the partner's place has rain / heat / cold (even if I haven't picked a
/// city yet); else the ≥ 5° gap; else nothing (and no divider).
WeatherSharedRow weatherSharedRow({
  required bool paired,
  WeatherPlace? mine,
  WeatherPlace? partner,
}) {
  if (!paired || partner == null) {
    return WeatherSharedRow.none;
  }
  if (!partner.usable || (mine != null && !mine.usable)) {
    return WeatherSharedRow.none;
  }
  if (partner.condition!.cta != null) {
    return WeatherSharedRow.cta;
  }
  if (mine != null &&
      weatherTempGap(mine.condition!.temp, partner.condition!.temp) != null) {
    return WeatherSharedRow.gap;
  }
  return WeatherSharedRow.none;
}

/// Home C §15: the card folds into one 76 px row when there is nothing to
/// mention — every shown place picked, fresh, and only "sky" (no rain / heat
/// / cold on either side) and no ≥ 5° gap. Waiting for the partner: just my
/// place.
bool weatherCardCompact({
  required bool paired,
  WeatherPlace? mine,
  WeatherPlace? partner,
}) {
  if (mine == null || !mine.usable) {
    return false;
  }
  if (mine.condition!.kind != WeatherConditionKind.sky) {
    return false;
  }
  if (!paired) {
    return true;
  }
  if (partner == null || !partner.usable) {
    return false;
  }
  return partner.condition!.kind == WeatherConditionKind.sky &&
      weatherSharedRow(paired: true, mine: mine, partner: partner) ==
          WeatherSharedRow.none;
}

// ── City search (D4, design §9.6 + §14b) ────────────────────────────────────

WeatherCity? weatherCityById(String id) {
  for (final c in kWeatherCities) {
    if (c.id == id) {
      return c;
    }
  }
  return null;
}

const Map<String, String> _foldGroups = <String, String>{
  'a': 'àáạảãâầấậẩẫăằắặẳẵä',
  'e': 'èéẹẻẽêềếệểễë',
  'i': 'ìíịỉĩï',
  'o': 'òóọỏõôồốộổỗơờớợởỡö',
  'u': 'ùúụủũưừứựửữü',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
  'c': 'ç',
  'n': 'ñ',
};

final Map<int, String> _foldMap = <int, String>{
  for (final e in _foldGroups.entries)
    for (final r in e.value.runes) r: e.key,
};

/// "Bà Rịa–Vũng Tàu" → "ba ria vung tau": lower-case, Vietnamese tone and
/// vowel marks off (precomposed or combining), đ → d, anything else that
/// isn't a-z / 0-9 becomes one space.
String weatherFold(String input) {
  final out = StringBuffer();
  for (final r in input.toLowerCase().runes) {
    if (r >= 0x300 && r <= 0x36F) {
      continue; // combining mark (decomposed input)
    }
    final mapped = _foldMap[r];
    if (mapped != null) {
      out.write(mapped);
    } else if ((r >= 0x61 && r <= 0x7A) || (r >= 0x30 && r <= 0x39)) {
      out.writeCharCode(r);
    } else {
      out.write(' ');
    }
  }
  return out.toString().replaceAll(RegExp(' +'), ' ').trim();
}

class WeatherCityHit {
  const WeatherCityHit(this.city, [this.via]);

  final WeatherCity city;

  /// The alias that matched (a former province, "Saigon"…) — the picker shows
  /// "Tỉnh cũ: Bình Thuận". Null when the name or region matched.
  final String? via;
}

/// Picker search: unaccented, case-free, substring match on names + region,
/// then aliases; also ignores spaces so "dalat", "hanoi", "tphcm" find their
/// city. Empty query → every city, list order.
List<WeatherCityHit> searchWeatherCities(
  String query, [
  List<WeatherCity> cities = kWeatherCities,
]) {
  final key = weatherFold(query);
  if (key.isEmpty) {
    return [for (final c in cities) WeatherCityHit(c)];
  }
  final keyTight = key.replaceAll(' ', '');
  bool hit(String text) {
    if (text.isEmpty) {
      return false;
    }
    final f = weatherFold(text);
    return f.contains(key) || f.replaceAll(' ', '').contains(keyTight);
  }

  final out = <WeatherCityHit>[];
  for (final c in cities) {
    if (hit(c.nameVi) ||
        hit(c.nameEn) ||
        hit(c.shortEn) ||
        hit(c.regionVi) ||
        hit(c.regionEn)) {
      out.add(WeatherCityHit(c));
      continue;
    }
    for (final a in c.aliases) {
      if (hit(a)) {
        out.add(WeatherCityHit(c, a));
        break;
      }
    }
  }
  return out;
}
