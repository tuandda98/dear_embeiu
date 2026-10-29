import 'dart:async';

import 'package:dear_embeiu/models/weather.dart';
import 'package:dear_embeiu/services/weather_service.dart';

/// In-memory stand-in: choices come from [choices], forecasts from [server]
/// (null = the callable throws, offline), the Hive copy from [hive].
class FakeWeatherService extends WeatherService {
  final StreamController<Map<String, WeatherChoice>> choices =
      StreamController<Map<String, WeatherChoice>>.broadcast();
  Map<String, CityForecast>? server = <String, CityForecast>{};
  final Map<String, CityForecast> hive = <String, CityForecast>{};
  final List<List<String>> calls = <List<String>>[];
  final List<String> writes = <String>[];
  bool refuseWrites = false;
  bool cacheCleared = false;

  @override
  bool get isUsingFirebase => true;

  @override
  Stream<Map<String, WeatherChoice>> watchChoices(String coupleId) =>
      choices.stream;

  @override
  Future<void> setCity({
    required String coupleId,
    required String ownerUid,
    required String myUid,
    required String cityId,
  }) async {
    if (refuseWrites) {
      throw Exception('permission-denied');
    }
    writes.add('$ownerUid=$cityId by $myUid');
  }

  @override
  Future<Map<String, CityForecast>> fetchForecasts(
    List<String> cityIds, {
    required String languageCode,
    DateTime? now,
  }) async {
    calls.add(List<String>.of(cityIds));
    final s = server;
    if (s == null) {
      throw Exception('unavailable');
    }
    return {
      for (final id in cityIds)
        if (s[id] case final f?)
          id: CityForecast(
            fetchedAt: f.fetchedAt,
            checkedAt: now!,
            hours: f.hours,
          ),
    };
  }

  @override
  Future<Map<String, CityForecast>> loadCached(
    Iterable<String> cityIds,
  ) async => {for (final id in cityIds) id: ?hive[id]};

  @override
  Future<void> saveCached(Map<String, CityForecast> forecasts) async =>
      hive.addAll(forecasts);

  @override
  Future<void> clearCache() async => cacheCleared = true;

  final Map<String, String?> prefs = <String, String?>{};
  Map<String, String> noticeLog = <String, String>{};

  @override
  Future<({bool cardHidden, bool noticeEnabled, Map<String, String> log})>
  loadPrefs() async => (
    cardHidden: prefs[WeatherService.keyCardHidden] == 'true',
    noticeEnabled: prefs[WeatherService.keyNoticeEnabled] != 'false',
    log: Map<String, String>.of(noticeLog),
  );

  @override
  Future<void> savePref(String key, String? value) async => prefs[key] = value;

  @override
  Future<void> saveNoticeLog(Map<String, String> log) async =>
      noticeLog = Map<String, String>.of(log);
}
