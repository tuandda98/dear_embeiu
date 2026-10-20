import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/weather.dart';
import 'firebase_bootstrap_service.dart';

/// Data layer of the weather feature ("Thời tiết hai nơi"):
/// - each member's city at `couples/{coupleId}/weather/{uid}` (Firestore,
///   rules D6: the partner may pick for you until you pick yourself);
/// - forecasts from the `getCityWeather` callable (MET Norway behind a
///   per-city server cache, D7);
/// - the last forecast per city in Hive (`weather_cache`), so the card still
///   shows numbers offline — the provider grades them fresh / stale / none by
///   age (D16).
///
/// Without Firebase (local fallback) there is no city and no forecast: the
/// streams stay empty and the card stays in its invite state.
class WeatherService {
  WeatherService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore,
      _functions = functions;

  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;

  static const String _cacheBoxName = 'weather_cache';

  /// Server side is ≤ 8 s per MET call; leave headroom for the cold start.
  static const Duration _callTimeout = Duration(seconds: 15);

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  FirebaseFunctions get _fns =>
      _functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  CollectionReference<Map<String, dynamic>> _choices(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('weather');

  /// Both members' choices (≤ 2 docs), keyed by owner uid.
  Stream<Map<String, WeatherChoice>> watchChoices(String coupleId) {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return Stream<Map<String, WeatherChoice>>.value(
        const <String, WeatherChoice>{},
      );
    }
    return _choices(coupleId).snapshots().map((snapshot) {
      return <String, WeatherChoice>{
        for (final doc in snapshot.docs)
          doc.id: ?WeatherChoice.fromDoc(doc.id, doc.data()),
      };
    });
  }

  /// Writes [ownerUid]'s city, picked by [myUid] (== owner, or the partner
  /// picking for them). Throws when the rules refuse — e.g. the partner has
  /// just picked their own city (`permission-denied`).
  Future<void> setCity({
    required String coupleId,
    required String ownerUid,
    required String myUid,
    required String cityId,
  }) async {
    if (!isUsingFirebase) {
      return;
    }
    await _choices(coupleId).doc(ownerUid).set(<String, Object>{
      'cityId': cityId,
      'setBy': myUid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Asks the callable for 1–2 cities. Returns only the cities the server
  /// had data for (one may be missing); throws on network / server errors.
  Future<Map<String, CityForecast>> fetchForecasts(
    List<String> cityIds, {
    required String languageCode,
    DateTime? now,
  }) async {
    if (!isUsingFirebase || cityIds.isEmpty) {
      return const <String, CityForecast>{};
    }
    final result = await _fns
        .httpsCallable(
          'getCityWeather',
          options: HttpsCallableOptions(timeout: _callTimeout),
        )
        .call<dynamic>(<String, dynamic>{
          'cityIds': cityIds,
          'lang': languageCode == 'vi' ? 'vi' : 'en',
        });
    final data = result.data;
    final cities = data is Map ? data['cities'] : null;
    if (cities is! Map) {
      return const <String, CityForecast>{};
    }
    final checkedAt = (now ?? DateTime.now()).toUtc();
    final out = <String, CityForecast>{};
    for (final id in cityIds) {
      final f = CityForecast.fromJson(cities[id], checkedAt: checkedAt);
      if (f != null) {
        out[id] = f;
      }
    }
    return out;
  }

  // ── Hive cache (last forecast per city) ───────────────────────────────────

  Future<Box<dynamic>> _openCache() => Hive.openBox<dynamic>(_cacheBoxName);

  Future<Map<String, CityForecast>> loadCached(Iterable<String> cityIds) async {
    try {
      final box = await _openCache();
      final out = <String, CityForecast>{};
      for (final id in cityIds) {
        final raw = box.get(id);
        if (raw is String) {
          final f = CityForecast.fromJson(jsonDecode(raw));
          if (f != null) {
            out[id] = f;
          }
        }
      }
      return out;
    } catch (_) {
      return const <String, CityForecast>{};
    }
  }

  Future<void> saveCached(Map<String, CityForecast> forecasts) async {
    try {
      final box = await _openCache();
      await box.putAll(<String, String>{
        for (final e in forecasts.entries) e.key: jsonEncode(e.value.toJson()),
      });
    } catch (_) {
      // Best-effort: the next successful fetch writes it again.
    }
  }

  /// Sign-out: the cities are coarse location of the previous account.
  Future<void> clearCache() async {
    try {
      final box = await _openCache();
      await box.clear();
    } catch (_) {
      // Best-effort.
    }
  }

  // ── Per-device prefs (Hive `app_settings`, a Box<String>) ─────────────────

  static const String _settingsBox = 'app_settings';
  static const String keyCardHidden = 'weather_card_hidden';
  static const String keyNoticeEnabled = 'weather_notice_enabled';
  static const String keyNoticeLog = 'weather_notice_log';

  Future<Box<String>> _openSettings() async => Hive.isBoxOpen(_settingsBox)
      ? Hive.box<String>(_settingsBox)
      : await Hive.openBox<String>(_settingsBox);

  /// The card's "Ẩn" flag, the morning-notice switch (default on, D13) and
  /// the notice log (date key → kind). Defaults when Hive isn't there.
  Future<({bool cardHidden, bool noticeEnabled, Map<String, String> log})>
  loadPrefs() async {
    try {
      final box = await _openSettings();
      final raw = box.get(keyNoticeLog);
      final decoded = raw == null ? null : jsonDecode(raw);
      return (
        cardHidden: box.get(keyCardHidden) == 'true',
        noticeEnabled: box.get(keyNoticeEnabled) != 'false',
        log: <String, String>{
          if (decoded is Map)
            for (final e in decoded.entries)
              if (e.value is String) '${e.key}': e.value as String,
        },
      );
    } catch (_) {
      return (
        cardHidden: false,
        noticeEnabled: true,
        log: const <String, String>{},
      );
    }
  }

  Future<void> savePref(String key, String? value) async {
    try {
      final box = await _openSettings();
      if (value == null) {
        await box.delete(key);
      } else {
        await box.put(key, value);
      }
    } catch (_) {
      // Best-effort: the in-memory value holds for this run.
    }
  }

  Future<void> saveNoticeLog(Map<String, String> log) =>
      savePref(keyNoticeLog, jsonEncode(log));
}
