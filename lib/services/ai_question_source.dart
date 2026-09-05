import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap_service.dart';
import 'question_source.dart';

/// AI-generated daily question (feature endless-questions, 2026-09-05).
///
/// The heavy lifting lives server-side: the callable `generateDailyQuestion`
/// (us-central1) reads the couple's recent answers, prompts the model, and
/// writes the day's marker itself (idempotent) — this source only asks for the
/// result and hands it back to the engine.
///
/// Fail-soft by contract: opt-out, no Firebase, timeout, refusal, malformed
/// payload — every path returns null so the engine falls through to the next
/// source (revisit / template / bank). NEVER throws.
class AiQuestionSource implements QuestionSource {
  AiQuestionSource({FirebaseFunctions? functions}) : _functions = functions;

  final FirebaseFunctions? _functions;

  /// Server-side budget is ~10s; keep a little headroom over it.
  static const Duration _timeout = Duration(seconds: 15);

  @override
  String get key => 'ai';

  bool get _isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  FirebaseFunctions get _fns =>
      _functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  Future<QuestionCandidate?> propose(QuestionContext ctx) async {
    // Couple-shared opt-in (`prefs/home.aiQuestionsEnabled`) — off means we
    // never even touch the network.
    if (!ctx.aiEnabled || ctx.coupleId.trim().isEmpty || !_isUsingFirebase) {
      return null;
    }

    try {
      final result = await _fns
          .httpsCallable(
            'generateDailyQuestion',
            options: HttpsCallableOptions(timeout: _timeout),
          )
          .call<dynamic>(<String, dynamic>{
            'coupleId': ctx.coupleId,
            'date': ctx.dateKey,
            'lang': ctx.languageCode == 'vi' ? 'vi' : 'en',
          });

      final data = result.data;
      if (data is! Map) {
        return null;
      }
      if (data['ok'] != true) {
        if (kDebugMode) {
          debugPrint('AiQuestionSource: declined (${data['reason']})');
        }
        return null;
      }

      final questionVi = _readText(data['questionVi']);
      final questionEn = _readText(data['questionEn']);
      if (questionVi == null || questionEn == null) {
        return null;
      }

      return QuestionCandidate(
        source: 'ai',
        questionVi: questionVi,
        questionEn: questionEn,
      );
    } catch (e) {
      // Offline, unauthenticated, deadline-exceeded, function missing (not yet
      // deployed)… — all the same to us: pass and let the next source answer.
      if (kDebugMode) {
        debugPrint('AiQuestionSource: propose failed — $e');
      }
      return null;
    }
  }

  /// Non-empty string or null (the payload is untrusted/dynamic).
  static String? _readText(Object? raw) {
    if (raw is! String) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
