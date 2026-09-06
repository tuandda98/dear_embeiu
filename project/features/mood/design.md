# 🎨 Designer — Tâm trạng hôm nay (Mood)

> Friendly, ấm, hợp brand "Sunset Romance". 1–2 chạm. Đặt ở Home nhóm "Hôm nay của chúng mình" (ngay dưới today-ritual card).

## Card (Home) — `MoodCard`
`ContentCard` (trắng r24). Bố cục:
- **Header:** disc icon `emoji_happy` (rose .12) + tiêu đề "Tâm trạng hôm nay".
- **2 cột (Bạn | Người ấy)** cách nhau divider mảnh:
  - Có mood: emoji 30px trong vòng tròn rose .10 + nhãn mood (w700) + note in nghiêng (≤2 dòng) nếu có.
  - Trống: vòng tròn `surfaceLight` + icon (`add` cho mình / `emoji_normal` cho người ấy) + text mời.
  - Cột "Bạn" bấm được → mở picker; cột người ấy read-only.
- **CTA full-width pill:** chưa chia sẻ → gradient `sunsetRomance` "Chia sẻ tâm trạng" (chữ trắng + heart); đã chia sẻ → `surfaceLight` "Đổi tâm trạng" (chữ secondary + edit_2).

## Trạng thái
| | Bạn | Người ấy |
|---|---|---|
| Chưa ai | "Chạm để chia sẻ" + CTA gradient | "{tên} chưa chia sẻ hôm nay" |
| Mình rồi | emoji+nhãn+note · CTA "Đổi tâm trạng" | (mood người ấy hoặc "chưa chia sẻ") |
| Người ấy rồi | (mời chia sẻ) | emoji+nhãn+note |
| Cả hai | emoji 2 bên | emoji 2 bên |

## Picker — `_MoodPickerSheet` (bottom sheet, blur `cardSurface` giống streak/records sheet)
- Tiêu đề serif "Hôm nay bạn thế nào?".
- **Wrap 8 mood chip** (78px, emoji 28 + nhãn) — chọn = viền `accentLove` + nền rose .14.
- TextField note (≤100, hint "Thêm đôi lời (không bắt buộc)", fill `surfaceLight` r16).
- Nút "Lưu tâm trạng" (disable đến khi chọn 1 mood).

## Bộ mood (key/emoji/vi/en)
happy 😄 Vui/Happy · loved 🥰 Hạnh phúc/Loved · missing 🥹 Nhớ/Missing you · calm 😌 Bình yên/Calm · meh 😐 Bình thường/Meh · tired 😪 Mệt/Tired · sad 😢 Buồn/Sad · stressed 😣 Căng thẳng/Stressed.

## Motion / a11y
- Chip chọn: `AnimatedContainer` 160ms. Haptic selectionClick khi chọn, lightImpact khi lưu.
- Emoji có nhãn chữ kèm (không chỉ dựa màu/emoji) — đọc được, không phụ thuộc màu.

## Nhật ký design
- [2026-06-19] [lead/designer] Spec v1 mood card + picker. Partner mood luôn hiện (care, không gate). Emoji scale 8 mood ấm. Sheet style đồng bộ streak/records.
