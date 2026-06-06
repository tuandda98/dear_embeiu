# Settings — Màn Cài đặt tổng (gom + cấu trúc module/sub-module)

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** settings
- **Ưu tiên:** P1 (dọn IA + nền cho mở rộng cài đặt)
- **Trạng thái:** 🧪 Test PASS (29/30) — chờ user smoke-test thiết bị (notification giờ riêng/mặc định) để đóng ✅ Done
- **Tạo ngày:** 2026-05-31
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · gắn chặt [reminders](../reminders/overview.md) (giờ theo mốc Dv8) + [custom-reminders](../custom-reminders/overview.md) · [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị
- *Vấn đề:* Profile hiện **rời rạc** — nhắc nhở (4 tile), ngôn ngữ, vùng nguy hiểm, chỉnh sửa câu chuyện nằm lẫn lộn. Khó mở rộng, khó tìm.
- *Giá trị:* Gom thành **1 màn Cài đặt có cấu trúc module → sub-module** → gọn, dễ tìm, dễ thêm cài đặt mới. Profile chỉ còn "danh tính couple".
- *Đối tượng:* mọi user.

## 2. Phạm vi (scope)
- **Trong:**
  - Profile giữ **hero couple card + stats**; thêm tile **"⚙️ Cài đặt"** → mở màn Settings.
  - Màn **Settings** mới, chia module → sub-module (mục 5b).
  - **Chuyển vào Settings:** "Chỉnh sửa câu chuyện", reminders (master + cột mốc + lời nhắc riêng), ngôn ngữ, vùng nguy hiểm (cache/leave/delete), link privacy.
  - **Per-milestone time** (giờ riêng từng mốc + giờ mặc định) — chi tiết ở [reminders Dv8](../reminders/overview.md).
- **Ngoài:**
  - KHÔNG thêm cài đặt mới ngoài cái đang có (push notif riêng, About… để sau).
  - KHÔNG đổi logic auth/couple/gallery — chỉ DI CHUYỂN vị trí UI các mục cài đặt sẵn có.
  - KHÔNG đụng backend/rules.

## 3. Quyết định đã chốt (decision log)
- **S1 — Màn Settings tổng cả app**, vào từ tile "Cài đặt" ở Profile. *User chọn (vs chỉ-gom-nhắc-nhở).*
- **S2 — Cấu trúc module → sub-module** (mục 5b).
- **S3 — "Chỉnh sửa câu chuyện" CHUYỂN vào Settings** (module Tài khoản); **hero couple GIỮ ở Profile.** *User chốt 2026-05-31.*
- **S4 — Vùng nguy hiểm (cache/leave/delete) CHUYỂN vào Settings** module Tài khoản. *PO đề xuất, user không phản đối.*
- **S5 — Reminders thành 1 module** trong Settings: master toggle + sub "Cột mốc & kỷ niệm" + sub "Lời nhắc của chúng mình" (không còn 4 tile rời ở Profile).
- **S6 — Giờ theo mốc (Q2):** giữ **giờ mặc định**; mỗi mốc có **giờ riêng tuỳ chọn** (null = dùng mặc định). Chi tiết kỹ thuật ở reminders **Dv8**.
- **S7 — Chưa thêm module mới** (push notif/About…) — để sau.

## 4. Acceptance criteria (xong khi…)
> [x] = VERIFIED qua code + Tester (2026-05-31, PASS 29/30). ⏳ = cần smoke-test thiết bị.
- [x] Profile: chỉ còn hero couple + stats + couple-info + tile "⚙️ Cài đặt"; KHÔNG còn reminders/ngôn ngữ/danger/chỉnh sửa rải rác (grep xác nhận sạch).
- [x] Tile "Cài đặt" → mở màn Settings.
- [x] Settings có module: 🔔 Nhắc nhở · 🌐 Ngôn ngữ · 👤 Tài khoản & dữ liệu · danger card · logout · footer privacy.
- [x] Module Nhắc nhở: master toggle (đổi tên + details) + sub "Cột mốc & kỷ niệm" + sub "Lời nhắc của chúng mình" (force-open Dv6 đúng).
- [x] Sub "Cột mốc & kỷ niệm": **Giờ mặc định** + 7 mốc, mỗi mốc **toggle + chip-giờ riêng** (mờ "Theo mặc định" / đậm + ✕ về mặc định; ẩn khi tắt). Schedule dùng `effectiveTimeOf` (Dv8). ⏳ *notification bắn đúng giờ cần thiết bị.*
- [x] Module Ngôn ngữ: đổi vi/en qua LocaleProvider (logic giữ).
- [x] Module Tài khoản: "Chỉnh sửa câu chuyện" (→ setup) + xoá cache + rời couple + xoá tài khoản — **hành vi y như cũ**, chỉ đổi vị trí (Tester soi kỹ nhánh Firebase/local + điều hướng).
- [x] Không regression mục di chuyển: reminders toggle/permission/lock-step, ngôn ngữ, leave/delete/cache, edit-story, logout, privacy, force-open.
- [x] i18n vi+en parity (11 key `settings*`); không hardcode.
- [x] `flutter analyze` sạch.

## 5. Nợ kỹ thuật / rủi ro (Tester soi)
- 🟡 Di chuyển danger zone (leave/delete account) — verify kỹ luồng + dialog xác nhận KHÔNG đổi hành vi (đây là chỗ khó hoàn tác, App Store/Play compliance).
- 🟡 Per-milestone time: schedule dùng đúng giờ (riêng/mặc định); đổi giờ mặc định có reschedule mốc chưa-đặt-riêng không.
- 🟡 Đảm bảo force-open (Dv6) + custom reminders + Reminders v2 còn nguyên sau khi chuyển vào Settings.

## 5b. Cấu trúc IA (module → sub-module)
```
Profile
 ├─ Hero couple card + stats        (GIỮ)
 └─ ⚙️ Cài đặt  ───────────────▶ [Màn SETTINGS]
                                     │
   ┌─────────────────────────────────┤
   │ 🔔 Nhắc nhở
   │    • Master toggle "Nhắc cột mốc & kỷ niệm" (+ details)
   │    • Cột mốc & kỷ niệm  ▶ [sub: Giờ mặc định + 7 mốc (toggle + giờ riêng)]
   │    • Lời nhắc của chúng mình ▶ [sub: list custom] (force-open nếu master off)
   │ 🌐 Ngôn ngữ
   │    • Tiếng Việt / English
   │ 👤 Tài khoản & dữ liệu
   │    • Chỉnh sửa câu chuyện ▶ setup
   │    • Xoá cache
   │    • Rời couple
   │    • Xoá tài khoản  (danger)
   │ ── Chính sách bảo mật (footer link)
```

## 6. Giao việc 3 vai
- 🎨 **Designer:** thiết kế màn Settings (module/sub-module, đồng nhất design system), tile "Cài đặt" ở Profile, sub "Cột mốc & kỷ niệm" có giờ mặc định + giờ riêng mỗi mốc (control giờ), Profile sau khi gọn. States + copy vi+en. → `design.md`.
- 💻 **Dev:** màn `SettingsScreen` (+ sub-screens), refactor Profile (bỏ phần đã chuyển, thêm tile Cài đặt), DI CHUYỂN code reminders/ngôn ngữ/danger/edit vào Settings (giữ logic), per-milestone time (model+persist+schedule, Dv8), ARB + gen-l10n, analyze sạch. → `dev.md`.
- 🧪 **Tester:** verify IA gom đúng + không regression (mọi chức năng di chuyển còn chạy), per-milestone time schedule đúng, danger zone an toàn, force-open/custom/v2 còn nguyên. → `test.md`.

## 7. Changelog
- [2026-05-31] [PO] Tạo feature settings: gom Profile rời rạc → màn Cài đặt module/sub-module (S1–S7); kéo theo per-milestone time ở reminders (Dv8). Khởi động pipeline.
- [2026-05-31] [Designer→Dev→Tester→PO] Pipeline xong: Designer (Profile gọn + Settings 3 module + chip-giờ inline mỗi mốc), Dev (`settings_screen.dart`, refactor profile di chuyển nguyên hành vi, Dv8 `setMilestoneTime`/`effectiveTimeOf`/persist `milestone_<name>_hour/minute`). Tester PASS 29/30, **0 bug, không regression**. analyze sạch. **Trạng thái: 🧪 PASS — chờ user smoke-test thiết bị (notification giờ riêng/mặc định) để đóng ✅ Done.**
- [2026-06-04] [Dev] Thêm **block thông tin tài khoản (read-only)** lên đầu module "Tài khoản & dữ liệu": **Tên hiển thị** + **Email** của user đang đăng nhập (user xin: "chỗ xem email/họ tên"). Tái dùng l10n có sẵn `displayNameLabel`/`emailLabel` (không thêm ARB). `_buildAccountInfoCard`/`_buildAccountInfoRow`, `context.watch<AuthProvider>().currentUser`, ẩn khi null. VERIFY runtime Pixel 10: hiện "Tên hiển thị: abc / Email: b@gmail.com". analyze sạch. + Cùng đợt (cross-cutting, ghi ở đây): **câu chào & cụm tên cặp "mình đứng trước"** — thêm param `creatorUserId` vào `AnimatedCoupleName` (`animated_couple_name.dart`), widget đọc `AuthProvider` uid + đảo để viewer đứng trước; áp 7 call site (home 1 + profile 1 + gallery 5; couple_info_card unused nên bỏ). Verify: case creator (abc) hiện đúng abc-trước runtime; case joiner (em→em-trước) verify logic, chờ login "em" xác nhận live.
