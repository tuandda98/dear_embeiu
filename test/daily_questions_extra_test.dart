import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/data/daily_questions.dart';
import 'package:dear_embeiu/data/daily_questions_extra.dart';

/// Normalized form used for duplicate detection: lowercase, punctuation
/// stripped, whitespace collapsed. Keeps the check tolerant to trivial
/// rewording of commas/question marks while still catching real repeats.
String _norm(String input) {
  final lowered = input.toLowerCase();
  final stripped = lowered.replaceAll(
    RegExp(r'''[.,;:!?"'“”‘’()\[\]…–—-]'''),
    ' ',
  );
  return stripped.replaceAll(RegExp(r'\s+'), ' ').trim();
}

void main() {
  group('dailyQuestionsExtra', () {
    test('has exactly 150 entries', () {
      expect(dailyQuestionsExtra.length, 150);
    });

    test('every entry has non-empty vi + en', () {
      for (var i = 0; i < dailyQuestionsExtra.length; i++) {
        final entry = dailyQuestionsExtra[i];
        final vi = entry['vi'];
        final en = entry['en'];
        expect(vi, isNotNull, reason: 'entry $i missing vi');
        expect(en, isNotNull, reason: 'entry $i missing en');
        expect(vi!.trim(), isNotEmpty, reason: 'entry $i has empty vi');
        expect(en!.trim(), isNotEmpty, reason: 'entry $i has empty en');
      }
    });

    test('no ICU braces in any string', () {
      for (var i = 0; i < dailyQuestionsExtra.length; i++) {
        final entry = dailyQuestionsExtra[i];
        for (final value in entry.values) {
          expect(value.contains('{'), isFalse, reason: 'entry $i has {');
          expect(value.contains('}'), isFalse, reason: 'entry $i has }');
        }
      }
    });

    test('every string is at most 200 characters', () {
      for (var i = 0; i < dailyQuestionsExtra.length; i++) {
        final entry = dailyQuestionsExtra[i];
        for (final value in entry.values) {
          expect(
            value.length,
            lessThanOrEqualTo(200),
            reason: 'entry $i too long: ${value.length} chars',
          );
        }
      }
    });

    test('no duplicates inside the extra bank (vi and en)', () {
      final seenVi = <String, int>{};
      final seenEn = <String, int>{};
      for (var i = 0; i < dailyQuestionsExtra.length; i++) {
        final vi = _norm(dailyQuestionsExtra[i]['vi']!);
        final en = _norm(dailyQuestionsExtra[i]['en']!);
        expect(
          seenVi.containsKey(vi),
          isFalse,
          reason: 'entry $i duplicates vi of entry ${seenVi[vi]}: $vi',
        );
        expect(
          seenEn.containsKey(en),
          isFalse,
          reason: 'entry $i duplicates en of entry ${seenEn[en]}: $en',
        );
        seenVi[vi] = i;
        seenEn[en] = i;
      }
    });

    test('no duplicates against the original bank (vi and en)', () {
      final baseVi = dailyQuestions.map((e) => _norm(e['vi']!)).toSet();
      final baseEn = dailyQuestions.map((e) => _norm(e['en']!)).toSet();
      for (var i = 0; i < dailyQuestionsExtra.length; i++) {
        final vi = _norm(dailyQuestionsExtra[i]['vi']!);
        final en = _norm(dailyQuestionsExtra[i]['en']!);
        expect(
          baseVi.contains(vi),
          isFalse,
          reason: 'entry $i repeats an original vi question: $vi',
        );
        expect(
          baseEn.contains(en),
          isFalse,
          reason: 'entry $i repeats an original en question: $en',
        );
      }
    });

    test('merged bank keeps the original entries at their original indices',
        () {
      final merged = [...dailyQuestions, ...dailyQuestionsExtra];
      expect(merged.length, dailyQuestions.length + 150);
      for (var i = 0; i < dailyQuestions.length; i++) {
        expect(merged[i], same(dailyQuestions[i]));
      }
    });
  });
}
