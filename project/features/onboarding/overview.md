# Onboarding — Giới thiệu app lần đầu mở + "cần cả hai mới có ý nghĩa"

> File PO sở hữu. **Trạng thái: 💻 Dev XONG 2026-09-05 (4 agent song song: O1 landing+link · O2 checklist+nhắc lại · O3 feature tour · O4 intro) — 🧪 Tester code-level đang soi, chờ smoke-test máy thật.** User uỷ quyền chốt theo đề xuất (làm cả 4 mục). Chi tiết: [dev.md](dev.md).

- **Feature:** onboarding
- **Ưu tiên đề xuất:** P0 cho phần "B phải tải app" (phễu ghép đôi = điểm nghẽn lớn nhất, CLAUDE.md §11), P1 cho intro slides.
- **Liên quan:** [coupling](../coupling/overview.md) · [invite-sharing](../invite-sharing/overview.md) (Phase 3 universal link) · [guest-mode](../guest-mode/overview.md) · [analytics](../analytics/overview.md)

## 1. Vấn đề
- Lần đầu mở app: rơi thẳng vào `guest_counter` → login → setup. Không có chỗ nào nói app làm được gì, và **không nói rõ app chỉ trọn vẹn khi người ấy cũng cài**.
- `inviteShareMessage` (l10n) chỉ có mã 6 ký tự, **KHÔNG có link tải** → B nhận tin "nhập mã này" mà không biết tải app ở đâu (đặc biệt B chưa từng nghe tên app).
- A ở trạng thái `waiting_partner` chỉ thấy 1 banner + mã; không có checklist "bước tiếp theo là gì", không có nhắc lại nếu B mãi không vào.
- Tính năng mới (vd Quan tâm 💌) ra mắt không có cách nào báo cho user cũ trong app.

## 2. Ý tưởng (xếp theo giá trị / công sức)

### 2.1 ⭐ Link tải trong tin nhắn mời + trang landing (½ ngày, giá trị cao nhất)
- Sửa `inviteShareMessage` (vi+en): thêm dòng `Tải app tại: https://dearembeiu.com/get?code=ABC123`.
- Trang `docs/get.html` (GitHub Pages sẵn, cùng chỗ `auth-action.html`): detect UA → redirect App Store `id6775165592` / Play `com.tony.dearembeiu`; desktop thì hiện 2 badge. Giữ `?code=` để sau này (invite-sharing Phase 3) deep-link `dearembeiu://join?code=` tự điền.
- Không đụng native, không đụng rules. Chỉ l10n + 1 file html.

### 2.2 ⭐ Màn chờ partner thành checklist có hướng dẫn (1 ngày)
Khi couple `waiting_partner`, banner Home + Setup đổi thành 3 bước:
1. **Gửi lời mời** — 1 nút "Gửi cho người ấy" (share sheet: mã + link tải), phụ: Copy mã, QR.
2. **Người ấy tải app & đăng ký** — text ngắn: "Người ấy cần cài Dear Embeiu (iOS/Android) rồi chọn *Nhập mã mời*."
3. **Nhập mã** — "Ghép xong app tự chuyển, bạn sẽ nhận thông báo" (đã có `notifyPartnerJoined`).
- Dưới checklist: **"Trong lúc chờ bạn vẫn dùng được"**: đặt ngày yêu, thêm kỷ niệm, trả lời câu hỏi hôm nay → người ấy vào sẽ thấy hết (single-player value, CLAUDE.md §11).
- **Nhắc lại tự động** (local one-shot): +24h và +72h nếu vẫn `waiting_partner`: "Người ấy chưa vào nè, gửi lại lời mời?" → tap mở share sheet. Band id mới (vd 1180–1189), huỷ khi active.

### 2.3 Intro 3 slide trước landing (1 ngày)
- Chỉ hiện 1 lần (Hive `onboarding_seen_v1`), có Bỏ qua, i18n, dùng primitives design-unify.
- Slide 1 "Đếm từng ngày yêu" · Slide 2 "Kho kỷ niệm + câu hỏi mỗi ngày + chuỗi" · **Slide 3 "Cần cả hai"**: minh hoạ 2 điện thoại, copy: "Dear Embeiu là không gian của 2 người. Bạn tạo mã mời, người ấy tải app và nhập mã là xong." + 2 badge store nhỏ.
- Rủi ro đã biết: intro carousel hay bị skip → giữ 3 slide, không quá 1 câu/slide, CTA cuối "Bắt đầu".

### 2.4 Feature tour theo phiên bản (1 ngày, tái dùng mãi)
- Sheet "Có gì mới" hiện 1 lần/version (Hive `feature_tour_seen_<build>`), nội dung lấy từ 1 list hằng trong code (title/body/icon/deep-link tab). Dùng ngay để giới thiệu 💌 Quan tâm cho user 1.5.0 → 1.6.0.
- Kết hợp **coach mark** trong ngữ cảnh (spotlight 1 lần lên: vuốt đổi nền thẻ đếm, chip chuỗi, nút 💌) — dạy đúng lúc, không cần carousel.

### 2.5 Đo lường (analytics đã có)
- `onboarding_view/skip/complete`, `invite_share` (kênh), `invite_reminder_tap`, `partner_joined` kèm `hours_since_invite`. Metric: **tỉ lệ ghép đôi trong 72h**.

## 3. Đề xuất thứ tự
1. 2.1 (link tải) → 2. 2.2 (checklist + nhắc lại) → 3. 2.4 (feature tour, dùng luôn cho 1.6.0) → 4. 2.3 (intro slides) → 5. QR/universal link (invite-sharing Phase 2/3).

## 4. Câu hỏi chờ user chốt
- Có làm intro slides không, hay chỉ checklist + feature tour (mình nghiêng về checklist trước)?
- Domain landing: dùng `dearembeiu.com/get` (GitHub Pages sẵn) OK?
- Nhắc lại A khi B chưa vào: 24h/72h đủ hay muốn dày hơn?
