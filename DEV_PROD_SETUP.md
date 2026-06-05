# 🔀 Môi trường Dev / Prod (tách backend Firebase)

> Mục tiêu: **chỉ build `--release` → DB prod; còn lại (debug + `--profile`) → DB dev.** Không dùng flavor, không sửa code `lib/`. Việc chọn project xảy ra ở **tầng native theo build-config** — prod là FALLBACK an toàn (release/config lạ không bao giờ lỡ ship config dev).

## Bản đồ project

| Vai trò | Firebase project | Build dùng | Config file |
|---|---|---|---|
| 🟢 **PROD** | `tonyembeiu` (app live App Store) | **chỉ `--release`** (+ config lạ) | `android/app/google-services.json` · `ios/config/prod/GoogleService-Info.plist` |
| 🔵 **DEV** | `tonyembeiu-dev` | `flutter run` (debug) **+ `--profile`** | `android/app/src/{debug,profile}/google-services.json` · `ios/config/dev/GoogleService-Info.plist` |

**🆔 Bundle/app id (đổi 2026-06-05 — cài cạnh nhau, KHÔNG đè):**
- 🟢 PROD (release): `com.tony.dearembeiu` — tên hiển thị **"Dear Embeiu"**.
- 🔵 DEV (debug/profile): `com.tony.dearembeiu.dev` — tên hiển thị **"Dear Embeiu Dev"**.

→ Bản dev cài lên device thật là **app riêng biệt** (icon riêng), KHÔNG đè bản App Store. Suffix gắn ở tầng native: **iOS** qua `Podfile` post_install (set `PRODUCT_BUNDLE_IDENTIFIER` + `APP_DISPLAY_NAME` theo config; `Info.plist` dùng biến `$(APP_DISPLAY_NAME)`); **Android** qua `applicationIdSuffix=".dev"` + label `${appName}` (`build.gradle.kts` `configureEach`, manifest placeholder). ⚠️ Vì dev đổi sang `.dev`, **config dev phải đăng ký lại theo id `.dev`** — xem mục "Việc CONSOLE" bước 0.

## Cơ chế switch

**Android** — Google Services Gradle plugin tự chọn `google-services.json` theo build-type:
- debug → `android/app/src/debug/google-services.json` (dev)
- profile → `android/app/src/profile/google-services.json` (dev)
- release → `android/app/google-services.json` (prod, FALLBACK an toàn)

→ Không cần code, không cần options trong Dart. Native auto-init đọc đúng file.

**iOS** — build-phase `Select GoogleService-Info (env)` (thêm qua `ios/Podfile` post_install, chạy ĐẦU TIÊN trước Copy Bundle Resources) copy plist theo `$CONFIGURATION`:
- `Debug` / `Profile` → `ios/config/dev/GoogleService-Info.plist` → ghi đè `ios/Runner/GoogleService-Info.plist`
- `Release` (+ config lạ) → `ios/config/prod/GoogleService-Info.plist` (FALLBACK an toàn)

Idempotent, sống qua `pod install` (find-or-create như phase "Strip Invalid Architectures").

## Lệnh chạy / build

```bash
flutter run                       # debug  -> DEV  (tonyembeiu-dev)
flutter run --profile             # profile -> DEV (đo hiệu năng, KHÔNG đụng prod)
flutter run --release             # release-> PROD (tonyembeiu)
flutter build apk --release       # PROD
flutter build ipa --release       # PROD
flutter build appbundle --release # PROD
```

## Deploy backend theo môi trường (alias .firebaserc)

```bash
# DEV (cũng là DEFAULT — bare deploy rơi vào dev cho an toàn)
npx firebase-tools deploy --only firestore:rules,firestore:indexes,storage --project dev
npx firebase-tools deploy --only functions --project dev   # cần Blaze (xem dưới)

# PROD — PHẢI ghi --project prod rõ ràng (cố ý, tránh lỡ tay)
npx firebase-tools deploy --only firestore:rules,firestore:indexes,storage --project prod
npx firebase-tools deploy --only functions --project prod
```

`.firebaserc`: `default`=`tonyembeiu-dev` (**dev = an toàn**: bare deploy không trúng prod), `prod`=`tonyembeiu`, `dev`=`tonyembeiu-dev`. ⚠️ Deploy prod **bắt buộc** `--project prod` (kể cả hosting privacy-policy).

## ⚠️ Việc CONSOLE phải làm 1 lần cho project dev (`tonyembeiu-dev`)

Project dev mới tạo còn trống — để debug build chạy được phải bật vài thứ trên console (không có CLI):

0. **🆔 ĐĂNG KÝ APP `.dev` trong project dev (BẮT BUỘC sau đổi 2026-06-05 — nếu thiếu, build dev FAIL):**
   - **Android:** Console `tonyembeiu-dev` → ⚙️ Project settings → *Your apps* → **Add app → Android** → package name **`com.tony.dearembeiu.dev`** → tải `google-services.json` → **ghi đè** `android/app/src/debug/google-services.json` **và** `android/app/src/profile/google-services.json` (cùng 1 file, copy vào cả 2 chỗ). *(Plugin Google Services khớp `package_name` với applicationId — id giờ là `.dev` nên file cũ `com.tony.dearembeiu` sẽ báo "No matching client".)*
   - **iOS:** **Add app → iOS** → bundle id **`com.tony.dearembeiu.dev`** → tải `GoogleService-Info.plist` → **ghi đè** `ios/config/dev/GoogleService-Info.plist`. *(Build-phase đã tự copy file này cho Debug/Profile — chỉ cần thay đúng file nguồn.)*
   - *(Tuỳ chọn)* Nếu muốn push trên dev iOS: upload APNs key vào project dev cho app `.dev`.
   - Sau khi thay xong: `flutter run` (debug) sẽ tự `pod install` (áp suffix iOS) + build → app **"Dear Embeiu Dev"** cài cạnh bản thật.
   - ⚠️ App `.dev` là **bản ghi mới** trong DB dev → tài khoản/couple test nằm riêng (đúng tinh thần sandbox). App `com.tony.dearembeiu` cũ đã đăng ký trong project dev có thể bỏ trống, không cần xoá.

1. **Firestore** — https://console.firebase.google.com/project/tonyembeiu-dev/firestore → **Create database** (chọn location, vd `nam5`/us). Sau đó deploy rules+indexes (lệnh trên).
2. **Authentication** → **Sign-in method** → bật **Email/Password** (app dùng email/password). Bắt buộc, không có CLI.
3. **Storage** (nếu test ảnh) → https://console.firebase.google.com/project/tonyembeiu-dev/storage → **Get started** tạo default bucket → deploy `storage` rules.
4. **(Tuỳ chọn) Cloud Functions / Push ở dev** — Functions v2 cần **nâng Blaze (billing)**. Không nâng thì debug build vẫn chạy nhưng **không có push/callable** (`deleteAccount`…). Sandbox dev thường bỏ qua được.
5. **(Tuỳ chọn) Push APNs ở dev iOS** — upload APNs key vào project dev (Cloud Messaging settings) nếu muốn test push trên iOS dev.

Sau khi xong 1–3, gọi Claude deploy rules/indexes/storage sang `dev` là dev DB sẵn sàng.

> ✅ **Đã provision xong (2026-06-05):** Firestore DB + rules + indexes, Storage bucket (US-EAST1 no-cost) + rules, Email/Password Auth đều đã bật & deploy sang `tonyembeiu-dev`. Chỉ còn Functions/push (Blaze) là tuỳ chọn.
> ⏳ **CÒN PHẢI LÀM (bước 0, sau đổi sang `.dev` ngày 2026-06-05):** đăng ký app Android+iOS id `com.tony.dearembeiu.dev` trong project dev rồi thay 3 file config (`src/debug` + `src/profile` google-services.json, `ios/config/dev` plist). **Chưa làm thì build dev (`flutter run`) sẽ fail "No matching client".** Build release/prod KHÔNG bị ảnh hưởng.

## 🔁 Quy trình dev & release

### 🔵 Vòng lặp DEV (hằng ngày — code & test)
Mọi thứ tự trỏ **dev** (`tonyembeiu-dev`), không đụng user thật.

- [ ] Code trên branch (feature/phase branch — ship theo branch, không dùng flag).
- [ ] **Chạy & test:** `flutter run` → debug → **tự vào dev backend**. Đăng ký/đăng nhập/đăng ảnh thoải mái.
- [ ] **Sửa backend** (rules/indexes/functions) → deploy **dev** trước, test lại:
  ```
  npx firebase-tools deploy --only firestore:rules,firestore:indexes,storage --project dev
  ```
- [ ] Trước khi xong: `fvm flutter analyze` (+ `fvm flutter test` nếu đụng logic).

> ⚠️ Functions/push ở dev cần Blaze (chưa nâng). Sửa Cloud Functions thì test logic ở prod cẩn thận, hoặc nâng Blaze cho dev.

### 🟢 Vòng RELEASE (lên store — prod)
Release **luôn = prod**, không thể nhầm.

- [ ] **Gộp code** vào branch release.
- [ ] **Bump version** `pubspec.yaml` (vd `1.1.0+5` → `1.1.1+6`) — cả version lẫn build number.
- [ ] **Deploy backend PROD** *nếu* có đổi rules/functions/indexes:
  ```
  npx firebase-tools deploy --only firestore:rules,firestore:indexes,functions --project prod
  ```
- [ ] **Build release** (tự trỏ prod):
  ```
  fvm flutter build ipa --release        # iOS  -> Transporter/Xcode -> App Store Connect
  fvm flutter build appbundle --release  # Android (.aab) -> Play Console
  ```
- [ ] **Upload + Submit:** tạo version → What's New → Submit.

### Bảng tra nhanh
| Việc | Lệnh | Trỏ vào |
|---|---|---|
| Dev/test hằng ngày | `flutter run` | 🔵 dev |
| Deploy rules khi dev | `deploy … --project dev` | 🔵 dev |
| Build lên store | `flutter build … --release` | 🟢 prod |
| Deploy rules cho prod | `deploy … --project prod` | 🟢 prod |
| `--profile` (đo hiệu năng) | `flutter run --profile` | 🔵 dev |

**Quy tắc đinh:**
- **Chỉ Release = prod · Debug + Profile = dev** — cố định ở tầng native, không cần nhớ cờ. Profiling KHÔNG đụng data prod.
- **TestFlight / Play internal testing = release = prod** (tester thật chạm data prod). Muốn tester chạm dev → chạy debug build trên máy.
- Đổi `firestore.rules`: **deploy dev test trước, prod sau** (deploy prod ghi đè production — sai là regression user thật).
- Mỗi deploy tự ghi vết restore vào `project/.firebase-deploy-log/`.

## Lưu ý an toàn
- **Prod = fallback an toàn:** chỉ Debug/Profile mới chủ động lấy config dev; mọi config khác (Release + lạ) rơi về prod ở `android/app/` + `ios/config/prod/`. Chiều nguy hiểm (ship dev lên store) **không thể xảy ra**.
- **Deploy: dev = default, prod phải `--project prod`** — bare `firebase deploy` trúng dev (sandbox), không bao giờ lỡ ghi đè prod.
- File config dev/prod **không bị gitignore** → commit bình thường (riêng `ios/Runner/GoogleService-Info.plist` là bản build-managed nên đã untrack+ignore; nguồn thật ở `ios/config/`).
- Bản 1.1.0 đang submit **không bị ảnh hưởng** (build release vẫn = prod y như trước).
