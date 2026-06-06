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
| `sign_up` | đăng ký thành công | `method`: email |
| `login` | đăng nhập thành công | `method`: email |
| `couple_created` | A tạo couple (có mã mời) | — |
| `invite_shared` | A copy/share mã (feature invite-sharing) | `method`: copy \| share_sheet |
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
