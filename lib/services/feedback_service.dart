import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'firebase_bootstrap_service.dart';

/// Loại tin góp ý — khớp enum `type` trong `firestore.rules` (`match /feedback`).
enum FeedbackType { idea, bug, rating }

/// Gửi góp ý / báo lỗi / đánh giá thấp (feature `feedback`).
///
/// ⚠️ Schema bám `feedbackOk()` trong `firestore.rules`: field tuỳ chọn không có
/// thì BỎ key (không gửi null), không thêm key lạ. Ảnh (nếu có) upload vào
/// `feedback/<uid>/<uuid>.jpg` TRƯỚC, rồi mới ghi doc kèm `screenshotPath`.
/// Không có Firestore local fallback: tin mà không tới được máy chủ thì vô nghĩa.
class FeedbackService {
  const FeedbackService();

  static const int maxMessageLength = 2000;
  static const int maxPhotoBytes = 10 * 1024 * 1024;
  static const Duration _timeout = Duration(seconds: 20);

  bool get isUsingFirebase =>
      FirebaseBootstrapService.isFirebaseReady && Firebase.apps.isNotEmpty;

  /// Ném [Exception] khi không gửi được (mạng, timeout, chưa đăng nhập,
  /// không có Firebase) để UI hiện banner + giữ nguyên nội dung.
  Future<void> submit({
    required FeedbackType type,
    required String message,
    int? stars,
    File? screenshot,
    String? locale,
  }) async {
    final uid = isUsingFirebase ? FirebaseAuth.instance.currentUser?.uid : null;
    if (uid == null || uid.isEmpty) {
      throw Exception('feedback: not signed in / Firebase unavailable');
    }
    final text = message.trim();
    if (text.length > maxMessageLength ||
        (type != FeedbackType.rating && text.isEmpty)) {
      throw ArgumentError('feedback: invalid message length');
    }

    await _send(
      uid: uid,
      type: type,
      text: text,
      stars: stars,
      screenshot: screenshot,
      locale: locale,
    ).timeout(_timeout);
  }

  Future<void> _send({
    required String uid,
    required FeedbackType type,
    required String text,
    required int? stars,
    required File? screenshot,
    required String? locale,
  }) async {
    String? screenshotPath;
    if (screenshot != null) {
      screenshotPath = 'feedback/$uid/${const Uuid().v4()}.jpg';
      await FirebaseStorage.instance
          .ref(screenshotPath)
          .putFile(screenshot, SettableMetadata(contentType: 'image/jpeg'));
    }

    final info = await PackageInfo.fromPlatform();
    final device = await _deviceInfo();
    final email = FirebaseAuth.instance.currentUser?.email;

    // ponytail: build số không parse được → 0 (rules chỉ cần int).
    final data = <String, dynamic>{
      'userId': uid,
      'type': type.name,
      'message': text,
      'appVersion': _clip(info.version, 20),
      'buildNumber': int.tryParse(info.buildNumber) ?? 0,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'createdAt': FieldValue.serverTimestamp(),
      if (stars != null && stars >= 1 && stars <= 5) 'stars': stars,
      'screenshotPath': ?screenshotPath,
      if (device.os != null) 'osVersion': _clip(device.os!, 60),
      if (device.model != null) 'deviceModel': _clip(device.model!, 80),
      if (locale != null && locale.isNotEmpty) 'locale': _clip(locale, 10),
      if (email != null && email.isNotEmpty) 'email': _clip(email, 200),
    };
    await FirebaseFirestore.instance.collection('feedback').add(data);
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  Future<({String? os, String? model})> _deviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        // `utsname.machine` (iPhone15,2) — `model` chỉ là "iPhone".
        return (os: '${i.systemName} ${i.systemVersion}', model: i.utsname.machine);
      }
      final a = await plugin.androidInfo;
      return (
        os: 'Android ${a.version.release} (SDK ${a.version.sdkInt})',
        model: '${a.manufacturer} ${a.model}',
      );
    } catch (_) {
      return (os: null, model: null);
    }
  }
}
