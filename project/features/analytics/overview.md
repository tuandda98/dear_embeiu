# Analytics — event funnel theo North Star

> File PO sở hữu. **Contract bất biến** cho Dev/Tester. Đọc trước khi code/nghiệm thu.

- **Feature:** analytics
- **Ưu tiên:** P0 (Sprint 0 — nền cho mọi quyết định; 5 feature khác đang chờ để đo)
- **Trạng thái:** 🧪 Test PASS (code-level, 2026-06-03) — chờ runtime GA4 DebugView trên device + user điền form Play/Apple console
- **Tạo ngày:** 2026-06-03 · **Release:** Phase 2 (nhánh hiện hành, build thẳng — no cờ)
- **Liên quan:** [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · [roadmap.md](roadmap.md) · dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị
- *Vấn đề:* app **chưa có analytics** (chỉ Crashlytics) → mọi quyết định sản phẩm đang định tính, không đo được phễu hay retention.
- *Giả thuyết:* có event funnel → biết chỗ rớt (ghép đôi? đăng ảnh đầu?) → tối ưu trúng → North Star tăng.
- *Đo bằng gì:* chính feature này **là** công cụ đo. North Star = **cặp active đăng ảnh/tuần**; phụ = tỉ lệ ghép đôi, D7/D30 theo cặp, time-to-first-photo.

## 2. Bối cảnh
- 5 feature đang chờ analytics để đo: gallery (push open-rate), home-engagement, lottie-moments, language (Gap G `language_changed`), custom-reminders.
- Stack: đã có firebase_core/auth/firestore/functions/storage/messaging/crashlytics. Thêm `firebase_analytics`.

## 3. Phạm vi
- **Trong:** package + `AnalyticsService` (no-context) + `AnalyticsEvents` hằng số + instrument event funnel + user properties + screen_view observer + **toggle opt-out** (Settings) + cập nhật privacy manifest + privacy policy.
- **Ngoài:** dashboard tự build (xem GA4 console); A/B testing; Remote Config; BigQuery export (bolt-on sau); IAP/ads.

## 4. Quyết định đã chốt (decision log)
- **D1 — Posture riêng tư (user duyệt 2026-06-03):** (a) **KHÔNG PII** trong param; (b) **KHÔNG IDFA / Google signals / ad personalization** → không ATT, "not used for tracking" cả 2 store; (c) **toggle opt-out** "Chia sẻ dữ liệu sử dụng (ẩn danh)" trong Settings, **default ON**, gọi `setAnalyticsCollectionEnabled`, lưu Hive; (d) cập nhật `xcprivacy` + `docs/privacy-policy.html`.
- **D2 — `user_id = Firebase uid`** khi đã đăng nhập (cần cho retention theo cặp), clear khi sign-out. Khai báo "linked" đúng ở store.
- **D3 — Release Phase 2** (nhánh hiện hành), build thẳng, không cờ (user release theo branch).
- **D4 — Bắn event ở provider/service, KHÔNG ở widget.** Service no-op khi Firebase chưa sẵn (local fallback) hoặc khi opt-out.

## 5. Event taxonomy (CONTRACT — tên snake_case)

**Phễu kích hoạt:**
| Event | Khi nào | Param (KHÔNG PII) |
|---|---|---|
| `sign_up` | đăng ký thành công (Apple/Google: lần đầu tạo hồ sơ) | `method`: email \| apple \| google |
| `login` | đăng nhập thành công | `method`: email \| apple \| google |
| `couple_created` | A tạo couple (có mã mời) | — |
| `invite_shared` | A copy/share mã (feature invite-sharing) | `method`: copy \| share_sheet \| qr (mở sheet Mã QR, feature pairing-funnel 2026-10-11) |
| `couple_join_attempt` | B submit mã | `result`: success \| invalid_code \| already_in_couple \| error |
| `couple_joined` | B join thành công (⭐ kích hoạt) | — |
| `photo_posted` | đăng ảnh thành công (⭐⭐ North Star) | `is_first`: bool |
| `photo_deleted` | xoá ảnh | — |

**Vòng gắn kết:**
| Event | Param |
|---|---|
| `love_note_set` | `action`: create \| update (KHÔNG text) |
| `daily_question_answered` | — (KHÔNG nội dung trả lời) |
| `daily_question_revealed` | — |
| `reminder_created` | `repeat`: once\|daily\|weekly\|monthly\|yearly |
| `notification_opened` | `type`: photo_posted\|partner_joined\|love_note\|daily_question |
| `language_changed` | `locale`: en\|vi\|system (đóng Gap G) |
| `account_deleted` | — |

**Feature mới (thêm 2026-10-14):**
| Event | Khi nào | Param (KHÔNG PII) |
|---|---|---|
| `chat_message_sent` | gửi tin chat | — (KHÔNG nội dung) |
| `mood_set` | chọn tâm trạng hôm nay | `has_note`: bool (KHÔNG giá trị tâm trạng) |
| `care_message_sent` | gửi "Quan tâm" | `queued`: bool (offline, chờ gửi) |
| `sleep_enabled` | xong sheet bật Giấc ngủ | `mode`: auto \| health \| manual |
| `sleep_share_changed` | bật/tắt chia sẻ giấc ngủ | `enabled`: bool |
| `sleep_night_saved` | ghi tay / sửa 1 đêm | `source`: manual \| edited (KHÔNG giờ ngủ) |
| `love_tree_opened` | mở Cây Tình Yêu | — |
| `intro_finished` | xong intro 3 slide | `skipped`: bool |
| `feature_tour_shown` | hiện "Có gì mới" | `manual`: bool (mở từ Cài đặt) |
| `login_failed` | đăng nhập lỗi (email/Apple/Google) | `method` · `reason`: mã lỗi Firebase (`wrong-password`, `invalid-credential`, `canceled`, `unknown`…) |
| `sign_up_failed` | đăng ký email lỗi | `method` · `reason` (vd `email-already-in-use`, `weak-password`) |
| `password_reset_requested` | gửi mail quên mật khẩu thành công | — |
| `password_reset_failed` | gửi mail quên mật khẩu lỗi | `reason`: mã lỗi (`unavailable`, `local-mode`, `unknown`…) |
| `couple_join_failed` | nhập mã ghép đôi thất bại | `reason`: tên `CoupleErrorCode` (`inviteNotFound`, `ownInvite`, `emptyInvite`, `full`, `alreadyHasCouple`, `unavailable`, `joinGeneric`, `unknown`…) |
| `couple_create_failed` | tạo không gian cặp đôi thất bại | `reason`: tên `CoupleErrorCode` hoặc `other`/`unknown` |

**analytics-coverage (2026-10-25)** — hành động trước đây chưa có event. Bắn ở chỗ hành động THÀNH CÔNG; param chỉ enum/bool/count.

| Event | Param | Nơi bắn |
|---|---|---|
| `photo_caption_edited` | — | `PhotoProvider.updatePhotoCaption` |
| `photo_replaced` | — | `PhotoProvider.replacePhotoImage` |
| `photo_reported` | `reason` (inappropriate\|spam\|other) | `PhotoProvider.reportPhoto` |
| `chat_bg_set` | `cleared` (bool) | `chat_bg_screen._onSave` |
| `counter_bg_set` | `count` (số ảnh cho phép, 0 = hiện hết) | `counter_bg_screen._onSave` |
| `reminder_created` | `repeat`, **+`notify_partner`** (bool) | `CustomRemindersProvider.add` |
| `reminder_updated` | `action` (edit\|toggle_on\|toggle_off\|delete\|restore), `notify_partner` | `CustomRemindersProvider.update/toggle/delete/restore` |
| `milestone_toggled` | `type` (MilestoneType), `on` | `ReminderProvider.toggleMilestone` |
| `milestone_time_set` | `type` | `ReminderProvider.setMilestoneTime` (khi đặt giờ riêng) |
| `dq_reminder_changed` | `enabled`, `count` (số giờ) | `ReminderProvider.setDailyQuestionReminderEnabled/setDailyQuestionTimes` (add/remove đi qua đây) |
| `lunar_reminder_changed` | `enabled`, `count` (số giờ) | `ReminderProvider.setLunarEnabled/Times/Days` |
| `decision_reminder_changed` | `enabled` | `ReminderProvider.setDecisionReminderEnabled` |
| `notification_mark_all_read` / `notification_removed` / `notification_cleared_all` | — | `NotificationInboxProvider` |
| `sign_out` | — | `AuthProvider.signOut` (thành công) |
| `verification_email_resent` | — | `AuthProvider.resendVerificationEmail` |
| `password_set` | — | `AuthProvider.setPassword` (thêm mật khẩu cho tài khoản Apple/Google) |
| `couple_updated` | `field` (anniversary\|names\|photo) — mỗi field đổi 1 event | `CoupleProvider.updateCouple` |
| `couple_left` | — | `CoupleProvider.leaveCouple` |
| `rps_choice_made` | — (KHÔNG gửi lựa chọn) | `RpsGameProvider.choose` |
| `rps_nudge_sent` / `rps_cancelled` | — | `RpsGameProvider.nudge` (status sent) / `cancel` |
| `sleep_color_set` / `sleep_night_deleted` / `sleep_card_hidden` | — | `SleepProvider.setColor/deleteNight/hideCard` |
| `weather_card_hidden` | — | `WeatherProvider.hideCard` (`weather_city_set`, `weather_notif_toggle` đã có sẵn) |
| `love_tree_shared` | — | `love_tree_screen` (share ảnh cây) |
| `force_update_store_tap` | — | `ForceUpdateScreen._openStore` |
| `invite_clipboard_used` | — | `setup_screen` (nhận gợi ý mã từ bộ nhớ tạm) |
| `ai_questions_toggle` | `enabled` | `settings_screen` (trước là `logEvent` trần) |

Không làm có chủ ý: `profile_updated` (app không có màn sửa tên/avatar — `updateCurrentUser` chỉ là đồng bộ nội bộ); `money_evening_reminder_changed` (trùng `money_reminder_toggle`); `language_changed{system}` (đã có sẵn).

**Screen view (2026-10-25):** observer có `routeFilter` = route có tên → bottom sheet/dialog nội dung đặt `routeSettings` cũng thành `screen_view`: StreakSheet, StreakMilestoneSheet, RecordsSheet, MemoriesSheet, MomentSheet, InviteQrSheet, MoodSheet, WeatherDetailSheet, WeatherCareSheet, CaroNewGameSheet, CaroRuleSheet, DecisionResultSheet, DecisionManualSheet, PlayTogetherSheet, TodayRitualSheet, FeatureTourSheet, CatchupGate, ArrivalPickSheet, InviteClipboardSheet, InviteCodeDialog, SleepSetupSheet, SleepEditSheet, SleepHowItWorksSheet, MoneySheet (mặc định), AddTransactionSheet, SettleSheet. Route trang đặt tên mới: PhotoViewer, CreatePost, SetupScreen (từ Journal), MoneyWallets/MoneyCategories/MoneyBudgets/MoneyReport/MoneySearch, MoneyGoal/MoneyWallet. Map thêm: ForgotPassword, VerifyEmail, ForceUpdate. Dialog xác nhận / time picker không tên → bỏ qua.

GA4 custom dimension (Event scope, tạo 2026-10-15): `reason` ("Auth fail reason") · `result` ("Result"). Thêm 2026-10-25: `field` ("Field") · `action` ("Action") · `cleared` ("Cleared") · `count` ("Count") · `notify_partner` ("Notify partner").

**User properties:** `couple_status` (single\|waiting_partner\|in_couple) · `has_posted_photo` (bool) · `app_locale` (en\|vi\|system) · `is_guest` (bool).
**Screen view:** auto qua `FirebaseAnalyticsObserver` cho home/gallery/profile/setup/guest/settings.

## 6. 🔒 Quy tắc riêng tư (BẤT BIẾN — Tester soi kỹ)
- ❌ KHÔNG đưa vào bất kỳ param nào: email, displayName, tên người, **nội dung note/answer/caption**, **giá trị mã mời**, URL ảnh, toạ độ.
- ✅ Chỉ id (uid là user_id, không bỏ vào param), enum cố định, bool, số đếm/bucket.
- ❌ KHÔNG bật IDFA / Google signals / ad personalization (iOS: `GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS = NO`; không link AdSupport).
- ✅ Opt-out tôn trọng ngay (toggle off → `setAnalyticsCollectionEnabled(false)`, không gửi event).

## 7. Acceptance criteria (xong khi…)
- [ ] `firebase_analytics` thêm; `AnalyticsService` + `AnalyticsEvents` tồn tại; init sau Firebase, no-op khi chưa sẵn/opt-out.
- [ ] Tất cả event mục 5 được bắn đúng call site (provider/service); user properties set; screen_view chạy.
- [ ] Toggle opt-out trong Settings (default ON, lưu Hive, l10n vi+en) → tắt thì không gửi event.
- [ ] `user_id=uid` khi authed, clear khi sign-out.
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` khai `NSPrivacyCollectedDataTypes` (Product Interaction + identifier), `NSPrivacyTracking=false`.
- [ ] `docs/privacy-policy.html` disclose Firebase Analytics (Google) + chuyển dữ liệu ra nước ngoài + cách opt-out.
- [ ] **0 PII** trong mọi param (Tester verify từng event).
- [ ] `fvm flutter analyze` sạch.
- [ ] Bảng giá trị để user điền **Play Data Safety** + **Apple App Privacy** (ghi trong dev.md).

## 8. Giao việc 3 vai
- 🎨 **Designer:** N/A — chỉ 1 toggle trong Settings hiện có, theo `design-system.md` (SwitchListTile, không màn mới). Copy vi+en do Dev đặt theo giọng app.
- 💻 **Dev:** implement toàn bộ mục 5–7 (xem dev brief). → *expect:* analyze sạch + bảng Data-Safety/App-Privacy.
- 🧪 **Tester:** verify 0 PII, event đúng call site, opt-out/no-op guard, toggle persist, privacy files. → PASS/FAIL.

## 9. Nợ kỹ thuật / rủi ro
- 🟡 Khai báo store (Data Safety / App Privacy) là **thao tác console của user** — Dev chỉ cấp bảng giá trị + sửa file in-repo (xcprivacy, policy).
- 🟡 GA4 DebugView để verify runtime (chưa test thiết bị trong vòng này — code-level trước).
- 🟢 Không đụng feature đang chạy (chỉ thêm lệnh log + 1 toggle).

## 10. Changelog
- [2026-06-03] [PO] Tạo feature, spec event taxonomy + posture riêng tư (D1–D4, user duyệt). Chuyển Dev.
- [2026-06-03] [Dev] Implement xong (chi tiết `dev.md`): firebase_analytics + AnalyticsService/AnalyticsEvents no-context (no-op khi Firebase chưa sẵn / opt-out), 17 call site provider/service/widget, user props, screen_view observer, toggle opt-out Settings (l10n en+vi, default ON), Info.plist ad-perso=false, xcprivacy 3 data type (linked, tracking=false), privacy-policy mục Analytics + data transfer + opt-out. `fvm flutter analyze` sạch. Không deploy (không đụng rules/functions). Chờ Tester soi 0-PII + opt-out no-op.
- [2026-10-11] [PO] `invite_shared.method` thêm `qr` (mở sheet Mã QR — feature pairing-funnel). Đăng nhập Apple/Google log `sign_up`/`login` với `method: apple|google` (`sign_up` = lần đầu tạo hồ sơ Firestore, không dựa `isNewUser` của Firebase).
- [2026-10-25] [Dev] analytics-coverage: phủ screen_view cho mọi route/sheet có tên + ~30 event hành động còn thiếu (bảng ở §5). Nhánh `feature/analytics-coverage`.
