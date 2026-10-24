import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/arrival.dart';
import '../utils/arrival_edge_filter.dart';
import 'firebase_bootstrap_service.dart';
import 'sleep_platform.dart';

/// What happened to one arrival event.
enum ArrivalSendResult {
  /// On the server — the partner's card has it (and maybe a push).
  sent,

  /// Not acked in time (offline): Firestore keeps it queued and sends later
  /// (D6: older than 30' by then → card only, no push).
  queued,

  /// Filtered on this phone (edge filter D6, unknown place) — nothing written.
  dropped,

  /// `permission-denied`: no longer in the couple / signed out. The caller
  /// stops every geofence (overview §5).
  denied,

  /// Any other error — the card offers "Thử lại".
  failed,
}

/// Storage for feature arrival. My places (address + coordinates) live ONLY in
/// Hive on this phone (D2); Firestore holds one doc per member with the
/// latest event (D3, D14). Mirrors [SleepService].
class ArrivalService {
  ArrivalService({
    FirebaseFirestore? firestore,
    this.ackTimeout = const Duration(seconds: 5),
  }) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  /// A write not acked within this is reported as [ArrivalSendResult.queued].
  final Duration ackTimeout;

  /// Its own folder under app documents that iCloud / Google backups skip
  /// (iOS: flag on the folder; Android: `res/xml` backup rules), like
  /// `sleep_nobackup`. Changing phones = set the places again (D2).
  static const String _boxName = 'arrival_nobackup';
  static const String _folder = 'arrival_nobackup';

  static Box<dynamic>? _opened;
  static Future<Box<dynamic>>? _opening;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  static Future<Box<dynamic>> _box() {
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
      return Hive.openBox<dynamic>(_boxName);
    }
    final dir = await Directory(
      '${docs.path}/$_folder',
    ).create(recursive: true);
    // Every launch: iOS can drop the flag when a backup is restored.
    await SleepPlatform.excludeFromBackup(dir.path);
    return Hive.openBox<dynamic>(_boxName, path: dir.path);
  }

  /// Account deletion: this user's places, edge state and settings go.
  /// Signing out keeps them (same phone, same person).
  static Future<void> wipeLocalData(String uid) async {
    final box = await _box();
    final session = box.get('session');
    await box.deleteAll([
      'places:$uid',
      'edge:$uid',
      'settings:$uid',
      'sharePartner:$uid',
      if (session is Map && session['uid'] == uid) 'session',
    ]);
  }

  // ── Local (Hive) ────────────────────────────────────────────────────────

  /// Every place, Home first; Home is always there (D19).
  Future<List<ArrivalPlace>> loadPlaces(String uid) async {
    final out = <String, ArrivalPlace>{};
    try {
      final raw = (await _box()).get('places:$uid');
      if (raw is Map) {
        for (final e in raw.entries) {
          final place = ArrivalPlace.fromJson('${e.key}', e.value);
          if (place != null) out[place.slot] = place;
        }
      }
    } catch (_) {
      // A corrupt box reads as "only Home".
    }
    return [
      out[kArrivalHome] ?? const ArrivalPlace.home(),
      for (final slot in kArrivalSlots.skip(1))
        if (out[slot] != null) out[slot]!,
    ];
  }

  Future<void> savePlaces(String uid, List<ArrivalPlace> places) async {
    await (await _box()).put('places:$uid', {
      for (final p in places) p.slot: p.toJson(),
    });
  }

  Future<ArrivalEdgeState> loadEdge(String uid, String slot) async {
    final raw = (await _box()).get('edge:$uid');
    return ArrivalEdgeState.fromJson(raw is Map ? raw[slot] : null);
  }

  Future<void> saveEdge(String uid, String slot, ArrivalEdgeState s) async {
    final box = await _box();
    final raw = box.get('edge:$uid');
    await box.put('edge:$uid', {if (raw is Map) ...raw, slot: s.toJson()});
  }

  /// Forget a place's in/out state (place moved / deleted).
  Future<void> clearEdge(String uid, String slot) async {
    final box = await _box();
    final raw = box.get('edge:$uid');
    if (raw is Map && raw.containsKey(slot)) {
      await box.put('edge:$uid', {...raw}..remove(slot));
    }
  }

  /// The user turned "Tự báo khi mình đến nơi" on (whether it can run is
  /// another matter: permission, remote switch, a place with a location).
  Future<bool> loadWantsAuto(String uid) async {
    final raw = (await _box()).get('settings:$uid');
    return raw is Map && raw['auto'] == true;
  }

  /// [partnerUid]: who "Tự báo" was switched on for. A new partner must opt
  /// in again (review native #1, D10), so the provider compares it.
  Future<void> saveWantsAuto(
    String uid,
    bool value, {
    String? partnerUid,
  }) async {
    await (await _box()).put('settings:$uid', {
      'auto': value,
      'partner': ?partnerUid,
    });
  }

  Future<String?> loadAutoPartner(String uid) async {
    final raw = (await _box()).get('settings:$uid');
    final partner = raw is Map ? raw['partner'] : null;
    return partner is String && partner.isNotEmpty ? partner : null;
  }

  /// The partner this phone last watched arrival for (BUG-4): a different
  /// one on the next launch means the couple changed, so the provider drops
  /// my doc in case a tap queued offline shared it with the new partner.
  Future<String?> loadSharePartner(String uid) async {
    final raw = (await _box()).get('sharePartner:$uid');
    return raw is String && raw.isNotEmpty ? raw : null;
  }

  Future<void> saveSharePartner(String uid, String partnerUid) async =>
      (await _box()).put('sharePartner:$uid', partnerUid);

  /// Who is signed in + their couple, for the geofence background callback
  /// (stage 2), which has no providers. Null coupleId = nowhere to send.
  Future<void> saveSession(String uid, String? coupleId) async {
    await (await _box()).put('session', {'uid': uid, 'coupleId': ?coupleId});
  }

  Future<({String uid, String coupleId})?> loadSession() async {
    final raw = (await _box()).get('session');
    if (raw is! Map) return null;
    final uid = raw['uid'];
    final coupleId = raw['coupleId'];
    if (uid is! String || coupleId is! String) return null;
    return (uid: uid, coupleId: coupleId);
  }

  Future<void> clearSession() async => (await _box()).delete('session');

  // ── Remote switch (D13) ─────────────────────────────────────────────────

  /// `config/app.arrivalAutoEnabled` — absent or unreadable = ON (the last
  /// value read is kept for offline launches).
  Future<bool> readRemoteAutoEnabled() async {
    final box = await _box();
    try {
      final snap = await _db
          .collection('config')
          .doc('app')
          .get()
          .timeout(const Duration(seconds: 4));
      final value = snap.data()?['arrivalAutoEnabled'] != false;
      await box.put('remoteAuto', value);
      return value;
    } catch (_) {
      return box.get('remoteAuto') != false;
    }
  }

  // ── Remote (Firestore) ──────────────────────────────────────────────────

  DocumentReference<Map<String, dynamic>> _doc(String coupleId, String uid) =>
      _db.collection('couples').doc(coupleId).collection('arrival').doc(uid);

  /// A member's arrival doc; null when they never set it up.
  Stream<ArrivalShare?> watchShare(String coupleId, String uid) {
    if (!isUsingFirebase || coupleId.isEmpty || uid.isEmpty) {
      return Stream<ArrivalShare?>.value(null);
    }
    // Metadata changes too: the server ack of a queued write flips
    // `hasPendingWrites` without touching the data.
    return _doc(coupleId, uid).snapshots(includeMetadataChanges: true).map((
      snap,
    ) {
      final data = snap.data();
      if (data == null) return null;
      final share = data['share'] == true;
      return ArrivalShare(
        share: share,
        auto: data['auto'] == true,
        last: share ? ArrivalEvent.fromMap(data['last'], _toDate) : null,
        pending: snap.metadata.hasPendingWrites,
      );
    });
  }

  static DateTime? _toDate(Object? v) => v is Timestamp ? v.toDate() : null;

  /// Writes [event] as my latest (D3). A manual tap turns sharing on;
  /// `mergeFields` replaces `last` whole — a plain merge would keep the old
  /// event's `name` on a Home event, which the rules reject.
  ///
  /// An automatic event (geofence) only UPDATES a doc that already shares
  /// (D10, rules): after a partner change the CF deleted the doc, so the
  /// update fails `not-found` instead of sharing with the new partner.
  /// `update` also replaces `last` whole.
  Future<void> putEvent(
    String coupleId,
    String uid,
    ArrivalEvent event, {
    required bool auto,
  }) => event.source == ArrivalEventSource.auto
      ? _doc(coupleId, uid).update({
          'auto': true,
          'last': event.toMap(Timestamp.fromDate),
          'updatedAt': FieldValue.serverTimestamp(),
        })
      : _doc(coupleId, uid).set({
    'share': true,
    'auto': auto,
    'last': event.toMap(Timestamp.fromDate),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(mergeFields: ['share', 'auto', 'last', 'updatedAt']));

  /// Only the "tự báo" flag (sharing already on).
  Future<void> setAuto(String coupleId, String uid, bool auto) =>
      _doc(coupleId, uid).set({
        'auto': auto,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Sharing on without an event yet (the switch on the setup screen).
  Future<void> turnOn(String coupleId, String uid, {required bool auto}) =>
      _doc(coupleId, uid).set({
        'share': true,
        'auto': auto,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  /// Sharing off = my doc goes, latest event included, in one write (D11).
  /// No `share:false` and no time stamp left behind: the partner can't tell
  /// "switched off at 21:14" from "never turned on". No push.
  Future<void> turnOff(String coupleId, String uid) =>
      _doc(coupleId, uid).delete();

  /// The one path every event takes — manual taps (provider) and geofence
  /// callbacks (stage 2, also from the background engine). Auto events go
  /// through the edge filter (D6); manual ones always send. [battery] is read
  /// by the caller (BatteryReader) so this stays testable.
  Future<ArrivalSendResult> reportEvent({
    required String uid,
    required String coupleId,
    required String slot,
    required ArrivalEventType type,
    required ArrivalEventSource source,
    required bool auto,
    DateTime? at,
    int? battery,
  }) async {
    final when = at ?? DateTime.now();
    final places = await loadPlaces(uid);
    ArrivalPlace? place;
    for (final p in places) {
      if (p.slot == slot) place = p;
    }
    if (place == null) return ArrivalSendResult.dropped;

    var bounce = false;
    ArrivalEdgeState? next;
    if (source == ArrivalEventSource.auto) {
      final decision = filterArrivalEdge(await loadEdge(uid, slot), type, when);
      if (!decision.send) return ArrivalSendResult.dropped;
      bounce = decision.bounce;
      next = decision.next;
    }

    final event = ArrivalEvent.at(
      place,
      type: type,
      at: when,
      source: source,
      battery: battery,
      bounce: bounce,
    );
    final result = await send(() => putEvent(coupleId, uid, event, auto: auto));
    // Only an event that is (or will be) on the server moves the in/out
    // state; a failed / denied one must not make the next one look like a
    // duplicate.
    if (next != null &&
        (result == ArrivalSendResult.sent ||
            result == ArrivalSendResult.queued)) {
      await saveEdge(uid, slot, next);
    }
    return result;
  }

  /// Runs one write and classifies the outcome.
  Future<ArrivalSendResult> send(Future<void> Function() write) async {
    try {
      await write().timeout(ackTimeout);
      return ArrivalSendResult.sent;
    } on TimeoutException {
      return ArrivalSendResult.queued;
    } on FirebaseException catch (e) {
      // not-found: an automatic event for a doc that is gone (sharing ended
      // by a partner change) — same as denied for the caller: stop.
      return e.code == 'permission-denied' || e.code == 'not-found'
          ? ArrivalSendResult.denied
          : ArrivalSendResult.failed;
    } catch (_) {
      return ArrivalSendResult.failed;
    }
  }
}
