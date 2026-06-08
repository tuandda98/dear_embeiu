# 🗺️ ROADMAP (portfolio) — Index tất cả feature

> **Cấp dự án:** toàn cảnh mọi feature + pha hiện tại. Roadmap CHI TIẾT của từng feature nằm ở `features/<ten>/roadmap.md` (chia phase Now/Next/Later riêng).
> Cập nhật trạng thái ở đây mỗi khi feature đổi pha.
> Trạng thái: `📋 Spec` → `🎨 Design` → `💻 Dev` → `🧪 Test` → `✅ Done` · (`⏸️ Paused`, `❌ Dropped`)
> Ưu tiên: P0 (chặn release/giá trị cao) · P1 · P2.

## Feature đã ship (v1.0.0) — đã tài liệu hoá làm baseline

> Đã ✅ ship; còn **nợ kỹ thuật** ghi trong `overview.md` mục "Nợ kỹ thuật" của từng feature (Tester nên chạy, Dev nên siết trước/sau release Play).

| Feature | Ưu tiên | Trạng thái | Nợ kỹ thuật nổi bật | Spec / Roadmap riêng |
|---------|---------|-----------|---------------------|----------------------|
| Auth (tài khoản) | P0 | ✅ Shipped · 🧪 **Đợt 1 PASS code-level (2026-06-05): Quên mật khẩu + Xác thực email bắt buộc** (link Firebase, hard-gate có grandfather user cũ, anti-enumeration) — chờ 6 smoke-test runtime · ✅ **Flow hardening (2026-06-05): #2 re-auth tại chỗ khi xoá tài khoản · #3 listener auth-state (session thu hồi tự về guest) · #4 gộp Splash/AuthGate** — analyze sạch, chờ smoke-test · ⏳ **Đợt 2: Google/Apple** (đã chốt, chờ user setup Console/Xcode 2× dev+prod; Apple bắt buộc kèm Google iOS — App Store 4.8) | 🔴 local password plaintext; validation yếu · ✅ email verify (Resend callable) **đã deploy cả dev+prod** (2026-06-05, secret dùng chung) | [spec](features/auth/overview.md) · [test](features/auth/test.md) · [roadmap](features/auth/roadmap.md) |
| Coupling (mã mời) | P0 | ✅ Shipped | 🔴 invite-code enumeration; coupleId sửa được · 🛡️ **Hardening 2026-06-04: chống `coupleSavePermissionDenied` cho user thật** (PO-gate PASS) — profile edit chỉ ghi 7 field sửa-được (`toProfileEditPayload`, không re-send memberIds/status/inviteCode cũ → hết fail `isCoupleProfileEdit` khi local stale); create/join/leave dùng `authUid` chuẩn + user-write narrow (`toCoupleMembershipPayload`); auto-recovery 1 lần (refresh token + re-fetch). KHÔNG đổi rules. | [spec](features/coupling/overview.md) · [dev](features/coupling/dev.md) |
| Counter (đếm ngày yêu) | P0 | ✅ Shipped | 🔴 ngày không đổi theo ngôn ngữ (gap A) | [spec](features/counter/overview.md) · [roadmap](features/counter/roadmap.md) |
| Gallery (ảnh chung + push) | P0 | ✅ Shipped | 🔴 push hardcode VI (gap B); 🟡 ai cũng xoá ảnh partner | [spec](features/gallery/overview.md) · [roadmap](features/gallery/roadmap.md) |
| Reminders (local) | P1 | ✅ Shipped | 🟡 permission fail im lặng; DST | [spec](features/reminders/overview.md) · [roadmap](features/reminders/roadmap.md) |

## Đang làm

| Feature | Ưu tiên | Trạng thái | Spec / Roadmap riêng |
|---------|---------|-----------|----------------------|
| **Couple code (mã ghép đôi riêng — fix rejoin flow)** | P0 | ✅ **Done (2026-06-05)** — tách `couple.coupleCode` khỏi `user.inviteCode`; fix Bug leaveCouple không update remaining member status; double-lookup join; rules `couple_codes` deployed dev+prod; 8/8 AC PASS | [spec](features/couple-code/overview.md) · [test](features/couple-code/test.md) |
| Custom reminders (reminder tuỳ chỉnh, local) | P1 | 🧪 Test PASS (smoke on-device OK) — gate D7 đang đổi sang force-open theo Reminders v2 | [spec](features/custom-reminders/overview.md) · [roadmap](features/custom-reminders/roadmap.md) |
| Reminders v2 (bỏ nudge hằng ngày + milestone tự bật/tắt + giờ-theo-mốc Dv8) | P1 | 🧪 Test PASS — chờ smoke-test thiết bị | [spec](features/reminders/overview.md) (5b) · [roadmap](features/reminders/roadmap.md) |
| Settings (màn Cài đặt tổng, gom Profile + giờ theo mốc Dv8) | P1 | 🧪 Test PASS (29/30) — chờ user smoke-test thiết bị (2026-05-31) | [spec](features/settings/overview.md) · [roadmap](features/settings/roadmap.md) |
| Photo report (UGC compliance Apple 1.2) | P1 | ✅ Done (2026-05-31) — rules đã deploy | [spec](features/photo-report/overview.md) · [roadmap](features/photo-report/roadmap.md) |
| Guest mode (fix Apple reject 5.1.1) | P0 | 🧪 Test PASS code-level — chờ user smoke-test thiết bị (5 case runtime) (2026-06-01) | [spec](features/guest-mode/overview.md) · [roadmap](features/guest-mode/roadmap.md) |
| Invite sharing (copy/share mã mời — giảm ma sát ghép đôi) | P1 | 🧪 Test PASS code-level — chờ user smoke-test (Phase 1: copy/share cross-platform; QR=P2, link 1-chạm=P3 để sau) (2026-06-01) | [spec](features/invite-sharing/overview.md) · [roadmap](features/invite-sharing/roadmap.md) |
| Home engagement (đẩy đăng ảnh từ Home — North Star) | P0 | 🧪 Test PASS code-level — chờ user smoke-test (Phase 1: CTA "Thêm kỷ niệm" + empty-state; partner-signal/streak=P2) (2026-06-01) | [spec](features/home-engagement/overview.md) · [roadmap](features/home-engagement/roadmap.md) |
| **Couple journal (Nhật ký Q&A + Love Note 2 chiều — a2 giữ chân)** | P1 | 🧪 **Test PASS code-level (2026-06-04)** — màn Nhật ký câu hỏi (marker doc lưu text câu hỏi vi/en, chỉ hiện ngày cả 2 đã reveal, phân trang 30 + Xem thêm), Love Note card hiện thêm "Lời nhắn của bạn" (AnimatedSize), token `accentLavenderDeep`. Analyze sạch; **rules marker đã DEPLOY**. Chờ user smoke-test runtime 2 thiết bị. | [design](features/couple-journal/design.md) · [dev](features/couple-journal/dev.md) |
| Daily question (#5 — câu hỏi mỗi ngày kiểu SumOne, reveal sau khi trả lời) | P1 | 🚧 Dev xong — chờ test + deploy rules/functions (v1: ngày=local, reveal client-side, confetti, no-streak) (2026-06-02). **Vá nền 2026-06-04 (a1): bank 58→229 câu vi/en + no-repeat theo couple (FNV-1a+permutation, daysSinceEpoch) — PO-gate PASS (analyze sạch, 14/14 test, no-dup, no-ICU)** | [dev](features/daily-question/dev.md) |

| Lottie moments (animation "khoảnh khắc": ghép đôi / empty gallery / daily reveal — Đợt 2 polish) | P2 | 💻 Dev — `LoveLottie` + wire 3 moment, analyze sạch, **3/4 slot có file** (pháo hoa/tim/camera, placeholder); **chờ user smoke-test + preview-đổi tông**; milestone cần trigger (no-cờ, release theo branch) (2026-06-03) | [spec](features/lottie-moments/overview.md) · [dev](features/lottie-moments/dev.md) |
| **Analytics (event funnel — North Star)** | P0 | 🧪 **Test PASS code-level** (2026-06-03) — `firebase_analytics` + AnalyticsService no-context (no-op khi Firebase chưa sẵn/opt-out), 14 event + user props + screen_view, toggle opt-out (default ON), privacy posture (no-tracking, xcprivacy/policy), **đóng Gap G language**. Chờ runtime GA4 DebugView + user điền form Play/Apple console. Phase 2, no-cờ | [spec](features/analytics/overview.md) · [dev](features/analytics/dev.md) · [test](features/analytics/test.md) |

| **Daily question reminder (b2 — local nudge trả lời câu hỏi)** | P1 | 🧪 **Test PASS code-level (2026-06-04)** — local daily notif id 1004 (độc lập master milestone toggle), tile Settings (switch + giờ, default ON 20:00), 5 key l10n. Analyze sạch. Thuần local, không deploy. Chờ user smoke-test runtime (notif bắn đúng giờ + permission). | [dev](features/daily-question/dev.md) |
| **Couple streak (b3 — chuỗi ngày kết nối, shame-free)** | P1 | 🧪 **Test PASS code-level (2026-06-04)** — PO-gate PASS (analyze sạch, thuật toán anchor+đếm-liên-tiếp+longestRun đúng, milestone one-shot guard Hive, fail-soft). Thuần client: marker `bothAnswered` set client-side trong submitAnswer (additive, KHÔNG deploy), StreakService (watch limit 180, filter client) + StreakProvider (5 state + đệm 1 ngày + milestone one-shot guard Hive). UI: StreakChip (footerExtra CounterCard), StreakSheet (explainer + celebration confetti/count-up 5 mốc), Journal summary. ~30 key l10n vi+en. Analyze sạch, fail-soft. Giới hạn v1: longest≤180 ngày, ngày lịch sử trước b3 không có cờ → streak tính từ giờ. | [design](features/streak/design.md) · [dev](features/streak/dev.md) |
| **Reactions ❤️ trên ảnh (b1 — siết vòng lặp 2 chiều, North Star)** | P1 | 🚧 **Dev xong full-stack (2026-06-04)** — subcollection `photos/{id}/reactions/{uid}`+collectionGroup watch, `ReactionProvider` optimistic+rollback, 6 emoji, 3 surface (feed bar / fullscreen on-dark / Home badge read-only), tap/double-tap/long-press picker + heart-burst. rules ADDITIVE + CF `notifyPhotoReaction` (D3 skip self, chỉ onCreate) + teardown + deep-link + i18n 8 key. analyze sạch, node-check PASS. **rules+functions(`notifyPhotoReaction`)+index ĐÃ DEPLOY (2026-06-04)** — PO-gate PASS (analyze sạch, node-check OK, byte emoji ❤️ khớp rules↔client, CF guard đủ). Chờ user smoke-test runtime 2 thiết bị (thả tim → push → badge). | [design](features/reactions/design.md) · [dev](features/reactions/dev.md) |

| **Notification center (trung tâm thông báo + tap điều hướng) + Font unify** | P1 | 🚧 **Dev xong full-stack (2026-06-06)** — Firestore-backed inbox `users/{uid}/notifications` (CF `writeInboxNotifications` ghi trong cả 6 sender + cleanup `deleteAccount`), rules ADDITIVE + composite index + 13 rules test (suite 140 passing), client model/service/`NotificationInboxProvider`/`NotificationCenterScreen` + bell-badge header Home, tap→tab tái dùng `NotificationTapRouter` (vá bug `partner_left` thiếu nhánh), l10n vi+en, render theo locale hiện tại. **+ Font: TOÀN APP 1 phông Be Vietnam Pro bundled (`assets/fonts`, gỡ google_fonts) — fix vỡ dấu tiếng Việt + nháy font iOS.** analyze sạch. **ĐÃ DEPLOY DEV (rules+index+functions); prod chờ lệnh user.** Chờ smoke-test 2 thiết bị. | [overview](features/notifications/overview.md) · [dev](features/notifications/dev.md) · [test](features/notifications/test.md) |
| **App robustness (review toàn flow — chống freeze UI)** | P0 | 🧪 **Test PASS code-level (2026-06-04)** — PO-gate PASS, chờ runtime verify. **Pass 1 (cold-start + auth):** diệt splash-treo-~1phút — timeout 5s + fallback local + race 8s ở `session_resolver`, `getIdToken()` bỏ force, đẩy push-sync/lastSeenAt/device-prune chạy nền (fire-and-forget), defer init non-critical qua post-first-frame ở `main.dart`; logout không kẹt (unregister token timeout/fire-and-forget, `signOut()` trả bool), delete account `BlockingLoadingOverlay` chống double-submit + callable timeout 60s. **Pass 2 (photo/gallery):** nén ảnh feed 1920/q85, `decodeWidth`→cacheWidth/memCacheWidth (hết jank/OOM), bỏ existsSync khi có remoteUrl, gallery error-state (hết nuốt lỗi), pull-to-refresh, batch upload tiến độ. analyze sạch, KHÔNG deploy. | [review+dev](features/app-robustness/dev.md) |

## Đã Done

| Feature | Ưu tiên | Trạng thái | Spec / Roadmap riêng |
|---------|---------|-----------|----------------------|
| Language (đa ngôn ngữ) | P0 | ✅ Done (2026-05-31) | [spec](features/language/overview.md) · [roadmap](features/language/roadmap.md) |

> ✅ Gap G (analytics `language_changed`) đã đóng bởi feature **analytics** (2026-06-03).

## Hạ tầng & chất lượng (tooling, không phải feature sản phẩm)

| Hạng mục | Trạng thái | Ghi chú |
|----------|-----------|---------|
| **Firebase rules unit tests** | ✅ **Done (2026-06-06)** | 140 test cho Firestore+Storage rules (gồm 13 ca subcollection `notifications`) (`firebase_rules_test/`, `@firebase/rules-unit-testing`+Mocha trên emulator), phủ mọi match block + allow/deny theo catalog rủi ro Tester (IDOR, immutability, field-whitelist, transition couple, enumeration). Chạy: `scripts/test-firebase-rules.sh`. **Tự enforce:** Stop hook băm `firestore.rules`+`storage.rules`+`functions/index.js` → đổi thì chạy lại hết, FAIL thì chặn. Phát hiện: device doc bắt buộc có key `languageCode` (rules engine deny khi thiếu key). Chi tiết: [`firebase_rules_test/README.md`](../firebase_rules_test/README.md). |

## Backlog (chưa tạo folder — tạo khi bắt đầu làm)

Theo `../CLAUDE.md` mục 11 (Product roadmap):

**NOW**
- ~~Analytics + event funnel~~ → đã có folder, **🧪 Test PASS code-level** (xem bảng "Đang làm").
- Onboarding/tutorial (giảm rớt bước ghép đôi)
- Reactions ❤️ trên ảnh (tận dụng push) — *mở rộng feature gallery*
- Day streak (đã stubbed l10n)

**NEXT**
- Home-screen widget
- Daily question (có thể dùng AI/Claude API)
- Shared calendar + đếm ngược sự kiện
- Dark mode

**LATER**
- Premium/subscription (sau khi có analytics + retention)
- AI features (caption/lời yêu, "ngày này năm xưa")
- LDR pack / chat / wishlist chung

---

*Khi tạo feature mới: copy `_templates/` (gồm `roadmap.md`) → `features/<ten-feature>/`, thêm dòng vào bảng phù hợp, xoá khỏi Backlog. Mỗi feature tự quản phase chi tiết trong `roadmap.md` của nó.*
