# Force Update — Dev log

> Dev sở hữu. Implement theo [overview.md](overview.md).

## Kiến trúc (client-only đọc config, không thêm package)
Đã có sẵn: `package_info_plus` (build hiện tại), `url_launcher` (mở store). KHÔNG thêm dependency.

### File
| File | Vai trò |
|---|---|
| `firestore.rules` | match `config/{document}`: `read: if true` (PUBLIC — gate chạy trước login), `write: if false` (chỉ admin Console). Thêm cuối block, sau `couple_codes`. |
| `lib/services/app_update_service.dart` | **MỚI.** Singleton `AppUpdateService.instance`. `isForceUpdateRequired()`: guard `isUsingFirebase` → đọc `config/app` (`.get().timeout(4s)`) → `currentBuild < minBuildNumber`. **FAIL-OPEN** (mọi lỗi → false). Cache `storeUrl` theo platform (`iosStoreUrl`/`androidStoreUrl` từ doc, fallback `AppUrls`). |
| `lib/app/session_resolver.dart` | Chèn gate ở ĐẦU `_resolve` (trước auth init): `if (await AppUpdateService.instance.isForceUpdateRequired()) return AppRoutes.forceUpdate;`. Nằm trong backstop 8s + try/catch → fail-safe. |
| `lib/screens/force_update_screen.dart` | **MỚI.** Full-screen `PopScope(canPop:false)`, nền dawnBlush, icon rocket + `EyebrowChip(forceUpdateBadge)` + `pageTitleStyle(28)` + body + `ElevatedButton` "Cập nhật ngay" → `launchUrl(storeUrl, externalApplication)`. |
| `lib/app/app_routes.dart` | `static const forceUpdate = '/force-update';` |
| `lib/main.dart` | route map `AppRoutes.forceUpdate → const ForceUpdateScreen()` + import. |
| `lib/app/app_urls.dart` | hằng fallback `androidStore` (Play link từ package), `iosStore` (rỗng — chờ App Store ID; nguồn chính là config doc). |
| `lib/l10n/app_{vi,en}.arb` | `forceUpdateBadge/Title/Body/Button` (+ gen-l10n). |

### Config doc shape (`config/app`, tạo thủ công ở Console)
```json
{ "minBuildNumber": 7,
  "iosStoreUrl": "https://apps.apple.com/app/idXXXXXXXXX",
  "androidStoreUrl": "https://play.google.com/store/apps/details?id=com.tony.dearembeiu" }
```

### Test
`firebase_rules_test/test/firestore.config.test.js` — 6 ca: unauthenticated read OK (quan trọng: gate chạy pre-login), signed-in read OK, create/update/delete đều DENY (unauth + signed-in). **Rules test 160 passing** (154 cũ + 6).

### Verify
- `flutter analyze lib` → 0 issue. `flutter gen-l10n` OK.
- `scripts/test-firebase-rules.sh` → 160 passing.
- ⚠️ **Chưa deploy rules + chưa tạo config doc** — chờ user (deploy DEV/prod + tạo doc ở Console). Rule additive (chỉ MỞ read config), không siết gì → backward-compat an toàn.
- Chưa runtime-verify trên thiết bị (cần deploy rules + tạo doc với `minBuildNumber` > 6 để thử chặn).

## Nhật ký
- [2026-06-14] [lead+dev] Dựng trọn feature force-update (hard-only, Firestore config, fail-open). 3 file mới + 5 file sửa + rule + 6 rules-test + l10n. analyze 0, rules-test 160 pass. Chưa deploy/tạo doc (chờ user).

- [2026-06-20] [dev/lead] **Hybrid auto-store force-update (cho 1.3.2).** User: "app tự check có bản release mới rồi tự force update". Thay vì chỉ `minBuildNumber` thủ công → thêm auto-detect store theo TỪNG nền tảng, tự xử vụ build-number-global (mỗi máy check store của nó). Branch `feature/auto-store-update`.
  - **`AppUpdateService` viết lại** (giữ fail-open tuyệt đối): config `config/app` thêm cờ **`autoStoreForce`** (bool). (1) **Manual floor** `minBuildNumber` giữ nguyên (cả 2 nền tảng, route-based). (2) **Auto**: iOS `_iosStoreHasNewerVersion` (iTunes Lookup API `itunes.apple.com/lookup?bundleId=`, so version dotted bằng `_isNewerVersion`, dùng `dart:io HttpClient` — không thêm dep http); Android `maybeRunAndroidUpdate` dùng **`in_app_update`** (Google Play In-App Updates): `checkForUpdate()`→`performImmediateUpdate()` (native full-screen, tải+cài trong app). `isForceUpdateRequired()` giờ CHỈ cho iOS (Android sớm return false).
  - **`session_resolver`**: tách nhánh `Platform.isAndroid` → `maybeRunAndroidUpdate()` (imperative, chỉ route fallback khi native không chạy được + vẫn cần chặn); else (iOS) → `isForceUpdateRequired()` → route forceUpdate. Thêm import `dart:io Platform`.
  - **pubspec**: `in_app_update: ^4.2.3` (resolved 4.2.5).
  - **config/app**: thêm field `autoStoreForce` — rules KHÔNG đổi (read:if true cho phép đọc field mới; client chỉ đọc). Không cần deploy rules.
  - **Đánh đổi (user biết):** auto-force = mọi bản store mới thành bắt buộc; cờ `autoStoreForce` để bật/tắt từ xa (không cần build lại). `minBuildNumber` vẫn là override chọn-thời-điểm.
  - **Hạn chế:** in_app_update CHỈ chạy khi app cài từ Play (debug/sideload → checkForUpdate throw → fallback manual floor). iOS không có API ép-cài native nên vẫn điều hướng ra App Store.
  - pub get OK, `flutter analyze` 0 (full). Tester đang review lock-out. **Chưa build app, chưa tạo doc config/app, chưa release — feature cho 1.3.2.**
- [2026-06-22] [dev] **Verify trạng thái force-update thực tế (release 1.3.5+14):** curl public doc `config/app` → **404 NOT_FOUND ở CẢ prod (`tonyembeiu`) lẫn dev (`tonyembeiu-dev`)**. ⇒ feature auto-store-force vẫn NGỦ (fail-open, chưa ai bị ép). Code đã ship từ 1.3.2 nhưng **công tắc remote chưa từng được tạo** → đây là lý do "đã làm mà như chưa". **Plan bật (chờ user OK — ghi prod):** sau khi build 14 live CẢ 2 store → tạo `config/app` = `{ autoStoreForce: true, minBuildNumber: 14, iosStoreUrl: "https://apps.apple.com/app/id6775165592", androidStoreUrl: "https://play.google.com/store/apps/details?id=com.tony.dearembeiu" }`. **`autoStoreForce` self-timing** (chỉ ép khi store thật sự có bản mới hơn → an toàn set sớm, không lockout, xài cho mọi release sau); **`minBuildNumber=14` chỉ set SAU khi 2 store có build 14 live** (build number toàn cục → set sớm = khoá chết user store chưa có 14). `minBuildNumber` chỉ thêm để quét nốt user pre-1.3.2 (chưa có code auto-check).
