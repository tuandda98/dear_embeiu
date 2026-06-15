import 'package:hive_flutter/hive_flutter.dart';

/// Per-type push notification preferences (feature notifications, D-notif-4).
///
/// Notifications revamp (2026-06-14): the per-type push opt-out UI was removed —
/// a couple ALWAYS gets every push. The prefs mirrored into the device doc are
/// therefore forced ALL-ON ([currentOrDefault] no longer reads stored values).
/// The field keys are still sent (the device-doc `hasOnly` rule lists them) and
/// the legacy [load]/[set] APIs remain so older callers/tests don't break, but
/// nothing in the UI mutes a type any more.
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

  /// Prefs mirrored into the device doc on registration. Notifications revamp
  /// (2026-06-14): always ALL-ON — the per-type push opt-out was removed, so a
  /// couple always gets every push regardless of any stored value. The keys are
  /// still sent (the device-doc `hasOnly` rule lists them).
  Map<String, bool> currentOrDefault() {
    return {for (final key in allKeys) key: true};
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
