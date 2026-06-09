import 'package:hive_flutter/hive_flutter.dart';

/// Per-type push notification preferences (feature notifications, D-notif-4).
///
/// The user can mute "low-stakes" pushes (new photo, reaction, daily-question
/// nudge) on THIS device while always-on types (love note, partner joined/left)
/// keep coming. Stored locally in Hive for an instant, offline-robust UI, then
/// MIRRORED into the device doc (`users/{uid}/devices/{id}`) so the Cloud
/// Functions fan-out can honour the choice at send time.
///
/// Field names match the device-doc keys the CF reads (`device.get(key, true)`)
/// so absent → default ON (backward-compatible with old app builds).
class NotificationSettingsService {
  NotificationSettingsService._();

  static final NotificationSettingsService instance =
      NotificationSettingsService._();

  static const String _boxName = 'notification_settings';

  /// Device-doc field keys (also the Hive keys). Mirror these in:
  /// - firestore.rules `isValidDeviceDocument` hasOnly list
  /// - functions/index.js `sendToRecipientDevices` type→pref map
  static const String keyPhoto = 'pushPhoto';
  static const String keyReaction = 'pushReaction';
  static const String keyDailyQuestion = 'pushDailyQuestion';

  static const List<String> allKeys = [keyPhoto, keyReaction, keyDailyQuestion];

  /// Reads all per-type prefs, defaulting each to ON when unset.
  Future<Map<String, bool>> load() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    return {
      for (final key in allKeys) key: box.get(key, defaultValue: true) as bool,
    };
  }

  /// Synchronous read used by the device-registration write (the box is opened
  /// once at startup, so it's already available). Falls back to all-ON if the
  /// box isn't open yet.
  Map<String, bool> currentOrDefault() {
    if (!Hive.isBoxOpen(_boxName)) {
      return {for (final key in allKeys) key: true};
    }
    final box = Hive.box<dynamic>(_boxName);
    return {
      for (final key in allKeys) key: box.get(key, defaultValue: true) as bool,
    };
  }

  /// Persists one pref locally. Mirroring to the device doc is the caller's job
  /// (so it can re-register with the current FCM token).
  Future<void> set(String key, bool value) async {
    final box = await Hive.openBox<dynamic>(_boxName);
    await box.put(key, value);
  }

  /// Opens the box so [currentOrDefault] works synchronously thereafter.
  Future<void> ensureLoaded() async {
    await Hive.openBox<dynamic>(_boxName);
  }
}
