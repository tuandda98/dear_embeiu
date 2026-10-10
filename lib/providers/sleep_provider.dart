import 'dart:async';

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
  /// that ended yesterday (tonight's isn't over yet).
  static String lastNightKey([DateTime? now]) {
    final n = now ?? DateTime.now();
    final day = n.hour < 4 ? DateTime(n.year, n.month, n.day - 1) : n;
    return sleepDateKey(day);
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
      _settings = await _service.loadSettings(myUid);
      _local = await _service.loadNights(myUid);
      if (_uid != myUid) {
        return; // switched again while loading
      }
      _supported = await SleepPlatform.isSupported();
      // Known before the first frame, so Android doesn't flash "permission
      // needed" (A2) until the first scan finishes.
      _permission = await SleepPlatform.hasPermission();
      _loaded = true;
    }
    if (!sameCouple) {
      _hydrated = false;
      _fingerprints = await _service.loadFingerprints(myUid, coupleId);
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
    _settings = const SleepSettings();
    _loaded = false;
    _local = <String, SleepNight?>{};
    _fingerprints = <String, String>{};
    _myProfile = null;
    _partnerProfile = null;
    _partnerNights = const <String, SleepNight>{};
    _hydrated = false;
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
    _myProfileSub = _service.watchProfile(coupleId, uid).listen((profile) {
      _myProfile = profile;
      notifyListeners();
      if (profile?.share == true && !_hydrated) {
        _hydrated = true;
        unawaited(_hydrateFromRemote());
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
      if (_merge(computed)) {
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

  /// Folds freshly computed nights into the store. Never touches a night the
  /// user edited, logged or deleted; never replaces data with "no data".
  bool _merge(Map<String, SleepNight?> computed) {
    var changed = false;
    computed.forEach((date, night) {
      if (night == null) {
        return;
      }
      if (_local.containsKey(date)) {
        final existing = _local[date];
        if (existing == null || existing.isLabeled || existing.sameAs(night)) {
          return;
        }
      }
      _local[date] = night;
      changed = true;
    });
    return changed;
  }

  // ── Sharing ───────────────────────────────────────────────────────────────

  bool get _canShare =>
      _service.isUsingFirebase && _coupleId != null && _uid != null;

  /// Pushes changed nights of the editable window while sharing. Older nights
  /// are frozen remotely (rules), so they are left alone.
  Future<void> _syncRecent() async {
    if (!_canShare || !myShare) {
      return;
    }
    final coupleId = _coupleId!;
    final uid = _uid!;
    final cutoff = sleepDateKey(
      DateTime.now().subtract(const Duration(days: kSleepEditableDays)),
    );
    var dirty = false;
    for (final entry in _local.entries) {
      if (entry.key.compareTo(cutoff) < 0) {
        continue;
      }
      final night = entry.value;
      if (night == null) {
        if (_fingerprints.remove(entry.key) != null) {
          dirty = true;
          unawaited(_quiet(_service.deleteNight(coupleId, uid, entry.key)));
        }
      } else if (_fingerprints[entry.key] != night.fingerprint) {
        _fingerprints[entry.key] = night.fingerprint;
        dirty = true;
        unawaited(_quiet(_service.putNight(coupleId, uid, night)));
      }
    }
    if (dirty) {
      await _service.saveFingerprints(uid, coupleId, _fingerprints);
    }
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
    notifyListeners();
    await _service.setProfile(coupleId, uid, share: share, color: color);
    if (share) {
      await Future.wait([
        for (final night in myNights.values)
          _quiet(_service.putNight(coupleId, uid, night)),
      ]);
      _fingerprints = {
        for (final night in myNights.values) night.date: night.fingerprint,
      };
    } else {
      await _service.deleteAllNights(coupleId, uid);
      _fingerprints = <String, String>{};
    }
    await _service.saveFingerprints(uid, coupleId, _fingerprints);
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
      await _quiet(_service.setProfile(_coupleId!, uid, color: colorId));
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
    if (_canShare && _myProfile == null) {
      // Colour only: the profile stream may not have landed yet (fresh
      // install), and a merge must never switch an existing share off.
      await _quiet(_service.setProfile(_coupleId!, uid, color: color));
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
  /// one "manual". Throws when the night is outside the 7-day window.
  Future<void> saveNight(String date, DateTime bedAt, DateTime wakeAt) async {
    final uid = _uid;
    if (uid == null || !sleepNightEditable(date) || !wakeAt.isAfter(bedAt)) {
      throw StateError('not editable');
    }
    final existing = _local[date];
    final SleepNight night;
    if (existing == null) {
      night = SleepNight(
        date: date,
        bedAt: bedAt,
        wakeAt: wakeAt,
        source: SleepSource.manual,
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
