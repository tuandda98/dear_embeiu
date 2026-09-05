# 🎨 Design — Care message ("Quan tâm")

> Designer sở hữu. Bám design system (`../../../CLAUDE.md` mục 8). Ghi hậu kiểm 2026-09-05: feature xây nhanh bằng agent Dev, design được chốt theo primitives sẵn có (không có spec riêng trước khi code).

- **Trạng thái design:** xong (as-built)

## Màn "Gửi quan tâm" (`care_message_screen.dart`)
- Header: `SubScreenHeader` chip-only "QUAN TÂM" / "CARE NOTE" (icon `IconsaxPlusBold.heart`), back trái.
- Khối 1 — 6 chip gợi ý (title + body điền sẵn): Nhớ em 💕 · Uống nước nha 💧 · Ăn cơm chưa? 🍚 · Ngủ sớm nha 🌙 · Anh yêu em ❤️ · Cố lên nha 💪 (l10n `careQuick1..6Title/Body`).
- Khối 2 — `ContentCard` chứa 2 TextField: title (≤60) + body (multiline ≤200).
- CTA pill navy h52 r999 "Gửi cho người ấy 💌": disable khi rỗng/chưa ghép đôi, spinner khi gửi; offline → toast "đã xếp hàng" rồi đóng.
- Khối 3 — "Đã gửi gần đây": danh sách tin (title + body trọn + giờ), ẩn khi rỗng.
- Entry: nút 💌 `message_favorite` 48px bare-ink ở header Home cạnh chuông (cùng ripple rose .12) + tile Profile.

## Thông báo
- Push: title/body NGUYÊN VĂN (không content-free — tin nhắn chính là nội dung).
- Notification center: avatar `message_favorite` `accentLoveDeep`, title = title nguyên văn, subtitle = body trọn (không cắt dòng), tap → Home.

## Nợ design
- Chưa có màn chi tiết 1 tin (body dài đọc trong center là đủ); chưa có preview trước khi gửi.
