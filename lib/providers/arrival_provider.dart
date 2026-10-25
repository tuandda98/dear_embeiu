import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/arrival.dart';
import '../services/arrival_platform.dart';
import '../services/arrival_service.dart';

/// State for feature arrival ("Về đến nhà chưa?", đợt 2): my places (Hive
/// only, D2), my sharing doc, my partner's latest event, and the manual
/// "Về nhà rồi" / "Đến nơi rồi" path (D7).
///
/// Lifecycle like [SleepProvider]: `watchForCouple` from `session_resolver`
/// (partner uid '' while the couple waits → [visible] false, D9), `clear` on
/// sign-out / no couple. Stage 3: HomeScreen re-arms it with the live couple
/// and calls [onResume] (permission re-check, D8).
class ArrivalProvider extends ChangeNotifier {
  ArrivalProvider({
    ArrivalService? service,
    ArrivalGeofence geofence = const NoopArrivalGeofence(),
    BatteryReader battery = const NoopBatteryReader(),
    this.placeSearch = const NoopPlaceSearch(),
    this.permissions = const NoopArrivalPermissions(),
    this.location = const NoopCurrentLocationReader(),
    bool? autoBuildAllowed,
  }) : _service = service ?? ArrivalService(),
       _geofence = geofence,
       _battery = battery,
       _autoBuildAllowed = autoBuildAllowed;

  final ArrivalService _service;
  final ArrivalGeofence _geofence;
  final BatteryReader _battery;
  final bool? _autoBuildAllowed;

  /// OS pieces the place / setup screens call directly (contract in
  /// `arrival_platform.dart`); `main.dart` passes the real ones.
  final PlaceSearch placeSearch;
  final ArrivalPermissions permissions;
  final CurrentLocationReader location;

  String? _uid;
  String? _coupleId;
  String _partnerUid = '';

  bool _loaded = false;
  List<ArrivalPlace> _places = const [ArrivalPlace.home()];
  bool _wantsAuto = false;
  bool _everShared = false;

  /// Partner "Tự báo" was switched on for (Hive). Null = unknown / off.
  String? _autoPartner;
  bool _remoteAuto = true;
  bool _hasAlways = false;

  ArrivalShare? _mine;
  ArrivalShare? _partner;

  bool _sending = false;
  ArrivalSendResult? _lastResult;
  String? _lastSlot;

  /// When the last manual send started — a server-acked `last` at or after
  /// it ends the "queued" state.
  DateTime? _sentAt;

  /// Custom slots kept free while their delete can still be undone (5 s),
  /// so a new place can't take the slot (or the last free one) meanwhile.
  final Map<String, Timer> _heldSlots = {};

  StreamSubscription<ArrivalShare?>? _mineSub;
  StreamSubscription<ArrivalShare?>? _partnerSub;

  // ── Read side ─────────────────────────────────────────────────────────────

  /// Only for an active couple (D9): no card, no settings row otherwise.
  bool get visible => _coupleId != null && _partnerUid.isNotEmpty;
  bool get isLoaded => _loaded;

  /// Home first, then custom places in slot order.
  List<ArrivalPlace> get places => _places;
  ArrivalPlace get home => _places.first;
  List<ArrivalPlace> get customPlaces => _places.skip(1).toList();
  List<ArrivalPlace> get placesWithLocation =>
      _places.where((p) => p.location != null).toList();

  bool get canAddPlace =>
      customPlaces.length + _heldSlots.length < kArrivalMaxCustom;

  /// Free slot for a new custom place; null when all 4 are taken.
  String? get nextFreeSlot {
    final used = {for (final p in _places) p.slot};
    for (final slot in kArrivalSlots.skip(1)) {
      if (!used.contains(slot) && !_heldSlots.containsKey(slot)) return slot;
    }
    return null;
  }

  bool get myShare => _mine?.share ?? false;

  /// Sharing was on at least once (Hive): "Bật lại…" vs "Bật để…".
  bool get everShared => _everShared || myShare;
  ArrivalEvent? get myLast => _mine?.last;

  bool get partnerShares => visible && (_partner?.share ?? false);
  bool get partnerAuto => partnerShares && (_partner?.auto ?? false);

  /// Null unless the partner shares (rules keep `last` off otherwise).
  ArrivalEvent? get partnerLast => partnerShares ? _partner?.last : null;

  /// The user switched "Tự báo khi mình đến nơi" on.
  bool get wantsAuto => _wantsAuto;

  /// Build constants (D13) + `config/app.arrivalAutoEnabled`.
  bool get autoAvailable =>
      (_autoBuildAllowed ?? arrivalAutoBuildAllowed) && _remoteAuto;

  /// Switched off remotely: the card says "Tạm thời chỉ báo bằng tay".
  bool get autoRemoteOff => _wantsAuto && !_remoteAuto;

  /// Wants auto but lacks "Luôn luôn" (card: "Chưa tự báo được…", D8 step 4).
  bool get needsAlways =>
      _wantsAuto &&
      autoAvailable &&
      !_hasAlways &&
      placesWithLocation.isNotEmpty;

  /// Geofences are (or should be) running right now.
  bool get autoRunning =>
      myShare &&
      _wantsAuto &&
      autoAvailable &&
      _hasAlways &&
      placesWithLocation.isNotEmpty;

  bool get sending => _sending;

  /// Outcome of the last manual send (queued → "Sẽ báo khi có mạng", failed →
  /// "Thử lại").
  ArrivalSendResult? get lastResult => _lastResult;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> watchForCouple(
    String coupleId,
    String myUid,
    String partnerUid,
  ) async {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }
    if (_coupleId == coupleId && _uid == myUid && _partnerUid == partnerUid) {
      return;
    }
    final sameUser = _uid == myUid;
    _coupleId = coupleId;
    _uid = myUid;
    _partnerUid = partnerUid;
    _cancelSubs();
    _mine = null;
    _partner = null;
    _lastResult = null;
    if (!sameUser) {
      _loaded = false;
      _sending = false;
      _places = const [ArrivalPlace.home()];
      notifyListeners();
      final places = await _service.loadPlaces(myUid);
      final wants = await _service.loadWantsAuto(myUid);
      final autoPartner = await _service.loadAutoPartner(myUid);
      final everShared = await _service.loadEverShared(myUid);
      if (_uid != myUid) return; // switched account while loading
      _places = places;
      _wantsAuto = wants;
      _everShared = everShared;
      _autoPartner = autoPartner;
      _loaded = true;
    }
    // Review native #1 (D10): "Tự báo" was switched on for someone else —
    // the new partner gets nothing until the user turns it on again.
    if (_wantsAuto && partnerUid.isNotEmpty && _autoPartner != partnerUid) {
      if (_autoPartner == null) {
        _autoPartner = partnerUid; // saved before partners were recorded
        await _service.saveWantsAuto(myUid, true, partnerUid: partnerUid);
      } else {
        _wantsAuto = false;
        _autoPartner = null;
        await _service.saveWantsAuto(myUid, false);
      }
    }
    if (!visible) {
      // Waiting for a partner: nobody to tell. Nothing runs.
      await _service.saveSession(myUid, null);
      await _geofence.stopAll();
      notifyListeners();
      return;
    }
    await _service.saveSession(myUid, coupleId);
    _mineSub = _service.watchShare(coupleId, myUid).handleError((_) {}).listen((
      s,
    ) {
      _mine = s;
      if (s?.share == true && !_everShared) {
        _everShared = true;
        unawaited(_service.saveEverShared(myUid).catchError((_) {}));
      }
      _clearQueuedIfAcked(s);
      notifyListeners();
      unawaited(_syncAuto());
    });
    _partnerSub = _service
        .watchShare(coupleId, partnerUid)
        .handleError((_) {})
        .listen((s) {
          _partner = s;
          notifyListeners();
        });
    notifyListeners();
    await onResume();
  }

  /// Drops the session and stops every geofence (nobody to send to).
  void clear({bool signedOut = false}) {
    final hadSession = _uid != null;
    _cancelSubs();
    _uid = null;
    _coupleId = null;
    _partnerUid = '';
    _loaded = false;
    _places = const [ArrivalPlace.home()];
    _wantsAuto = false;
    _everShared = false;
    _autoPartner = null;
    _mine = null;
    _partner = null;
    _sending = false;
    _lastResult = null;
    _lastSlot = null;
    _sentAt = null;
    _releaseAllSlots();
    if (hadSession) {
      unawaited(_geofence.stopAll());
      unawaited(_service.clearSession().catchError((_) {}));
    }
    notifyListeners();
  }

  /// App back in the foreground: re-read permission + remote switch, then
  /// start / stop geofences to match (D8: a permission lowered in Settings
  /// cancels them).
  Future<void> onResume() async {
    if (!visible) return;
    final always = await _geofence.hasAlwaysPermission();
    final remote = await _service.readRemoteAutoEnabled();
    _hasAlways = always;
    _remoteAuto = remote;
    notifyListeners();
    await _syncAuto();
  }

  // ── Places (this phone only, D2) ──────────────────────────────────────────

  /// Adds or replaces [place]. False when invalid (custom without a valid
  /// name, a 5th custom place, an unknown slot).
  Future<bool> savePlace(ArrivalPlace place) async {
    final uid = _uid;
    if (uid == null || !kArrivalSlots.contains(place.slot)) return false;
    var p = place;
    if (!p.isHome) {
      final name = normalizeArrivalName(p.name ?? '');
      if (name == null) return false;
      p = ArrivalPlace(
        slot: p.slot,
        name: name,
        icon: p.icon ?? ArrivalIcon.pin,
        location: p.location,
      );
    }
    final existing = _places.where((x) => x.slot == p.slot).firstOrNull;
    if (existing == null && !p.isHome && !canAddPlace) return false;
    _places = _sorted([
      for (final x in _places)
        if (x.slot != p.slot) x,
      p,
    ]);
    if (!identical(existing?.location, p.location)) {
      // A moved place starts with an unknown in/out state.
      await _service.clearEdge(uid, p.slot);
    }
    await _service.savePlaces(uid, _places);
    notifyListeners();
    await _syncAuto();
    return true;
  }

  /// Custom place → removed; Home → only its location goes (D19). Returns
  /// what was removed so the UI can undo for 5 s (Lead 2026-10-20) by
  /// calling [savePlace] with it.
  Future<ArrivalPlace?> deletePlace(String slot) async {
    final uid = _uid;
    final existing = _places.where((x) => x.slot == slot).firstOrNull;
    if (uid == null || existing == null) return null;
    _places = [
      for (final x in _places)
        if (x.slot != slot) x else if (x.isHome) x.withLocation(null),
    ];
    await _service.clearEdge(uid, slot);
    await _service.savePlaces(uid, _places);
    notifyListeners();
    await _syncAuto();
    return existing;
  }

  // ── Sharing ───────────────────────────────────────────────────────────────

  /// Off = my latest event leaves the server in the same write and every
  /// geofence stops (D11) — no push to the partner. [deletePlaces] also
  /// drops every saved location on this phone (names stay). Auto is switched
  /// off too: turning sharing back on never silently resumes location use.
  Future<ArrivalSendResult> setShare(
    bool on, {
    bool deletePlaces = false,
  }) async {
    final uid = _uid;
    final coupleId = _coupleId;
    if (uid == null || coupleId == null || !visible) {
      return ArrivalSendResult.dropped;
    }
    if (on) {
      return _service.send(
        () => _service.turnOn(coupleId, uid, auto: _autoWithShare),
      );
    }
    _wantsAuto = false;
    await _service.saveWantsAuto(uid, false);
    await _geofence.stopAll();
    if (deletePlaces) {
      _places = [for (final p in _places) p.withLocation(null)];
      for (final slot in kArrivalSlots) {
        await _service.clearEdge(uid, slot);
      }
      await _service.savePlaces(uid, _places);
    }
    notifyListeners();
    return _service.send(() => _service.turnOff(coupleId, uid));
  }

  /// "Tự báo khi mình đến nơi". The permission flow (D8) runs in the UI
  /// before this; geofences start once [autoRunning] holds.
  Future<void> setWantsAuto(bool value) async {
    final uid = _uid;
    if (uid == null) return;
    _wantsAuto = value;
    _autoPartner = value && _partnerUid.isNotEmpty ? _partnerUid : null;
    await _service.saveWantsAuto(uid, value, partnerUid: _autoPartner);
    notifyListeners();
    await onResume();
  }

  // ── Manual "Về nhà rồi" / "Đến nơi rồi" (D7) ─────────────────────────────

  /// No location permission needed, and works for a place with no location.
  /// Turns sharing on when it was off (design dev note).
  Future<ArrivalSendResult> sendManual([String slot = kArrivalHome]) async {
    final uid = _uid;
    final coupleId = _coupleId;
    if (uid == null || coupleId == null || !visible || _sending) {
      return ArrivalSendResult.dropped;
    }
    _sending = true;
    _lastSlot = slot;
    _sentAt = DateTime.now();
    notifyListeners();
    final battery = await _readBattery();
    final result = await _service.reportEvent(
      uid: uid,
      coupleId: coupleId,
      slot: slot,
      type: ArrivalEventType.enter,
      source: ArrivalEventSource.manual,
      auto: _autoWithShare,
      battery: battery,
    );
    if (_uid != uid) return result; // signed out meanwhile
    _sending = false;
    _lastResult = result;
    // The ack may have landed while we waited for the timeout.
    if (result == ArrivalSendResult.queued) _clearQueuedIfAcked(_mine);
    if (result == ArrivalSendResult.denied) {
      await _geofence.stopAll();
    }
    notifyListeners();
    return result;
  }

  /// Keeps [slot] free for [duration] (undo window of a deleted place).
  void holdSlot(String slot, Duration duration) {
    if (slot == kArrivalHome) return;
    _heldSlots.remove(slot)?.cancel();
    _heldSlots[slot] = Timer(duration, () => releaseSlot(slot));
    notifyListeners();
  }

  void releaseSlot(String slot) {
    final timer = _heldSlots.remove(slot);
    if (timer == null) return;
    timer.cancel();
    notifyListeners();
  }

  void _releaseAllSlots() {
    for (final t in _heldSlots.values) {
      t.cancel();
    }
    _heldSlots.clear();
  }

  void _clearQueuedIfAcked(ArrivalShare? s) {
    final sentAt = _sentAt;
    final last = s?.last;
    if (_lastResult != ArrivalSendResult.queued ||
        s == null ||
        s.pending ||
        last == null ||
        sentAt == null) {
      return;
    }
    // 1 s slack: `at` is taken a moment after [_sentAt] on this clock.
    if (!last.at.isBefore(sentAt.subtract(const Duration(seconds: 1)))) {
      _lastResult = null;
    }
  }

  /// "Thử lại" after a failed send.
  Future<ArrivalSendResult> retry() => sendManual(_lastSlot ?? kArrivalHome);

  // ── Internals ─────────────────────────────────────────────────────────────

  /// What `auto` will be once sharing is on.
  bool get _autoWithShare =>
      _wantsAuto &&
      autoAvailable &&
      _hasAlways &&
      placesWithLocation.isNotEmpty;

  Future<int?> _readBattery() async {
    try {
      final level = await _battery.level();
      return level?.clamp(0, 100);
    } catch (_) {
      return null; // D5/§5: battery optional
    }
  }

  /// Geofences + the `auto` flag the partner's card reads follow
  /// [autoRunning].
  Future<void> _syncAuto() async {
    final uid = _uid;
    final coupleId = _coupleId;
    if (uid == null || coupleId == null || !visible) return;
    final running = autoRunning;
    if (running) {
      await _geofence.sync(placesWithLocation);
    } else {
      await _geofence.stopAll();
    }
    final mine = _mine;
    if (mine != null && mine.share && mine.auto != running) {
      unawaited(_service.send(() => _service.setAuto(coupleId, uid, running)));
    }
  }

  static List<ArrivalPlace> _sorted(List<ArrivalPlace> places) => [...places]
    ..sort(
      (a, b) => kArrivalSlots.indexOf(a.slot) - kArrivalSlots.indexOf(b.slot),
    );

  void _cancelSubs() {
    _mineSub?.cancel();
    _mineSub = null;
    _partnerSub?.cancel();
    _partnerSub = null;
  }

  @override
  void dispose() {
    _releaseAllSlots();
    _cancelSubs();
    super.dispose();
  }
}
