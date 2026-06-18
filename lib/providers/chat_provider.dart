import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_message.dart';
import '../services/chat_service.dart';

/// Delivery state of one of MY outgoing messages (feature chat-status,
/// 2026-06-18), derived from the partner's receipt. `none` = not applicable
/// (the partner's message, or the local fallback with no partner).
enum ChatMessageStatus { none, sending, sent, delivered, read }

/// State for the couple chat tab (feature chat): owns the realtime window of
/// the newest 50 messages plus the accumulated older pages (pagination D5,
/// same recipe as LoveNoteProvider's history AFTER the race fix), and the
/// unread marker that drives the bottom-nav dot (D7).
///
/// Unlike the note archive (armed only while its screen is open), the chat
/// stream runs for the whole session of an active couple — the unread dot must
/// work while the user sits on any tab. Wired in SessionResolver + re-armed
/// from HomeScreen, cleared on sign-out/leave (like every couple watcher).
class ChatProvider extends ChangeNotifier {
  ChatProvider({ChatService? service}) : _service = service ?? ChatService();

  final ChatService _service;

  /// Realtime window size AND "show more" page size (pagination D5).
  static const int _pageSize = 50;

  StreamSubscription<ChatWindow>? _subscription;
  String? _coupleId;
  String? _myUid;

  /// Firebase mode: id-keyed accumulator (window + older pages). Messages are
  /// append-only + immutable, so entries never need removing — the map both
  /// dedups the window against fetched pages and lets a window re-emission
  /// (pending → confirmed) overwrite in place.
  final Map<String, ChatMessage> _byId = <String, ChatMessage>{};

  /// Arrival sequence per id — sort tiebreaker so optimistic messages (null
  /// `createdAt` until the server resolves it) keep their send order instead
  /// of shuffling on rebuild (List.sort isn't stable).
  final Map<String, int> _arrival = <String, int>{};
  int _arrivalSeq = 0;

  /// Local fallback: the whole (this-device-only) conversation, no pagination.
  List<ChatMessage> _localMessages = const <ChatMessage>[];

  bool _isLoading = false;
  bool _hasMore = false;
  bool _loadingMore = false;

  /// Monotonic counter of REAL server send-refusals (rules denied after the
  /// optimistic echo). The screen tracks the last value it has surfaced and
  /// shows a snackbar when this grows (tester bug #1).
  int _sendRejections = 0;
  int get sendRejections => _sendRejections;

  /// Oldest `createdAt` of the contiguous loaded prefix (window + pages).
  DateTime? _cursor;

  // ── Unread marker (D7) ────────────────────────────────────────────────────
  // Hive `app_settings` key `chat_seen_<coupleId>` = epoch-millis of the
  // newest PARTNER message the user has seen. Until loaded we report no
  // unread so the dot never flashes on stale state.
  int? _seenMillis;
  bool _seenLoaded = false;

  String get _seenKey => 'chat_seen_$_coupleId';

  // ── Read/delivery receipts (feature chat-status, 2026-06-18) ───────────────
  // The PARTNER's receipt timestamps, watched so MY outgoing messages can show
  // đã nhận / đã đọc. `_deliveredUpToMillis` throttles my own delivered-stamp
  // writes to once per genuinely-newer partner message.
  StreamSubscription<ChatReceipt>? _receiptSub;
  DateTime? _partnerDeliveredAt;
  DateTime? _partnerReadAt;
  int _deliveredUpToMillis = 0;

  /// The delivery status of [message] for the status line under the latest
  /// outgoing bubble. Returns [ChatMessageStatus.none] for partner messages and
  /// in the local fallback (no partner to receive/read).
  ChatMessageStatus statusOf(ChatMessage message) {
    if (!_service.isUsingFirebase || message.authorUserId != _myUid) {
      return ChatMessageStatus.none;
    }
    final when = message.createdAt;
    if (message.isPending || when == null) {
      return ChatMessageStatus.sending;
    }
    final t = when.millisecondsSinceEpoch;
    if ((_partnerReadAt?.millisecondsSinceEpoch ?? -1) >= t) {
      return ChatMessageStatus.read;
    }
    if ((_partnerDeliveredAt?.millisecondsSinceEpoch ?? -1) >= t) {
      return ChatMessageStatus.delivered;
    }
    return ChatMessageStatus.sent;
  }

  /// Messages newest-first (the chat screen lays them out via reverse:true).
  List<ChatMessage> get messages {
    if (!_service.isUsingFirebase) {
      return _localMessages;
    }
    final list = _byId.values.toList()
      ..sort((a, b) {
        // Pending messages (no server timestamp yet) sort to the newest end.
        final at = a.createdAt;
        final bt = b.createdAt;
        if (at == null || bt == null) {
          if (at == null && bt == null) {
            return (_arrival[b.id] ?? 0).compareTo(_arrival[a.id] ?? 0);
          }
          return at == null ? -1 : 1; // null = newest → first (desc order)
        }
        final byTime = bt.compareTo(at);
        if (byTime != 0) {
          return byTime;
        }
        return (_arrival[b.id] ?? 0).compareTo(_arrival[a.id] ?? 0);
      });
    return list;
  }

  /// True while the FIRST page is loading (skeleton state).
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;
  bool get isUsingFirebase => _service.isUsingFirebase;

  /// The newest partner message's timestamp, or null when none exists.
  DateTime? get _latestPartnerAt {
    final uid = _myUid;
    if (uid == null) {
      return null;
    }
    for (final message in messages) {
      if (message.authorUserId != uid && message.createdAt != null) {
        return message.createdAt;
      }
    }
    return null;
  }

  /// Whether the partner sent something newer than the seen marker (D7).
  /// Own messages never raise the dot; unloaded marker reports false.
  bool get hasUnread {
    if (!_seenLoaded) {
      return false;
    }
    final latest = _latestPartnerAt;
    if (latest == null) {
      return false;
    }
    return latest.millisecondsSinceEpoch > (_seenMillis ?? 0);
  }

  /// Begins watching the chat for [coupleId] on behalf of [myUid]. Safe to
  /// call repeatedly; no-ops when the (couple, uid) pair is unchanged and
  /// already streaming, resubscribes when either changes.
  void watchForCouple(String coupleId, String myUid) {
    if (coupleId.trim().isEmpty || myUid.trim().isEmpty) {
      clear();
      return;
    }

    if (_coupleId == coupleId && _myUid == myUid && _subscription != null) {
      return;
    }

    _coupleId = coupleId;
    _myUid = myUid;
    _resetMessageState();
    _seenMillis = null;
    _seenLoaded = false;
    _partnerDeliveredAt = null;
    _partnerReadAt = null;
    _deliveredUpToMillis = 0;
    _isLoading = true;
    notifyListeners();

    _loadSeenMarker(coupleId);
    _kickLoveNoteMigration(coupleId);

    // Follow the partner's receipt so our sent bubbles can flip to đã nhận /
    // đã đọc as they catch up.
    _receiptSub?.cancel();
    _receiptSub =
        _service.watchPartnerReceipt(coupleId, myUid).listen((receipt) {
      if (coupleId != _coupleId) {
        return;
      }
      _partnerDeliveredAt = receipt.deliveredAt;
      _partnerReadAt = receipt.readAt;
      notifyListeners();
    });

    _subscription?.cancel();
    _subscription = _service.watchMessages(coupleId, limit: _pageSize).listen(
      (window) {
        final entries = window.messages;
        if (!_service.isUsingFirebase) {
          // Local conversation arrives whole — nothing more to page in.
          _localMessages = entries;
          _hasMore = false;
        } else {
          for (final message in entries) {
            final id = message.id;
            if (id != null) {
              _arrival.putIfAbsent(id, () => _arrivalSeq++);
              _byId[id] = message;
            }
          }
          // The first SERVER emission initializes the cursor + hasMore; later
          // emissions only carry NEWER entries (the window), so the cursor
          // stays put. Cache emissions still render above but never anchor
          // pagination — a thin cache can be a PARTIAL window (<50 docs even
          // though the server holds more), which would lock hasMore=false for
          // the whole session / leave a gap below the cache block (bug #2).
          if (_cursor == null && entries.isNotEmpty && !window.isFromCache) {
            _cursor = entries.last.createdAt;
            _hasMore = entries.length >= _pageSize;
          }
          _maybeMarkDelivered();
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Couples whose love-note backfill was already requested this app session —
  /// the lazy migration fires at most once per couple per launch.
  static final Set<String> _loveNoteMigrationAttempted = <String>{};

  /// One-time auto-migration (2026-06-14): the chat replaces the old two-way
  /// love notes. The first time this (updated) app opens chat for a couple, it
  /// asks the backend to backfill that couple's EXISTING love notes into the
  /// conversation. New notes from a partner still on the old build are mirrored
  /// live by a Cloud Function trigger, so this only covers the pre-update
  /// history. Fire-and-forget, guarded once per session, errors swallowed — a
  /// missing/old function or offline state must never block or break the chat.
  void _kickLoveNoteMigration(String coupleId) {
    if (!_service.isUsingFirebase ||
        !_loveNoteMigrationAttempted.add(coupleId)) {
      return;
    }
    unawaited(() async {
      try {
        await FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('migrateLoveNotesToChat')
            .call(<String, dynamic>{'coupleId': coupleId});
      } catch (_) {
        // Best-effort only — the chat works whether or not this succeeds.
      }
    }());
  }

  /// Sends a message. Returns false when there is no active couple/uid (the
  /// composer shows the failure snackbar). Optimistic: Firestore's latency
  /// compensation pops the bubble into the stream immediately — nothing is
  /// inserted locally here (AC2: no duplicates).
  ///
  /// A LATE server refusal (rules denied — e.g. the couple dissolved while
  /// the message sat in the offline queue) arrives via [sendRejections]:
  /// the screen listens and surfaces a snackbar (tester bug #1). Plain
  /// offline time never rejects — the queued write just waits.
  Future<bool> send(String text) async {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null || text.trim().isEmpty) {
      return false;
    }

    await _service.send(
      coupleId: coupleId,
      uid: uid,
      text: text,
      onServerReject: (_) {
        // Only flag the session that sent it — after a sign-out/couple switch
        // the new session shouldn't show a stale failure for the old couple.
        if (coupleId == _coupleId) {
          _sendRejections++;
          notifyListeners();
        }
      },
    );

    if (!_service.isUsingFirebase) {
      // The local one-shot stream has already completed — reload so the just
      // sent message appears. Guard the couple after the await (race fix).
      final reloaded = await _service.watchMessages(coupleId).first;
      if (coupleId == _coupleId) {
        _localMessages = reloaded.messages;
        notifyListeners();
      }
    }
    return true;
  }

  /// Fetches the next (older) page. Re-entrancy guarded; no-op when nothing
  /// more remains.
  Future<void> loadMore() async {
    final coupleId = _coupleId;
    final cursor = _cursor;
    if (_loadingMore || !_hasMore || coupleId == null || cursor == null) {
      return;
    }

    _loadingMore = true;
    notifyListeners();

    try {
      final older = await _service.fetchOlder(
        coupleId,
        startAfterCreatedAt: cursor,
        limit: _pageSize,
      );
      // Re-check the couple AFTER the await (same race as the note archive):
      // a sign-out or couple switch while the fetch was in flight must not
      // leak the previous couple's messages — drop the stale page entirely.
      if (coupleId == _coupleId) {
        for (final message in older) {
          final id = message.id;
          if (id != null) {
            _arrival.putIfAbsent(id, () => _arrivalSeq++);
            _byId[id] = message;
          }
        }
        final oldest = older.isEmpty ? null : older.last.createdAt;
        if (oldest != null) {
          _cursor = oldest;
        }
        _hasMore = older.length >= _pageSize;
      }
    } catch (_) {
      // Keep hasMore so the "show more" button stays available for a retry.
    }

    _loadingMore = false;
    notifyListeners();
  }

  /// Marks the conversation seen: stores the newest partner message's
  /// timestamp (or now, when none) so [hasUnread] flips off. Called when the
  /// user lands on the chat tab and when a partner message arrives while the
  /// tab is already open.
  Future<void> markSeen() async {
    final coupleId = _coupleId;
    if (coupleId == null) {
      return;
    }
    final latest = _latestPartnerAt?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    if (_seenLoaded && _seenMillis != null && latest <= _seenMillis!) {
      return; // Already seen — avoid a pointless rebuild + Hive write.
    }
    _seenMillis = latest;
    _seenLoaded = true;
    notifyListeners();
    // Tell the partner we've read up to now (đã đọc) — and implicitly received
    // it (đã nhận). Best-effort; guarded on the live couple/uid.
    final uid = _myUid;
    if (uid != null) {
      _deliveredUpToMillis = latest;
      unawaited(
        _service.markReceipt(coupleId, uid, delivered: true, read: true),
      );
    }
    try {
      final box = await Hive.openBox<String>('app_settings');
      // Guard the couple after the await — never stamp another couple's key.
      if (coupleId == _coupleId) {
        await box.put(_seenKey, '$latest');
      }
    } catch (_) {
      // Best-effort: the in-memory marker already keeps this session honest.
    }
  }

  /// Stamps MY deliveredAt when a partner message newer than anything we've
  /// acknowledged has arrived (the device now HAS it). Throttled by
  /// [_deliveredUpToMillis] so it writes at most once per newer partner message.
  void _maybeMarkDelivered() {
    final coupleId = _coupleId;
    final uid = _myUid;
    if (coupleId == null || uid == null || !_service.isUsingFirebase) {
      return;
    }
    final latest = _latestPartnerAt?.millisecondsSinceEpoch;
    if (latest == null || latest <= _deliveredUpToMillis) {
      return;
    }
    _deliveredUpToMillis = latest;
    unawaited(_service.markReceipt(coupleId, uid, delivered: true));
  }

  Future<void> _loadSeenMarker(String coupleId) async {
    try {
      final box = await Hive.openBox<String>('app_settings');
      if (coupleId != _coupleId) {
        return; // Couple changed while the box was opening.
      }
      _seenMillis = int.tryParse(box.get('chat_seen_$coupleId') ?? '');
      _seenLoaded = true;
      notifyListeners();
    } catch (_) {
      // Box unavailable → keep reporting no unread (fail-soft, no dot flash).
      _seenLoaded = true;
    }
  }

  void _resetMessageState() {
    _byId.clear();
    _arrival.clear();
    _arrivalSeq = 0;
    _localMessages = const <ChatMessage>[];
    _isLoading = false;
    _hasMore = false;
    _loadingMore = false;
    _cursor = null;
  }

  /// Stops watching and resets state (sign-out or leaving a couple).
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _receiptSub?.cancel();
    _receiptSub = null;
    _resetMessageState();
    _coupleId = null;
    _myUid = null;
    _seenMillis = null;
    _seenLoaded = false;
    _partnerDeliveredAt = null;
    _partnerReadAt = null;
    _deliveredUpToMillis = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _receiptSub?.cancel();
    super.dispose();
  }
}
