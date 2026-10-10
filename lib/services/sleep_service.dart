import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sleep_night.dart';
import 'firebase_bootstrap_service.dart';

/// Where MY nights come from.
enum SleepMode {
  /// Android: screen on/off events (Usage access).
  auto,

  /// iOS: Apple Health `sleepAnalysis`.
  health,

  /// No automatic source — the user logs nights by hand.
  manual,
}

/// Per-account device settings (Hive only — nothing here is shared).
class SleepSettings {
  const SleepSettings({
    this.enabled = false,
    this.mode = SleepMode.manual,
    this.hiddenUntil,
    this.healthHintDismissed = false,
    this.localColor,
  });

  /// Tracking turned on (setup sheet finished).
  final bool enabled;
  final SleepMode mode;

  /// "Ẩn" on the Home card hides it until then (30 days, then it returns once).
  final DateTime? hiddenUntil;
  final bool healthHintDismissed;

  /// Colour choice when there is no Firestore profile (guest / offline build).
  final String? localColor;

  SleepSettings copyWith({
    bool? enabled,
    SleepMode? mode,
    DateTime? hiddenUntil,
    bool clearHidden = false,
    bool? healthHintDismissed,
    String? localColor,
  }) => SleepSettings(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    hiddenUntil: clearHidden ? null : (hiddenUntil ?? this.hiddenUntil),
    healthHintDismissed: healthHintDismissed ?? this.healthHintDismissed,
    localColor: localColor ?? this.localColor,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'mode': mode.name,
    'hiddenUntil': hiddenUntil?.millisecondsSinceEpoch,
    'healthHintDismissed': healthHintDismissed,
    'localColor': localColor,
  };

  factory SleepSettings.fromJson(Map<dynamic, dynamic> json) {
    final hidden = json['hiddenUntil'];
    return SleepSettings(
      enabled: json['enabled'] == true,
      mode: SleepMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => SleepMode.manual,
      ),
      hiddenUntil: hidden is int
          ? DateTime.fromMillisecondsSinceEpoch(hidden)
          : null,
      healthHintDismissed: json['healthHintDismissed'] == true,
      localColor: json['localColor'] as String?,
    );
  }
}

/// A member's shared sleep profile: `couples/{c}/sleep/{uid}`.
class SleepProfile {
  const SleepProfile({required this.share, this.color});

  final bool share;
  final String? color;
}

/// Storage for feature sleep. My nights live in Hive (always — the device is
/// the source of truth); they are mirrored to Firestore only while sharing is
/// on, and wiped from Firestore when it's turned off (privacy by design).
class SleepService {
  SleepService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _boxName = 'sleep_local';

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  // ── Local (Hive) ────────────────────────────────────────────────────────

  Future<SleepSettings> loadSettings(String uid) async {
    try {
      final raw = (await _box()).get('settings:$uid');
      if (raw is Map) {
        return SleepSettings.fromJson(raw);
      }
    } catch (_) {
      // fall through to defaults
    }
    return const SleepSettings();
  }

  Future<void> saveSettings(String uid, SleepSettings settings) async {
    await (await _box()).put('settings:$uid', settings.toJson());
  }

  /// My nights by wake date. A null value is a deletion marker: the user
  /// deleted that night, so the next scan must not bring it back.
  Future<Map<String, SleepNight?>> loadNights(String uid) async {
    final out = <String, SleepNight?>{};
    try {
      final raw = (await _box()).get('nights:$uid');
      if (raw is Map) {
        for (final entry in raw.entries) {
          final value = entry.value;
          if (entry.key is! String || value is! Map) {
            continue;
          }
          if (value['deleted'] == true) {
            out[entry.key as String] = null;
          } else {
            final night = SleepNight.fromMap(value);
            if (night != null) {
              out[entry.key as String] = night;
            }
          }
        }
      }
    } catch (_) {
      // A corrupt box reads as empty; the next scan refills it.
    }
    return out;
  }

  Future<void> saveNights(String uid, Map<String, SleepNight?> nights) async {
    await (await _box()).put('nights:$uid', {
      for (final e in nights.entries)
        e.key: e.value?.toJson() ?? {'deleted': true},
    });
  }

  /// What was last uploaded per date (skips rewriting unchanged nights).
  Future<Map<String, String>> loadFingerprints(
    String uid,
    String coupleId,
  ) async {
    try {
      final raw = (await _box()).get('fp:$uid:$coupleId');
      if (raw is Map) {
        return {
          for (final e in raw.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
        };
      }
    } catch (_) {
      // start fresh
    }
    return <String, String>{};
  }

  Future<void> saveFingerprints(
    String uid,
    String coupleId,
    Map<String, String> fp,
  ) async {
    await (await _box()).put('fp:$uid:$coupleId', fp);
  }

  // ── Remote (Firestore) ──────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _profile(
    String coupleId,
    String uid,
  ) => _db.collection('couples').doc(coupleId).collection('sleep').doc(uid);

  CollectionReference<Map<String, dynamic>> _nights(
    String coupleId,
    String uid,
  ) => _profile(coupleId, uid).collection('nights');

  /// Null when the member never set sleep up.
  Stream<SleepProfile?> watchProfile(String coupleId, String uid) {
    if (!isUsingFirebase || coupleId.isEmpty || uid.isEmpty) {
      return Stream<SleepProfile?>.value(null);
    }
    // "No profile" only counts once the server says so: an empty cache
    // (reinstall, offline) must not look like a member who never set up. The
    // server confirming "still no doc" is a metadata-only change, hence
    // includeMetadataChanges; `distinct` drops the other metadata events.
    return _profile(coupleId, uid)
        .snapshots(includeMetadataChanges: true)
        .where((snap) => snap.exists || !snap.metadata.isFromCache)
        .map((snap) {
          final data = snap.data();
          if (data == null) {
            return null;
          }
          return SleepProfile(
            share: data['share'] == true,
            color: data['color'] as String?,
          );
        })
        .distinct(
          (a, b) =>
              (a == null) == (b == null) &&
              a?.share == b?.share &&
              a?.color == b?.color,
        );
  }

  /// A member's shared nights since [sinceKey] ('YYYY-MM-DD'). Only readable
  /// while that member shares (rules) — subscribe after seeing `share == true`.
  Stream<Map<String, SleepNight>> watchNights(
    String coupleId,
    String uid, {
    required String sinceKey,
  }) {
    return _nights(coupleId, uid)
        .where('date', isGreaterThanOrEqualTo: sinceKey)
        .snapshots()
        .map(_toNights)
        // The owner just turned sharing off: rules now deny the read. That's
        // "not shared", not a failure — end the stream quietly.
        .handleError(
          (_) {},
          test: (e) => e is FirebaseException && e.code == 'permission-denied',
        );
  }

  Future<Map<String, SleepNight>> fetchNights(
    String coupleId,
    String uid,
  ) async => _toNights(await _nights(coupleId, uid).get());

  Map<String, SleepNight> _toNights(QuerySnapshot<Map<String, dynamic>> snap) {
    final out = <String, SleepNight>{};
    for (final doc in snap.docs) {
      final night = SleepNight.fromMap(doc.data());
      if (night != null) {
        out[night.date] = night;
      }
    }
    return out;
  }

  Future<void> setProfile(
    String coupleId,
    String uid, {
    bool? share,
    String? color,
  }) => _profile(coupleId, uid).set({
    'share': ?share,
    'color': ?color,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  /// Final times + source only (R2 — never the originally detected times).
  Future<void> putNight(String coupleId, String uid, SleepNight n) =>
      _nights(coupleId, uid).doc(n.date).set({
        'date': n.date,
        'bedAt': Timestamp.fromDate(n.bedAt),
        'wakeAt': Timestamp.fromDate(n.wakeAt),
        'wakeUps': n.wakeUps.take(60).toList(),
        'source': n.source.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> deleteNight(String coupleId, String uid, String date) =>
      _nights(coupleId, uid).doc(date).delete();

  /// Sharing turned off → remove every shared night (rules allow it once the
  /// profile says `share: false`).
  Future<void> deleteAllNights(String coupleId, String uid) async {
    final snap = await _nights(coupleId, uid).get();
    await Future.wait([
      for (final doc in snap.docs) doc.reference.delete().catchError((_) {}),
    ]);
  }
}
