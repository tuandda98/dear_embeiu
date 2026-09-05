import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/data/revisit_templates.dart';
import 'package:dear_embeiu/services/revisit_question_source.dart';

/// Pure-logic tests for the "NHÌN LẠI" question source (feature
/// `endless-questions`). Firestore access is deliberately not covered here —
/// everything below is the deterministic part the two devices must agree on.
void main() {
  String keyOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  group('monthsAgo (clamp cuối tháng)', () {
    test('giữ nguyên ngày khi tháng đích đủ dài', () {
      expect(monthsAgo(DateTime(2026, 9, 5), 1), DateTime.utc(2026, 8, 5));
    });

    test('31 → 30 khi tháng trước chỉ có 30 ngày', () {
      expect(monthsAgo(DateTime(2026, 5, 31), 1), DateTime.utc(2026, 4, 30));
    });

    test('31 → 28 với tháng 2 năm thường', () {
      expect(monthsAgo(DateTime(2026, 3, 31), 1), DateTime.utc(2026, 2, 28));
    });

    test('31 → 29 với tháng 2 năm nhuận', () {
      expect(monthsAgo(DateTime(2028, 3, 31), 1), DateTime.utc(2028, 2, 29));
    });

    test('lùi qua ranh giới năm', () {
      expect(monthsAgo(DateTime(2026, 1, 31), 1), DateTime.utc(2025, 12, 31));
    });
  });

  group('revisitTargetsFor', () {
    final today = DateTime(2026, 9, 5);
    final targets = revisitTargetsFor(today);

    test('4 mốc theo đúng thứ tự ưu tiên 365 > 100 > 30 > tháng trước', () {
      expect(
        targets.map((t) => t.bucket).toList(),
        <String>[
          revisitBucketYear,
          revisitBucketHundred,
          revisitBucketThirty,
          revisitBucketMonth,
        ],
      );
      expect(targets.map((t) => t.bucket).toList(), revisitBucketPriority);
    });

    test('ngày mốc và dung sai đúng', () {
      expect(targets[0].date, DateTime.utc(2025, 9, 5));
      expect(targets[1].date, DateTime.utc(2026, 5, 28));
      expect(targets[2].date, DateTime.utc(2026, 8, 6));
      expect(targets[3].date, DateTime.utc(2026, 8, 5));
      expect(targets.take(3).every((t) => t.toleranceDays == 2), isTrue);
      expect(targets[3].toleranceDays, 0);
    });
  });

  group('pickRevisitDate', () {
    final today = DateTime(2026, 9, 5);
    const seed = 'couple-1|2026-09-05';

    test('bắt được ngày cách 30 ngày', () {
      final pick = pickRevisitDate(
        today: today,
        availableDateKeys: <String>['2026-08-06'],
        seedKey: seed,
      );
      expect(pick, isNotNull);
      expect(pick!.bucket, revisitBucketThirty);
      expect(pick.dateKey, '2026-08-06');
    });

    test('chấp nhận lệch ±2 ngày, loại lệch 3 ngày', () {
      for (final k in <String>['2026-08-04', '2026-08-08']) {
        expect(
          pickRevisitDate(
            today: today,
            availableDateKeys: <String>[k],
            seedKey: seed,
          )?.bucket,
          revisitBucketThirty,
          reason: k,
        );
      }
      expect(
        pickRevisitDate(
          today: today,
          availableDateKeys: <String>['2026-08-09'],
          seedKey: seed,
        ),
        isNull,
      );
    });

    test('ưu tiên 365 > 100 > 30 khi có đủ ứng viên', () {
      final pick = pickRevisitDate(
        today: today,
        availableDateKeys: <String>['2026-08-06', '2026-05-28', '2025-09-05'],
        seedKey: seed,
      );
      expect(pick!.bucket, revisitBucketYear);
      expect(pick.dateKey, '2025-09-05');

      final withoutYear = pickRevisitDate(
        today: today,
        availableDateKeys: <String>['2026-08-06', '2026-05-28'],
        seedKey: seed,
      );
      expect(withoutYear!.bucket, revisitBucketHundred);
    });

    test('cùng ngày tháng trước (clamp) khi không trúng mốc ngày', () {
      // 31/03 → tháng trước = 28/02 (clamp) → dùng copy 'ngày này tháng trước'.
      final clamped = pickRevisitDate(
        today: DateTime(2026, 3, 31),
        availableDateKeys: <String>['2026-02-28'],
        seedKey: seed,
      );
      expect(clamped, isNotNull);
      expect(clamped!.bucket, revisitBucketMonth);
      expect(clamped.dateKey, '2026-02-28');

      // Đúng ngày kỷ niệm tháng (30/06 so với 30/07) cũng vào nhóm 'month'
      // dù nó nằm luôn trong cửa sổ 30 ngày ±2.
      final monthly = pickRevisitDate(
        today: DateTime(2026, 7, 30),
        availableDateKeys: <String>['2026-06-30'],
        seedKey: seed,
      );
      expect(monthly!.bucket, revisitBucketMonth);
      expect(monthly.dateKey, '2026-06-30');
    });

    test('bỏ qua ngày đã nhìn lại gần đây', () {
      expect(
        pickRevisitDate(
          today: today,
          availableDateKeys: <String>['2026-08-06'],
          excludedDateKeys: <String>{'2026-08-06'},
          seedKey: seed,
        ),
        isNull,
      );
    });

    test('bỏ qua 7 ngày gần nhất và ngày sai định dạng', () {
      final fresh = <String>[
        for (var i = 0; i <= 7; i++)
          keyOf(today.subtract(Duration(days: i))),
        'hôm-qua',
      ];
      expect(
        pickRevisitDate(
          today: today,
          availableDateKeys: fresh,
          seedKey: seed,
        ),
        isNull,
      );
    });

    test('deterministic: cùng seed → cùng kết quả, khác seed có thể khác', () {
      final options = <String>['2026-08-04', '2026-08-05', '2026-08-06'];
      final a = pickRevisitDate(
        today: today,
        availableDateKeys: options,
        seedKey: seed,
      );
      final b = pickRevisitDate(
        today: today,
        availableDateKeys: options.reversed,
        seedKey: seed,
      );
      expect(a!.dateKey, b!.dateKey);
      expect(options.contains(a.dateKey), isTrue);
    });

    test('rỗng → null', () {
      expect(
        pickRevisitDate(
          today: today,
          availableDateKeys: const <String>[],
          seedKey: seed,
        ),
        isNull,
      );
    });
  });

  group('truncateForQuote', () {
    test('giữ nguyên khi ngắn hơn giới hạn', () {
      expect(truncateForQuote('  Câu hỏi ngắn  ', 90), 'Câu hỏi ngắn');
    });

    test('gộp khoảng trắng', () {
      expect(truncateForQuote('a\n  b\tc', 90), 'a b c');
    });

    test('cắt đúng độ dài và thêm dấu …', () {
      final long = 'á' * 200;
      final cut = truncateForQuote(long, 90);
      expect(cut.runes.length, 90);
      expect(cut.endsWith('…'), isTrue);
    });

    test('chuỗi rỗng → rỗng', () {
      expect(truncateForQuote('   ', 90), '');
    });
  });

  group('renderRevisitQuestion', () {
    const seed = 'couple-1|2026-09-05';
    const oldVi = 'Khoảnh khắc nào khiến bạn nhận ra mình thích người ấy?';
    const oldEn = 'What moment made you realize you liked your partner?';

    test('có cả vi + en, trích câu hỏi cũ, không có ICU braces', () {
      for (final bucket in revisitBucketPriority) {
        final text = renderRevisitQuestion(
          bucket: bucket,
          oldQuestionVi: oldVi,
          oldQuestionEn: oldEn,
          seedKey: seed,
        );
        expect(text.vi.contains(oldVi), isTrue, reason: bucket);
        expect(text.en.contains(oldEn), isTrue, reason: bucket);
        expect(text.vi.contains('{'), isFalse, reason: bucket);
        expect(text.vi.contains('}'), isFalse, reason: bucket);
        expect(text.en.contains('{'), isFalse, reason: bucket);
        expect(text.en.contains('}'), isFalse, reason: bucket);
        expect(text.vi.runes.length <= 280, isTrue, reason: bucket);
        expect(text.en.runes.length <= 280, isTrue, reason: bucket);
      }
    });

    test('câu hỏi cũ dài bị cắt, tổng vẫn ≤ 280', () {
      final long = 'Câu hỏi rất dài ${'x' * 400}?';
      for (final bucket in revisitBucketPriority) {
        final text = renderRevisitQuestion(
          bucket: bucket,
          oldQuestionVi: long,
          oldQuestionEn: long,
          seedKey: seed,
        );
        expect(text.vi.contains('…'), isTrue, reason: bucket);
        expect(text.vi.runes.length <= 280, isTrue, reason: bucket);
        expect(text.en.runes.length <= 280, isTrue, reason: bucket);
      }
    });

    test('thiếu bản EN → dùng lại bản VI', () {
      final text = renderRevisitQuestion(
        bucket: revisitBucketYear,
        oldQuestionVi: oldVi,
        oldQuestionEn: '   ',
        seedKey: seed,
      );
      expect(text.en.contains(oldVi), isTrue);
    });

    test('deterministic theo seed', () {
      final a = renderRevisitQuestion(
        bucket: revisitBucketThirty,
        oldQuestionVi: oldVi,
        oldQuestionEn: oldEn,
        seedKey: seed,
      );
      final b = renderRevisitQuestion(
        bucket: revisitBucketThirty,
        oldQuestionVi: oldVi,
        oldQuestionEn: oldEn,
        seedKey: seed,
      );
      expect(a.vi, b.vi);
    });

    test('bucket lạ → fallback mẫu 30 ngày, không crash', () {
      final text = renderRevisitQuestion(
        bucket: 'không-tồn-tại',
        oldQuestionVi: oldVi,
        oldQuestionEn: oldEn,
        seedKey: seed,
      );
      expect(text.vi.isNotEmpty, isTrue);
      expect(text.en.isNotEmpty, isTrue);
    });
  });

  group('revisitTemplates (dữ liệu)', () {
    test('mỗi nhóm ≥ 6 mẫu, đủ vi + en, không ICU braces', () {
      for (final bucket in revisitBucketPriority) {
        final variants = revisitTemplates[bucket];
        expect(variants, isNotNull, reason: bucket);
        expect(variants!.length >= 6, isTrue, reason: bucket);
        for (final t in variants) {
          expect(t.viPrefix.trim().isNotEmpty, isTrue, reason: bucket);
          expect(t.viSuffix.trim().isNotEmpty, isTrue, reason: bucket);
          expect(t.enPrefix.trim().isNotEmpty, isTrue, reason: bucket);
          expect(t.enSuffix.trim().isNotEmpty, isTrue, reason: bucket);
          final joined =
              t.viPrefix + t.viSuffix + t.enPrefix + t.enSuffix;
          expect(joined.contains('{'), isFalse, reason: bucket);
          expect(joined.contains('}'), isFalse, reason: bucket);
          // Giọng văn: "chúng mình", không dùng "hai đứa".
          expect(t.viPrefix.contains('hai đứa'), isFalse, reason: bucket);
          expect(t.viSuffix.contains('hai đứa'), isFalse, reason: bucket);
        }
      }
    });
  });

  group('buildRevisitHints', () {
    test('null / rỗng → null', () {
      expect(buildRevisitHints(null), isNull);
      expect(buildRevisitHints('   '), isNull);
    });

    test('trích câu trả lời cũ của chính mình, cắt ≤ 80', () {
      final hints = buildRevisitHints('á' * 200);
      expect(hints, isNotNull);
      expect(hints!.vi.startsWith('Hồi đó bạn viết: "'), isTrue);
      expect(hints.en.startsWith('Back then you wrote: "'), isTrue);
      expect(hints.vi.contains('…'), isTrue);
      // 80 ký tự trích + phần vỏ.
      expect(hints.vi.runes.length, 'Hồi đó bạn viết: ""'.length + 80);
    });
  });

  group('fnv1a32', () {
    test('ổn định và nằm trong 32 bit', () {
      expect(fnv1a32('abc'), fnv1a32('abc'));
      expect(fnv1a32('abc') == fnv1a32('abd'), isFalse);
      expect(fnv1a32('couple|2026-09-05') <= 0xFFFFFFFF, isTrue);
      expect(fnv1a32('') , 0x811c9dc5);
    });
  });
}
