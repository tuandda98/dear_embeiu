# 💻 Dev — App Check

> Dev sở hữu. Đọc `overview.md` trước.

- **Trạng thái dev:** xong + verify (client + console PROD) — commit `a57c76f` trên branch `feature/app-check`, chờ ship cùng release kế tiếp
- **Người/role:** Dev

## Kế hoạch kỹ thuật
- *Cách tiếp cận:* thêm `firebase_app_check`, activate NGAY sau `Firebase.initializeApp()` trong `FirebaseBootstrapService.initialize()` (trước khi bất kỳ provider nào chạm Firestore). Không đụng UI, không đụng rules, không đụng Cloud Functions.
- *File đụng tới:*
  - `pubspec.yaml` — thêm `firebase_app_check: ^0.4.0` (khoá về `0.4.5`).
  - `lib/services/firebase_bootstrap_service.dart` — import + gọi `_activateAppCheck()` trong `initialize()`; thêm hàm `_activateAppCheck()`.
- *Thay đổi model / Firestore / CF / native config:* **KHÔNG CÓ.** Không sửa `firestore.rules`, `storage.rules`, `functions/index.js`, gradle, plist, entitlements ⇒ **không chạy rules-test, không deploy gì.**
- *Cần deploy?* Không. Chỉ cấu hình Firebase Console (đã làm, xem nhật ký).

## Chi tiết implement
```dart
await FirebaseAppCheck.instance.activate(
  providerAndroid: kReleaseMode
      ? const AndroidPlayIntegrityProvider()
      : const AndroidDebugProvider(),
  providerApple: kReleaseMode
      ? const AppleAppAttestProvider()
      : const AppleDebugProvider(),
);
```
- Dùng `kReleaseMode`, **không** `kDebugMode` — profile build cũng trỏ project DEV (xem `DEV_PROD_SETUP.md`), nên debug + profile phải cùng đi nhánh debug provider. `kDebugMode` sẽ đẩy profile sang Play Integrity/App Attest trên project DEV ⇒ sai project, token luôn fail.
- API mới `providerAndroid`/`providerApple` (object). `androidProvider`/`appleProvider` (enum) đã deprecated ở 0.4.x — dùng sẽ ra 2 warning analyze.
- Không dùng `AppleAppAttestWithDeviceCheckFallbackProvider`: min iOS của app là 15.0 (`ios/Podfile`), App Attest cần 14+ ⇒ fallback không bao giờ chạy tới.
- Bọc try/catch RIÊNG, ngoài `_isFirebaseReady = true`, để lỗi App Check không kéo cả Firebase xuống "chưa sẵn sàng" (sẽ hiện màn bootstrap sai).

## Edge case kỹ thuật
- **Web:** `kIsWeb` → return sớm. Web cần reCAPTCHA site key riêng, app không build web.
- **Không mạng lúc cold start:** `activate()` là lệnh cục bộ (chỉ cài provider), token lấy lười lúc có request đầu ⇒ không làm chậm splash.
- **Token bị từ chối:** mọi API đang Unenforced nên request vẫn đi bình thường.
- **minSdk:** `firebase_app_check` cần API 23; app dùng `flutter.minSdkVersion` = 24 ⇒ đạt.

## Checklist implement
- [x] Thêm dependency, giữ diff tối thiểu (chỉ +3 package trong lock, KHÔNG bump package Firebase nào khác — `flutter pub add` mặc định bump 27 package, phải hoàn tác rồi thêm tay + `pub get`)
- [x] Activate trong bootstrap, fail-open
- [x] `flutter analyze` sạch (0 issue)
- [x] `flutter test` 141/141 pass
- [x] Không hardcode chuỗi hiển thị (feature không có UI)
- [x] Build Android verify: `flutter build apk --debug` OK + dex có `io/flutter/plugins/firebase/appcheck/FirebaseAppCheckPlugin` + `GeneratedPluginRegistrant.java:39` đăng ký plugin
- [x] iOS `pod install` OK — `FirebaseAppCheck (12.15.0)` + `AppCheckCore (11.3.2)` + `firebase_app_check (0.4.5)` vào `Podfile.lock`
- [ ] Build release CẢ 2 nền tảng ở lần release kế tiếp

## Nhật ký implement
- [2026-09-26] [Dev] Thêm `firebase_app_check: ^0.4.0` (→ 0.4.5) + activate ở `firebase_bootstrap_service.dart`. analyze 0 · test 141/141. KHÔNG đụng backend.
- [2026-09-26] [Dev] Firebase Console **PROD `tonyembeiu`** → App Check → Apps: đăng ký app Android `com.tony.dearembeiu` với **Play Integrity**, TTL mặc định 1 giờ, 2 fingerprint SHA-256:
  - app signing key của Play: `8B:E2:94:48:4F:64:F4:83:6F:E5:30:77:7A:F9:47:3E:37:9A:51:49:9E:5C:DA:03:6E:69:0F:A3:38:45:CD:60`
  - upload key: `59:D3:94:4D:5C:AE:14:B3:91:C0:E9:69:44:F6:85:25:F7:62:D0:E1:EC:C7:99:2E:27:C3:2E:C9:9D:B3:F1:7E`
  (lấy từ Play Console → Được bảo vệ bằng Play → Ký ứng dụng; app signing SHA-256 không hiện dạng text, phải đọc trong đoạn JSON `assetlinks.json` mẫu trên trang đó). Phải tick ô đồng ý ToS Play Integrity API mới bấm Save được — user uỷ quyền 2026-09-26.
  - App iOS `com.tony.dearembeiu` đã Registered với **App Attest** từ trước (không phải do đợt này).
- [2026-09-26] [Dev] **Tất cả API giữ nguyên Unenforced.** Không bật enforce bất cứ API nào.
- [2026-09-26] [Dev] Project DEV `tonyembeiu-dev`: App Check chưa từng bật (trang vẫn là "Get started") — cố ý để nguyên (D5).

## Việc còn lại (bước sau, KHÔNG làm trong đợt này)
1. **Ship**: bản release kế tiếp mang App Check ra thị trường. Không cần deploy backend.
2. **Theo dõi** ~2 tuần ở Console → App Check → tab APIs: xem tỉ lệ request verified.
3. **Enforce CF trước** (chỗ tốn tiền nhất): trong `functions/index.js`, với `generateDailyQuestion` thêm chặn `if (!request.app) throw new HttpsError('failed-precondition', ...)`. Đây là code nên kiểm soát được, khác với nút Enforce của Console.
4. **Enforce Storage → Firestore** khi verified đã cao. Bật từng cái một, theo dõi Crashlytics giữa mỗi bước.
5. **Debug token cho DEV** (khi cần test): chạy debug build, tìm dòng log `Enter this debug secret into the allow list...` (Android: logcat; iOS: Xcode console) → Firebase Console DEV → App Check → app → ⋮ → Manage debug tokens → dán vào.

- [2026-09-26] [Dev] ⚠️ **Sự cố phối hợp:** giữa chừng có phiên Claude song song làm hotfix crash 1.7.1 → `git stash` phần App Check này để hotfix đi sạch (đúng, không phải lỗi). Sau khi 1.7.1+24 submit xong đã `stash pop`, merge lại giữ `version: 1.7.1+24`, chạy lại `pub get` + `pod install` + verify. **Bài học:** `flutter pub get` chạy trước khi cây thư mục bị revert thì `.flutter-plugins-dependencies` vẫn ghi theo bản cũ ⇒ `pod install` im lặng bỏ qua plugin (Podfile.lock không đổi 1 dòng nào) và APK build ra KHÔNG có plugin mà vẫn exit 0. Luôn verify bằng `.flutter-plugins-dependencies` + grep dex, đừng tin exit code.
- [2026-09-26] [Dev] Commit `a57c76f` trên `feature/app-check` (tách khỏi `release/1.7.1` sau khi bản đó đã submit). Chưa merge vào release nào.
