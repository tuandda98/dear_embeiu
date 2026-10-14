import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/sleep_night.dart';
import 'firebase_bootstrap_service.dart';
import 'sleep_platform.dart';

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
    this.motionHintDismissed = false,
    this.localColor,
  });

  /// Tracking turned on (setup sheet finished).
  final bool enabled;
  final SleepMode mode;

  /// "Ẩn" on the Home card hides it until then (30 days, then it returns once).
  final DateTime? hiddenUntil;
  final bool healthHintDismissed;

  /// The one-time motion tip (vòng vá 1, P2-6) was closed.
  final bool motionHintDismissed;

  /// Colour choice when there is no Firestore profile (guest / offline build).
  final String? localColor;

  SleepSettings copyWith({
    bool? enabled,
    SleepMode? mode,
    DateTime? hiddenUntil,
    bool clearHidden = false,
    bool? healthHintDismissed,
    bool? motionHintDismissed,
    String? localColor,
  }) => SleepSettings(
    enabled: enabled ?? this.enabled,
    mode: mode ?? this.mode,
    hiddenUntil: clearHidden ? null : (hiddenUntil ?? this.hiddenUntil),
    healthHintDismissed: healthHintDismissed ?? this.healthHintDismissed,
    motionHintDismissed: motionHintDismissed ?? this.motionHintDismissed,
    localColor: localColor ?? this.localColor,
  );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'mode': mode.name,
    'hiddenUntil': hiddenUntil?.millisecondsSinceEpoch,
    'healthHintDismissed': healthHintDismissed,
    'motionHintDismissed': motionHintDismissed,
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
      motionHintDismissed: json['motionHintDismissed'] == true,
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

  /// Sleep data stays on this phone (privacy policy, audit D6): the box lives
  /// in its own folder under app documents that iCloud / Google backups skip
  /// (iOS: flag set on the folder; Android: `res/xml` backup rules).
  static const String _boxName = 'sleep_nobackup';
  static const String _folder = 'sleep_nobackup';

  /// 1.8.0–1.9.0 kept everything here, in Hive's default (backed-up) folder.
  static const String _legacyBoxName = 'sleep_local';
  static const String _kMovedFromLegacy = 'movedFromLegacy';

  static Box<dynamic>? _opened;
  static Future<Box<dynamic>>? _opening;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  Future<Box<dynamic>> _box() => _openBox();

  /// The one place that opens the local sleep box (instance and static
  /// callers share it). Concurrent first calls wait for the same open, so
  /// nobody reads the box before the old data has moved in.
  static Future<Box<dynamic>> _openBox() {
    final box = _opened;
    if (box != null && box.isOpen) {
      return Future<Box<dynamic>>.value(box);
    }
    return _opening ??= _openNoBackup()
        .then((b) => _opened = b)
        .whenComplete(() => _opening = null);
  }

  static Future<Box<dynamic>> _openNoBackup() async {
    final Directory docs;
    try {
      docs = await getApplicationDocumentsDirectory();
    } catch (_) {
      // No path_provider (unit tests): stay where Hive was set up.
      return Hive.openBox<dynamic>(_legacyBoxName);
    }
    final dir = await Directory(
      '${docs.path}/$_folder',
    ).create(recursive: true);
    // Every launch: iOS can drop the flag when a backup is restored.
    await SleepPlatform.excludeFromBackup(dir.path);
    return openBoxIn(dir.path);
  }

  /// Opens the box in [dir], first moving in what an older version kept in
  /// Hive's default folder. Copy (+ marker, one write) → delete the old box:
  /// a crash at any step loses nothing, and a rerun after the copy never
  /// puts old values back over newer ones.
  @visibleForTesting
  static Future<Box<dynamic>> openBoxIn(String dir) async {
    final box = await Hive.openBox<dynamic>(_boxName, path: dir);
    if (!await Hive.boxExists(_legacyBoxName)) {
      return box;
    }
    final legacy = await Hive.openBox<dynamic>(_legacyBoxName);
    if (box.get(_kMovedFromLegacy) != true) {
      try {
        await box.putAll({...legacy.toMap(), _kMovedFromLegacy: true});
      } catch (_) {
        // Not moved: this launch keeps writing to the old box, the next one
        // copies again into an empty box — a half copy left here would bring
        // back keys the old box deletes meanwhile.
        await box.deleteFromDisk().catchError((_) {});
        return legacy;
      }
    }
    await box.flush(); // the copy is on disk before the old box goes
    await legacy.deleteFromDisk().catchError((_) {}); // else next launch
    return box;
  }

  /// Account deletion: drops this user's sleep data from the phone — settings,
  /// nights, the upload fingerprints of every couple and the device-handover
  /// marks. Signing out keeps it.
  static Future<void> wipeLocalData(String uid) async {
    // Android's recorded still/moving transitions go too (F1).
    await SleepPlatform.stopMotionTracking();
    final box = await _openBox();
    final keys = box.keys
        .where(
          (k) =>
              k == 'settings:$uid' ||
              k == 'nights:$uid' ||
              k == 'left:$uid' ||
              k == 'notMine:$uid' ||
              (k is String && k.startsWith('fp:$uid:')),
        )
        .toList();
    await box.deleteAll(keys);
    if (box.get('device:uid') == uid) {
      // Still "someone else held it" for the next account, without the uid.
      await box.put('device:uid', '');
    }
  }

  /// Audit D7 + L3: screen events / Health samples on this phone belong to
  /// whoever held it at the time. When [uid] takes the phone over from
  /// another account, the time since [uid] last put it down — everything
  /// before, the first time [uid] is here — is someone else's. Returns those
  /// spans (empty while the phone has only known [uid], the first account
  /// here included). A night that ends inside one is not [uid]'s.
  Future<List<({DateTime from, DateTime until})>> claimDevice(
    String uid,
  ) async {
    try {
      final box = await _box();
      final last = box.get('device:uid');
      final now = DateTime.now().millisecondsSinceEpoch;
      // Older than any scan reaches (14 nights).
      final keepAfter = now - const Duration(days: 30).inMilliseconds;
      if (last != uid) {
        if (last is String) {
          final left = box.get('left:$uid');
          await box.putAll({
            if (last.isNotEmpty) 'left:$last': now,
            'notMine:$uid': [
              ..._spans(box.get('notMine:$uid')).where((s) => s[1] > keepAfter),
              [left is int ? left : 0, now],
            ],
          });
        }
        await box.put('device:uid', uid);
      }
      return [
        for (final s in _spans(box.get('notMine:$uid')))
          (
            from: DateTime.fromMillisecondsSinceEpoch(s[0]),
            until: DateTime.fromMillisecondsSinceEpoch(s[1]),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  static List<List<int>> _spans(Object? raw) => [
    if (raw is List)
      for (final s in raw)
        if (s is List && s.length == 2 && s[0] is int && s[1] is int)
          [s[0] as int, s[1] as int],
  ];

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
    // includeMetadataChanges.
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
        });
  }

  /// A member's shared nights since [sinceKey] ('YYYY-MM-DD'), the newest 400
  /// at most. Only readable while that member shares (rules) — subscribe
  /// after seeing `share == true`.
  Stream<Map<String, SleepNight>> watchNights(
    String coupleId,
    String uid, {
    required String sinceKey,
  }) {
    // A real wake date is at most a day ahead (rules cap wakeAt at now + 1
    // day); the margin outlives an app left open for weeks, since the bound
    // is fixed at subscribe time.
    final untilKey = sleepDateKey(DateTime.now().add(const Duration(days: 31)));
    return _nights(coupleId, uid)
        .where(
          'date',
          isGreaterThanOrEqualTo: sinceKey,
          isLessThanOrEqualTo: untilKey,
        )
        .orderBy('date', descending: true)
        .limit(400)
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
        'tz': ?n.tz,
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
