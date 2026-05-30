# Coupling — Ghép đôi qua mã mời

> File PO sở hữu. Nguồn sự thật chung. Designer/Dev/Tester đọc trước.

- **Feature:** coupling
- **Ưu tiên:** P0 (then chốt — giá trị app chỉ xuất hiện khi cả 2 ghép đôi)
- **Trạng thái:** ✅ Shipped (v1.0.0)
- **Liên quan:** [roadmap.md](roadmap.md) · [design.md](design.md) · [dev.md](dev.md) · [test.md](test.md) · bối cảnh [`../../../CLAUDE.md`](../../../CLAUDE.md) mục 5,13

## 1. Mô tả
A tạo couple → nhận **mã mời 6 ký tự** (`invite_codes/{code}`) → đưa cho B → B nhập mã để join. Join bằng **Firestore transaction**: memberIds [A]→[A,B], couple `waiting_partner`→`active`, cả 2 user `in_couple`. Leave → demote về waiting_partner; xoá couple chỉ khi còn 1 member.

> ⚠️ Đây là **điểm nghẽn phễu lớn nhất** (cần cả 2 người) — PO ưu tiên tối ưu onboarding/mời ở roadmap.

## 2. Phạm vi
- **Trong:** tạo couple (tên 2 người, anniversary, ảnh đại diện), sinh mã mời, join bằng mã, leave couple, banner chờ partner (hiện mã ở Home).
- **Ngoài:** mời qua deep link/QR, nhiều couple/lịch sử couple, đổi mã mời.

## 3. Code liên quan
- `lib/services/couple_service.dart` (~726 dòng), `lib/providers/couple_provider.dart`, `lib/services/user_service.dart`
- `lib/screens/setup_screen.dart` (create/join), banner ở `home_screen.dart`
- Backend: rules `couples/{coupleId}`, `invite_codes/{code}`; coupling transaction

## 4. Acceptance (đã đạt)
- [x] Tạo couple → có mã 6 ký tự; B nhập mã → ghép thành công
- [x] Concurrent join an toàn (transaction — chỉ 1 người thắng)
- [x] Leave demote đúng; xoá couple chỉ khi sole member

## 5. Nợ kỹ thuật / rủi ro
- 🔴 **Invite code enumeration:** mọi user đăng nhập `read` được MỌI `invite_codes/{code}` → liệt kê/đếm/brute-force join. Không rate-limit.
- 🔴 **invite_code.coupleId đổi được** bởi owner (chỉ createdAt/userId immutable) → hijack/phá luồng mời.
- 🟡 **Waiting-partner couple lộ data cho non-member** nếu đoán/leak coupleId (person1/2Name, anniversaryDate, couplePhotoUrl).
- 🟡 Leave trong khi partner join / cả 2 cùng leave → state lạ, ảnh orphan (cleanup Storage không transactional). [CẦN TEST]
- 🟡 Không validate person1Name != person2Name; invite input không check độ dài trước lookup.

## 6. Changelog
- [2026-05-30] [PO] Tài liệu hoá feature đã ship + nợ kỹ thuật từ catalog (CLAUDE.md mục 12,13).
