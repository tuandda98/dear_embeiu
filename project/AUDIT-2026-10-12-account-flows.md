# Audit luồng tài khoản — tạo · đăng nhập · đăng xuất · ghép đôi · đổi điện thoại (2026-10-12)

> Chỉ audit, KHÔNG sửa code (user chốt "chỉ audit thôi"). Nhánh `feature/home-widget`@bb73ac1, đã gồm toàn bộ bản vá `AUDIT-2026-10-12.md` — các mục AU/PA/BE/N đã vá được verify trên đĩa và không báo lại.
> Cách làm: 3 Tester read-only chạy song song (auth · ghép đôi · đổi máy), Lead tự verify lại 2 P1 + 4 P2 trên đĩa. Bằng chứng chạy: emulator rules 8 ca probe (scratch, chưa đưa vào suite) · `flutter test` auth 103/103 + ghép đôi 36/36 · CF `npm test` 12/12.
> CONFIRMED = đọc được đường code; NGHI NGỜ = cần máy thật/Firebase.

## Tóm tắt

**FAIL — 2 P1 · 8 P2 · 27 P3.**

- **P1 bảo mật, đang mở trên PROD:** ai có tài khoản cũng liệt kê được MỌI couple đang chờ người ấy (PROD hiện ~31) kèm mã mời → chiếm chỗ người ấy. Vá 1 từ trong rules.
- **P1 chức năng, có từ 2026-06-14:** "Lời nhắc riêng" chết trên mọi bản cài mới — mỗi lần mở app là huỷ lịch, danh sách vẫn hiện "Tiếp theo…" nhưng không bao giờ nổ.
- P2: mã cá nhân bị trỏ nhầm couple (rules) · mạng chậm lúc mở app → tạo couple thứ hai hoặc rời nhầm couple · máy bị đá vẫn nhận push 60 ngày · máy cũ mở app đá máy mới · lời nhắc "Cũng nhắc người ấy" mồ côi nhắc mãi · đăng xuất không huỷ nhắc mốc/lịch âm/lời nhắc riêng · spinner đăng nhập treo khi rớt mạng · mail đặt lại mật khẩu bắn không giới hạn.

## P1

| ID | Chỗ | Kịch bản → hậu quả | Vá |
|---|---|---|---|
| **PJ-1** CONFIRMED (emulator + Lead đọc rules) | `firestore.rules:394-401` | `allow read` (= get + list) cho couple `status == waiting_partner && memberCount == 1`, điều kiện chỉ dựa trên field của doc → query `where('status','==','waiting_partner').where('memberCount','==',1)` qua rules, trả MỌI couple đang chờ: tên, ngày yêu, ảnh bìa, `inviteCode` + `coupleCode`, uid người tạo → join bất kỳ couple nào. Suite chỉ test list không filter (`firestore.couples.test.js:103`) nên không bắt. Không app nào (kể cả Nịnh Vợ Iu) list `couples` → đổi an toàn. | `allow read:` → `allow get:` + test list có filter → `assertFails`. **Deploy PROD** cùng đợt 1.9.1. |
| **F1** CONFIRMED (Lead verify) | `lib/main.dart:172-176` · `lib/providers/reminder_provider.dart:319-322, 497-505` | Gate khởi động đọc Hive `reminder_settings.enabled` (default `false`) → `false` thì `customRemindersProvider.cancelAllSchedules()`. Khoá này chỉ được ghi trong `_persist()`, mà `_persist()` chỉ có `setTime()` gọi, và `setTime` không còn ai gọi trong `lib/` từ khi bỏ master toggle (2026-06-14). Mọi bản cài không từng bật master toggle cũ → mỗi cold start huỷ hết lời nhắc riêng; chỉ nổ nếu tạo/sửa trong phiên rồi không mở lại app. Không có đường re-arm nào khác (`rescheduleAllEnabled` chỉ ở `main.dart:173`). | Bỏ gate, luôn `rescheduleAllEnabled()` (hoặc `defaultValue: true`). Cần test máy thật: cài mới → nhắc +3 phút → kill → mở lại → chờ. |

## P2

| ID | Chỗ | Kịch bản → hậu quả | Vá |
|---|---|---|---|
| **PJ-2** CONFIRMED (emulator) | `firestore.rules:1056-1061` · `couple_service.dart:399-404` · `functions/index.js:3054-3062` | Create `couple_codes/{code}` chỉ đòi là thành viên `coupleId`, không buộc `code == couples/{id}.coupleCode`. Kẻ biết mã CÁ NHÂN của nạn nhân (QR/link người độc thân chia sẻ, người yêu cũ) tạo `couple_codes/{mãNạnNhân} → couple mình`. `joinCoupleByCode` tra `couple_codes` TRƯỚC `invite_codes` → người ấy của nạn nhân vào nhầm couple, hoặc mã chết vĩnh viễn (pointer `update:false`, `deleteCoupleCompletely` chỉ xoá khi `coupleCode` khớp; mã cá nhân không đổi được). | Rule create thêm `get(/databases/$(database)/documents/couples/$(request.resource.data.coupleId)).data.get('coupleCode','') == code` + PJ-7. |
| **PJ-3** CONFIRMED đường code (tần suất: đã thấy 1 lần `onboarding/test.md:39`) | `session_resolver.dart:96-106` · `couple_service.dart:162-165, 175-195, 371-373` · `setup_screen.dart:273,552` | Mở app đầu mạng chậm: `fetchCouple` timeout 5s không cache → `null` không lỗi, hoặc backstop 8s → Setup chế độ tạo/tham gia dù `users.coupleId` đang có. (a) Bấm Tạo: `createCouple` không chặn `hasCouple` → couple thứ hai, `users.coupleId` + `invite_codes` trỏ sang, couple cũ vẫn ghi A → A rời couple mới rồi nhập lại mã cũ bị "đã ở trong couple này" → kẹt. (b) Bấm Tham gia khi `waiting_partner`: `leaveCouple` chạy TRƯỚC khi tra mã → gõ sai 1 ký tự cũng xoá sạch couple + ảnh qua `leaveCoupleCleanup`, link mời đã gửi chết. | Setup: `hasCouple && couple == null` → "đang tải/thử lại", không hiện form · `_safeFallbackRoute` → `home` khi `hasCouple` · dời khối leave xuống sau `targetIsJoinable` · rule create couple đòi `users/{uid}.coupleId == null` (chặn (a) + PJ-13). |
| **F2 = AU-T1** CONFIRMED (Lead verify) | `auth_provider.dart:157-174` · `user_service.dart:259-289` · `functions/index.js:67-110` | Máy bị "đá" (single-session) chỉ `unawaited(_authService.signOut())`, KHÔNG `unregisterForUser`/`deleteToken` → doc `users/{uid}/devices/{id}` còn sống → CF vẫn gửi push, gồm "Quan tâm" NGUYÊN VĂN, tới khi `pruneStaleDevices` (60 ngày / ngoài top 8). Sign-out thường có xoá doc nhưng timeout 5s nuốt lỗi và không `deleteToken` → đăng xuất lúc offline = máy bán vẫn nhận push 60 ngày. | Trong listener, trước `signOut()`: `await PushNotificationService.instance.unregisterForUser(kicked).timeout(5s)` + `deleteMessagingToken()` (đã có ở `_signOutQuietly`, `auth_service.dart:1072-1083`). |
| **F3** CONFIRMED | `auth_provider.dart:221-223` · `auth_service.dart:789` | `initialize()` luôn `_mintAndWatchSessionToken` (cold start = take over). Refresh token Firebase trên máy cũ vẫn hợp lệ (sign-out thường không revoke) → máy cũ cold start → mint token mới → máy mới bị `sessionRevoked` về guest → đăng nhập lại → đá ngược (ping-pong). Máy mất/bán đá được chủ thật. `readLocalSessionToken()` chưa ai dùng. | `initialize()`: đọc token local + remote; `local != null && remote != null && remote != local` → `_signOutQuietly()` thay vì mint. |
| **F4** CONFIRMED | `custom_reminder.dart:94` · `partner_reminder_provider.dart:58` · `firestore.rules:527-531` · `functions/index.js:354-470, 2918-2982, 2984-3070` | Liên kết `partnerReminderId` chỉ nằm trong Hive `custom_reminders`. Máy mới/cài lại → box trống → mirror `partnerReminders` trên server còn `enabled:true`; provider người nhận arm mọi doc `authorUserId != uid`, không kiểm author còn là member; không có UI quản lý; rules update/delete chỉ author → người nhận bất lực. CF rời couple / xoá tài khoản / xoá couple không dọn `partnerReminders` → người ở lại VÀ người ghép mới sau này vẫn bị nhắc lời của người cũ. | (1) `_onReminders` lọc `memberIds.contains(r.authorUserId)`; (2) CF rời/xoá: xoá `partnerReminders where authorUserId == leaver`; (3) máy mới: `CustomRemindersProvider.load()` có couple → import lại mirror do mình tạo. |
| **F5 = AU-T4** CONFIRMED | `session_resolver.dart:148-167` · `reminder_provider.dart:1556-1589, 1687` · `reminder_service.dart:173` | Đăng xuất/xoá tài khoản chỉ huỷ 1004 · 1020–1033 · 1040–1052 · 1100–1159 · 1180–1189 + band 3000. Sót: mốc ngày yêu 1001–1099 (`cancelAll` chỉ chạy trong `_reschedule` = cần Home có couple), lịch âm 1060–1099, lời nhắc riêng 2000–2999 + Hive `custom_reminders`. Máy bán vẫn nổ "Kỷ niệm 1 năm" của couple cũ; máy dùng chung: B thấy lời nhắc riêng của A ở Cài đặt. Trái hộp thoại "Toàn bộ dữ liệu… sẽ bị xoá vĩnh viễn" (`app_vi.arb:994`). | `cancelDailyQuestionSchedule` thêm `cancelAll()` + `cancelLunar()`; resolver nhánh guest gọi `customRemindersProvider.cancelAllSchedules()`; xoá tài khoản thì xoá cả box. |
| **AU-T2** CONFIRMED (Lead verify) | `auth_provider.dart:250-254, 298-302, 351-354` · `user_service.dart:153-156` · `push_notification_service.dart:319, 409-429` | Đăng nhập/đăng ký/Apple/Google: `await syncForUser` + `await _mintAndWatchSessionToken` không timeout; Firestore `set()` offline chờ mãi; `requestPermission` chờ hộp OS. Rớt mạng ngay sau khi Auth trả về → nút khoá, spinner không dừng, phải kill app (mở lại thì vào được vì phiên đã lưu). Cold start thì `unawaited`, sign-out bound 5s — chỉ 3 luồng tương tác bị. | `.timeout(5s, onTimeout: () {})` quanh 2 await, hoặc `unawaited` như cold start. |
| **AU-T3** CONFIRMED | `functions/index.js:3389-3474` · `forgot_password_screen.dart:103-117` | `sendCustomPasswordResetEmail` không auth, không rate-limit, App Check chưa enforce; "Gửi lại" không cooldown. `curl -X POST .../sendCustomPasswordResetEmail -d '{"data":{"email":"victim@x.com"}}'` lặp N lần → N thư từ `noreply@dearembeiu.com`. Spam nạn nhân, tốn Resend, domain bị đánh dấu spam. | Throttle theo email trong CF (doc `resetThrottle/{sha256(email)}`, từ chối < 60s). KHÔNG `enforceAppCheck` (chặn luôn bản ≤ 1.7.0). |

## P3

### Tạo tài khoản · đăng nhập · đăng xuất (AU-T)
| ID | Chỗ | Nội dung |
|---|---|---|
| AU-T5 | `couple_provider.dart:43-56` · `session_resolver.dart:95-99` | Đăng xuất không xoá `couple_data.json` (tên 2 người, ngày yêu, path ảnh bìa còn trên đĩa). `_safeFallbackRoute` không kiểm uid trong `memberIds` → B đăng nhập trên máy A, cold start > 8s → về `home` dù B chưa có couple. |
| AU-T6 | `session_resolver.dart:90-107` | Resolve > 8s → fallback `setup`/`home` không kiểm `requiresEmailVerification` → tài khoản chưa verify vào Setup tạo couple được (rules không kiểm `email_verified`). |
| AU-T7 | `user_service.dart:163-166` · `auth_provider.dart:158` | Xoá tài khoản ở máy khác: stream `null` bị bỏ qua → máy còn lại giữ phiên tới khi ID token hết hạn (≤ 1h), permission-denied liên tục. |
| AU-T8 | `auth_service.dart:180-192` | Đăng ký email: `_generateUniqueInviteCode()` ném TRƯỚC khối xoá auth user → Auth user mồ côi đang đăng nhập, chưa gửi mail xác thực; bấm Tạo lại báo "Email đã được dùng". Tự lành ở cold start. |
| AU-T9 | `verify_email_screen.dart:51-53` · `auth_service.dart:200-204` | Màn Verify cooldown 60s ngay khi mount dù mail lúc đăng ký gửi hỏng bị nuốt. |
| AU-T10 | `auth_service.dart:164,258,648` · `docs/auth-action.html:440-446` | App `trim()` mật khẩu, web đặt lại không trim → mật khẩu có khoảng trắng đầu/cuối đặt trên web → app báo sai. |
| AU-T11 | `auth_service.dart:66, 214-247, 301, 1170` | Local fallback (khi `Firebase.initializeApp()` ném) lưu mật khẩu nguyên văn trong secure storage + `_memoryFallbackStore` static, tạo tài khoản uuid cục bộ không verify. Gần như không gặp ở release nhưng code có trong binary. |
| AU-T12 NGHI NGỜ | `auth_service.dart:117` · `auth_provider.dart:172` · `main.dart:96-99` | `unawaited(...)` không `catchError` → ghi profile bị rules từ chối (displayName rỗng, `invite_codes.userId` ≠ uid) → Crashlytics `fatal: true` giả mỗi lần mở app. |
| AU-T13 NGHI NGỜ [máy thật] | `auth_service.dart:474-480` | Firebase coi Google/Apple là trusted provider: email trùng tài khoản mật khẩu CHƯA verify → gỡ provider `password` âm thầm → đăng nhập email sau báo sai mật khẩu; PF6 có thể hầu như không chạy. Test: tạo tài khoản email không verify → "Tiếp tục với Google" cùng email → xem `providerData`. |
| AU-T14 NGHI NGỜ | `auth_provider.dart:237-244, 279-290` | Multi-touch cùng frame "Đăng nhập" + "Google": `signIn` không kiểm `_socialSignIn`, `signInWithSocial` không kiểm `_isLoading` → 2 luồng song song. |
| AU-T15 | `functions/index.js:2772-2799` | Copy: 3 luồng không lọt tiếng Anh thô. Còn `leaveCoupleCleanup` HttpsError cài cứng VI → máy EN thấy tiếng Việt. Android thiếu SHA-1 / không có tài khoản Google đều ra "Chưa đăng nhập được với Google", không gợi ý "thêm tài khoản Google vào máy". Đăng ký email trùng Apple/Google → "Email đã được dùng", không gợi ý đăng nhập Apple/Google. |

### Ghép đôi (PJ)
| ID | Chỗ | Nội dung |
|---|---|---|
| PJ-4 | `firestore.rules:295-308` · `functions/index.js:2954-2975` | Không có "gỡ người ấy": người lạ/nhầm vào (PJ-1 làm dễ) → A chỉ còn cách rời, couple + dữ liệu về tay người kia. Vá: callable `removePartner` (creator-only). |
| PJ-5 | `couple_service.dart:245-250, 1088-1089` · `setup_screen.dart:909` | `createCoupleCodeEntry` lỗi bị nuốt nhưng Setup/Home hiện `coupleCode` (chỉ có trong `couple_codes`) → mã chết không báo; mã dự phòng sau 10 lần trùng không kiểm → `update:false` → nuốt. |
| PJ-6 | `couple_service.dart:706-713, 774-800` | CF `leaveCoupleCleanup` hỏng (vd outage billing 09-2026) → client tự xoá doc couple → `messages`/`dailyAnswers`/`sleep`/`games`/`careMessages`/`questionState` mồ côi vĩnh viễn, `deleteAccount` sau này bỏ qua. |
| PJ-7 CONFIRMED (emulator) | `firestore.rules:246-250` | `coupleCode` không trong `coupleMetadataIsImmutable` → người ấy đổi mã hiện trên Setup/Home; mắt xích PJ-2. Vá bằng `.get('coupleCode',null)` để app 1.0 không gửi field vẫn qua. |
| PJ-8 | `couple_service.dart:365-367, 415-421` | Couple legacy (trước `bc07661` 2026-06-06, không `coupleCode`): creator rời → người còn lại chỉ hiện mã cá nhân của creator → ai nhập cũng "chưa tạo không gian"; creator nhập mã mình bị chặn → kẹt 1 người mãi. Vá: `notifyPartnerLeft` sinh `coupleCode` nếu thiếu. |
| PJ-9 | `couple_service.dart:732-744` | Ghi chéo `users/{remainingUid}` luôn bị rules chặn → dead code + 1 permission-denied mỗi lượt rời (CF đã lo). |
| PJ-10 | `invite_clipboard.dart:36, 94-98` | Mã từ clipboard khớp `[a-z0-9]{6}` nhưng không qua `isInviteCode` → `ABC10O` vẫn hiện sheet rồi báo sai mã. |
| PJ-11 (đã ghi overview 🔴, nhắc vì chi phí) | `firestore.rules:372, 1055` | Quét mã: 32⁶ ≈ 1,07 tỷ, `get` mở cho mọi tài khoản, rules không đòi `email_verified`, App Check chưa enforce → mỗi get trượt = 1 read tính tiền (~6 USD/mã lộ với ~100 mã sống). |
| PJ-12 NGHI NGỜ [máy thật] | `home_screen.dart:617` · `reminder_provider.dart:1462-1489, 1595` | Push `partner_joined` đã huỷ dải 1180–1189, mở app lúc offline → signature bị xoá → lập lại dải từ couple cache còn `waiting` tới khi stream về `active`. |
| PJ-13 | `firestore.rules:385-392` | Không giới hạn số couple/user → tạo hàng loạt couple chờ mồ côi, listable (PJ-1). Cùng 1 rule với PJ-3. |

### Đổi điện thoại (F)
| ID | Chỗ | Nội dung |
|---|---|---|
| F6 | `push_notification_service.dart:212, 463` | `const FlutterSecureStorage()` iOS mặc định `kSecAttrAccessibleWhenUnlocked` (migratable) → khôi phục iCloud/Quick Start → 2 máy cùng `push_notification_installation_id` → ghi đè 1 doc `devices`, máy sync sau thắng, máy kia mất push âm thầm. Vá: `IOSOptions(accessibility: first_unlock_this_device)`. |
| F7 (+ NGHI NGỜ FID) | `AndroidManifest.xml` · `res/xml/data_extraction_rules.xml` | Android không `allowBackup=false`, rules backup chỉ loại sleep → `shared_prefs` (Firebase Auth), `files/` (marker cài đặt, Hive, `PersistedInstallation*.json`) đều restore → máy mới Android mở app = đã đăng nhập sẵn, không qua purge (iOS thì keychain `ThisDeviceOnly` → guest). NGHI NGỜ: FID restore → 2 máy trùng Installation → token FCM lạc. |
| F8 | Hive `custom_reminders`, `reminder_settings`, `notification_settings`, `app_settings`; Documents `couple_data.json`/`photos_data.json` | Không gắn uid → restore iCloud rồi tài khoản KHÁC đăng nhập: thừa hưởng lời nhắc riêng (tên/ghi chú) người trước; `_syncPartner` (`custom_reminders_provider.dart:175-177`) `updateReminder(coupleId mới, id cũ)` fail. |
| F9 | `sleep_service.dart:207-239` | Máy second-hand Android chưa factory reset: `claimDevice` chưa có `device:uid` → quét đủ 14 đêm UsageStats của chủ cũ, share bật thì upload cho người ấy. D7 chỉ chặn khi đổi tài khoản trong cùng bản cài. |
| F10 | `analytics_service.dart:100` | Opt-out analytics lưu local → máy mới tự bật lại. |
| F11 | `auth_service.dart:620-692` · `settings_screen.dart:386-393` · `functions/index.js:16, 3385` | D1 "Đặt mật khẩu" đúng luồng. Hở còn lại: user bán iPhone TRƯỚC khi đặt → "Quên mật khẩu" gửi qua Resend tới email relay Apple → relay chặn domain chưa đăng ký (đã ghi "Còn lại 3" audit trước) → app vẫn báo "đã gửi" → khoá vĩnh viễn. Copy `setPasswordSubtitle` không nói "làm trước khi đổi máy". |
| F12 | `firestore.rules:105` | Không đổi được email (không có `verifyBeforeUpdateEmail`); email cũ chết = mất đường "quên mật khẩu". |
| F13 | `chat_provider.dart:182` | Máy mới: chấm chưa đọc Chat sáng tới khi mở tab (marker `chat_seen_<coupleId>` local). Cosmetic. |
| F14 | `home_widget_bridge.dart:36-37` · `test/home_widget_bridge_test.dart:91-94` | Widget: Dart đẩy `state: empty` khi đăng xuất/kick/xoá (CONFIRMED). Native iOS/Android chưa có trên đĩa → "máy mới widget hiện gì" test sau khi native xong. Lưu ý: iOS App Group container nằm trong iCloud backup → máy mới thấy snapshot cũ trước khi mở app (cùng chủ, vô hại). |

## Đổi máy: về lại / mất (cùng tài khoản, cài mới, KHÔNG restore backup)

| Về lại (Firestore/Auth) | Mất (chỉ local) |
|---|---|
| Couple, ảnh, chat, câu hỏi, chuỗi, journal, mood, reaction, quan tâm, RPS, inbox | **Lời nhắc riêng** (+ mirror mồ côi F4; cái tạo mới cũng chết vì F1) |
| Giờ nhắc câu hỏi (`prefs/home`), lời nhắc người ấy đặt cho mình (band 3000 re-arm), nhắc gated | Toggle/giờ từng cột mốc (`milestone_*`) → mặc định; nhắc lịch âm → tắt |
| Đêm ngủ khi `share=true` (`sleep_provider.dart:687-717`, kể cả `source:health` → nhãn "Apple Health" trên Android) | Đêm ngủ khi `share=false` (đúng D6); `SleepSettings` → chạy lại setup |
| Ảnh nền thẻ đếm/chat (`prefs/home`) | Mute theo loại push → mặc định bật; ngôn ngữ → theo máy; opt-out analytics (F10) |
| Catch-up gate | `onboarding_seen_v1` (intro hiện lại), `feature_tour_seen_build`, `love_tree_seen_*` (hoa nở lại 1 lần), `counter_bg_hint_done`, `chat_seen_*`, `invite_shared_at_*` |
| Phiên Android qua Google backup (F7) | Phiên iOS (keychain ThisDeviceOnly) → đăng nhập lại; deviceId iOS lại theo backup (F6) |

## Điểm MẠNH đã kiểm (đừng báo nhầm là bug)

- Ghép đôi: join là `runTransaction` + rule `memberCount==1 && waiting` + CF đọc lại `memberIds` → 2 người 1 mã / B join lúc A rời-xoá đều an toàn; join khi `in_couple` chặn (client `:352` + rule newcomer N4); mã `Random.secure` + kiểm tồn tại 12/10 lần; PA3 `coupleRead` latch đúng; B KHÔNG ghi đè ngày yêu (join gửi lại giá trị đọc trong transaction); `get.html` không XSS (regex + `textContent`, `lang` whitelist, UA có iPadOS); wake iOS content-available + Android data-only priority high, handler nền/fg + Home huỷ 1 lần/process; `leaveCoupleCleanup` người ngoài → permission-denied; Storage chỉ quét folder mình (N2); `invite_codes`/`couple_codes` chỉ `get` (H1); PA-N1 couple đã xoá → `exists false`; self-heal status 2 chiều; clipboard iOS `detectPatterns` trước khi đọc, hỏi 1 lần/mã, loại mã của mình.
- Auth: Apple đóng sheet → `"canceled"` khớp firebase_auth 6.7.0 iOS; email rỗng → signOut + lỗi; relay email không thành tên, `profileDisplayName` không rỗng; `_requireSession(uid)` chặn xoá nhầm (BUG-24); revoke token + Google `disconnect` sau xoá; Google cancel → sentinel, `initialize` 1 lần có retry; AU4 navigator lấy trước await; AU5 `_socialSignIn` guard; rules `users/{uid}` chỉ chủ, `hasOnly`/`hasAll` chặt, `sessionToken` optional qua `.get`, `devices` `hasOnly` 8 field khớp client; CF `deleteAccount` `isDocId` + member check + xoá `devices`/`notifications`, copy vi/en; `sendCustomVerificationEmail` lấy email từ Auth record; `rewriteActionLink` fail-open; `auth-action.html` lo verify/reset 2 bước/recover; deep link chỉ foreground (D8); verify poll 4s + resume, guard `_navigated` + `mounted`.
- Đăng xuất: unregister device (bound 5s) TRƯỚC `signOut`; `_intentionalAuthClear` chống kick giả; badge iOS về 0; 13 provider clear + sleep clear; widget về trống; band 3000 + 1020–1052 + 1100–1189 huỷ; Google `signOut()` để lần sau chọn tài khoản khác.
- Xoá tài khoản / cài lại: Apple sheet trước mọi teardown; `wipeLocalData(uid)` sleep; `purgePersistedSession` xoá Keychain + couple/photos cache; AU2 PopScope; cài lại cùng máy iOS → marker `Application Support` mất → `handleFreshInstall` → purge chạy trước `runApp` (`main.dart:118-121`, `auth_service.dart:824-849`).
- Đổi máy: 2 máy cùng uid = 2 doc `devices/{deviceId}` riêng; đổi mật khẩu qua link → Firebase revoke refresh token → máy cũ còn ≤ 1h rồi `authStateChanges` null → guest; xoá tài khoản → CF xoá hết device docs → push dừng ngay; sleep `sleep_nobackup` loại backup cả 2 nền tảng + đổi tài khoản không trộn; D1 relay email đi qua không vướng cổng xác thực; `tz` trên đêm ngủ, tz local set lại mỗi launch.
- Test đang có: auth 103/103 · ghép đôi 36/36 · CF 12/12.

## Nếu vá — đụng backend

- **Rules:** PJ-1 (`allow get`), PJ-2 (`couple_codes` create kiểm `coupleCode`), PJ-7 (`coupleCode` bất biến), PJ-3/PJ-13 (create couple đòi `users/{uid}.coupleId == null`). Tất cả additive hoặc siết đường app chưa dùng; chạy `scripts/test-firebase-rules.sh` + thêm test list có filter.
- **CF:** AU-T3 throttle `sendCustomPasswordResetEmail`; F4 dọn `partnerReminders` ở `notifyPartnerLeft`/`handleCoupleOnAccountDeletion`/`deleteCoupleCompletely`; PJ-8 sinh `coupleCode` cho couple legacy; PJ-4 callable `removePartner` (tuỳ chọn).
- Gộp vào đợt deploy PROD của 1.9.1 (`fix/audit-2026-10-12` đang chờ). PJ-1 là lỗi đang mở trên PROD, vá 1 từ, không cần bản app mới.

## Cần test máy thật (không kết luận được từ code)

1. F1: cài mới → tạo lời nhắc riêng +3 phút → kill app → mở lại → chờ.
2. F2/AU-T1: 2 máy cùng tài khoản → máy 1 bị đá → người ấy gửi "Quan tâm" → máy 1 có hiện push không.
3. AU-T2: bật airplane ngay sau khi Auth trả về → spinner có dừng không.
4. AU-T13: Google cùng email với tài khoản mật khẩu chưa verify → `providerData` còn `password` không.
5. F11: mail "Quên mật khẩu" tới email relay Apple sau khi đăng ký domain với Apple Private Email Relay.
6. F14: widget trên máy mới sau khi native xong.
