# Invite sharing — Chia sẻ mã mời mượt hơn (giảm ma sát ghép đôi cho User 2)

> File PO sở hữu. Designer/Dev/Tester đọc trước.

- **Feature:** invite-sharing
- **Ưu tiên:** P1 (mở rộng [coupling](../coupling/overview.md) — phễu then chốt: giá trị chỉ có khi cả 2 ghép đôi)
- **Trạng thái:** 🧪 Test PASS (code-level) — chờ user smoke-test thiết bị (Phase 1)
- **Tạo ngày:** 2026-06-01
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · feature [coupling](../coupling/overview.md) · [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 5

## 1. Vấn đề & giá trị
- *Vấn đề:* User 2 (B) ghép đôi tốn thời gian — phải **gõ tay 6 ký tự bằng mắt** (dễ nhầm O/0, I/1). Mã mời lại hiện ở 3 nơi (Setup/Home banner/Profile) nhưng **chỉ Setup có nút Copy**, không nhất quán, và **chưa có nút Share** nào.
- *Giá trị:* A chia sẻ mã 1 chạm qua iMessage/Zalo/Messenger; mọi chỗ hiện mã đều copy/share được → B đỡ phải gõ tay (paste). Giảm ma sát phễu ghép đôi (điểm nghẽn lớn nhất của app — CLAUDE.md mục 11).

## 2. Phạm vi (scope) — Phase 1
- **Trong:**
  - Thêm package `share_plus`.
  - **Nút Share** cạnh mã mời ở **cả 3 nơi**: Setup (`_buildInviteCodeCard`), Home banner chờ partner, Profile detail tile. Mở share sheet native gửi **câu mời ấm áp song ngữ kèm mã**.
  - **Đồng bộ nút Copy** ở cả 3 nơi (hiện chỉ Setup có — `setup_screen.dart:632`).
  - Copy song ngữ (vi+en) cho câu mời.
- **Ngoài (để pha sau):**
  - **Phase 2:** QR code (hiện + quét).
  - **Phase 3:** Universal Link / Android App Link 1-chạm tự-join + login-1-lần-auto-resume (xem roadmap.md).
  - KHÔNG đụng cấu hình native ở Phase 1.
  - KHÔNG sửa logic join/transaction/rules.

## 3. Quyết định đã chốt (decision log)
- **IS1 — Làm phân pha:** Phase 1 (copy/share, không native) trước → Phase 2 (QR) → Phase 3 (link 1-chạm). User chốt 2026-06-01.
- **IS2 — Cross-platform chung:** Phase 1 dùng `share_plus` + Clipboard thuần Flutter → **1 bộ code chạy cả Android + iOS, không cần cấu hình riêng nền nào**. Android vẫn là target (AndroidManifest + Play docs còn).
- **IS3 — Share gồm mã, CHƯA gồm link auto-join** (link là Phase 3). Câu mời nên viết để dễ chèn link sau.
- **IS4 — KHÔNG dùng Firebase Dynamic Links** (Google khai tử 2025) — dành cho Phase 3, ghi sẵn để khỏi chọn nhầm.

## 4. Acceptance criteria (Phase 1)
- [ ] Mọi nơi hiện mã mời (Setup / Home banner / Profile) đều có **nút Copy** + **nút Share**, đồng bộ trên **cả iOS và Android**.
- [ ] Tap Copy → chép mã, hiện toast xác nhận (tái dùng `inviteCodeCopiedMsg`).
- [ ] Tap Share → mở share sheet native với câu mời song ngữ + mã (đúng locale đang dùng).
- [ ] i18n vi+en đủ chuỗi mới; không hardcode.
- [ ] `flutter analyze` sạch; bám design system (tái dùng pattern nút copy hiện có ở Setup).
- [ ] KHÔNG regression luồng tạo/join/leave couple.

## 5. Nợ kỹ thuật / rủi ro (Tester soi)
- 🟡 Share sheet khác nhau iOS vs Android — verify cả 2 nền mở được, nội dung + mã đúng, đúng locale.
- 🟡 Câu mời chứa ký tự đặc biệt/emoji + interpolation mã — không vỡ ICU/l10n.
- 🟡 Mã chỉ hiện khi couple `waiting_partner` — nút Share/Copy phải ẩn/đúng trạng thái khi đã `active` (không còn chờ partner).
- ⚠️ **Cảnh báo kế thừa từ coupling:** nợ 🔴 invite-code enumeration (overview coupling mục 5) — làm join dễ hơn thì rủi ro brute-force tăng. Phase 1 chưa siết (user chọn UX trước); ghi nhận để xử lý khi làm Phase 3 / task bảo mật riêng.

## 6. Giao việc 3 vai
- 🎨 **Designer:** vị trí + layout nút Copy/Share ở 3 màn (Setup/Home banner/Profile), tái dùng pattern nút copy Setup hiện có; thiết kế cụm "Copy | Share" đồng nhất; soạn câu mời song ngữ (ấm áp, dễ chèn link sau). States (waiting_partner vs active). → `design.md`.
- 💻 **Dev:** thêm `share_plus`; tạo widget/cụm nút Copy+Share dùng chung; gắn vào 3 nơi; l10n vi+en; analyze sạch; không native; không đụng join logic. → `dev.md`.
- 🧪 **Tester:** verify copy/share ở cả 3 nơi trên iOS + Android, nội dung+mã+locale đúng, ẩn đúng trạng thái, không regression couple. → `test.md`.

## 7. Changelog
- [2026-06-01] [PO] Tạo feature từ phân tích "giảm ma sát ghép đôi cho User 2". Chốt phân pha (IS1): Phase 1 = copy/share đồng bộ (cross-platform, không native) trước; QR (P2) + link 1-chạm auto-join + login-auto-resume (P3) để sau. Khởi động pipeline.
- [2026-06-01] [PO] Pipeline Phase 1 xong: Designer (`InviteActionButtons` 2 biến thể + câu mời song ngữ) → Dev (widget mới + gắn 3 nơi + share_plus 11.1.0 `SharePlus.instance.share`) → Tester PASS code-level → Dev-fix (gate cụm nút ở Setup chỉ hiện khi `waiting_partner`, theo lưu ý Tester). **2 quyết định PO khi gate:** (1) câu mời BỎ dòng "Tải app:" (app chưa live store, link để Phase 3); (2) l10n làm qua ARB + `fvm flutter gen-l10n` (sửa lại chỉ dẫn "hand-maintain" stale trong design.md). PO verify: `fvm flutter analyze` = "No issues found!"; không đụng join/rules/native. Giữ 🧪 Test PASS, **chờ user smoke-test runtime** (share sheet iOS+Android nội dung/locale · iPad popover · Home banner màn nhỏ wrap · toast copy · tooltip). Chưa commit/deploy.
