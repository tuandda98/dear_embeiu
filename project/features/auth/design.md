# 🎨 Design — Auth

> Designer sở hữu. Đọc [overview.md](overview.md). Bám design system (`../../../CLAUDE.md` mục 8). CHỈ thiết kế.

- **Trạng thái design:** ✅ Đã có (mô tả hiện trạng để baseline)

## Hiện trạng UI (đã ship)
- **splash / auth_gate:** nền `secondaryGradient` (dawnBlush), tim trắng 80px, spinner trắng; chỉ resolve route, không animation.
- **login / register:** nền gradient, header badge eyebrow + pageTitle, **form card glass** (white alpha .22, bo 28). Field label rose w700, input bo 20 prefix icon rose, nút submit rose. LanguageToggle góc trên phải.
- **register thêm:** policy disclosure clickable, checkbox điều khoản (bắt buộc tick), link privacy.

## Copy (song ngữ) — đã có trong ARB
Các key auth (login/register/password/email/displayName validation…) đã có VI+EN trong `lib/l10n/app_*.arb`.

## Đề xuất cải thiện (nếu nâng cấp sau)
- Thêm "Quên mật khẩu" (hiện chưa có) → cần thiết kế flow + màn nhập email.
- Trạng thái lỗi inline rõ hơn cho từng field (hiện dựa SnackBar/validator).

## Nhật ký design
- [2026-05-30] [PO] Ghi nhận hiện trạng UI auth từ CLAUDE.md mục 8.
