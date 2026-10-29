import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/services/push_notification_service.dart';
import 'package:dear_embeiu/services/reminder_service.dart';

/// flutter_local_notifications keeps only the tap callback of the LAST
/// `initialize`; ReminderService initialises after the push service, so both
/// pass one shared callback (đợt 2). Before that, tapping a foreground push
/// banner did nothing.
NotificationResponse _tap(String payload) => NotificationResponse(
  notificationResponseType: NotificationResponseType.selectedNotification,
  payload: payload,
);

void main() {
  setUp(() {
    NotificationTapRouter.pendingHomeTab.value = -1;
    ReminderService.pendingWeatherTap.value = null;
  });

  test('a foreground push banner still deep-links (chat → tab 1)', () {
    PushNotificationService.handleLocalNotificationTap(
      _tap('{"type":"chat_message"}'),
    );
    expect(NotificationTapRouter.pendingHomeTab.value, 1);
    expect(ReminderService.pendingWeatherTap.value, isNull);
  });

  test('the weather morning notice routes to its own handler', () {
    const payload =
        '{"type":"${ReminderService.weatherMorningType}","city":"vn-ha-noi"}';
    PushNotificationService.handleLocalNotificationTap(_tap(payload));
    expect(ReminderService.pendingWeatherTap.value, payload);
    expect(NotificationTapRouter.pendingHomeTab.value, 0);
  });

  test('a reminder with a plain payload is ignored', () {
    PushNotificationService.handleLocalNotificationTap(_tap('milestone'));
    expect(NotificationTapRouter.pendingHomeTab.value, -1);
  });
}
