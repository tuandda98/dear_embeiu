# 💻 Dev — Coupling

> Dev sở hữu. Đọc [overview.md](overview.md) + [design.md](design.md).

- **Trạng thái dev:** ✅ Đã implement (baseline)

## Đã implement
- `couple_service.dart`: create/join(`runTransaction`)/leave; sinh mã (charset 32 ký tự bỏ I/O/1/0, 6 ký tự, `Random.secure()`, retry tối đa 12). Pre-checks join: chặn đang in_couple, reject code rỗng/chính mình, auto-leave nếu đang waiting solo. Normalize `trim().toUpperCase()`.
- `couple_provider.dart`: create/join/update/leave + Firestore stream.

## Việc cần làm tiếp (từ nợ kỹ thuật)
- [ ] Siết rules `invite_codes`: hạn chế read (không cho liệt kê toàn bộ) + khoá sửa `coupleId`.
- [ ] Chặn non-member đọc couple waiting_partner (rà rules `couples` ~349-351).
- [ ] Xử lý leave-khi-partner-join / cả 2 leave; cleanup Storage an toàn (tránh ảnh orphan).
- [ ] Validate person1 != person2; check độ dài invite trước lookup.
- [ ] (Tuỳ) share sheet/QR cho mã mời.

## Nhật ký implement
- [2026-05-30] [PO] Khởi tạo doc; liệt kê việc cần Dev xử lý.
