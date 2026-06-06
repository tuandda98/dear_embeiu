import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Feature: lottie-moments (Đợt 2 revamp).
///
/// Các "slot" animation có tên cố định. File .json nằm ở assets/lottie/.
/// Slot nào thiếu file → [LoveLottie] tự rơi về [LoveLottie.fallback], không
/// crash. Nhờ vậy có thể đổi animation chỉ bằng cách thả 1 file, không đụng code.
enum LoveLottieSlot {
  /// B nhập mã ghép đôi thành công (setup → home). ⭐ North Star: tỉ lệ ghép đôi.
  coupleJoined('assets/lottie/couple_joined.json'),

  /// Gallery chưa có ảnh nào. ⭐ North Star: mời đăng ảnh đầu tiên.
  emptyGallery('assets/lottie/empty_gallery.json'),

  /// Đạt cột mốc ngày yêu (520 / 1000 / 1314…). Slot đã sẵn, trigger in-app TBD.
  milestone('assets/lottie/milestone.json'),

  /// Mở khoá câu trả lời Daily Question (thay/nâng cấp confetti hiện tại).
  dailyReveal('assets/lottie/daily_reveal.json');

  const LoveLottieSlot(this.asset);

  final String asset;
}

/// Bọc Lottie an toàn cho các "khoảnh khắc" cảm xúc.
///
/// Render animation khi file asset nạp được; nếu file thiếu/hỏng → hiện
/// [fallback] (mặc định: không hiện gì), tuyệt đối không crash. Nhờ vậy slot
/// chưa có file vẫn an toàn và đổi animation chỉ bằng cách thả 1 file.
///
/// Tự chạy 1 lần (one-shot) khi [repeat] = false, hoặc lặp êm khi
/// [repeat] = true (hợp empty state).
class LoveLottie extends StatelessWidget {
  const LoveLottie({
    super.key,
    required this.slot,
    this.width,
    this.height,
    this.repeat = false,
    this.fallback = const SizedBox.shrink(),
  });

  final LoveLottieSlot slot;
  final double? width;
  final double? height;
  final bool repeat;

  /// Hiện khi cờ tắt hoặc file thiếu/hỏng. Mặc định = không hiện gì (giữ nguyên
  /// hành vi cũ tại điểm chèn).
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      slot.asset,
      width: width,
      height: height,
      repeat: repeat,
      fit: BoxFit.contain,
      // Thiếu/hỏng asset → rơi về fallback, tuyệt đối không vỡ màn hình.
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
