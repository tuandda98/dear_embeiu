import 'package:dear_embeiu/data/daily_questions.dart';
import 'package:dear_embeiu/data/daily_questions_extra.dart';
import 'package:dear_embeiu/data/question_templates.dart';
import 'package:dear_embeiu/services/bank_question_source.dart';
import 'package:dear_embeiu/services/question_engine.dart';
import 'package:dear_embeiu/services/question_source.dart';
import 'package:dear_embeiu/services/template_question_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Unit tests for the question engine (feature endless-questions).
///
/// Everything asserted here is PURE (schedule planning, deterministic picking,
/// template copy hygiene) — the Firestore marker path needs the emulator and is
/// covered by manual/rules testing instead.
QuestionContext ctxFor(
  DateTime date, {
  String coupleId = 'couple-abc',
  List<int> askedBankIds = const <int>[],
  List<String> recentTemplateKeys = const <String>[],
  int currentStreak = 3,
  int photosThisWeek = 2,
  String? partnerMood,
  bool aiEnabled = false,
  DateTime? anniversary,
}) {
  final dateOnly = DateTime(date.year, date.month, date.day);
  final key = '${dateOnly.year.toString().padLeft(4, '0')}-'
      '${dateOnly.month.toString().padLeft(2, '0')}-'
      '${dateOnly.day.toString().padLeft(2, '0')}';
  return QuestionContext(
    coupleId: coupleId,
    myUid: 'me',
    partnerUid: 'you',
    date: dateOnly,
    dateKey: key,
    languageCode: 'vi',
    anniversaryDate: anniversary ?? DateTime(2024, 1, 1),
    currentStreak: currentStreak,
    photosThisWeek: photosThisWeek,
    myMoodToday: null,
    partnerMoodToday: partnerMood,
    askedBankIds: askedBankIds,
    recentTemplateKeys: recentTemplateKeys,
    recentRevisitDates: const <String>[],
    aiEnabled: aiEnabled,
  );
}

void main() {
  group('weekday schedule', () {
    // 2026-09-07 is a Monday → the whole week follows from there.
    final monday = DateTime(2026, 9, 7);
    final engine = QuestionEngine.withDefaults();

    test('Mon/Wed/Sun ask the template source for the right group', () {
      expect(engine.planFor(ctxFor(monday)).first,
          'template:$kTplGroupWeekStart');
      expect(
        engine.planFor(ctxFor(monday.add(const Duration(days: 2)))).first,
        'template:$kTplGroupFeeling',
      );
      expect(
        engine.planFor(ctxFor(monday.add(const Duration(days: 6)))).first,
        'template:$kTplGroupWeekRecap',
      );
    });

    test('Tue/Thu/Sat go to the bank, Fri to revisit', () {
      expect(engine.planFor(ctxFor(monday.add(const Duration(days: 1)))).first,
          'bank');
      expect(engine.planFor(ctxFor(monday.add(const Duration(days: 3)))).first,
          'bank');
      expect(engine.planFor(ctxFor(monday.add(const Duration(days: 5)))).first,
          'bank');
      expect(engine.planFor(ctxFor(monday.add(const Duration(days: 4)))).first,
          'revisit');
    });

    test('every plan carries the [template, bank] fallback, deduped', () {
      for (int i = 0; i < 7; i++) {
        final plan = engine.planFor(ctxFor(monday.add(Duration(days: i))));
        // Both safety nets are always reachable...
        expect(plan.contains('bank'), isTrue, reason: 'day $i: $plan');
        expect(plan.contains('template'), isTrue, reason: 'day $i: $plan');
        // ...and no step is ever asked twice.
        expect(plan.toSet().length, plan.length, reason: 'day $i: $plan');
        // The generic template step always precedes the generic bank step.
        if (plan.contains('template') && plan.last == 'bank') {
          expect(plan.indexOf('template'), lessThan(plan.indexOf('bank')));
        }
      }
    });

    test('calendar overrides win over the weekday rotation', () {
      // 2026-02-14 (Valentine) is a Saturday — a bank day by rotation.
      expect(engine.planFor(ctxFor(DateTime(2026, 2, 14))).first,
          'template:$kTplGroupValentine');
      // 2027-01-01 (New Year) is a Friday — a revisit day by rotation.
      expect(engine.planFor(ctxFor(DateTime(2027, 1, 1))).first,
          'template:$kTplGroupNewYear');
      expect(engine.planFor(ctxFor(DateTime(2026, 12, 25))).first,
          'template:$kTplGroupChristmas');
      expect(engine.planFor(ctxFor(DateTime(2026, 10, 20))).first,
          'template:$kTplGroupVnWomen');
      expect(engine.planFor(ctxFor(DateTime(2027, 3, 8))).first,
          'template:$kTplGroupWomensDay');
    });

    test('month edges, streak, photo-less weekend and mood add hooks', () {
      expect(
        engine.planFor(ctxFor(DateTime(2026, 9, 30))),
        contains('template:$kTplGroupMonthEnd'),
      );
      expect(
        engine.planFor(ctxFor(DateTime(2026, 9, 1))),
        contains('template:$kTplGroupMonthStart'),
      );
      expect(
        engine.planFor(ctxFor(monday, currentStreak: 100)),
        contains('template:$kTplGroupStreakMilestone'),
      );
      expect(
        engine.planFor(ctxFor(DateTime(2026, 9, 12), photosThisWeek: 0)),
        contains('template:$kTplGroupNoPhotosWeekend'),
      );
      expect(
        engine.planFor(ctxFor(monday, partnerMood: 'tired')),
        contains('template:$kTplGroupMoodPartner'),
      );
      // Anniversary milestone within +/- 3 days (100 days on 2024-04-10).
      expect(
        engine.planFor(
          ctxFor(DateTime(2024, 4, 8), anniversary: DateTime(2024, 1, 1)),
        ),
        contains('template:$kTplGroupMilestoneNear'),
      );
    });

    test('AI runs first only when the couple opted in', () {
      expect(engine.planFor(ctxFor(monday)).contains('ai'), isFalse);
      expect(engine.planFor(ctxFor(monday, aiEnabled: true)).first, 'ai');
    });

    test('registerSource priority runs before the schedule', () {
      final custom = QuestionEngine.withDefaults()
        ..registerSource(const _StubSource('revisit'), priority: 10);
      expect(custom.planFor(ctxFor(monday)).first, 'revisit');
      expect(custom.hasSource('revisit'), isTrue);
    });
  });

  group('bank source', () {
    test('is deterministic for the same couple + day', () {
      final a = BankQuestionSource.pick(
        coupleId: 'c1',
        dateKey: '2026-09-05',
        askedBankIds: const <int>[],
      );
      final b = BankQuestionSource.pick(
        coupleId: 'c1',
        dateKey: '2026-09-05',
        askedBankIds: const <int>[],
      );
      expect(a, isNotNull);
      expect(a!.questionId, b!.questionId);
      expect(a.questionVi, isNotEmpty);
      expect(a.questionEn, isNotEmpty);
      expect(a.source, 'bank');
    });

    test('different couples get different orders', () {
      final ids = <int?>{};
      for (final couple in <String>['c1', 'c2', 'c3', 'c4', 'c5']) {
        ids.add(
          BankQuestionSource.pick(
            coupleId: couple,
            dateKey: '2026-09-05',
            askedBankIds: const <int>[],
          )?.questionId,
        );
      }
      expect(ids.length, greaterThan(1));
    });

    test('never repeats a question already in askedBankIds', () {
      const coupleId = 'c-no-repeat';
      final asked = <int>[];
      for (int day = 1; day <= 40; day++) {
        final dateKey = '2026-09-${day.toString().padLeft(2, '0')}';
        final candidate = BankQuestionSource.pick(
          coupleId: coupleId,
          dateKey: dateKey,
          askedBankIds: asked,
        );
        expect(candidate, isNotNull);
        expect(asked.contains(candidate!.questionId), isFalse,
            reason: 'repeat on $dateKey');
        asked.add(candidate.questionId!);
      }
      expect(asked.toSet().length, asked.length);
    });

    test('appending to the bank does not shift existing indices', () {
      expect(BankQuestionSource.bankLength,
          dailyQuestions.length + dailyQuestionsExtra.length);
      for (int i = 0; i < dailyQuestions.length; i++) {
        expect(BankQuestionSource.entryAt(i), dailyQuestions[i]);
      }
      expect(BankQuestionSource.entryAt(-1), isNull);
      expect(BankQuestionSource.entryAt(BankQuestionSource.bankLength), isNull);
    });
  });

  group('template catalogue', () {
    test('every template has vi + en, no ICU braces or markup', () {
      for (final t in questionTemplates) {
        expect(t.vi.trim(), isNotEmpty, reason: t.key);
        expect(t.en.trim(), isNotEmpty, reason: t.key);
        for (final text in <String>[t.vi, t.en]) {
          expect(text.contains('{'), isFalse, reason: t.key);
          expect(text.contains('}'), isFalse, reason: t.key);
          expect(text.contains('<'), isFalse, reason: t.key);
          expect(text.contains('>'), isFalse, reason: t.key);
          expect(text.length, lessThanOrEqualTo(200), reason: t.key);
          expect(text.contains('hai đứa'), isFalse, reason: t.key);
        }
      }
    });

    test('template keys are unique', () {
      final keys = questionTemplates.map((t) => t.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('every scheduled group has copy', () {
      const groups = <String>[
        kTplGroupWeekStart,
        kTplGroupFeeling,
        kTplGroupWeekRecap,
        kTplGroupMonthStart,
        kTplGroupMonthEnd,
        kTplGroupNewYear,
        kTplGroupValentine,
        kTplGroupWomensDay,
        kTplGroupVnWomen,
        kTplGroupChristmas,
        kTplGroupMilestoneNear,
        kTplGroupMoodPartner,
        kTplGroupNoPhotosWeekend,
        kTplGroupStreakMilestone,
      ];
      for (final group in groups) {
        expect(templatesForGroup(group), isNotEmpty, reason: group);
      }
    });
  });

  group('template source', () {
    const source = TemplateQuestionSource();

    test('proposeGroup is deterministic and fills no placeholders raw',
        () async {
      final ctx = ctxFor(DateTime(2026, 9, 7));
      final a = await source.proposeGroup(ctx, kTplGroupWeekStart);
      final b = await source.proposeGroup(ctx, kTplGroupWeekStart);
      expect(a, isNotNull);
      expect(a!.templateKey, b!.templateKey);
      expect(a.questionVi.contains('%'), isFalse);
      expect(a.questionEn.contains('%'), isFalse);
      expect(a.source, 'template');
      expect(a.templateKey!.startsWith('$kTplGroupWeekStart:'), isTrue);
    });

    test('avoids keys listed in recentTemplateKeys', () async {
      final plain = await source.proposeGroup(
        ctxFor(DateTime(2026, 9, 7)),
        kTplGroupWeekStart,
      );
      final avoided = await source.proposeGroup(
        ctxFor(DateTime(2026, 9, 7),
            recentTemplateKeys: <String>[plain!.templateKey!]),
        kTplGroupWeekStart,
      );
      expect(avoided, isNotNull);
      expect(avoided!.templateKey, isNot(plain.templateKey));
    });

    test('mood group substitutes a real word and skips unknown moods',
        () async {
      final known = await source.proposeGroup(
        ctxFor(DateTime(2026, 9, 7), partnerMood: 'tired'),
        kTplGroupMoodPartner,
      );
      expect(known, isNotNull);
      expect(known!.questionVi.contains('mệt'), isTrue);
      expect(known.questionEn.contains('tired'), isTrue);

      final unknown = await source.proposeGroup(
        ctxFor(DateTime(2026, 9, 7), partnerMood: 'not-a-mood'),
        kTplGroupMoodPartner,
      );
      expect(unknown, isNull);
    });

    test('milestone copy only counts down BEFORE the milestone', () async {
      // 100 days after 2024-01-01 is 2024-04-10; two days before → "còn 2".
      final before = await source.proposeGroup(
        ctxFor(DateTime(2024, 4, 8), anniversary: DateTime(2024, 1, 1)),
        kTplGroupMilestoneNear,
      );
      expect(before, isNotNull);
      expect(before!.questionVi.contains('100'), isTrue);
      expect(before.questionVi.contains('%'), isFalse);

      // Far from any milestone → nothing to say.
      final far = await source.proposeGroup(
        ctxFor(DateTime(2024, 6, 1), anniversary: DateTime(2024, 1, 1)),
        kTplGroupMilestoneNear,
      );
      expect(far, isNull);
    });

    test('unknown group returns null so the engine can fall through', () async {
      expect(
        await source.proposeGroup(ctxFor(DateTime(2026, 9, 7)), 'nope'),
        isNull,
      );
    });

    test('nearestMilestoneOffset also catches whole years', () {
      final hit = TemplateQuestionSource.nearestMilestoneOffset(
        DateTime(2024, 1, 1),
        DateTime(2025, 12, 30),
      );
      expect(hit, isNotNull);
      expect(hit!.milestone, 730);
      expect(hit.offset.abs() <= TemplateQuestionSource.milestoneWindowDays,
          isTrue);
      expect(
        TemplateQuestionSource.nearestMilestoneOffset(
          DateTime(2024, 1, 1),
          DateTime(2023, 12, 25),
        ),
        isNull,
      );
    });
  });

  group('ResolvedQuestion', () {
    test('picks text and hint by language with fallbacks', () {
      const q = ResolvedQuestion(
        questionVi: 'Câu hỏi',
        questionEn: 'Question',
        source: 'template',
        hintVi: 'Gợi ý',
      );
      expect(q.textFor('vi'), 'Câu hỏi');
      expect(q.textFor('en'), 'Question');
      expect(q.hintFor('vi'), 'Gợi ý');
      expect(q.hintFor('en'), 'Gợi ý');

      const noHint = ResolvedQuestion(
        questionVi: 'A',
        questionEn: 'B',
        source: 'bank',
      );
      expect(noHint.hintFor('vi'), isNull);
    });
  });

  group('deterministic primitives', () {
    test('hash + permutation are stable and total', () {
      expect(stableQuestionHash('abc'), stableQuestionHash('abc'));
      expect(stableQuestionHash('abc'), isNot(stableQuestionHash('abd')));
      final perm = deterministicPermutation(10, stableQuestionHash('x'));
      expect(perm.toSet().length, 10);
      expect(perm, deterministicPermutation(10, stableQuestionHash('x')));
      expect(daysSinceQuestionEpoch(DateTime(2020, 1, 2)), 1);
    });
  });
}

/// Minimal stand-in for the sources other agents own ('revisit' / 'ai').
class _StubSource implements QuestionSource {
  const _StubSource(this.key);

  @override
  final String key;

  @override
  Future<QuestionCandidate?> propose(QuestionContext ctx) async => null;
}
