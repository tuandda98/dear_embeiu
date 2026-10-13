import 'dart:async';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';

import '../models/sleep_night.dart';
import '../services/sleep_platform.dart';
import '../services/sleep_service.dart';
import '../theme/person_palette.dart';
import '../utils/sleep_calculator.dart';

/// State for feature sleep ("Giấc ngủ của chúng mình", 2026-10-10): my nights
/// (computed on this phone, kept in Hive), my sharing flag + colour, and — only
/// while my partner shares — their nights from Firestore.
///
/// Lifecycle mirrors [MoodProvider]: `watchForCouple` is wired in
/// `session_resolver` and re-armed from HomeScreen; `clear` on sign-out /
/// no-couple. HomeScreen calls [onResume] so a night is re-scanned each time
/// the app comes back (no background work — design dev note 4).
class SleepProvider extends ChangeNotifier {
  SleepProvider({SleepService? service}) : _service = service ?? SleepService();

  final SleepService _service;

  /// Nights scanned on every refresh (Android keeps screen events ~1–2 weeks).
  static const int scanNights = 14;

  /// How far back the partner's shared nights are streamed.
  static const int _partnerHistoryDays = 400;

  String? _uid;
  String? _coupleId;
  String _partnerUid = '';

  /// While the phone was another account's (D7, L3): screen / Health data
  /// from then is theirs. Empty while the phone was always mine.
  List<({DateTime from, DateTime until})> _notMine = const [];

  SleepSettings _settings = const SleepSettings();
  bool _loaded = false;
  bool _supported = false;
  bool _permission = false;
  bool _scanning = false;

  Map<String, SleepNight?> _local = <String, SleepNight?>{};
  Map<String, String> _fingerprints = <String, String>{};

  SleepProfile? _myProfile;
  SleepProfile? _partnerProfile;
  Map<String, SleepNight> _partnerNights = const <String, SleepNight>{};
  bool _partnerLoadFailed = false;
  bool _hydrated = false;
  bool _myProfileLoaded = false;

  /// Share on/off writes run one after another, so a quick off→on can't let
  /// the "delete everything" land after the re-upload.
  Future<void> _shareOps = Future<void>.value();

  /// The share value last asked for, until its write lands: the profile
  /// stream must not flip the switch back to an older value meanwhile.
  bool? _pendingShare;
  int _shareSeq = 0;
  SleepProfile? _remoteProfile;
  bool _clearingShared = false;

  /// Fingerprint of a night whose upload is on its way.
  static const String _kPushing = 'pushing';

  /// Kept in the fingerprint map while "delete everything" runs. It survives
  /// the app being killed: the next launch then knows the server holds
  /// anything between none and all of my nights.
  static const String _kWiping = '~wiping';

  StreamSubscription<SleepProfile?>? _myProfileSub;
  StreamSubscription<SleepProfile?>? _partnerProfileSub;
  StreamSubscription<Map<String, SleepNight>>? _partnerNightsSub;

  // ── Read side ─────────────────────────────────────────────────────────────

  /// Local data loaded (drives the first-load skeleton).
  bool get isLoaded => _loaded;
  bool get isUsingFirebase => _service.isUsingFirebase;
  bool get enabled => _settings.enabled;
  SleepMode get mode => _settings.mode;
  bool get platformSupported => _supported;
  bool get healthHintDismissed => _settings.healthHintDismissed;

  /// "Ẩn" was tapped on the setup card less than 30 days ago.
  bool get cardHidden {
    final until = _settings.hiddenUntil;
    return !enabled && until != null && DateTime.now().isBefore(until);
  }

  /// Android lost (or never got) Usage access while in automatic mode — A2.
  bool get needsPermission => enabled && mode == SleepMode.auto && !_permission;

  /// iOS automatic mode but Health gave nothing for two weeks — state M.
  bool get healthHasNoData {
    if (!enabled || mode != SleepMode.health) {
      return false;
    }
    final cutoff = sleepDateKey(
      DateTime.now().subtract(const Duration(days: scanNights)),
    );
    return !_local.values.any(
      (n) =>
          n != null &&
          n.source == SleepSource.health &&
          n.date.compareTo(cutoff) >= 0,
    );
  }

  bool get hasPartner => _partnerUid.isNotEmpty;
  bool get myShare => _myProfile?.share ?? false;
  bool get partnerShares => hasPartner && (_partnerProfile?.share ?? false);

  /// My nights (deletion markers dropped).
  Map<String, SleepNight> get myNights => {
    for (final e in _local.entries)
      if (e.value != null) e.key: e.value!,
  };

  /// The partner's nights — empty unless they currently share.
  Map<String, SleepNight> get partnerNights =>
      partnerShares ? _partnerNights : const <String, SleepNight>{};

  String? get _myChoice => _myProfile?.color ?? _settings.localColor;

  ({String mine, String partner, bool mineAdjusted}) get _colors =>
      PersonPalette.resolve(
        myUid: _uid ?? '',
        myChoice: _myChoice,
        partnerUid: _partnerUid,
        partnerChoice: _partnerProfile?.color,
      );

  /// Colour ids actually drawn (rule C1 applied).
  String get myColorId => _colors.mine;
  String get partnerColorId => _colors.partner;

  /// My saved colour clashes with my partner's and I sort after them, so a
  /// stand-in colour is shown (subtitle `sleepColorAutoChanged`).
  bool get myColorAdjusted => hasPartner && _colors.mineAdjusted;

  /// The partner's raw choice (what the colour picker locks around).
  String? get partnerColorChoice => hasPartner ? _partnerProfile?.color : null;

  /// "Đêm qua": the night that ended this morning — or, before 4 am, the one
  /// that ended yesterday (tonight's isn't over yet). Scans stop at the same
  /// night ([recentWakeDates]).
  static String lastNightKey([DateTime? now]) =>
      sleepDateKey(lastWakeDate(now ?? DateTime.now()));

  /// "Đêm qua" on the partner's clock (audit D2): a partner abroad wakes up on
  /// their own date. Uses the tz of their latest night; [lastNightKey] when
  /// that night has none (saved before 1.9.1).
  String partnerLastNightKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    String? latest;
    for (final key in partnerNights.keys) {
      if (latest == null || key.compareTo(latest) > 0) {
        latest = key;
      }
    }
    final tz = latest == null ? null : partnerNights[latest]?.tz;
    return lastNightKey(tz == null ? n : n.toUtc().add(Duration(minutes: tz)));
  }

  /// One-shot flag for the "couldn't load your person's sleep" SnackBar.
  bool consumePartnerLoadFailed() {
    final failed = _partnerLoadFailed;
    _partnerLoadFailed = false;
    return failed;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Starts (or re-arms) everything for this couple. No-ops when unchanged.
  /// [partnerUid] is '' while the couple is still waiting for a partner.
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
    final sameCouple = sameUser && _coupleId == coupleId;
    _coupleId = coupleId;
    _uid = myUid;
    _partnerUid = partnerUid;

    if (!sameUser) {
      _loaded = false;
      _local = <String, SleepNight?>{};
      _settings = const SleepSettings();
      notifyListeners();
      final settings = await _service.loadSettings(myUid);
      final nights = await _service.loadNights(myUid);
      final notMine = await _service.claimDevice(myUid);
      final supported = await SleepPlatform.isSupported();
      // Known before the first frame, so Android doesn't flash "permission
      // needed" (A2) until the first scan finishes.
      final permission = await SleepPlatform.hasPermission();
      if (_uid != myUid) {
        return; // account switched while loading — never mix two users' data
      }
      _settings = settings;
      _local = nights;
      _notMine = notMine;
      _supported = supported;
      _permission = permission;
      _loaded = true;
    }
    if (!sameCouple) {
      _hydrated = false;
      _myProfileLoaded = false;
      // Another couple: none of the old one's sharing state carries over —
      // and the old couple's profile stream must not land in between.
      _myProfileSub?.cancel();
      _myProfileSub = null;
      _clearingShared = false;
      _myProfile = null;
      _remoteProfile = null;
      _pendingShare = null;
      _shareSeq++;
      _shareOps = Future<void>.value();
      final fingerprints = await _service.loadFingerprints(myUid, coupleId);
      if (_uid != myUid || _coupleId != coupleId) {
        return;
      }
      _fingerprints = fingerprints;
      _watchMyProfile();
    }
    _watchPartner();
    notifyListeners();
    await refresh();
  }

  void clear() {
    _cancelSubs();
    _uid = null;
    _coupleId = null;
    _partnerUid = '';
    _notMine = const [];
    _settings = const SleepSettings();
    _loaded = false;
    _local = <String, SleepNight?>{};
    _fingerprints = <String, String>{};
    _myProfile = null;
    _remoteProfile = null;
    _partnerProfile = null;
    _partnerNights = const <String, SleepNight>{};
    _hydrated = false;
    _myProfileLoaded = false;
    // A write of the previous account still waiting must not hold this one's.
    _shareOps = Future<void>.value();
    _pendingShare = null;
    _shareSeq++;
    _clearingShared = false;
    notifyListeners();
  }

  /// App came back to the foreground: re-check Usage access (the user may be
  /// returning from Settings) and re-scan.
  Future<void> onResume() => refresh();

  void _watchMyProfile() {
    _myProfileSub?.cancel();
    final coupleId = _coupleId;
    final uid = _uid;
    if (coupleId == null || uid == null || !_service.isUsingFirebase) {
      return;
    }
    // Metadata-only events (pending write acked, cache → server) carry
    // nothing new for my own profile; the partner's stream keeps them, they
    // re-arm its nights stream.
    _myProfileSub = _service
        .watchProfile(coupleId, uid)
        .distinct(
          (a, b) =>
              (a == null) == (b == null) &&
              a?.share == b?.share &&
              a?.color == b?.color,
        )
        .listen((profile) {
          _remoteProfile = profile;
          final pending = _pendingShare;
          _myProfile = pending == null
              ? profile
              : SleepProfile(
                  share: pending,
                  color: profile?.color ?? _myChoice,
                );
          _myProfileLoaded = true;
          notifyListeners();
          if (!myShare) {
            // Not shared, yet this phone still has nights marked as up there: a
            // delete that died with the app, or a partner leaving (the CF turned
            // sharing off). Finish the job so "off" really means deleted.
            if (pending == null && _fingerprints.isNotEmpty) {
              _clearShared(coupleId, uid);
            }
            return;
          }
          // A share change of mine is on its way: it uploads once its flag has
          // landed. Pushing here would queue nights ahead of a quick "off".
          if (pending != null) {
            // Read-only: a new phone still gets my history back.
            if (!_hydrated && _fingerprints.isEmpty) {
              _hydrated = true;
              unawaited(_hydrateFromRemote());
            }
            return;
          }
          // A wipe died with the app, then sharing came back on: the server holds
          // some or none of my nights — pull what's there, push the rest.
          if (_fingerprints.remove(_kWiping) != null) {
            _hydrated = false;
            unawaited(_service.saveFingerprints(uid, coupleId, _fingerprints));
          }
          // Cold start: the scan may finish before this lands and skip the upload,
          // so sync here too (fingerprints skip what's already up). Pull my own
          // shared history back first only when this device knows nothing about
          // it (reinstall / new phone) — not on every launch.
          if (!_hydrated && _fingerprints.isEmpty) {
            _hydrated = true;
            unawaited(_hydrateFromRemote().then((_) => _syncRecent()));
          } else {
            unawaited(_syncRecent());
          }
        }, onError: (_) {});
  }

  void _watchPartner() {
    _partnerProfileSub?.cancel();
    _partnerNightsSub?.cancel();
    _partnerNightsSub = null;
    _partnerProfile = null;
    _partnerNights = const <String, SleepNight>{};
    final coupleId = _coupleId;
    if (coupleId == null || !hasPartner || !_service.isUsingFirebase) {
      return;
    }
    _partnerProfileSub = _service.watchProfile(coupleId, _partnerUid).listen((
      profile,
    ) {
      _partnerProfile = profile;
      if (profile?.share == true) {
        _watchPartnerNights();
      } else {
        // Rules stop the reads anyway; drop what we had right away.
        _partnerNightsSub?.cancel();
        _partnerNightsSub = null;
        _partnerNights = const <String, SleepNight>{};
      }
      notifyListeners();
    }, onError: (_) {});
  }

  void _watchPartnerNights() {
    final coupleId = _coupleId;
    if (_partnerNightsSub != null || coupleId == null) {
      return;
    }
    final since = sleepDateKey(
      DateTime.now().subtract(const Duration(days: _partnerHistoryDays)),
    );
    _partnerNightsSub = _service
        .watchNights(coupleId, _partnerUid, sinceKey: since)
        .listen(
          (nights) {
            _partnerNights = nights;
            notifyListeners();
          },
          onError: (_) {
            _partnerLoadFailed = true;
            notifyListeners();
          },
          // Ends after a permission-denied (sharing just turned off); a later
          // `share: true` must be able to subscribe again.
          onDone: () => _partnerNightsSub = null,
        );
  }

  void _cancelSubs() {
    _myProfileSub?.cancel();
    _partnerProfileSub?.cancel();
    _partnerNightsSub?.cancel();
    _myProfileSub = null;
    _partnerProfileSub = null;
    _partnerNightsSub = null;
  }

  // ── Scanning ──────────────────────────────────────────────────────────────

  /// Re-reads the automatic source and merges the last [scanNights] nights.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null || !_loaded || _scanning) {
      return;
    }
    _scanning = true;
    try {
      _permission = await SleepPlatform.hasPermission();
      if (!enabled) {
        return;
      }
      final now = DateTime.now();
      final dates = recentWakeDates(now, scanNights);
      // Start 12 h before the first window so its opening state is known.
      final from = sleepWindow(
        dates.first,
      ).start.subtract(const Duration(hours: 12));
      Map<String, SleepNight?> computed = const {};
      if (mode == SleepMode.auto && SleepPlatform.isAndroid && _permission) {
        computed = computeScreenNights(
          await SleepPlatform.screenEvents(from, now),
          wakeDates: dates,
          now: now,
        );
      } else if (mode == SleepMode.health && SleepPlatform.isIOS) {
        computed = computeHealthNights(
          await SleepPlatform.healthSamples(from, now),
          wakeDates: dates,
          now: now,
        );
      }
      if (_uid != uid) {
        return;
      }
      if (mergeComputed(_local, computed, now: now, notMine: _notMine)) {
        await _service.saveNights(uid, _local);
      }
      await _syncRecent();
    } catch (_) {
      // A failed scan leaves the stored nights as they were.
    } finally {
      _scanning = false;
      notifyListeners();
    }
  }

  /// Folds freshly computed nights into [local]; true when it changed. Never
  /// touches a night the user edited, logged or deleted; never replaces data
  /// with "no data". After a flight the same screen events land in other
  /// windows, so a night recorded on another clock stays as it is — only a
  /// later scan of that same sleep (today or yesterday), no shorter at either
  /// end, updates it, keeping its clock — and a new night that overlaps one
  /// stored under another date is that same sleep: dropped. Nights on this
  /// phone's clock are measured again like in 1.8.0; ones saved before 1.9.1
  /// (clock unknown) are settled once older than yesterday. Nights that ended
  /// while the phone was another account's ([notMine], D7) are theirs.
  @visibleForTesting
  static bool mergeComputed(
    Map<String, SleepNight?> local,
    Map<String, SleepNight?> computed, {
    required DateTime now,
    List<({DateTime from, DateTime until})> notMine = const [],
  }) {
    final yesterday = sleepDateKey(DateTime(now.year, now.month, now.day - 1));
    var changed = false;
    computed.forEach((date, night) {
      if (night == null ||
          notMine.any(
            (s) =>
                !night.wakeAt.isBefore(s.from) &&
                night.wakeAt.isBefore(s.until),
          )) {
        return;
      }
      var fresh = night;
      if (local.containsKey(date)) {
        final existing = local[date];
        if (existing == null || existing.isLabeled) {
          return;
        }
        final tz = existing.tz;
        final overlaps = existing.overlapWith(night) > 0;
        final otherClock =
            tz != null &&
            existing.bedAt.toLocal().timeZoneOffset.inMinutes != tz;
        if (((otherClock || tz == null) && date.compareTo(yesterday) < 0) ||
            (otherClock && !overlaps)) {
          return;
        }
        // Scanned here, a night from another clock comes back cut at this
        // clock's window edge (Vietnam 22:00 = 17:00 in Berlin, before the
        // 18:00 start → "23:00"): only a scan as long at both ends updates it
        // (audit N-L1).
        if (otherClock &&
            (night.bedAt.isAfter(existing.bedAt) ||
                night.wakeAt.isBefore(existing.wakeAt))) {
          return;
        }
        if (tz != null && overlaps) {
          fresh = night.copyWith(tz: tz);
        }
        if (existing.sameAs(fresh)) {
          return;
        }
      }
      final seenElsewhere = local.entries.any(
        (e) =>
            e.key != date && e.value != null && e.value!.overlapWith(fresh) > 0,
      );
      if (seenElsewhere) {
        return;
      }
      local[date] = fresh;
      changed = true;
    });
    return changed;
  }

  // ── Sharing ───────────────────────────────────────────────────────────────

  bool get _canShare =>
      _service.isUsingFirebase && _coupleId != null && _uid != null;

  /// Pushes my nights while sharing (see [planSync]).
  Future<void> _syncRecent() async {
    // A share change still on its way uploads once its flag has landed.
    if (!_canShare || !myShare || _pendingShare != null) {
      return;
    }
    final coupleId = _coupleId!;
    final uid = _uid!;
    final plan = planSync(
      _local,
      _fingerprints,
      sleepDateKey(
        DateTime.now().subtract(const Duration(days: kSleepEditableDays)),
      ),
    );
    for (final date in plan.deletes) {
      unawaited(
        _service
            .deleteNight(coupleId, uid, date)
            // Rejected = never created or out of reach: nothing to undo.
            .whenComplete(() => _markSynced(uid, coupleId, date, null))
            .catchError((_) {}),
      );
    }
    if (plan.pushes.isEmpty) {
      return;
    }
    await _markPushing(uid, coupleId, plan.pushes);
    for (final night in plan.pushes.where(_stillLocal)) {
      // The real fingerprint only once the write lands: a failed put of a
      // recent night is retried on the next sync.
      unawaited(
        _put(coupleId, uid, night)
            .then(
              (_) => _markSynced(uid, coupleId, night.date, night.fingerprint),
            )
            .catchError((_) {}),
      );
    }
  }

  /// What a sync sends. Inside the editable window (dates >= [cutoff]):
  /// nights whose fingerprint changed, and deletes for nights that went up or
  /// are on their way. Older: only nights that never went up (sharing turned
  /// on, app killed before the upload) — the ones already up are frozen
  /// remotely (rules).
  @visibleForTesting
  static ({List<SleepNight> pushes, List<String> deletes}) planSync(
    Map<String, SleepNight?> local,
    Map<String, String> fingerprints,
    String cutoff,
  ) {
    final pushes = <SleepNight>[];
    final deletes = <String>[];
    local.forEach((date, night) {
      final known = fingerprints.containsKey(date);
      if (date.compareTo(cutoff) < 0) {
        if (night != null && !known) {
          pushes.add(night);
        }
      } else if (night == null) {
        if (known) {
          deletes.add(date);
        }
      } else if (fingerprints[date] != night.fingerprint) {
        pushes.add(night);
      }
    });
    return (pushes: pushes, deletes: deletes);
  }

  /// Rules from before 1.9.1 (PROD until they're deployed) refuse `tz`: the
  /// night goes once more without it, else a refused night older than 7 days
  /// would stay marked "pushing" for good. The new rules take the first try.
  Future<void> _put(String coupleId, String uid, SleepNight night) => _service
      .putNight(coupleId, uid, night)
      .catchError(
        (Object _) => _service.putNight(
          coupleId,
          uid,
          SleepNight(
            date: night.date,
            bedAt: night.bedAt,
            wakeAt: night.wakeAt,
            wakeUps: night.wakeUps,
            source: night.source,
          ),
        ),
        test: (e) =>
            night.tz != null &&
            e is FirebaseException &&
            e.code == 'permission-denied',
      );

  /// Deleted or edited while the markers were being saved: the sync that made
  /// that change sends its own write, this stale one must not follow it.
  bool _stillLocal(SleepNight night) =>
      _local[night.date]?.fingerprint == night.fingerprint;

  /// Server says "not shared" but nights may still sit there: delete them all
  /// (one run at a time, queued with the share changes).
  void _clearShared(String coupleId, String uid) {
    if (_clearingShared) {
      return;
    }
    _clearingShared = true;
    _shareOps = _shareOps
        .then((_) => _wipe(coupleId, uid))
        .catchError((_) {})
        .whenComplete(() => _clearingShared = false);
  }

  /// Deletes every shared night. The fingerprints go first (with the
  /// [_kWiping] mark), so a wipe cut short by a killed app can't leave this
  /// phone believing nights are still up when sharing comes back on.
  Future<void> _wipe(String coupleId, String uid) async {
    bool current() => _uid == uid && _coupleId == coupleId;
    if (current()) {
      _fingerprints
        ..clear()
        ..[_kWiping] = '1';
      await _service.saveFingerprints(uid, coupleId, _fingerprints);
    }
    await _service.deleteAllNights(coupleId, uid);
    if (current()) {
      _fingerprints.remove(_kWiping);
      await _service.saveFingerprints(uid, coupleId, _fingerprints);
    }
  }

  /// Marks nights as on their way up BEFORE writing them, so a delete issued
  /// before the ack still goes out (it checks `containsKey`).
  Future<void> _markPushing(
    String uid,
    String coupleId,
    List<SleepNight> nights,
  ) async {
    for (final night in nights) {
      _fingerprints[night.date] = _kPushing;
    }
    await _service.saveFingerprints(uid, coupleId, _fingerprints);
  }

  Future<void> _markSynced(
    String uid,
    String coupleId,
    String date,
    String? fingerprint,
  ) async {
    if (_uid != uid || _coupleId != coupleId) {
      return;
    }
    if (fingerprint == null) {
      _fingerprints.remove(date);
    } else {
      _fingerprints[date] = fingerprint;
    }
    await _service.saveFingerprints(uid, coupleId, _fingerprints);
  }

  /// Reinstall / new phone while sharing: pull my own shared nights back.
  Future<void> _hydrateFromRemote() async {
    final coupleId = _coupleId;
    final uid = _uid;
    if (coupleId == null || uid == null) {
      return;
    }
    try {
      final remote = await _service.fetchNights(coupleId, uid);
      if (_uid != uid || _coupleId != coupleId) {
        return; // signed out meanwhile: these nights aren't the new account's
      }
      var changed = false;
      remote.forEach((date, night) {
        _fingerprints[date] = night.fingerprint;
        if (!_local.containsKey(date)) {
          _local[date] = night;
          changed = true;
        }
      });
      await _service.saveFingerprints(uid, coupleId, _fingerprints);
      if (changed && _uid == uid) {
        await _service.saveNights(uid, _local);
        notifyListeners();
      }
    } catch (_) {
      // Offline: the next refresh retries nothing, which is fine — the data
      // is still on Firestore.
    }
  }

  /// Share on → profile flag first (rules read it), then the whole history.
  /// Share off → flag first, then every shared night is deleted.
  Future<void> setShare(bool share) async {
    if (!_canShare) {
      return;
    }
    final coupleId = _coupleId!;
    final uid = _uid!;
    final color = _myChoice ?? myColorId;
    _myProfile = SleepProfile(share: share, color: color);
    _pendingShare = share;
    final seq = ++_shareSeq;
    notifyListeners();
    // The flag goes into Firestore's own write queue right away: that queue
    // keeps the order of the taps and survives the app being killed. Held in
    // memory behind a slow "on", an "off" would die with the app and the
    // "on" would win.
    final flag = _service.setProfile(coupleId, uid, share: share, color: color);
    unawaited(flag.catchError((_) {})); // awaited (and handled) below
    // Nights follow one share change at a time, so a quick off→on can't let
    // the "delete everything" land after the re-upload. Never awaited by the
    // UI: offline, Firestore only acks once back online.
    _shareOps = _shareOps
        .then((_) => _applyShare(coupleId, uid, share, flag).catchError((_) {}))
        .whenComplete(() {
          if (seq != _shareSeq) {
            return; // a newer tap (or another account) took over
          }
          // Back to what the server holds — the old value if it refused.
          _pendingShare = null;
          _myProfile = _remoteProfile ?? _myProfile;
          notifyListeners();
          unawaited(_syncRecent()); // edits made while it was pending
        });
  }

  Future<void> _applyShare(
    String coupleId,
    String uid,
    bool share,
    Future<void> flag,
  ) async {
    // The flag lands first, in its own commit: the rules read it with get().
    await flag;
    bool current() => _uid == uid && _coupleId == coupleId;
    if (!share) {
      await _wipe(coupleId, uid);
      return;
    }
    if (!current()) {
      return; // signed out meanwhile: never push another account's nights
    }
    final nights = myNights.values.toList();
    await _markPushing(uid, coupleId, nights);
    await Future.wait([
      for (final night in nights.where(_stillLocal))
        _quiet(
          _put(coupleId, uid, night).then<void>((_) {
            if (current()) {
              _fingerprints[night.date] = night.fingerprint;
            }
          }),
        ),
    ]);
    if (current()) {
      await _service.saveFingerprints(uid, coupleId, _fingerprints);
    }
  }

  Future<void> setColor(String colorId) async {
    final uid = _uid;
    if (uid == null || !PersonPalette.isValid(colorId)) {
      return;
    }
    final partner = partnerColorChoice;
    if (partner != null && PersonPalette.clashes(colorId, partner)) {
      return;
    }
    _settings = _settings.copyWith(localColor: colorId);
    _myProfile = SleepProfile(share: myShare, color: colorId);
    notifyListeners();
    await _service.saveSettings(uid, _settings);
    if (_canShare) {
      unawaited(_quiet(_service.setProfile(_coupleId!, uid, color: colorId)));
    }
  }

  // ── Setup / settings ──────────────────────────────────────────────────────

  /// Finishes the setup sheet. The first member to set up gets Rose, the
  /// second the first colour that doesn't clash (Purple next to Rose).
  Future<void> enableTracking(SleepMode mode) async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    final color =
        _myChoice ?? PersonPalette.firstFreeAgainst(_partnerProfile?.color);
    _settings = _settings.copyWith(
      enabled: true,
      mode: mode,
      clearHidden: true,
      localColor: color,
    );
    notifyListeners();
    await _service.saveSettings(uid, _settings);
    // Colour only, and only once the stream proved there's no profile yet — a
    // merge must never switch an existing share off or overwrite a colour
    // that simply hasn't loaded. Not awaited (offline would block the sheet).
    if (_canShare && _myProfileLoaded && _myProfile == null) {
      unawaited(_quiet(_service.setProfile(_coupleId!, uid, color: color)));
    }
    await refresh();
  }

  /// Android: opens Usage access settings (granted state arrives on resume).
  /// iOS: shows the Health prompt.
  Future<bool> requestPermission() async {
    final ok = await SleepPlatform.requestPermission();
    _permission = await SleepPlatform.hasPermission();
    notifyListeners();
    return ok || _permission;
  }

  /// Re-checks Usage access without scanning (setup sheet polling on resume).
  Future<bool> checkPermission() async {
    _permission = await SleepPlatform.hasPermission();
    notifyListeners();
    return _permission;
  }

  Future<void> openPermissionSettings() => SleepPlatform.openSettings();

  Future<void> hideCard() async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    _settings = _settings.copyWith(
      hiddenUntil: DateTime.now().add(const Duration(days: 30)),
    );
    notifyListeners();
    await _service.saveSettings(uid, _settings);
  }

  Future<void> dismissHealthHint() async {
    final uid = _uid;
    if (uid == null) {
      return;
    }
    _settings = _settings.copyWith(healthHintDismissed: true);
    notifyListeners();
    await _service.saveSettings(uid, _settings);
  }

  // ── Editing (R1–R4) ───────────────────────────────────────────────────────

  /// Saves my night for [date]: an existing night becomes "edited", an empty
  /// one "manual". Throws when the night is outside the 7-day window. The
  /// night keeps the clock the times were picked on (D2): [tz] for a night
  /// from a trip, else this phone's.
  Future<void> saveNight(
    String date,
    DateTime bedAt,
    DateTime wakeAt, {
    int? tz,
  }) async {
    final uid = _uid;
    if (uid == null || !sleepNightEditable(date) || !wakeAt.isAfter(bedAt)) {
      throw StateError('not editable');
    }
    tz ??= bedAt.toLocal().timeZoneOffset.inMinutes;
    final existing = _local[date];
    final SleepNight night;
    if (existing == null) {
      night = SleepNight(
        date: date,
        bedAt: bedAt,
        wakeAt: wakeAt,
        source: SleepSource.manual,
        tz: tz,
      );
    } else {
      // Keep the wake-ups that still fall inside the new times.
      final kept = <int>[];
      for (final m in existing.wakeUps) {
        final t = existing.bedAt.add(Duration(minutes: m));
        if (t.isAfter(bedAt) && t.isBefore(wakeAt)) {
          kept.add(t.difference(bedAt).inMinutes);
        }
      }
      night = SleepNight(
        date: date,
        bedAt: bedAt,
        wakeAt: wakeAt,
        wakeUps: kept,
        source: existing.source == SleepSource.manual
            ? SleepSource.manual
            : SleepSource.edited,
        tz: tz,
      );
    }
    _local[date] = night;
    notifyListeners();
    await _service.saveNights(uid, _local);
    await _syncRecent();
  }

  /// Deletes my night for [date]; the marker stops the next scan from
  /// bringing it back.
  Future<void> deleteNight(String date) async {
    final uid = _uid;
    if (uid == null || !sleepNightEditable(date)) {
      throw StateError('not editable');
    }
    _local[date] = null;
    notifyListeners();
    await _service.saveNights(uid, _local);
    await _syncRecent();
  }

  static Future<void> _quiet(Future<void> f) => f.catchError((_) {});

  @override
  void dispose() {
    _cancelSubs();
    super.dispose();
  }
}
