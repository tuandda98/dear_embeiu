# Birthday Page — Dev

Trang sinh nhật riêng cho Embe iu (14/08/1998, sinh nhật thứ 28).

## ⚠️ Luật quan trọng: KHÔNG commit nội dung trang

Repo `tuandda98/dear_embeiu` là **public**. Ảnh riêng tư, lá thư và trích dẫn Daily
Question TUYỆT ĐỐI không được vào git (xoá sau vẫn còn trong lịch sử commit).
`docs/birthday/` đã nằm trong `.gitignore` để chốt chặn.

Vì vậy trang KHÔNG dùng GitHub Pages mà dùng **Firebase Hosting site riêng** —
file đẩy thẳng từ máy lên Google, không qua git.

## Địa chỉ
- Trang sinh nhật: `https://dearembeiu-birthday.web.app/14081998/`
- Trang đọc điều ước (cho Anh By): `https://dearembeiu-birthday.web.app/dieu-uoc/`
  → cần khoá đọc, lấy từ Secret Manager: `BIRTHDAY_READ_KEY` (project prod).
- Site Firebase: `dearembeiu-birthday` (tạo bằng `hosting:sites:create`, project `tonyembeiu`).

`firebase.json` giờ có **mảng** 2 hosting. ⚠️ Entry site cũ (`tonyembeiu`) đã thêm
`"birthday/**"` vào `ignore` — thiếu dòng này thì deploy site cũ sẽ đẩy ảnh riêng tư
lên `tonyembeiu.web.app`.

Deploy: `npx firebase-tools deploy --only hosting:dearembeiu-birthday --project prod`

## Cloud Function `birthdayWish`
`onRequest` (us-central1, CORS mở). Trang là HTML tĩnh và người viết KHÔNG đăng nhập,
nên function ghi bằng quyền admin — không phải nới rules Firestore cho client, cũng
không phải bật đăng nhập ẩn danh trên prod.
- `POST {text, from}` → ghi `birthdayWishes/{autoId}`. Chặn spam: text ≤ 500 ký tự,
  ngừng nhận khi collection đã có ≥ 200 bản ghi.
- `GET ?key=<BIRTHDAY_READ_KEY>` → đọc lại. Khoá ở Secret Manager, KHÔNG trong repo.

## Nội dung
- 6 màn: đếm ngược → cổng → chào → thổi nến → thư → thống kê/trích dẫn → album → đếm ngày.
- **Đếm ngược** khoá tới `2026-08-14T00:00:00+07:00`, đúng giờ tự mở không cần tải lại.
  Xem trước bằng `?preview=1`.
- **Nhạc**: giai điệu *Happy Birthday* tổng hợp bằng Web Audio (bài thuộc phạm vi công
  cộng) — không cần file. Nhạc nền tuỳ chọn: thả `song.mp3` cạnh `index.html`, không có
  thì bỏ qua im lặng.
- **Thổi nến**: `getUserMedia` + `AnalyserNode`; nhận diện hơi thổi = năng lượng dải
  < 900 Hz **và** dải thấp chiếm > 62% phổ (để giọng nói/nhạc không thổi tắt nến oan).
  Luôn có nút bấm dự phòng.
- **Album 39 ảnh**: 27 ảnh lọc từ Apple Photos Library bằng nhận diện khuôn mặt (ảnh có
  mặt CẢ hai người) + 12 ảnh từ app kèm **nguyên văn caption và tên người đăng**. Đã loại
  hết ảnh đồ ăn/đồ vật. Xuất 2 cỡ (1000px + 520px) dùng `srcset` → điện thoại chỉ tải 1,1 MB.
- Sửa nội dung: toàn bộ nằm trong object `CONFIG` đầu thẻ `<script>`.

## Nguồn số liệu
Firestore prod, couple `qlAB4LKZCQV7MwB8SvPy` ("Anh By ❤️ Embe ieu"), kỷ niệm 30/11/2025:
66/66 ngày cả hai cùng trả lời Daily Question, 2.806 từ. Ngày 07/07 cả hai cùng trả lời
"Vỡ Tan" cho câu hỏi về bài hát thời gian đầu.

## Nhật ký
- [2026-08-10] [dev] Dựng trang, deploy live. Vá lỗi nến đè chữ eyebrow (`margin-top:82px`
  cho `.cake-wrap`). Thay caption tự bịa bằng caption gốc trong app. Thêm đếm ngược +
  ô điều ước + function `birthdayWish` + trang `/dieu-uoc/`. Đã kiểm chứng: dearembeiu.com
  (privacy/account-deletion/auth-action) KHÔNG bị ảnh hưởng; `docs/birthday/` không xuất
  hiện trong `git status`.
