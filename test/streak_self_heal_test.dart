import 'package:dear_embeiu/services/daily_question_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Self-heal of the `bothAnswered` streak flag: which markers a client may
// re-flag, and what counts as "both answered".
void main() {
  const question = {'questionVi': 'Câu hỏi?', 'questionEn': 'Question?'};

  test('only flagless markers that carry their question get re-flagged', () {
    expect(DailyQuestionService.markerNeedsRevealFlag({...question}), isTrue);
    expect(
      DailyQuestionService.markerNeedsRevealFlag({
        ...question,
        'bothAnswered': false,
      }),
      isTrue,
    );
    expect(
      DailyQuestionService.markerNeedsRevealFlag({
        ...question,
        'bothAnswered': true,
      }),
      isFalse,
    );
    // No marker / no question: the rule would deny the write and inventing a
    // question breaks the journal — left to the Cloud Function.
    expect(DailyQuestionService.markerNeedsRevealFlag(null), isFalse);
    expect(
      DailyQuestionService.markerNeedsRevealFlag({'date': '2026-10-01'}),
      isFalse,
    );
    expect(
      DailyQuestionService.markerNeedsRevealFlag({'questionVi': 'Câu hỏi?'}),
      isFalse,
    );
  });

  test('both answered needs two non-blank answers', () {
    expect(
      DailyQuestionService.bothAnswered([
        {'text': 'A'},
        {'text': 'B'},
      ]),
      isTrue,
    );
    expect(
      DailyQuestionService.bothAnswered([
        {'text': 'A'},
      ]),
      isFalse,
    );
    expect(
      DailyQuestionService.bothAnswered([
        {'text': 'A'},
        {'text': '   '},
      ]),
      isFalse,
    );
    expect(
      DailyQuestionService.bothAnswered([
        {'text': 'A'},
        <String, dynamic>{},
      ]),
      isFalse,
    );
  });
}
