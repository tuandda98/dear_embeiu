# UI audit 2026-10-13

- Lý do: user yêu cầu 2026-10-13 "check lại toàn app và sửa lỗi UI".
- Phạm vi: audit mức code `lib/screens` + `lib/widgets` (không chạy app). Spec fix cho Dev ở [`design.md`](design.md).
- Hai lỗi user đã chỉ (login trùng nhãn "Email", Settings SafeArea cắt phẳng) do Lead tự sửa; audit này tìm lỗi CÙNG LOẠI ở màn khác + checklist skill.

## Nhật ký
- [2026-10-13] [Designer] Audit code toàn app, ghi 36 finding vào design.md.

- [2026-10-13] [Lead] Dev A + Dev B vá 36 finding (commit `aef4b3f`), Lead vá thêm scrim landing/Setup; smoke Android + iOS một phần — xem [test.md](test.md).
