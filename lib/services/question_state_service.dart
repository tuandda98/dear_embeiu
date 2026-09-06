import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_bootstrap_service.dart';

/// Per-couple memory of what the question engine has already asked
/// (`couples/{coupleId}/questionState/main`, feature endless-questions).
///
/// Replaces the old `daysSinceEpoch % bankLength` rotation: because the engine
/// now remembers the bank indices it already used, questions can be APPENDED to
/// the bank without reshuffling anyone's order.
///
/// Fail-soft by design: the rules for this doc may not be deployed yet on every
/// environment, so a `permission-denied`/missing doc simply reads as "empty
/// state" and every write is best-effort (a failure never blocks the card).
class QuestionState {
  const QuestionState({
    this.askedBankIds = const <int>[],
    this.recentTemplateKeys = const <String>[],
    this.recentRevisitDates = const <String>[],
  });

  /// Bank indices (positions in `[...dailyQuestions, ...dailyQuestionsExtra]`)
  /// this couple has already been asked.
  final List<int> askedBankIds;

  /// Template keys (`group:topic:variant`) used recently — avoid repeats.
  final List<String> recentTemplateKeys;

  /// `refDate` keys already revisited by the 'revisit' source.
  final List<String> recentRevisitDates;

  static const QuestionState empty = QuestionState();

  /// Client-side caps (the doc must stay tiny — one read per day per device).
  static const int maxAskedBankIds = 2000;
  static const int maxRecentTemplateKeys = 60;
  static const int maxRecentRevisitDates = 60;
}

class QuestionStateService {
  QuestionStateService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String coupleId) => _db
      .collection('couples')
      .doc(coupleId)
      .collection('questionState')
      .doc('main');

  /// Reads the couple's question state. Returns [QuestionState.empty] on the
  /// local fallback, a missing doc, or ANY error (rules not deployed yet).
  Future<QuestionState> load(String coupleId) async {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return QuestionState.empty;
    }
    try {
      final snapshot = await _doc(coupleId).get();
      final data = snapshot.data();
      if (data == null) {
        return QuestionState.empty;
      }
      return QuestionState(
        askedBankIds: _intList(data['askedBankIds']),
        recentTemplateKeys: _stringList(data['recentTemplateKeys']),
        recentRevisitDates: _stringList(data['recentRevisitDates']),
      );
    } catch (_) {
      return QuestionState.empty;
    }
  }

  /// Records what today's resolution used. Best-effort; never throws.
  ///
  /// Appends with `arrayUnion` while the list still fits under its cap; once it
  /// would overflow, the whole (oldest-trimmed) list is rewritten instead so the
  /// doc can never grow without bound.
  Future<void> record({
    required String coupleId,
    required QuestionState current,
    int? bankId,
    String? templateKey,
    String? revisitDate,
  }) async {
    if (coupleId.trim().isEmpty || !isUsingFirebase) {
      return;
    }
    final payload = <String, Object?>{};

    _appendInt(
      payload: payload,
      field: 'askedBankIds',
      existing: current.askedBankIds,
      value: bankId,
      cap: QuestionState.maxAskedBankIds,
    );
    _appendString(
      payload: payload,
      field: 'recentTemplateKeys',
      existing: current.recentTemplateKeys,
      value: templateKey,
      cap: QuestionState.maxRecentTemplateKeys,
    );
    _appendString(
      payload: payload,
      field: 'recentRevisitDates',
      existing: current.recentRevisitDates,
      value: revisitDate,
      cap: QuestionState.maxRecentRevisitDates,
    );

    if (payload.isEmpty) {
      return;
    }
    payload['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _doc(coupleId).set(payload, SetOptions(merge: true));
    } catch (_) {
      // Ignore — the question is already resolved and snapshotted on the
      // marker; this state only improves future variety.
    }
  }

  void _appendInt({
    required Map<String, Object?> payload,
    required String field,
    required List<int> existing,
    required int? value,
    required int cap,
  }) {
    if (value == null || existing.contains(value)) {
      return;
    }
    if (existing.length + 1 <= cap) {
      payload[field] = FieldValue.arrayUnion(<Object>[value]);
      return;
    }
    final next = <int>[...existing, value];
    payload[field] = next.sublist(next.length - cap);
  }

  void _appendString({
    required Map<String, Object?> payload,
    required String field,
    required List<String> existing,
    required String? value,
    required int cap,
  }) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || existing.contains(trimmed)) {
      return;
    }
    if (existing.length + 1 <= cap) {
      payload[field] = FieldValue.arrayUnion(<Object>[trimmed]);
      return;
    }
    final next = <String>[...existing, trimmed];
    payload[field] = next.sublist(next.length - cap);
  }

  static List<int> _intList(Object? raw) {
    if (raw is! List) {
      return const <int>[];
    }
    final out = <int>[];
    for (final item in raw) {
      if (item is int) {
        out.add(item);
      } else if (item is num) {
        out.add(item.toInt());
      }
    }
    return out;
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw.whereType<String>().toList();
  }
}
