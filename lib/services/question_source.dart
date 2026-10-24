/// Contract for the pluggable daily-question engine (feature endless-questions,
/// 2026-09-05). The engine (`question_engine.dart`) asks each registered
/// [QuestionSource] in priority order for a candidate; the first non-null wins
/// and is snapshotted into the day's `dailyAnswers/{date}` marker so BOTH
/// partners see the identical question (marker = source of truth).
///
/// Implementations live in their own files (template / bank / revisit / ai) and
/// must be deterministic for a given [QuestionContext] where possible, fail-soft
/// (return null on any error — never throw), and fast (≤ ~8s incl. network).
library;

/// Everything a source may look at when proposing today's question.
class QuestionContext {
  const QuestionContext({
    required this.coupleId,
    required this.myUid,
    required this.partnerUid,
    required this.date,
    required this.dateKey,
    required this.languageCode,
    required this.anniversaryDate,
    required this.currentStreak,
    required this.photosThisWeek,
    required this.myMoodToday,
    required this.partnerMoodToday,
    required this.askedBankIds,
    required this.recentTemplateKeys,
    required this.recentRevisitDates,
    required this.aiEnabled,
  });

  final String coupleId;
  final String myUid;

  /// Empty when the couple is still waiting for the partner.
  final String partnerUid;

  /// Local date-only for "today".
  final DateTime date;

  /// 'YYYY-MM-DD' (same key space as `DailyQuestionService.dateKey`).
  final String dateKey;

  /// 'vi' | 'en' — the CURRENT device language (for logging/hints only; every
  /// candidate must carry BOTH languages).
  final String languageCode;

  final DateTime anniversaryDate;
  final int currentStreak;
  final int photosThisWeek;

  /// Mood keys (`couples/{id}/moods/{uid}.mood`) for today, or null.
  final String? myMoodToday;
  final String? partnerMoodToday;

  /// Bank indices already used by this couple (from `questionState/main`).
  final List<int> askedBankIds;

  /// Template keys used in the last ~60 days (avoid repeats).
  final List<String> recentTemplateKeys;

  /// `refDate` keys already revisited (avoid re-asking the same old day).
  final List<String> recentRevisitDates;

  /// Couple-shared opt-in for the AI source (`prefs/home.aiQuestionsEnabled`).
  final bool aiEnabled;
}

/// One proposed question. Both languages are REQUIRED; hints are optional and
/// rendered under the question on the card (per-user text is allowed here
/// because hints are NOT stored in the marker — only the question is).
class QuestionCandidate {
  const QuestionCandidate({
    required this.source,
    required this.questionVi,
    required this.questionEn,
    this.questionId,
    this.templateKey,
    this.refDate,
    this.hintVi,
    this.hintEn,
  });

  /// 'bank' | 'template' | 'revisit' | 'ai' — persisted on the marker.
  final String source;
  final String questionVi;
  final String questionEn;

  /// Bank index (source == 'bank').
  final int? questionId;

  /// Template key (source == 'template').
  final String? templateKey;

  /// 'YYYY-MM-DD' of the past day being revisited (source == 'revisit').
  final String? refDate;

  /// Optional per-user hint shown under the question (NOT persisted).
  final String? hintVi;
  final String? hintEn;

  /// Extra marker fields to persist alongside `questionVi/En` + `source`.
  Map<String, Object> get markerExtras => <String, Object>{
        'questionId': ?questionId,
        'templateKey': ?templateKey,
        'refDate': ?refDate,
      };
}

/// A pluggable proposer. Register instances on the engine in priority order.
abstract class QuestionSource {
  /// Stable id: 'ai' | 'revisit' | 'template' | 'bank'.
  String get key;

  /// Return a candidate for [ctx] or null to pass. MUST NOT throw.
  Future<QuestionCandidate?> propose(QuestionContext ctx);
}
