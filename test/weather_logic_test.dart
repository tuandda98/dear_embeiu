import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:dear_embeiu/data/weather_cities.dart';
import 'package:dear_embeiu/models/weather.dart';
import 'package:dear_embeiu/utils/weather_logic.dart';

// Same sample day as the design mock (docs/design/weather/data.js): Tuesday
// 20/10/2026 in Vietnam (UTC+7), forecast from 08:00 today to 09:00 tomorrow.
const Duration vn = Duration(hours: 7);

/// "h" o'clock on 20/10 Vietnam time (24+ = tomorrow), as a UTC instant.
DateTime vnAt(int h, [int m = 0]) =>
    DateTime.utc(2026, 10, 20, h, m).subtract(vn);

/// 26 hours 08:00 → 09:00 tomorrow, like `series()` in data.js.
List<WeatherHour> series(
  List<num> temps, {
  List<String>? syms,
  List<num>? rains,
}) => [
  for (var i = 0; i < 26; i++)
    WeatherHour(
      t: vnAt(8 + i),
      temp: temps[i].toDouble(),
      symbol: syms?[i] ?? 'cloudy',
      rain: (rains?[i] ?? 0).toDouble(),
    ),
];

List<T> rep<T>(T v, int n) => List<T>.filled(n, v);

final hcm = series(
  [
    29,
    30,
    31,
    32,
    33,
    33,
    32,
    29,
    28,
    28,
    27,
    27,
    26,
    26,
    26,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    25,
    26,
    27,
    28,
  ],
  syms: [
    ...rep('partlycloudy_day', 6),
    'rainshowers_day',
    'rain',
    'heavyrainshowers_day',
    'lightrain',
    ...rep('cloudy', 16),
  ],
  rains: [...rep(0, 6), 1.4, 3.2, 5.1, 0.6, ...rep(0, 16)],
);
const hanoiTemps = [
  23,
  24,
  25,
  26,
  27,
  27,
  27,
  26,
  25,
  24,
  23,
  23,
  22,
  22,
  22,
  22,
  22,
  21,
  21,
  21,
  21,
  21,
  21,
  21,
  22,
  23,
];
final hanoi = series(hanoiTemps);
final daLat = series([
  17,
  18,
  19,
  20,
  21,
  21,
  20,
  19,
  18,
  17,
  17,
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  16,
  17,
  18,
], syms: rep('partlycloudy_day', 26));
final bienHoa = series([
  29,
  31,
  33,
  34,
  35,
  36,
  36,
  35,
  33,
  31,
  30,
  29,
  28,
  28,
  27,
  27,
  27,
  27,
  27,
  26,
  26,
  26,
  26,
  27,
  28,
  29,
], syms: rep('clearsky_day', 26));
final sapa = series([
  15,
  16,
  17,
  18,
  18,
  18,
  17,
  16,
  15,
  14,
  14,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  13,
  14,
  15,
], syms: rep('fog', 26));

WeatherCondition cond(List<WeatherHour> h, DateTime now) =>
    weatherConditionFor(h, now, vn)!;

WeatherPlace place(String id, List<WeatherHour> h, {DateTime? now}) =>
    WeatherPlace(
      cityId: id,
      freshness: WeatherFreshness.fresh,
      condition: weatherConditionFor(h, now ?? vnAt(8, 10), vn),
    );

void main() {
  group('condition (§6.2, D10)', () {
    final now = vnAt(8, 10);

    test('TP.HCM: rain from 14:00 → "Chiều nay mưa", umbrella', () {
      final c = cond(hcm, now);
      expect(c.kind, WeatherConditionKind.rainThisAfternoon);
      expect(c.cta, WeatherCta.umbrella);
      expect(c.temp, 29);
      expect(c.max, 33);
      expect(c.sky, WeatherSky.partlyCloudy);
    });

    test('raining in the current hour wins over everything', () {
      final c = cond(hcm, vnAt(14, 30));
      expect(c.kind, WeatherConditionKind.rainNow);
    });

    test('rain before noon → this morning; after 18:00 → tonight', () {
      final morning = [
        for (final h in hanoi)
          h.t == vnAt(10)
              ? WeatherHour(
                  t: h.t,
                  temp: h.temp,
                  symbol: 'lightrain',
                  rain: 0.6,
                )
              : h,
      ];
      expect(cond(morning, now).kind, WeatherConditionKind.rainThisMorning);
      final tonight = [
        for (final h in hanoi)
          h.t == vnAt(19)
              ? WeatherHour(t: h.t, temp: h.temp, symbol: 'cloudy', rain: 1.1)
              : h,
      ];
      expect(cond(tonight, now).kind, WeatherConditionKind.rainTonight);
    });

    test('0.4 mm with a dry code is not rain; 0.5 mm is', () {
      WeatherConditionKind at(double mm) => cond([
        for (final h in hanoi)
          h.t == vnAt(15)
              ? WeatherHour(t: h.t, temp: h.temp, symbol: 'cloudy', rain: mm)
              : h,
      ], now).kind;
      expect(at(0.4), WeatherConditionKind.sky);
      expect(at(0.5), WeatherConditionKind.rainThisAfternoon);
    });

    test('thunder / sleet codes count as rain even at 0 mm', () {
      for (final code in ['rainandthunder', 'sleetshowers_day']) {
        final h = [
          for (final x in hanoi)
            x.t == vnAt(16)
                ? WeatherHour(t: x.t, temp: x.temp, symbol: code, rain: 0)
                : x,
        ];
        expect(cond(h, now).isRain, isTrue, reason: code);
      }
    });

    test('Hà Nội dry and cloudy → sky text, no button', () {
      final c = cond(hanoi, now);
      expect(c.kind, WeatherConditionKind.sky);
      expect(c.sky, WeatherSky.cloudy);
      expect(c.cta, isNull);
      expect(c.temp, 23);
    });

    test('hot at 35° (Biên Hoà 36°) → water', () {
      final c = cond(bienHoa, now);
      expect(c.kind, WeatherConditionKind.hot);
      expect(c.max, 36);
      expect(c.cta, WeatherCta.water);
      final edge = series([
        ...rep(34.6, 1),
        ...rep(30, 25),
      ], syms: rep('fair', 26));
      expect(
        cond(edge, now).kind,
        WeatherConditionKind.hot,
        reason: '34.6 rounds to 35',
      );
      final below = series([
        ...rep(34.4, 1),
        ...rep(30, 25),
      ], syms: rep('fair', 26));
      expect(cond(below, now).kind, WeatherConditionKind.sky);
    });

    test('cold at ≤ 15° (Sa Pa 13°) → warm; Đà Lạt 16° is not cold', () {
      final c = cond(sapa, now);
      expect(c.kind, WeatherConditionKind.cold);
      expect(c.min, 13);
      expect(c.cta, WeatherCta.warm);
      expect(c.sky, WeatherSky.fog);
      final d = cond(daLat, now);
      expect(d.kind, WeatherConditionKind.sky);
      expect(d.min, 16);
    });

    test('snow makes it cold even above 15°', () {
      final h = series(
        rep(18, 26),
        syms: [...rep('cloudy', 5), 'lightsnow', ...rep('cloudy', 20)],
      );
      expect(cond(h, now).kind, WeatherConditionKind.cold);
    });

    test('rain beats hot beats cold', () {
      final hotAndRain = [
        for (final h in bienHoa)
          h.t == vnAt(17)
              ? WeatherHour(t: h.t, temp: h.temp, symbol: 'rain', rain: 2)
              : h,
      ];
      expect(
        cond(hotAndRain, now).kind,
        WeatherConditionKind.rainThisAfternoon,
      );
      final hotAndCold = series([36, ...rep(14, 25)], syms: rep('fair', 26));
      expect(cond(hotAndCold, now).kind, WeatherConditionKind.hot);
    });

    test('after 21:00 the window stretches to 09:00 tomorrow', () {
      final lateRain = [
        for (final h in hanoi)
          h.t == vnAt(31)
              ? WeatherHour(
                  t: h.t,
                  temp: h.temp,
                  symbol: 'lightrain',
                  rain: 0.8,
                )
              : h,
      ];
      expect(
        cond(lateRain, vnAt(22)).kind,
        WeatherConditionKind.rainTomorrowMorning,
      );
      expect(
        cond(lateRain, vnAt(21, 30)).kind,
        WeatherConditionKind.sky,
        reason: '21:xx still has 3 hours',
      );
      expect(cond(lateRain, vnAt(20)).kind, WeatherConditionKind.sky);
    });

    test('min / max cover only the rest of today', () {
      final c = cond(hanoi, vnAt(18));
      expect(c.max, 23);
      expect(c.min, 22);
      expect(c.temp, 23);
    });

    test('an unknown MET code hides the sky text only', () {
      final c = cond(series(hanoiTemps, syms: rep('xyzunknown', 26)), now);
      expect(c.kind, WeatherConditionKind.sky);
      expect(c.sky, WeatherSky.unknown);
    });

    test('the city clock is used, not the phone clock', () {
      // Seoul (UTC+9): 14:00 Seoul hour has rain. At 08:10 Vietnam time it is
      // 10:10 in Seoul, so the rain is "this afternoon" there.
      final seoul = [
        for (var i = 0; i < 24; i++)
          WeatherHour(
            t: DateTime.utc(2026, 10, 20, i),
            temp: 18,
            symbol: i == 5 ? 'rain' : 'cloudy',
            rain: i == 5 ? 1 : 0,
          ),
      ];
      final c = weatherConditionFor(
        seoul,
        vnAt(8, 10),
        const Duration(hours: 9),
      )!;
      expect(c.kind, WeatherConditionKind.rainThisAfternoon);
      expect(c.temp, 18);
    });

    test('a forecast that no longer covers today → null', () {
      expect(weatherConditionFor(hanoi, vnAt(40), vn), isNull);
      expect(weatherConditionFor(const [], vnAt(8), vn), isNull);
    });
  });

  test('sky groups (§6.3)', () {
    const expected = {
      'clearsky_day': WeatherSky.clear,
      'fair_night': WeatherSky.clear,
      'partlycloudy_polartwilight': WeatherSky.partlyCloudy,
      'cloudy': WeatherSky.cloudy,
      'fog': WeatherSky.fog,
      'lightrainshowers_day': WeatherSky.lightRain,
      'lightrain': WeatherSky.lightRain,
      'rainshowers_night': WeatherSky.rain,
      'heavyrain': WeatherSky.heavyRain,
      'heavyrainshowersandthunder_day': WeatherSky.thunder,
      'snowandthunder': WeatherSky.thunder,
      'lightsnow': WeatherSky.snow,
      'sleetshowers_day': WeatherSky.snow,
      'tornado': WeatherSky.unknown,
      '': WeatherSky.unknown,
    };
    expected.forEach(
      (code, sky) => expect(weatherSkyOf(code), sky, reason: code),
    );
    expect(weatherSymbolIsNight('clearsky_night'), isTrue);
    expect(weatherSymbolIsNight('clearsky_day'), isFalse);
  });

  test('freshness: ≤ 6 h / 6–24 h / > 24 h (D16)', () {
    final now = vnAt(8, 10);
    expect(
      weatherFreshness(now.subtract(const Duration(minutes: 58)), now),
      WeatherFreshness.fresh,
    );
    expect(
      weatherFreshness(now.subtract(const Duration(hours: 6)), now),
      WeatherFreshness.fresh,
    );
    expect(
      weatherFreshness(now.subtract(const Duration(minutes: 630)), now),
      WeatherFreshness.stale,
    );
    expect(
      weatherFreshness(now.subtract(const Duration(minutes: 1520)), now),
      WeatherFreshness.none,
    );
    expect(weatherFreshness(null, now), WeatherFreshness.none);
    expect(
      weatherFreshness(now.add(const Duration(minutes: 3)), now),
      WeatherFreshness.fresh,
      reason: 'clock skew',
    );
  });

  group('shared row + compact card', () {
    final me = place('vn-ha-noi', hanoi);

    test('gap: ≥ 5° only (D11)', () {
      expect(weatherTempGap(23, 29), 6);
      expect(weatherTempGap(25, 17), -8);
      expect(weatherTempGap(23, 22), isNull);
      expect(weatherTempGap(23, 27), isNull);
    });

    test('partner rain → nudge, even over a 6° gap', () {
      final p = place('vn-tp-hcm', hcm);
      expect(
        weatherSharedRow(paired: true, mine: me, partner: p),
        WeatherSharedRow.cta,
      );
      expect(weatherCardCompact(paired: true, mine: me, partner: p), isFalse);
    });

    test('plain weather, 6° apart → gap row; 1° apart → compact', () {
      final dl = place('vn-da-lat', daLat);
      expect(
        weatherSharedRow(paired: true, mine: me, partner: dl),
        WeatherSharedRow.gap,
      );
      expect(weatherCardCompact(paired: true, mine: me, partner: dl), isFalse);
      final hp = place(
        'vn-hai-phong',
        series([22, ...rep(22, 25)], syms: rep('partlycloudy_day', 26)),
      );
      expect(
        weatherSharedRow(paired: true, mine: me, partner: hp),
        WeatherSharedRow.none,
      );
      expect(weatherCardCompact(paired: true, mine: me, partner: hp), isTrue);
    });

    test('rain on MY side only: no nudge, but not compact either', () {
      final mineRain = place('vn-tp-hcm', hcm);
      final hp = place('vn-hai-phong', series(rep(30, 26)));
      expect(
        weatherSharedRow(paired: true, mine: mineRain, partner: hp),
        WeatherSharedRow.none,
      );
      expect(
        weatherCardCompact(paired: true, mine: mineRain, partner: hp),
        isFalse,
      );
    });

    test('I have no city yet: the partner nudge still shows', () {
      final p = place('vn-tp-hcm', hcm);
      expect(weatherSharedRow(paired: true, partner: p), WeatherSharedRow.cta);
      expect(weatherCardCompact(paired: true, partner: p), isFalse);
    });

    test(
      'waiting for the partner: never a shared row; compact on plain sky',
      () {
        expect(
          weatherSharedRow(paired: false, mine: place('vn-tp-hcm', hcm)),
          WeatherSharedRow.none,
        );
        expect(weatherCardCompact(paired: false, mine: me), isTrue);
        expect(
          weatherCardCompact(paired: false, mine: place('vn-sa-pa', sapa)),
          isFalse,
        );
      },
    );

    test('stale numbers: no nudge, no compact row', () {
      final p = place('vn-tp-hcm', hcm);
      final staleP = WeatherPlace(
        cityId: p.cityId,
        freshness: WeatherFreshness.stale,
        condition: p.condition,
      );
      expect(
        weatherSharedRow(paired: true, mine: me, partner: staleP),
        WeatherSharedRow.none,
      );
      final staleMe = WeatherPlace(
        cityId: me.cityId,
        freshness: WeatherFreshness.stale,
        condition: me.condition,
      );
      expect(
        weatherSharedRow(paired: true, mine: staleMe, partner: p),
        WeatherSharedRow.none,
      );
      expect(weatherCardCompact(paired: false, mine: staleMe), isFalse);
    });

    test('partner city not picked yet → full card ("Chọn giúp")', () {
      expect(weatherCardCompact(paired: true, mine: me), isFalse);
    });
  });

  group('city search (D4, design §14b)', () {
    List<String> ids(String q) => [
      for (final h in searchWeatherCities(q)) h.city.id,
    ];

    test('fold strips Vietnamese marks, đ, punctuation', () {
      expect(weatherFold('Bà Rịa–Vũng Tàu'), 'ba ria vung tau');
      expect(weatherFold('  ĐÀ   LẠT '), 'da lat');
      expect(weatherFold('Montréal'), 'montreal');
      expect(weatherFold('TP.HCM'), 'tp hcm');
      // Decomposed input (some Android keyboards): "Huế" as e + U+0302 + U+0301.
      expect(weatherFold('Huế'), 'hue');
    });

    test('"binh thuan" → Phan Thiết via the old province', () {
      final hits = searchWeatherCities('binh thuan');
      final pt = hits.firstWhere((h) => h.city.id == 'vn-phan-thiet');
      expect(pt.via, 'Bình Thuận');
      expect(pt.city.regionVi, 'Lâm Đồng');
    });

    test('no-space and short forms find their city', () {
      expect(ids('hanoi').first, 'vn-ha-noi');
      expect(ids('dalat').first, 'vn-da-lat');
      expect(ids('ha noi').first, 'vn-ha-noi');
      for (final q in [
        'hcm',
        'tphcm',
        'sg',
        'sai gon',
        'saigon',
        'HCMC',
        'Hồ Chí Minh',
      ]) {
        expect(ids(q), contains('vn-tp-hcm'), reason: q);
      }
    });

    test('abroad, English names, nothing found', () {
      expect(ids('seoul').first, 'kr-seoul');
      expect(ids('taipei'), contains('tw-taipei'));
      expect(ids('đài bắc'), contains('tw-taipei'));
      expect(ids('munich'), contains('de-munich'));
      expect(ids('xyz'), isEmpty);
    });

    test('a name match has no "via"; empty query lists every city', () {
      expect(searchWeatherCities('Đà Lạt').first.via, isNull);
      expect(searchWeatherCities('  ').length, kWeatherCities.length);
    });

    test('searching by the new province finds its cities', () {
      expect(
        ids('lam dong'),
        containsAll(['vn-da-lat', 'vn-gia-nghia', 'vn-phan-thiet']),
      );
    });
  });

  group('city list (Phụ lục A, D9)', () {
    test('ids unique, slug-shaped, ≤ 40; coords 2 decimals; tz set', () {
      final seen = <String>{};
      final slug = RegExp(r'^[a-z]{2}-[a-z0-9-]{1,36}$');
      for (final c in kWeatherCities) {
        expect(seen.add(c.id), isTrue, reason: 'duplicate ${c.id}');
        expect(slug.hasMatch(c.id), isTrue, reason: c.id);
        expect(c.lat.abs() <= 90 && c.lon.abs() <= 180, isTrue, reason: c.id);
        expect((c.lat * 100).roundToDouble() / 100, c.lat, reason: c.id);
        expect((c.lon * 100).roundToDouble() / 100, c.lon, reason: c.id);
        expect(c.tz, contains('/'), reason: c.id);
      }
      expect(kWeatherCities.where((c) => c.isVietnam).length, 66);
      expect(kWeatherCities.where((c) => !c.isVietnam).length, 50);
    });

    test('the 6 centrally-run cities come first with no region', () {
      expect(kWeatherCities.take(6).map((c) => c.id), [
        'vn-ha-noi',
        'vn-tp-hcm',
        'vn-hai-phong',
        'vn-da-nang',
        'vn-hue',
        'vn-can-tho',
      ]);
      expect(kWeatherCities.take(6).every((c) => c.regionVi.isEmpty), isTrue);
      expect(
        kWeatherCities.skip(6).every((c) => c.regionVi.isNotEmpty),
        isTrue,
      );
    });

    test('Dart list == functions/weather_cities.json (id + coordinates)', () {
      final raw =
          jsonDecode(File('functions/weather_cities.json').readAsStringSync())
              as List;
      expect(raw.length, kWeatherCities.length);
      for (var i = 0; i < raw.length; i++) {
        final j = raw[i] as Map<String, dynamic>;
        final c = kWeatherCities[i];
        expect(j['id'], c.id);
        expect((j['lat'] as num).toDouble(), c.lat, reason: c.id);
        expect((j['lon'] as num).toDouble(), c.lon, reason: c.id);
      }
    });

    test('every tz is in the timezone database', () {
      tz_data.initializeTimeZones();
      for (final c in kWeatherCities) {
        expect(() => tz.getLocation(c.tz), returnsNormally, reason: c.tz);
      }
    });

    test('short EN name only where set', () {
      final hcmc = weatherCityById('vn-tp-hcm')!;
      expect(hcmc.shortName('en'), 'HCMC');
      expect(hcmc.shortName('vi'), 'TP.HCM');
      expect(weatherCityById('vn-ha-noi')!.shortName('en'), 'Hanoi');
      expect(weatherCityById('nope'), isNull);
    });
  });

  test('forecast JSON round-trips (Hive cache)', () {
    final f = CityForecast(
      fetchedAt: vnAt(7, 12),
      checkedAt: vnAt(8),
      hours: hcm.take(3).toList(),
    );
    final back = CityForecast.fromJson(jsonDecode(jsonEncode(f.toJson())))!;
    expect(back.fetchedAt, f.fetchedAt);
    expect(back.checkedAt, f.checkedAt);
    expect(back.hours.map((h) => h.symbol), [
      'partlycloudy_day',
      'partlycloudy_day',
      'partlycloudy_day',
    ]);
    expect(back.hours.first.temp, 29);
    expect(CityForecast.fromJson({'fetchedAt': 'x'}), isNull);
    // The callable's shape: no checkedAt, odd hour entries dropped.
    final fromServer = CityForecast.fromJson({
      'fetchedAt': 1,
      'stale': true,
      'hours': [
        {'t': 3600000, 'temp': 20, 'symbol': 'fog', 'rain': 0},
        {'t': 'bad'},
      ],
    }, checkedAt: vnAt(9));
    expect(fromServer!.hours.length, 1);
    expect(fromServer.checkedAt, vnAt(9));
  });

  test('a choice made by the partner is not "set by self"', () {
    expect(
      WeatherChoice.fromDoc('u1', {
        'cityId': 'vn-hue',
        'setBy': 'u2',
      })!.setBySelf,
      isFalse,
    );
    expect(
      WeatherChoice.fromDoc('u1', {
        'cityId': 'vn-hue',
        'setBy': 'u1',
      })!.setBySelf,
      isTrue,
    );
    expect(WeatherChoice.fromDoc('u1', {'cityId': ''}), isNull);
    expect(WeatherChoice.fromDoc('u1', null), isNull);
  });
}
