import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/chat_message.dart';
import 'firebase_bootstrap_service.dart';

/// Reads/writes the couple's private chat (feature chat, D2):
/// `couples/{coupleId}/messages/{autoId}` — append-only, immutable messages.
///
/// Local fallback (no Firebase): a simple append-only Hive box, same recipe as
/// LoveNoteService's local history — messages send/read on THIS device only
/// (there is no partner sync without Firebase), which keeps the composer alive
/// instead of dead-ending the tab. Cheapest option that satisfies "gửi/đọc
/// local-only" (dev decision 2026-06-11).
/// One realtime window emission: the messages plus whether the snapshot came
/// from the local cache (pagination must anchor on server snapshots only).
class ChatWindow {
  const ChatWindow({required this.messages, required this.isFromCache});

  const ChatWindow.empty()
      : messages = const <ChatMessage>[],
        isFromCache = false;

  final List<ChatMessage> messages;
  final bool isFromCache;
}

class ChatService {
  ChatService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  static const String _localBoxName = 'chat_messages_local';

  /// Max message length — must match the Firestore rule (D2).
  static const int maxLength = 1000;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _messagesCollection(
          String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('messages');

  /// Streams the newest [limit] messages, newest first (the realtime "window",
  /// pagination D5). `includeMetadataChanges` is ON so optimistic local echoes
  /// emit twice — once with `hasPendingWrites` (pending bubble) and once when
  /// the server confirms (bubble sharpens) — without ever inserting a local
  /// duplicate (design §4, AC2).
  ///
  /// Each emission carries `isFromCache`: the provider must NOT anchor its
  /// pagination cursor on a cache emission (a thin cache can be a partial
  /// window — tester bug #2), only on server-confirmed snapshots.
  Stream<ChatWindow> watchMessages(String coupleId, {int limit = 50}) {
    if (coupleId.trim().isEmpty) {
      return Stream<ChatWindow>.value(const ChatWindow.empty());
    }

    if (!isUsingFirebase) {
      return Stream<ChatWindow>.fromFuture(
        _loadLocal(coupleId).then(
          (messages) => ChatWindow(messages: messages, isFromCache: false),
        ),
      );
    }

    return _messagesCollection(coupleId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map(
          (snapshot) => ChatWindow(
            messages: snapshot.docs
                .map((doc) => ChatMessage.fromDoc(
                      doc.id,
                      doc.data(),
                      isPending: doc.metadata.hasPendingWrites,
                    ))
                .toList(),
            isFromCache: snapshot.metadata.isFromCache,
          ),
        );
  }

  /// One-shot page of messages strictly older than [startAfterCreatedAt],
  /// newest first (pagination D5). Local mode has no pagination (the box is
  /// loaded whole) → empty.
  Future<List<ChatMessage>> fetchOlder(
    String coupleId, {
    required DateTime startAfterCreatedAt,
    int limit = 50,
  }) async {
    if (!isUsingFirebase || coupleId.trim().isEmpty) {
      return const <ChatMessage>[];
    }

    final snapshot = await _messagesCollection(coupleId)
        .orderBy('createdAt', descending: true)
        .startAfter([Timestamp.fromDate(startAfterCreatedAt)])
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => ChatMessage.fromDoc(doc.id, doc.data()))
        .toList();
  }

  /// Appends a new message. [text] is only trimmed — NO client-side clamp:
  /// the composer's `maxLength: 1000` already bounds input, and a `substring`
  /// clamp here measured UTF-16 units (≠ the field's grapheme count ≠ the
  /// rule's `size()`), silently halving emoji-heavy messages and risking a
  /// surrogate-pair split (tester bug #3). The Firestore rule stays the final
  /// gate; an over-long write is rejected and surfaces via [onServerReject].
  Future<void> send({
    required String coupleId,
    required String uid,
    required String text,
    void Function(Object error)? onServerReject,
  }) async {
    final trimmed = text.trim();
    if (coupleId.trim().isEmpty || uid.trim().isEmpty || trimmed.isEmpty) {
      return;
    }

    if (!isUsingFirebase) {
      await _appendLocal(coupleId, uid, trimmed);
      return;
    }

    // NOT awaited-on-network: Firestore's latency compensation echoes the doc
    // into the snapshot stream immediately (hasPendingWrites) even offline, so
    // the optimistic bubble shows without any local insertion. The returned
    // future completes only when the server acks — awaiting it would hang the
    // composer offline, so we deliberately fire-and-forget after the local
    // write is queued. Plain offline time is NOT an error (the future simply
    // stays pending while the queue waits); it only rejects on a REAL server
    // refusal (rules denied — e.g. the couple was dissolved while this sat in
    // the offline queue), which we surface instead of swallowing (bug #1).
    unawaited(
      _messagesCollection(coupleId)
          .add({
            'authorUserId': uid,
            'text': trimmed,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .then<void>((_) {})
          .catchError((Object error) {
            onServerReject?.call(error);
          }),
    );
  }

  // ── Local fallback (Hive) ──────────────────────────────────────────────
  // Append-only list per couple, keyed "{coupleId}:{isoTimestamp}". Only this
  // device's messages exist locally. Best-effort: failures are swallowed so
  // the feature never crashes without Firebase.

  Future<Box<dynamic>> _openLocalBox() => Hive.openBox<dynamic>(_localBoxName);

  Future<void> _appendLocal(String coupleId, String uid, String text) async {
    try {
      final box = await _openLocalBox();
      final now = DateTime.now();
      await box.put('$coupleId:${now.toIso8601String()}', {
        'authorUserId': uid,
        'text': text,
        'createdAt': now.toIso8601String(),
      });
    } catch (_) {
      // Best-effort: ignore local persistence failures.
    }
  }

  Future<List<ChatMessage>> _loadLocal(String coupleId) async {
    try {
      final box = await _openLocalBox();
      final messages = <ChatMessage>[];
      for (final key in box.keys) {
        if (key is String && key.startsWith('$coupleId:')) {
          final raw = box.get(key);
          if (raw is Map) {
            messages.add(ChatMessage.fromJson(Map<String, dynamic>.from(raw)));
          }
        }
      }
      messages.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return messages;
    } catch (_) {
      return const <ChatMessage>[];
    }
  }
}
