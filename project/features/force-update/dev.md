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
