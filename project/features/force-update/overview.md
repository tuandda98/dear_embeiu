# Force Update — Overview (PO)

> Bắt buộc người dùng cập nhật khi bản đang dùng quá cũ. PO sở hữu file này.

## Vấn đề / mục tiêu
Khi release bản mới (đặc biệt khi backend đổi schema, vá bug nghiêm trọng, hoặc bỏ hỗ trợ bản cũ), cần CHẶN các bản client quá cũ — không cho dùng tiếp tới khi cập nhật. Tránh tình trạng bản cũ gọi API/đọc dữ liệu sai → lỗi khó debug + trải nghiệm vỡ.

## Phạm vi (chốt với user 2026-06-14)
- **Chỉ HARD force** (chặn toàn trang, không bỏ qua được). KHÔNG làm soft/gợi-ý ở đợt này.
- **Nguồn cấu hình: Firestore doc `config/app`** (public-read). Đổi qua Firebase Console là có hiệu lực ngay, không cần build lại app. KHÔNG dùng firebase_remote_config (tránh thêm package).
- **So sánh theo build number toàn cục** (`pubspec` `+N`) — dự án không bao giờ reset build number nên so số nguyên là chính xác, khỏi parse SemVer.

## Cơ chế
1. Cold-start: `SessionResolver.resolveStartRoute` gọi `AppUpdateService.isForceUpdateRequired()` TRƯỚC mọi việc (kể cả auth) → nếu true, ra route `forceUpdate` (chặn cả guest).
2. Service đọc `config/app`, so `minBuildNumber` với build hiện tại (`package_info_plus`).
3. `ForceUpdateScreen`: full-screen, chặn back (`PopScope canPop:false`), nút "Cập nhật ngay" mở store (`url_launcher`).

## Nguyên tắc an toàn — FAIL-OPEN (quan trọng)
Mọi lỗi/offline-không-cache/doc-không-tồn-tại/`minBuildNumber` thiếu hoặc sai kiểu → **KHÔNG chặn**. Một sự cố config KHÔNG được khoá toàn bộ user khỏi app. Gate có timeout riêng 4s + nằm trong backstop 8s của resolver.

## Cách VẬN HÀNH (khi release bản mới muốn ép cập nhật)
1. Upload bản mới lên store như thường (build number tăng, vd `+7`).
2. Sau khi bản mới DUYỆT & LIVE trên store, vào Firebase Console → Firestore → doc `config/app`:
   - `minBuildNumber` = build number tối thiểu được phép chạy (vd đặt `7` để ép mọi bản `<7` cập nhật).
   - `iosStoreUrl` = link App Store (cần App Store ID), `androidStoreUrl` = link Play.
   ⚠️ **CHỈ nâng `minBuildNumber` SAU khi bản mới đã live trên store** — nếu không, user bị chặn mà chưa có bản để tải.
3. Doc public-read nên client đọc được ngay (không cần đăng nhập).

## Decision log
- [2026-06-14] Hard-only (không soft) · Firestore doc (không Remote Config) · so theo build number toàn cục · fail-open. (User chốt qua 2 câu hỏi.)

## Nợ / mở rộng tương lai
- Thêm mức SOFT (gợi ý optional, có nút "Để sau") — `latestBuildNumber` + banner/dialog dismissible.
- App Store ID (số) chưa biết → hiện để `iosStoreUrl` điền trực tiếp trong config doc; khi app live thì điền hằng `AppUrls.iosStore` luôn.
- `forceMessage` tuỳ chỉnh từ server (hiện copy cố định trong l10n).
