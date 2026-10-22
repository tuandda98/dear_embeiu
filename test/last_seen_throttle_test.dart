import 'package:dear_embeiu/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lastSeenAt: tối đa 1 lần ghi mỗi giờ', () {
    var now = DateTime(2026, 10, 15, 9);
    final service = UserService(clock: () => now);

    expect(service.takeLastSeenSlot(), isTrue); // lần mở đầu tiên
    now = now.add(const Duration(minutes: 5));
    expect(service.takeLastSeenSlot(), isFalse); // chuyển app liên tục
    now = now.add(const Duration(minutes: 54, seconds: 59));
    expect(service.takeLastSeenSlot(), isFalse); // 59p59s sau lần ghi
    now = now.add(const Duration(seconds: 1));
    expect(service.takeLastSeenSlot(), isTrue); // tròn 1 giờ
    expect(service.takeLastSeenSlot(), isFalse);
  });
}
