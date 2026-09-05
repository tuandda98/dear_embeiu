import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/app_badge.dart';
import '../services/notification_inbox_service.dart';

/// State for the in-app notification center: streams the current couple's
/// notifications for the signed-in user, exposes the unread count (for the
/// AppBar bell badge), and handles mark-read / dismiss with optimistic updates.
class NotificationInboxProvider extends ChangeNotifier {
  NotificationInboxProvider({NotificationInboxService? service})
      : _service = service ?? NotificationInboxService();

  final NotificationInboxService _service;

  StreamSubscription<List<AppNotification>>? _subscription;
  String? _uid;
  String? _coupleId;
  List<AppNotification> _items = const <AppNotification>[];
  bool _isLoading = false;

  List<AppNotification> get items => _items;
  bool get isLoading => _isLoading;
  bool get isEmpty => _items.isEmpty;
  int get unreadCount => _items.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  /// Unread notifications whose tap target is [tab] (drives auto-read on tab open).
  int unreadForTab(int tab) => _items.where((n) => _autoReadsOn(n, tab)).length;

  /// Home auto-reads what the Home tab SHOWS. A care note isn't rendered on
  /// Home at all (only the bell), so it must stay unread until the center
  /// opens — otherwise the badge dies within one frame of arrival.
  static bool _autoReadsOn(AppNotification n, int tab) =>
      !n.read &&
      n.targetHomeTab == tab &&
      n.type != AppNotificationType.careMessage;

  /// Begins watching notifications for [coupleId] on behalf of [myUid]. Safe to
  /// call repeatedly: no-ops when the (couple, uid) pair is unchanged and
  /// already streaming, resubscribes when either changes.
  void watchForCouple(String coupleId, String myUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }

    if (_coupleId == coupleId && _uid == myUid && _subscription != null) {
      return;
    }

    _coupleId = coupleId;
    _uid = myUid;
    _items = const <AppNotification>[];
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _service.watch(myUid, coupleId).listen(
      (items) {
        _items = items;
        _isLoading = false;
        notifyListeners();
        // Keep the iOS app-icon badge in sync with the real unread count. The
        // stream re-emits after every mark-read/delete (Firestore round-trip),
        // so syncing here covers optimistic mutations too (D-notif-2).
        AppBadge.set(unreadCount);
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> markRead(String id) async {
    final uid = _uid;
    if (uid == null) return;
    _items = [
      for (final n in _items) n.id == id ? n.copyWith(read: true) : n,
    ];
    notifyListeners();
    await _service.markRead(uid, id);
  }

  /// Auto-read: marks every UNREAD notification whose [AppNotification.targetHomeTab]
  /// equals [tab] as read — called when the user opens that Home tab, since
  /// landing on the tab means they've "seen" the new activity surfaced there
  /// (photos on Gallery, notes/answers/pairing on Home). Keeps the bell badge
  /// honest instead of counting content the user already viewed in-app.
  /// Optimistic + best-effort batch; no-ops when nothing matches.
  Future<void> markReadForTab(int tab) async {
    final uid = _uid;
    if (uid == null) return;
    final ids = [
      for (final n in _items)
        if (_autoReadsOn(n, tab)) n.id,
    ];
    if (ids.isEmpty) return;
    _items = [
      for (final n in _items)
        _autoReadsOn(n, tab) ? n.copyWith(read: true) : n,
    ];
    notifyListeners();
    await _service.markAllRead(uid, ids);
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null) return;
    final unreadIds = [for (final n in _items) if (!n.read) n.id];
    if (unreadIds.isEmpty) return;
    _items = [for (final n in _items) n.read ? n : n.copyWith(read: true)];
    notifyListeners();
    await _service.markAllRead(uid, unreadIds);
  }

  Future<void> remove(String id) async {
    final uid = _uid;
    if (uid == null) return;
    _items = [for (final n in _items) if (n.id != id) n];
    notifyListeners();
    await _service.delete(uid, id);
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    final ids = [for (final n in _items) n.id];
    if (ids.isEmpty) return;
    _items = const <AppNotification>[];
    notifyListeners();
    await _service.clearAll(uid, ids);
  }

  /// Stops watching and resets state (sign-out / leaving a couple).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _uid = null;
    _coupleId = null;
    _items = const <AppNotification>[];
    _isLoading = false;
    notifyListeners();
    // Sign-out / no couple → clear the icon badge.
    AppBadge.set(0);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
