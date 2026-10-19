import 'dart:math';

import 'package:dear_embeiu/data/activity_bank.dart';
import 'package:dear_embeiu/data/dish_bank.dart';
import 'package:dear_embeiu/models/decision.dart';
import 'package:dear_embeiu/services/push_notification_service.dart';
import 'package:dear_embeiu/utils/decision_suggester.dart';
import 'package:flutter_test/flutter_test.dart';

Decision pick(
  DecisionKind kind,
  String date,
  String result, {
  String resultId = '',
  String filter = 'tuy',
}) => Decision(
  id: '${date}_${kind.name}',
  kind: kind,
  date: date,
  result: result,
  resultId: resultId,
  filter: filter,
);

// Wednesday 2026-10-21.
final weekdayNoon = DateTime(2026, 10, 21, 12);
final weekdayEvening = DateTime(2026, 10, 21, 18);
final weekdayMorning = DateTime(2026, 10, 21, 8);
final saturdayNoon = DateTime(2026, 10, 24, 12);

double shareOf(
  List<(DecisionCandidate, double)> pool,
  bool Function(DecisionBankItem) test,
) {
  final total = pool.fold<double>(0, (s, e) => s + e.$2);
  final hit = pool
      .where((e) => e.$1.item != null && test(e.$1.item!))
      .fold<double>(0, (s, e) => s + e.$2);
  return hit / total;
}

void main() {
  test('banks keep their size, unique ids and fit the 40-char rule', () {
    expect(kDishBank.length, 117);
    expect(kActivityBank.length, 64);
    for (final bank in [kDishBank, kActivityBank]) {
      expect(bank.map((e) => e.id).toSet().length, bank.length);
      for (final item in bank) {
        expect(item.vi.length, lessThanOrEqualTo(kDecisionResultMax));
        expect(item.en.length, lessThanOrEqualTo(kDecisionResultMax));
      }
    }
  });

  test('eat/go doc ids are {date}_{kind}', () {
    expect(decisionDocId(DecisionKind.eat, '2026-10-21'), '2026-10-21_eat');
    expect(decisionDocId(DecisionKind.go, '2026-10-21'), '2026-10-21_go');
  });

  test('names normalise: trim, collapse spaces, ignore case', () {
    expect(normalizeDecisionName('  Bún   Chả '), 'bún chả');
    expect(normalizeDecisionName('Bún chả'), normalizeDecisionName('bún  CHẢ'));
  });

  group('eat', () {
    test('drops what was picked in the last 7 days, keeps day 8', () {
      final history = [
        pick(DecisionKind.eat, '2026-10-15', 'Bún chả', resultId: 'bun_cha'),
        pick(DecisionKind.eat, '2026-10-14', 'Phở bò', resultId: 'pho_bo'),
        // typed with odd spacing / case, no id — still excluded by name
        pick(DecisionKind.eat, '2026-10-20', '  pizza '),
      ];
      final ids = DecisionSuggester.pool(
        kind: DecisionKind.eat,
        filter: 'tuy',
        now: weekdayNoon,
        history: history,
        english: false,
      ).map((e) => e.$1.resultId).toSet();
      expect(ids.contains('bun_cha'), isFalse); // 6 days ago
      expect(ids.contains('pizza'), isFalse); // name match
      expect(ids.contains('pho_bo'), isTrue); // 7 days ago = outside window
    });

    test('10 spins never land on a dish picked this week', () {
      final s = DecisionSuggester(random: Random(1));
      final history = [
        for (var i = 0; i < 7; i++)
          pick(
            DecisionKind.eat,
            DecisionSuggester.dayKey(weekdayNoon, i),
            kDishBank[i].vi,
            resultId: kDishBank[i].id,
          ),
      ];
      final banned = {for (var i = 0; i < 7; i++) kDishBank[i].id};
      for (var i = 0; i < 10; i++) {
        final c = s.next(
          kind: DecisionKind.eat,
          now: weekdayNoon,
          history: history,
        )!;
        expect(banned.contains(c.resultId), isFalse);
      }
    });

    test('chips filter by tag', () {
      for (final (filter, tag) in [
        ('nha', 'nha'),
        ('ngoai', 'ngoai'),
        ('nhanh', 'nhanh'),
      ]) {
        final pool = DecisionSuggester.pool(
          kind: DecisionKind.eat,
          filter: filter,
          now: weekdayNoon,
          history: const [],
          english: false,
        );
        expect(pool, isNotEmpty);
        expect(pool.every((e) => e.$1.item!.has(tag)), isTrue, reason: filter);
      }
    });

    test('from 14:00 dinner dishes weigh x2 (>= 70% of the draw)', () {
      final pool = DecisionSuggester.pool(
        kind: DecisionKind.eat,
        filter: 'tuy',
        now: weekdayEvening,
        history: const [],
        english: false,
      );
      expect(pool.firstWhere((e) => e.$1.resultId == 'lau_thai').$2, 2);
      expect(pool.firstWhere((e) => e.$1.resultId == 'banh_cuon').$2, 1);
      expect(shareOf(pool, (i) => i.has('toi')), greaterThanOrEqualTo(0.7));
    });

    test('before 10:00 breakfast dishes weigh x2, noon adds nothing', () {
      final morning = DecisionSuggester.pool(
        kind: DecisionKind.eat,
        filter: 'tuy',
        now: weekdayMorning,
        history: const [],
        english: false,
      );
      expect(morning.firstWhere((e) => e.$1.resultId == 'banh_cuon').$2, 2);
      final noon = DecisionSuggester.pool(
        kind: DecisionKind.eat,
        filter: 'tuy',
        now: weekdayNoon,
        history: const [],
        english: false,
      );
      expect(noon.every((e) => e.$2 == 1), isTrue);
    });

    test('typed-in dishes of the last 90 days join the pool x2, once', () {
      final history = [
        pick(DecisionKind.eat, '2026-09-01', 'Bánh đúc nóng'),
        pick(DecisionKind.eat, '2026-09-10', 'bánh  đúc nóng'),
        pick(DecisionKind.eat, '2026-06-01', 'Món quá cũ'), // > 90 days
        pick(DecisionKind.eat, '2026-09-02', 'Canh cua', filter: 'nha'),
      ];
      final any = DecisionSuggester.pool(
        kind: DecisionKind.eat,
        filter: 'tuy',
        now: weekdayNoon,
        history: history,
        english: false,
      ).where((e) => e.$1.item == null).toList();
      expect(any.map((e) => normalizeDecisionName(e.$1.name)).toList(), [
        'bánh đúc nóng',
        'canh cua',
      ]);
      expect(any.every((e) => e.$2 == 2), isTrue);
      // A typed-in dish only joins the chip it was committed under.
      final nha = DecisionSuggester.pool(
        kind: DecisionKind.eat,
        filter: 'nha',
        now: weekdayNoon,
        history: history,
        english: false,
      ).where((e) => e.$1.item == null).map((e) => e.$1.name);
      expect(nha, ['Canh cua']);
    });

    test('no repeat inside a session until the pool runs out', () {
      final s = DecisionSuggester(random: Random(7));
      final seen = <String>{};
      final poolSize = DecisionSuggester.pool(
        kind: DecisionKind.eat,
        filter: 'nha',
        now: weekdayNoon,
        history: const [],
        english: false,
      ).length;
      for (var i = 0; i < poolSize; i++) {
        final c = s.next(
          kind: DecisionKind.eat,
          filter: 'nha',
          now: weekdayNoon,
        )!;
        expect(seen.add(c.resultId), isTrue, reason: 'repeat at spin $i');
      }
      // Pool exhausted → starts over instead of returning null.
      expect(
        s.next(kind: DecisionKind.eat, filter: 'nha', now: weekdayNoon),
        isNotNull,
      );
    });

    test('english session stores the English name', () {
      final c = DecisionSuggester(
        random: Random(3),
      ).next(kind: DecisionKind.eat, now: weekdayNoon, english: true)!;
      expect(c.name, c.item!.en);
    });
  });

  group('go', () {
    test('drops the last 14 days', () {
      final history = [
        pick(DecisionKind.go, '2026-10-08', 'Đi cà phê', resultId: 'ca_phe'),
        pick(DecisionKind.go, '2026-10-07', 'Đi dạo', resultId: 'di_dao'),
      ];
      final ids = DecisionSuggester.pool(
        kind: DecisionKind.go,
        filter: 'tuy',
        now: weekdayNoon,
        history: history,
        english: false,
      ).map((e) => e.$1.resultId).toSet();
      expect(ids.contains('ca_phe'), isFalse); // 13 days ago
      expect(ids.contains('di_dao'), isTrue); // 14 days ago
    });

    test('chips: free only free, stay-in only nha', () {
      for (final f in ['free', 'nha', 'ngoai']) {
        final pool = DecisionSuggester.pool(
          kind: DecisionKind.go,
          filter: f,
          now: weekdayNoon,
          history: const [],
          english: false,
        );
        expect(pool, isNotEmpty);
        expect(pool.every((e) => e.$1.item!.has(f)), isTrue);
      }
    });

    test(
      'weekend / evening favour cuoi_tuan + toi, weekday day halves cuoi_tuan',
      () {
        double w(DateTime now, String id) => DecisionSuggester.pool(
          kind: DecisionKind.go,
          filter: 'tuy',
          now: now,
          history: const [],
          english: false,
        ).firstWhere((e) => e.$1.resultId == id).$2;
        expect(w(saturdayNoon, 'picnic'), 2); // cuoi_tuan
        expect(w(saturdayNoon, 'karaoke'), 2); // toi
        expect(w(saturdayNoon, 'ca_phe'), 1); // ngay
        expect(w(weekdayEvening, 'karaoke'), 2);
        expect(w(weekdayNoon, 'picnic'), 0.5);
        expect(w(weekdayNoon, 'karaoke'), 1);
      },
    );
  });

  group('custom', () {
    test('only lands on the typed options', () {
      final s = DecisionSuggester(random: Random(5));
      final hits = <String>{};
      for (var i = 0; i < 50; i++) {
        hits.add(
          s.next(kind: DecisionKind.custom, options: ['Anh', 'Em'])!.name,
        );
      }
      expect(hits, {'Anh', 'Em'});
    });

    test('fewer than 2 options → nothing to spin', () {
      expect(
        DecisionSuggester().next(kind: DecisionKind.custom, options: ['Anh']),
        isNull,
      );
    });

    test('validation: 2..12 options, ≤40 each, ≤480 total, no duplicate', () {
      expect(validateCustomOptions(['A']), CustomOptionsIssue.tooFew);
      expect(validateCustomOptions(['A', 'B']), isNull);
      expect(
        validateCustomOptions([for (var i = 0; i < 12; i++) 'o$i']),
        isNull,
      );
      expect(
        validateCustomOptions([for (var i = 0; i < 13; i++) 'o$i']),
        CustomOptionsIssue.tooMany,
      );
      expect(
        validateCustomOptions(['A', 'x' * 41]),
        CustomOptionsIssue.tooLong,
      );
      // 12 × 40 = 480 is the ceiling and still fine.
      expect(
        validateCustomOptions([
          for (var i = 0; i < 12; i++)
            '${'x' * 38}${i.toString().padLeft(2, '0')}',
        ]),
        isNull,
      );
      expect(
        validateCustomOptions(['Anh', ' anh ']),
        CustomOptionsIssue.duplicate,
      );
    });
  });

  test('a food push for today cancels the meal nudge; other days do not', () {
    final now = DateTime(2026, 10, 21, 15);
    expect(
      isTodayMealDecisionPush({
        'type': 'decision',
        'kind': 'eat',
        'date': '2026-10-21',
      }, now),
      isTrue,
    );
    expect(
      isTodayMealDecisionPush({
        'type': 'decision',
        'kind': 'eat',
        'date': '2026-10-20',
      }, now),
      isFalse,
    );
    expect(
      isTodayMealDecisionPush({
        'type': 'decision',
        'kind': 'go',
        'date': '2026-10-21',
      }, now),
      isFalse,
    );
  });
}
