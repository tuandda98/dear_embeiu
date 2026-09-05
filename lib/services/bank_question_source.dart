import '../data/daily_questions.dart';
import '../data/daily_questions_extra.dart';
import 'question_source.dart';

/// The curated static bank as a pluggable source (feature endless-questions).
///
/// ⚠️ Selection deliberately does NOT use the legacy `daysSinceEpoch % n`
/// rotation: that made the whole order depend on the bank LENGTH, so appending a
/// single question reshuffled every couple mid-cycle. Here the couple's
/// already-asked indices live in `questionState/main.askedBankIds`, so the bank
/// can grow by APPENDING (`daily_questions_extra.dart`) without ever disturbing
/// what has been asked.
///
/// Order is still deterministic — seeded by (coupleId + dateKey) — so both
/// phones resolving the same day independently land on the same question even
/// before the marker exists.
class BankQuestionSource implements QuestionSource {
  const BankQuestionSource();

  @override
  String get key => 'bank';

  /// The merged bank. Indices are positions in THIS list; entries may only ever
  /// be appended (see `daily_questions_extra.dart`).
  static List<Map<String, String>> get bank => <Map<String, String>>[
        ...dailyQuestions,
        ...dailyQuestionsExtra,
      ];

  static int get bankLength => dailyQuestions.length + dailyQuestionsExtra.length;

  /// The bank entry at [index], or null when out of range.
  static Map<String, String>? entryAt(int index) {
    final all = bank;
    if (index < 0 || index >= all.length) {
      return null;
    }
    return all[index];
  }

  @override
  Future<QuestionCandidate?> propose(QuestionContext ctx) async {
    try {
      return pick(
        coupleId: ctx.coupleId,
        dateKey: ctx.dateKey,
        askedBankIds: ctx.askedBankIds,
      );
    } catch (_) {
      return null;
    }
  }

  /// Deterministic pick, exposed for tests and for the engine's fallback path.
  ///
  /// Walks a (coupleId + dateKey)-seeded permutation of all bank indices and
  /// returns the first one NOT in [askedBankIds]. When the couple has exhausted
  /// the bank, the asked set is treated as empty (a fresh cycle begins) rather
  /// than leaving the card blank.
  static QuestionCandidate? pick({
    required String coupleId,
    required String dateKey,
    required List<int> askedBankIds,
  }) {
    final all = bank;
    final n = all.length;
    if (n == 0) {
      return null;
    }
    final seed = stableQuestionHash('$coupleId|$dateKey');
    final perm = deterministicPermutation(n, seed);
    final asked = askedBankIds.toSet();

    int chosen = perm[0];
    if (asked.length < n) {
      for (final index in perm) {
        if (!asked.contains(index)) {
          chosen = index;
          break;
        }
      }
    }

    final entry = all[chosen];
    final vi = entry['vi']?.trim() ?? '';
    final en = entry['en']?.trim() ?? '';
    if (vi.isEmpty && en.isEmpty) {
      return null;
    }
    return QuestionCandidate(
      source: 'bank',
      questionVi: vi.isEmpty ? en : vi,
      questionEn: en.isEmpty ? vi : en,
      questionId: chosen,
    );
  }
}
