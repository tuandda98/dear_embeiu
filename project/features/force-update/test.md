
## Test — hybrid auto-store force-update (2026-06-20) [Master Tester]

VERDICT: **PASS** (code-level). 0 lock-out CAO · 2 TRUNG · 2 THẤP. Cần smoke-test runtime.

### Đã verify (đọc code)
- [VERIFIED] Fail-open tuyệt đối: mọi lỗi mạng/offline/doc-thiếu/field-thiếu/parse-hỏng/timeout/in_app_update-throw/iTunes-hỏng → `false` (không chặn). Backstop session_resolver 8s không bao giờ trả forceUpdate.
- [VERIFIED] Android back-out sau performImmediateUpdate(): update OK → process restart; back-out → return true → hard-block.
- [VERIFIED] _isNewerVersion: 1.3.10>1.3.9 (int-segment), version rỗng/lạ→0, 1.3 vs 1.3.0→false, không báo newer sai.
- [VERIFIED] Config TẮT (autoStoreForce false + no minBuildNumber) → không ép (Android không cả gọi checkForUpdate). Bật/tắt từ xa OK.
- [VERIFIED] minBuildNumber so buildNumber (build toàn cục) int compare, không nhầm version string.
- [VERIFIED] session_resolver phân nhánh Platform sạch, 2 hàm guard loại trừ nhau.

### Findings
- **[TRUNG] F1 — ✅ ĐÃ SỬA 2026-06-20:** `app_urls.dart:12` từ `iosStore=''` → `'https://apps.apple.com/app/id6775165592'`. Nút "Cập nhật ngay" iOS không còn no-op kể cả khi config thiếu iosStoreUrl.
- **[TRUNG] F2** — _storeUrl chỉ set sau khi đọc config OK; reach ForceUpdateScreen ngoài gate → null → fallback AppUrls (giờ đã có giá trị nhờ F1 fix). An toàn.
- **[THẤP] F3** — iOS auto so marketing version (info.version) vs iTunes version; KHÔNG bắt delta build-number cùng marketing version. Dùng minBuildNumber để ép theo build. Giới hạn iTunes API.
- **[THẤP] F4** — Lookup bằng bundleId; DEV bundle chưa lên store → results rỗng → false (fail-open đúng).

### Cần test runtime
1. Android In-App Update (Play internal testing, 2 thiết bị): updateAvailable → immediate UI → back-out rơi ForceUpdateScreen; sideload/emulator → throw → floor vẫn chặn.
2. iTunes Lookup bundleId PROD trả đúng version.
3. Bật/tắt từ xa: autoStoreForce:false + xoá minBuildNumber → không chặn.
4. Offline cold-start: fail-open ≤4s, không freeze splash (8s backstop).
