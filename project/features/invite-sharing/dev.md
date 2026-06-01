# 💻 Dev — invite-sharing (Phase 1: Copy + Share đồng bộ)

> Dev sở hữu. Đọc `overview.md` + `design.md` trước. Implement đúng logic + đúng design. Bám kiến trúc Provider + service (`../../../CLAUDE.md` mục 2).

- **Trạng thái dev:** xong / chờ test
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* Tạo 1 widget dùng chung `InviteActionButtons` (cụm 2 pill Copy | Share) bám đúng pattern nút Copy của Setup; 2 biến thể nền (`onDark` true=glass trắng cho Setup/Home, false=rose sáng cho Profile) + `iconOnly` cho banner Home hẹp. Gắn cùng widget vào cả 3 nơi để 1 "ngôn ngữ nút" lặp lại, không trùng lặp logic Clipboard/Share. State-gate giữ nguyên (cụm nút nằm trong guard `waiting_partner`/`inviteCode` sẵn có ⇒ tự ẩn khi couple `active`).
- *File/hàm đụng tới:*
  - **TẠO** `lib/widgets/invite_action_buttons.dart` — widget dùng chung (Copy: Clipboard + SnackBar `inviteCodeCopiedMsg`; Share: `SharePlus.instance.share(ShareParams(text: inviteShareMessage(code), sharePositionOrigin: ...))`).
  - **SỬA** `lib/screens/setup_screen.dart` `_buildInviteCodeCard` — gỡ nút Copy đơn lẻ + Row mã cũ; mã 30px về full-width (Text), cụm `InviteActionButtons(onDark:true)` xuống hàng riêng dưới mã (nhịp 10/8). Gỡ import `flutter/services.dart` (Clipboard không còn dùng trực tiếp), thêm import widget.
  - **SỬA** `lib/screens/home_screen.dart` banner chờ partner (guard `couple.inviteCode.isNotEmpty`) — bọc chip mã + `InviteActionButtons(onDark:true, iconOnly:true)` trong `Wrap(spacing:8)` để không overflow màn hẹp. Thêm import widget.
  - **SỬA** `lib/screens/profile_screen.dart` — thêm tham số optional `Widget? belowValue` vào `_buildDetailTile` (render dưới value, KHÔNG ảnh hưởng tile ngày/cột mốc); tile mã mời truyền `InviteActionButtons(onDark:false)`. Thêm import widget.
  - **SỬA** `pubspec.yaml` — thêm `share_plus: ^11.0.0` (resolve 11.1.0).
  - **SỬA** `lib/l10n/app_en.arb` + `app_vi.arb` — thêm `shareBtn` (getter) + `inviteShareMessage(code)` (placeholder String `code`) → `fvm flutter gen-l10n` sinh getter ở `app_localizations*.dart` (committed). KHÔNG hand-edit Dart (override PO; memory "hand-maintain" đã stale).
- *Thay đổi model / Firestore / Cloud Function / native config:* KHÔNG. Không đụng join/transaction/rules. share_plus không cần cấu hình native (1 bộ code Android+iOS).
- *Cần deploy?* Không.

## Quyết định kỹ thuật (chốt)
- **API share_plus:** dùng API KHÔNG deprecated của v11.1.0 — `SharePlus.instance.share(ShareParams(text: ..., sharePositionOrigin: origin))`. `Share.share()` cũ đã `@Deprecated` ở v11.
- **iPad popover:** tính `sharePositionOrigin` từ `RenderBox` của chính cụm nút (`box.localToGlobal(Offset.zero) & box.size`); null-safe nếu chưa có size ⇒ tránh crash popover trên iPad/macOS.
- **Câu mời (override PO):** BỎ dòng cuối "Tải app:"/"Get the app:" (design.md ghi có — đã bỏ vì app chưa lên store). Chỉ gồm lời mời + mã `{code}`.
- **l10n qua ARB + gen-l10n** (override PO), không hand-edit Dart.
- Share lỗi (hiếm, OS-driven) → bọc try-catch, no-op im lặng, không toast lỗi (theo design).

## Edge case kỹ thuật cần xử lý
- iPad/macOS share sheet popover cần origin (xử lý — null-safe). [VERIFIED code]
- Locale câu mời theo locale đang dùng (qua `context.l10n.inviteShareMessage`). [VERIFIED code]
- Emoji 💞 + `\n` + 1 placeholder `{code}` — gen-l10n sinh `$code` đúng, không vỡ ICU. [VERIFIED: đọc generated]
- Cụm nút tự ẩn khi `active` vì nằm trong guard cũ (không thêm state disabled). [VERIFIED code]

## Checklist implement
- [x] Thêm `share_plus` (pubspec) + pub get (resolve 11.1.0)
- [x] Tạo `InviteActionButtons` (2 biến thể + iconOnly)
- [x] Gắn Setup (hàng riêng dưới mã, glass có chữ)
- [x] Gắn Home banner (icon-only, Wrap chống overflow)
- [x] Gắn Profile (`belowValue`, rose sáng, không phá tile khác)
- [x] ARB en+vi + `fvm flutter gen-l10n`
- [x] `flutter analyze` sạch
- [x] Không hardcode chuỗi (qua l10n)

## Nhật ký implement
- [2026-06-01] [Dev] Phase 1 invite-sharing xong: tạo widget dùng chung `InviteActionButtons` (Copy bê nguyên logic Setup; Share = `SharePlus.instance.share(ShareParams(...))` v11.1.0, KHÔNG deprecated, có `sharePositionOrigin` cho iPad), gắn 3 nơi (Setup/Home banner icon-only/Profile rose). Thêm `share_plus ^11.0.0` (resolve 11.1.0). Thêm l10n `shareBtn` + `inviteShareMessage(code)` qua ARB en+vi + `fvm flutter gen-l10n` (override PO: KHÔNG hand-edit Dart; câu mời BỎ dòng "Tải app:"). `flutter analyze` sạch (0 lỗi). Profile thêm tham số optional `belowValue` cho `_buildDetailTile` (không phá tile ngày/cột mốc). Trạng thái dev: xong / chờ test.
- [2026-06-01] [Dev] fix: gate cụm Copy/Share ở Setup chỉ hiện khi waiting_partner (theo lưu ý Tester). Trong `setup_screen.dart` `_buildInviteCard` thêm cờ `showInviteActions = !hasCreatedCoupleSpace || isWaitingForPartner` rồi bọc `InviteActionButtons` (kèm SizedBox 10 phía trên) trong `if (showInviteActions)`. Mã + description giữ nguyên hiển thị; chỉ ẩn cụm nút khi couple `active`. CHỈ đụng setup_screen.dart. `fvm flutter analyze` sạch (0 lỗi).
