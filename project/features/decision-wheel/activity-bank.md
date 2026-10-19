# Ngân hàng "Đi đâu / làm gì" — nguồn cho `lib/data/activity_bank.dart`

> PO sở hữu nội dung. Dev sinh hằng Dart từ bảng này (giữ `id`; thêm mục = sửa file này trước). 64 mục, 5 nhóm.
>
> Cột: **Nơi** `nha` · `ngoai` · **Tiền** `free` (không tốn) · `re` (dưới ~200k cho 2 người) · `ton` · **Lúc** `ngay` (làm được bất kỳ lúc nào) · `toi` · `cuoi_tuan` (cần nửa ngày trở lên). Emoji là nội dung hiển thị. Tên `en` là động từ ("Grab coffee") để ghép câu push *"let's {result}"*.

## A. Ra ngoài nhanh (1–2 tiếng)

| id | Tên (vi) | Name (en) | Nơi | Tiền | Lúc | Emoji |
|---|---|---|---|---|---|---|
| ca_phe | Đi cà phê | grab coffee | ngoai | re | ngay | ☕ |
| tra_sua | Đi uống trà sữa | get bubble tea | ngoai | re | ngay | 🧋 |
| an_vat | Đi ăn vặt vỉa hè | hit a street-food spot | ngoai | re | toi | 🍢 |
| di_dao | Đi dạo bờ hồ / công viên | take a walk by the lake or park | ngoai | free | ngay | 🌳 |
| pho_di_bo | Đi phố đi bộ / chợ đêm | stroll the night market | ngoai | re | toi | 🌃 |
| hoang_hon | Đi ngắm hoàng hôn | catch the sunset | ngoai | free | toi | 🌇 |
| nha_sach | Đi nhà sách | browse a bookstore | ngoai | free | ngay | 📚 |
| chup_anh_dao | Đi chụp ảnh dạo | go on a photo walk | ngoai | free | ngay | 📷 |
| photobooth | Chụp photobooth | take photobooth pics | ngoai | re | ngay | 📸 |
| sieu_thi_nau | Đi siêu thị rồi về nấu | shop groceries and cook | ngoai | re | ngay | 🛒 |
| cafe_meo | Đi cafe mèo / cafe chó | visit a cat or dog cafe | ngoai | re | ngay | 🐱 |
| kem | Đi ăn kem | go for ice cream | ngoai | re | ngay | 🍦 |
| xe_may_vong | Chạy xe một vòng thành phố | ride around the city | ngoai | free | toi | 🛵 |
| cafe_rooftop | Lên cafe rooftop | find a rooftop cafe | ngoai | re | toi | 🌆 |

## B. Ra ngoài vui chơi (nửa buổi)

| id | Tên (vi) | Name (en) | Nơi | Tiền | Lúc | Emoji |
|---|---|---|---|---|---|---|
| xem_phim_rap | Đi xem phim rạp | see a movie | ngoai | re | toi | 🎬 |
| karaoke | Đi hát karaoke | go karaoke | ngoai | re | toi | 🎤 |
| bowling | Đi chơi bowling | go bowling | ngoai | re | toi | 🎳 |
| bida | Đi đánh bida | play pool | ngoai | re | toi | 🎱 |
| cafe_board_game | Đi cafe board game | play board games at a cafe | ngoai | re | toi | 🎲 |
| escape_room | Chơi escape room | try an escape room | ngoai | ton | cuoi_tuan | 🔐 |
| vr_game | Chơi VR / khu trò chơi | hit an arcade or VR spot | ngoai | re | toi | 🕹️ |
| truot_patin | Đi trượt patin / trượt băng | go skating | ngoai | re | cuoi_tuan | ⛸️ |
| leo_nui_trong_nha | Leo núi trong nhà | try indoor climbing | ngoai | ton | cuoi_tuan | 🧗 |
| bao_tang | Đi bảo tàng / triển lãm | visit a museum or exhibition | ngoai | re | cuoi_tuan | 🖼️ |
| kich_hai | Đi xem kịch / hài | see a play or comedy show | ngoai | ton | toi | 🎭 |
| nhac_song | Đi nghe nhạc sống | catch live music | ngoai | re | toi | 🎶 |
| ho_boi | Đi bơi | go swimming | ngoai | re | cuoi_tuan | 🏊 |
| mua_sam | Đi mua sắm | go shopping | ngoai | ton | cuoi_tuan | 🛍️ |
| spa_massage | Đi spa / massage đôi | get a couples massage | ngoai | ton | cuoi_tuan | 💆 |
| lam_gom | Đi làm gốm / vẽ tranh | do a pottery or painting class | ngoai | ton | cuoi_tuan | 🎨 |
| lop_nau_an | Học nấu một món mới | take a cooking class | ngoai | ton | cuoi_tuan | 👩‍🍳 |
| so_thu_thuy_cung | Đi sở thú / thủy cung | visit the zoo or aquarium | ngoai | re | cuoi_tuan | 🐠 |
| cong_vien_nuoc | Đi công viên nước | hit a water park | ngoai | ton | cuoi_tuan | 🌊 |
| tap_nhay | Đi học nhảy đôi | take a dance class | ngoai | re | toi | 💃 |

## C. Ngoài trời / đi xa

| id | Tên (vi) | Name (en) | Nơi | Tiền | Lúc | Emoji |
|---|---|---|---|---|---|---|
| picnic | Đi picnic | have a picnic | ngoai | re | cuoi_tuan | 🧺 |
| dap_xe | Đạp xe cùng nhau | go cycling | ngoai | free | cuoi_tuan | 🚲 |
| chay_bo | Chạy bộ buổi sáng cùng nhau | go for a morning run | ngoai | free | ngay | 🏃 |
| cam_trai | Đi cắm trại | go camping | ngoai | ton | cuoi_tuan | 🏕️ |
| bien_gan | Đi biển gần | drive to a nearby beach | ngoai | ton | cuoi_tuan | 🏖️ |
| du_lich_2_ngay | Đi chơi 2 ngày gần thành phố | take a weekend trip | ngoai | ton | cuoi_tuan | 🧳 |
| ngam_sao | Đi ngắm sao | go stargazing | ngoai | free | toi | 🌌 |
| chua_nha_tho | Đi chùa / nhà thờ | visit a pagoda or church | ngoai | free | cuoi_tuan | 🙏 |
| cho_hoa | Đi chợ hoa | wander a flower market | ngoai | re | cuoi_tuan | 🌸 |
| tham_bo_me | Về thăm bố mẹ | visit the parents | ngoai | free | cuoi_tuan | 👨‍👩‍👧 |
| gap_ban_chung | Rủ bạn chung đi chơi | hang out with mutual friends | ngoai | re | toi | 🍻 |
| leo_nui | Đi leo núi / trekking nhẹ | go hiking | ngoai | free | cuoi_tuan | ⛰️ |

## D. Ở nhà

| id | Tên (vi) | Name (en) | Nơi | Tiền | Lúc | Emoji |
|---|---|---|---|---|---|---|
| phim_o_nha | Xem phim ở nhà | have a movie night in | nha | free | toi | 📺 |
| nau_an_cung | Nấu ăn cùng nhau | cook together | nha | re | ngay | 🍳 |
| lam_banh | Làm bánh | bake something | nha | re | cuoi_tuan | 🧁 |
| choi_game_cung | Chơi game cùng nhau | play video games together | nha | free | toi | 🎮 |
| board_game_nha | Chơi board game / bài | play board games or cards | nha | free | toi | 🃏 |
| yoga_doi | Tập yoga / tập thể dục đôi | do a couples workout | nha | free | ngay | 🧘 |
| don_nha | Dọn nhà cùng nhau rồi gọi đồ ăn | clean the place then order in | nha | re | cuoi_tuan | 🧹 |
| ngu_nuong_brunch | Ngủ nướng rồi ăn brunch | sleep in and brunch | nha | re | cuoi_tuan | 🥞 |
| lam_nen | Làm nến / xà phòng / đồ thủ công | do a craft project | nha | re | cuoi_tuan | 🕯️ |
| karaoke_nha | Hát karaoke ở nhà | sing karaoke at home | nha | free | toi | 🎙️ |
| spa_tai_nha | Tự làm spa tại nhà | do a home spa night | nha | re | toi | 🛁 |
| nghe_nhac_doc_sach | Nghe nhạc, đọc sách cạnh nhau | listen to music and read together | nha | free | ngay | 🎧 |

## E. Chỉ hai mình (gắn với app)

| id | Tên (vi) | Name (en) | Nơi | Tiền | Lúc | Emoji |
|---|---|---|---|---|---|---|
| xem_lai_anh | Xem lại ảnh kỷ niệm cùng nhau | look back at our photos together | nha | free | toi | 📱 |
| viet_thu | Viết cho nhau một lá thư | write each other a letter | nha | free | toi | ✉️ |
| ke_chuyen_ngay_xua | Kể lại ngày đầu quen nhau | retell how we met | nha | free | toi | 💞 |
| len_ke_hoach_chuyen_di | Lên kế hoạch một chuyến đi | plan a trip together | nha | free | toi | 🗺️ |
| hoc_cai_moi | Cùng học một thứ mới 30 phút | learn something new for 30 minutes | nha | free | ngay | 🧠 |
| hen_ho_lai | Hẹn hò như lần đầu | re-do our first date | ngoai | re | toi | 🌹 |

## Luật dùng trong `DecisionSuggester` (overview D4)
- Pool = bảng này + mục nhập tay (`kind: go`, `resultId == ''`) trong 90 ngày, trọng số ×2.
- Loại mục có `result` chuẩn hoá trùng kết quả `go` đã chốt 14 ngày gần nhất.
- Chip: Tuỳ = tất cả · Ở nhà = `nha` · Ra ngoài = `ngoai` · Không tốn tiền = `free`.
- Thứ 7/CN cả ngày, hoặc ngày thường sau 17:00: mục `cuoi_tuan`/`toi` trọng số ×2; ngày thường trước 17:00 mục `cuoi_tuan` trọng số ×0,5 (vẫn có thể ra).
- Ngẫu nhiên thật mỗi lần quay, không lặp trong cùng phiên cho tới khi hết pool.
