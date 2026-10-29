import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../widgets/catchup_gate.dart';
import '../widgets/rating_sheet.dart';

/// Trạng thái lưu để quyết định có mời chấm sao hay không (feature `feedback`, D2).
class RatingPromptState {
  const RatingPromptState({
    this.firstOpen,
    this.openCount = 0,
    this.lastPrompt,
    this.ratedHigh = false,
  });

  final DateTime? firstOpen;
  final int openCount;
  final DateTime? lastPrompt;
  final bool ratedHigh;
}

/// Tự mời chấm sao sau khoảnh khắc vui. Lưu trong Hive `app_settings`
/// (`Box<String>` → mọi giá trị là chuỗi).
class RatingPromptService {
  const RatingPromptService._();

  static const String _boxName = 'app_settings';
  static const String _kFirstOpen = 'rating_first_open';
  static const String _kOpenCount = 'rating_open_count';
  static const String _kLastPrompt = 'rating_last_prompt';
  static const String _kRatedHigh = 'rating_rated_high';

  static const int minDaysInstalled = 7;
  static const int minOpens = 5;
  static const int minDaysBetweenPrompts = 90;

  static bool _countedThisProcess = false;
  static bool _scheduling = false;

  /// Hàm thuần: đủ điều kiện mời chưa.
  static bool shouldPrompt(RatingPromptState s, DateTime now) {
    if (s.ratedHigh) return false;
    final first = s.firstOpen;
    if (first == null || now.difference(first).inDays < minDaysInstalled) {
      return false;
    }
    if (s.openCount < minOpens) return false;
    final last = s.lastPrompt;
    if (last != null && now.difference(last).inDays < minDaysBetweenPrompts) {
      return false;
    }
    return true;
  }

  static Future<Box<String>> _box() async => Hive.isBoxOpen(_boxName)
      ? Hive.box<String>(_boxName)
      : await Hive.openBox<String>(_boxName);

  static RatingPromptState _read(Box<String> box) => RatingPromptState(
    firstOpen: DateTime.tryParse(box.get(_kFirstOpen) ?? ''),
    openCount: int.tryParse(box.get(_kOpenCount) ?? '') ?? 0,
    lastPrompt: DateTime.tryParse(box.get(_kLastPrompt) ?? ''),
    ratedHigh: box.get(_kRatedHigh) == 'true',
  );

  /// Đếm 1 lần mở app / process (gọi từ Home.initState). Lần đầu cũng ghi ngày
  /// "cài" (user cũ cập nhật lên bản này thì tính từ lúc đó — chấp nhận).
  static Future<void> recordOpen() async {
    if (_countedThisProcess) return;
    _countedThisProcess = true;
    try {
      final box = await _box();
      if (box.get(_kFirstOpen) == null) {
        await box.put(_kFirstOpen, DateTime.now().toIso8601String());
      }
      final n = int.tryParse(box.get(_kOpenCount) ?? '') ?? 0;
      await box.put(_kOpenCount, '${n + 1}');
    } catch (_) {}
  }

  /// Đã chấm 4–5 sao (từ thẻ tự mời hoặc từ Cài đặt) → không tự mời nữa.
  static Future<void> markRatedHigh() async {
    try {
      await (await _box()).put(_kRatedHigh, 'true');
    } catch (_) {}
  }

  /// Gọi ở khoảnh khắc vui. Chờ ~1s, né sheet/modal khác, rồi mời nếu đủ điều
  /// kiện. Mọi lỗi đều im lặng.
  static Future<void> maybePrompt(
    BuildContext context, {
    required String source,
  }) async {
    if (_scheduling) return;
    _scheduling = true;
    try {
      final box = await _box();
      if (!shouldPrompt(_read(box), DateTime.now())) return;
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!context.mounted) return;
      // Chỉ hiện khi Home đang là màn trên cùng (không có sheet/dialog/màn khác
      // đè) và không có CatchupGate.
      if (ModalRoute.of(context)?.isCurrent != true || CatchupGate.isShowing) {
        return;
      }
      // Ghi "đã mời" lúc hiện — "Để sau" / vuốt đóng cũng đợi 90 ngày.
      await box.put(_kLastPrompt, DateTime.now().toIso8601String());
      if (!context.mounted) return;
      await RatingSheet.show(context, source: source);
    } catch (_) {
    } finally {
      _scheduling = false;
    }
  }
}
