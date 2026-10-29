import 'package:dear_embeiu/services/rating_prompt_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 1);
  RatingPromptState s({
    int daysAgo = 10,
    int opens = 6,
    int? lastDaysAgo,
    bool high = false,
  }) => RatingPromptState(
    firstOpen: now.subtract(Duration(days: daysAgo)),
    openCount: opens,
    lastPrompt: lastDaysAgo == null
        ? null
        : now.subtract(Duration(days: lastDaysAgo)),
    ratedHigh: high,
  );

  test('đủ điều kiện', () => expect(RatingPromptService.shouldPrompt(s(), now), true));
  test('chưa đủ 7 ngày', () => expect(RatingPromptService.shouldPrompt(s(daysAgo: 6), now), false));
  test('chưa đủ 5 lần mở', () => expect(RatingPromptService.shouldPrompt(s(opens: 4), now), false));
  test('mời cách <90 ngày', () => expect(RatingPromptService.shouldPrompt(s(lastDaysAgo: 89), now), false));
  test('mời cách >=90 ngày', () => expect(RatingPromptService.shouldPrompt(s(lastDaysAgo: 90), now), true));
  test('đã chấm 4-5', () => expect(RatingPromptService.shouldPrompt(s(high: true), now), false));
  test('chưa có ngày cài', () => expect(RatingPromptService.shouldPrompt(const RatingPromptState(openCount: 9), now), false));
}
