# <Tên feature>

> File PO sở hữu. Nguồn sự thật chung cho cả feature. Designer/Dev/Tester đọc file này trước.
>
> 💡 **Mẫu đã điền đầy đủ để bắt chước giọng văn & độ chi tiết:** xem một feature đã `✅ Done` gần nhất, vd [`../language/overview.md`](../language/overview.md) hoặc [`../daily-question/overview.md`](../daily-question/overview.md). Acceptance criteria phải viết RÕ & đo được (PO đóng Done dựa vào đây).

- **Feature:** <ten-feature>
- **Ưu tiên:** <P0 | P1 | P2>
- **Trạng thái:** 📋 Spec
- **Tạo ngày:** <YYYY-MM-DD>
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh dự án [`../../../CLAUDE.md`](../../../CLAUDE.md)

## 1. Vấn đề & giá trị
- *Vấn đề người dùng:* <…>
- *Giả thuyết giá trị:* <nếu làm X thì Y cải thiện…>
- *Đối tượng:* <ai>
- *Đo bằng gì (metric):* <…>

## 2. Bối cảnh / nghiên cứu
- <insight thị trường, đối thủ, best-practice, kèm nguồn nếu có>

## 3. Phạm vi (scope)
- **Trong phạm vi:** <…>
- **Ngoài phạm vi:** <…>

## 4. Quyết định đã chốt (decision log)
> Đừng lật lại trừ khi user/PO đổi ý.
- **D1 —** <quyết định> · *Lý do:* <…>

## 5. Acceptance criteria (xong khi…)
- [ ] <tiêu chí 1>
- [ ] <tiêu chí 2>

## 6. Giao việc 3 vai (tóm tắt — chi tiết ở file mỗi role)
- 🎨 **Designer:** <làm gì> → *expect:* <deliverable>
- 💻 **Dev:** <làm gì> → *expect:* <deliverable>
- 🧪 **Tester:** <làm gì> → *expect:* <deliverable>

## 7. Changelog feature
- [<YYYY-MM-DD>] [PO] Tạo feature, viết spec.
- [2026-06-04] [Designer] Xuất design spec v1 (`design.md`): bộ 6 emoji ❤️😍😂🥹🔥👍, 3 surface (feed card chính / fullscreen / home badge read-only), 3 lối tương tác (tap/double-tap/long-press), full states + copy vi/en (UI+push) + mục phụ thuộc kỹ thuật (subcollection + rules + CF). Chờ PO chốt vài quyết định mở.
