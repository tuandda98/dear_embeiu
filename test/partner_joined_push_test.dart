import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/services/push_notification_service.dart';

// PF19 (feature pairing-funnel): the `partner_joined` push (CF
// notifyPartnerJoined, sent with wakeClients) is what cancels the invite
// follow-ups 1180–1189 while the creator's app is closed. Payloads mirror the
// CF: the alert push mirrors title/body into data, the Android wake companion
// carries the bare dataExtra.
void main() {
  test(
    'alert push and Android wake companion both cancel the invite nudges',
    () {
      expect(
        isPartnerJoinedPush({
          'type': 'partner_joined',
          'coupleId': 'c1',
          'joinerUserId': 'u2',
          'title': 'Người ấy đã vào',
          'body': '…',
        }),
        isTrue,
      );
      expect(
        isPartnerJoinedPush({
          'type': 'partner_joined',
          'coupleId': 'c1',
          'joinerUserId': 'u2',
        }),
        isTrue,
      );
    },
  );

  test('any other push leaves the invite nudges alone', () {
    for (final type in [
      'partner_left',
      'daily_question',
      'chat_message',
      'partner_reminder_set',
      '',
    ]) {
      expect(
        isPartnerJoinedPush({'type': type, 'coupleId': 'c1'}),
        isFalse,
        reason: type,
      );
    }
    expect(isPartnerJoinedPush({}), isFalse);
  });
}
