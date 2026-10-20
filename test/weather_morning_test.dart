import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/models/weather.dart';
import 'package:dear_embeiu/utils/weather_logic.dart';
import 'package:dear_embeiu/widgets/weather/weather_card.dart';

/// The 07:30 notice (overview §6.7, D13): when it fires, the 3-in-7-days cap,
/// no same kind two days running, and the log it keeps. Phone and city share
/// the machine's clock here so the test runs in any time zone.

final DateTime evening = DateTime(2026, 10, 20, 20, 0); // phone-local
Duration sameClock(DateTime utc) => utc.toLocal().timeZoneOffset;

/// 36 hours from [from] (local); [at] hours after tomorrow 07:30 gets
/// [symbol] / [temp].
CityForecast forecast({
  DateTime? fetched,
  String symbol = 'cloudy',
  double? temp,
  int at = 6,
}) {
  final fire = DateTime(2026, 10, 21, 7, 30).toUtc();
  final start = DateTime.utc(fire.year, fire.month, fire.day, fire.hour - 12);
  return CityForecast(
    fetchedAt: (fetched ?? evening).toUtc(),
    checkedAt: (fetched ?? evening).toUtc(),
    hours: [
      for (var i = 0; i < 36; i++)
        WeatherHour(
          t: start.add(Duration(hours: i)),
          temp:
              start.add(Duration(hours: i)) ==
                  DateTime.utc(fire.year, fire.month, fire.day, fire.hour + at)
              ? (temp ?? 25)
              : 25,
          symbol:
              start.add(Duration(hours: i)) ==
                  DateTime.utc(fire.year, fire.month, fire.day, fire.hour + at)
              ? symbol
              : 'cloudy',
          rain: 0,
        ),
    ],
  );
}

WeatherMorningPlan? plan(
  CityForecast? f, {
  DateTime? now,
  Map<String, String> log = const {},
}) => weatherMorningPlan(
  nowLocal: now ?? evening,
  forecast: f,
  cityOffsetAt: sameClock,
  log: log,
);

void main() {
  test('next 07:30: today before it, tomorrow after it', () {
    expect(
      weatherMorningFireAt(DateTime(2026, 10, 20, 6)),
      DateTime(2026, 10, 20, 7, 30),
    );
    expect(
      weatherMorningFireAt(DateTime(2026, 10, 20, 7, 30)),
      DateTime(2026, 10, 21, 7, 30),
    );
    expect(weatherMorningFireAt(evening), DateTime(2026, 10, 21, 7, 30));
  });

  test('rain / heat / cold ahead → the matching kind; plain sky → none', () {
    expect(plan(forecast(symbol: 'rain'))!.cta, WeatherCta.umbrella);
    final hot = plan(forecast(temp: 36))!;
    expect([hot.cta, hot.max], [WeatherCta.water, 36]);
    final cold = plan(forecast(temp: 12))!;
    expect([cold.cta, cold.min], [WeatherCta.warm, 12]);
    expect(plan(forecast()), isNull);
    expect(plan(null), isNull);
    expect(plan(forecast(symbol: 'rain'))!.dateKey, '2026-10-21');
  });

  test('only the 14 hours after 07:30 count', () {
    expect(plan(forecast(symbol: 'rain', at: 13)), isNotNull);
    expect(plan(forecast(symbol: 'rain', at: 15)), isNull);
  });

  test('forecast older than 18 h at 07:30 → no notice', () {
    final old = forecast(
      symbol: 'rain',
      fetched: DateTime(2026, 10, 20, 13, 0), // 18 h 30 before
    );
    expect(plan(old), isNull);
    final ok = forecast(symbol: 'rain', fetched: DateTime(2026, 10, 20, 14));
    expect(plan(ok), isNotNull);
  });

  test('at most 3 in 7 days', () {
    final rain = forecast(symbol: 'rain');
    expect(
      plan(rain, log: {'2026-10-15': 'warm', '2026-10-17': 'water'}),
      isNotNull,
      reason: '2 in the 6 days before + this one = 3',
    );
    expect(
      plan(
        rain,
        log: {
          '2026-10-15': 'warm',
          '2026-10-17': 'water',
          '2026-10-19': 'warm',
        },
      ),
      isNull,
    );
    expect(
      plan(
        rain,
        log: {
          '2026-10-16': 'warm',
          '2026-10-18': 'water',
          '2026-10-20': 'warm',
        },
      ),
      isNull,
    );
    expect(
      plan(
        rain,
        log: {
          '2026-10-13': 'warm',
          '2026-10-14': 'warm',
          '2026-10-17': 'water',
        },
      ),
      isNotNull,
      reason: '10-14 is 7 days before 10-21: out of the window',
    );
  });

  test('never the same kind two days running', () {
    final rain = forecast(symbol: 'rain');
    expect(plan(rain, log: {'2026-10-20': 'umbrella'}), isNull);
    expect(plan(rain, log: {'2026-10-20': 'water'}), isNotNull);
    expect(plan(rain, log: {'2026-10-19': 'umbrella'}), isNotNull);
  });

  test('the log: record the coming morning, forget it when dropped', () {
    final p = plan(forecast(symbol: 'rain'))!;
    final log = weatherMorningLogAfter(
      {'2026-10-20': 'warm', '2026-10-01': 'water'},
      nowLocal: evening,
      plan: p,
    );
    expect(log, {'2026-10-20': 'warm', '2026-10-21': 'umbrella'});
    final dropped = weatherMorningLogAfter(log, nowLocal: evening, plan: null);
    expect(dropped, {'2026-10-20': 'warm'}, reason: 'past mornings stay');
  });

  group('care prefill (§6.6)', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    final en = lookupAppLocalizations(const Locale('en'));

    test('rain / hot / cold wording with the city and numbers', () {
      final rain = weatherCarePrefill(
        vi,
        WeatherCta.umbrella,
        city: 'TP.HCM',
        min: 25,
        max: 33,
      );
      expect(rain.title, 'Nhớ mang ô nhé');
      expect(rain.body, 'TP.HCM sắp mưa đó. Ra ngoài nhớ mang ô theo nha.');
      final hot = weatherCarePrefill(
        vi,
        WeatherCta.water,
        city: 'Biên Hoà',
        min: 27,
        max: 36,
      );
      expect(hot.title, 'Uống nước nhiều nha');
      expect(hot.body, contains('36°'));
      final cold = weatherCarePrefill(
        en,
        WeatherCta.warm,
        city: 'Seoul',
        min: 4,
        max: 11,
      );
      expect(cold.title, 'Dress warm');
      expect(cold.body, contains('dropping to 4°'));
    });

    test('the longest city still fits care-message limits (60 / 200)', () {
      for (final l in [vi, en]) {
        for (final cta in WeatherCta.values) {
          final n = weatherCarePrefill(
            l,
            cta,
            city: 'Buôn Ma Thuột',
            min: -10,
            max: 40,
          );
          expect(n.title.length, lessThanOrEqualTo(60));
          expect(n.body.length, lessThanOrEqualTo(200));
        }
      }
    });

    test('nudge labels name the person', () {
      expect(
        weatherCtaLabel(vi, WeatherCta.umbrella, 'Thảo'),
        'Nhắc Thảo mang ô',
      );
      expect(
        weatherCtaLabel(vi, WeatherCta.water, 'Thảo'),
        'Nhắc Thảo uống nước',
      );
      expect(weatherCtaLabel(vi, WeatherCta.warm, 'Thảo'), 'Nhắc Thảo mặc ấm');
    });
  });
}
