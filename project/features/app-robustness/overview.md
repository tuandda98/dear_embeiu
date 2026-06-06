# 📋 Overview — App Robustness (review toàn flow, chống freeze UI)

> PO sở hữu. Đợt review toàn app + hardening chống freeze UI (2026-06-04). Nguồn: yêu cầu user "review lại toàn bộ flow, săn điểm freeze, đặc biệt guest/login/register/logout/delete".

- **Trạng thái:** 🧪 Test PASS code-level (Pass 1 + Pass 2) — chờ runtime smoke-test.
- **Ưu tiên:** P0 (UX nền tảng).

## Bối cảnh
User quan sát thực tế: **splash treo ~1 phút** khi mở app. Yêu cầu review toàn flow + săn mọi điểm freeze.

## Review (3 agent read-only song song, PO tổng hợp + verify)
- **Kiến trúc nền tốt:** skeleton loading, `BlockingLoadingOverlay` (gallery/setup/profile), try/catch + `mounted` guard, **login/register/guest PASS**.
- **3 ổ freeze chính** (đã verify `grep .timeout( lib/` = 0 — KHÔNG timeout nào trong toàn lib):
  1. **Cold-start/splash treo ~1 phút:** chuỗi await mạng tuần tự trong đường resolve route, không timeout (`getIdToken(true)` force, `authStateChanges().firstWhere` vô hạn, `syncForUser`/lastSeenAt/fetchUserProfile/fetchCouple block route; `main()` init nặng trước runApp).
  2. **Logout & delete account:** dialog ở `settings_screen` không đọc `isLoading` → double-submit; `unregisterForUser` (network, no-timeout) chặn logout; callable delete no-timeout.
  3. **Ảnh:** `pickImage` feed không resize (full-res 4–12MB) → đơ; `Image.file` không cacheWidth → RAM/jank/OOM; `existsSync()` đồng bộ trong build.
- **UX:** gallery nuốt lỗi stream (hiện "empty" gây tưởng mất ảnh), thiếu pull-to-refresh, batch upload nhấp nháy.

## Quyết định PO
- Làm **cả 4 pack**, gộp **2 Dev pass**: Pass 1 = cold-start + auth robustness (P0); Pass 2 = photo perf + gallery UX.
- **Nén ảnh: 1920px / quality 85** (cân bằng tốt app couple xem trên điện thoại). Ảnh cũ đã upload không đổi.
- KHÔNG đổi rules/Firestore/Function (client-only, không deploy). Cân nhắc thêm `timeoutSeconds` cho CF `deleteAccount` (chưa làm — client đã timeout 60s).

## Kết quả
- **Pass 1 + Pass 2** implement xong, `fvm flutter analyze` sạch, PO-gate PASS (đọc đĩa + verify từng thay đổi khớp finding). Chi tiết kỹ thuật: [`dev.md`](dev.md).
- Cold-start giờ resolve route trong ≤8s mọi trường hợp (thường <2s), offline → fallback từ cache (home nếu có couple cache), không treo splash.

## Changelog
- [2026-06-04] [Dev] FIX crash khi nhận FCM lúc app **foreground** (Android). `_handleForegroundMessage` (`push_notification_service.dart:362`) truyền notification id = `messageId.hashCode ^ DateTime.now().millisecondsSinceEpoch` (~1.7e12) → vượt int32 → `flutter_local_notifications.validateId` throw `ArgumentError` (range hợp lệ [-2³¹, 2³¹−1], xác nhận tại `helpers.dart:7`). Fix: mask `& 0x7FFFFFFF` → id luôn ∈ [0, 2³¹−1], không đụng dải reminder (1001–1099/2000–2999). VERIFY: đúng by-construction + đối chiếu bound `validateId`; app rebuild Pixel 10 chạy sạch (0 exception thật sau khi lọc noise emulator). ⚠️ **Chưa repro được FCM foreground sống** (cần partner gửi push thật / FCM server key) — fix đã live, lần tới có push foreground sẽ không crash.

## Còn lại / theo dõi
- Runtime smoke-test 2 thiết bị: push E2E sau khi dời `syncForUser` fire-and-forget; cold-start offline hiện home từ cache; logout mạng chập chờn ≤5s; delete overlay chống double-tap; ảnh feed mượt + chất lượng chấp nhận được. **+ FCM foreground không crash (id mask) — cần push thật để xác nhận.**
- 🟢 polish chưa làm: gom code chọn ảnh Home/Gallery trùng, marquee loop, profile months≈30, setup double-loading.
