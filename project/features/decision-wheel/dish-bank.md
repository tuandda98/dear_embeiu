# Ngân hàng món ăn — nguồn cho `lib/data/dish_bank.dart`

> PO sở hữu nội dung. Dev sinh hằng Dart từ bảng này (giữ nguyên `id`, không tự thêm/bớt món; thêm món = sửa file này trước). 117 món, chia 7 nhóm.
>
> Cột: **Bữa** `sang` · `trua` · `toi` (nhiều giá trị, cách bằng dấu phẩy) · **Nơi** `nha` (nhà nấu) · `ngoai` (ăn ngoài) · **Công** `nhanh` · `vua` · `cau_ky`. Emoji là nội dung hiển thị cạnh tên món (không phải icon giao diện). Tên `en` giữ tên Việt khi món quen thuộc với người nước ngoài (pho, banh mi).

## A. Cơm nhà

| id | Tên (vi) | Name (en) | Bữa | Nơi | Công | Emoji |
|---|---|---|---|---|---|---|
| com_suon_ram | Cơm sườn ram mặn | Rice with caramelized pork ribs | trua,toi | nha | vua | 🍖 |
| thit_kho_tau | Thịt kho tàu trứng | Braised pork belly with eggs | trua,toi | nha | cau_ky | 🥘 |
| ca_kho_to | Cá kho tộ | Clay-pot braised fish | trua,toi | nha | vua | 🐟 |
| canh_chua_ca | Canh chua cá + cơm | Sour fish soup with rice | trua,toi | nha | vua | 🍲 |
| rau_muong_xao_toi | Rau muống xào tỏi + trứng chiên | Garlic water spinach & fried egg | trua,toi | nha | nhanh | 🥬 |
| dau_hu_sot_ca | Đậu hũ sốt cà chua | Tofu in tomato sauce | trua,toi | nha | nhanh | 🍅 |
| ga_kho_gung | Gà kho gừng | Ginger braised chicken | trua,toi | nha | vua | 🍗 |
| thit_rang_chay_canh | Thịt rang cháy cạnh | Crispy-edged pan-fried pork | trua,toi | nha | nhanh | 🥓 |
| canh_bi_do | Canh bí đỏ nấu tôm | Pumpkin shrimp soup | trua,toi | nha | nhanh | 🎃 |
| ca_chien_nuoc_mam | Cá chiên sốt nước mắm | Fried fish with fish-sauce glaze | trua,toi | nha | vua | 🐟 |
| bo_xao_hanh_tay | Bò xào hành tây | Stir-fried beef with onion | trua,toi | nha | nhanh | 🥩 |
| tom_rim | Tôm rim mặn ngọt | Sweet-salty braised shrimp | trua,toi | nha | nhanh | 🦐 |
| muc_xao_dua | Mực xào dứa | Squid stir-fry with pineapple | trua,toi | nha | vua | 🦑 |
| thit_luoc_ca_phao | Thịt luộc cà pháo mắm tôm | Boiled pork with pickled eggplant | trua,toi | nha | nhanh | 🍆 |
| trung_duc_thit | Trứng đúc thịt | Pork omelette | trua,toi | nha | nhanh | 🍳 |
| suon_xao_chua_ngot | Sườn xào chua ngọt | Sweet and sour ribs | trua,toi | nha | vua | 🍖 |
| ga_rang_muoi | Gà rang muối | Salt-roasted chicken | toi | nha,ngoai | vua | 🍗 |
| cai_thia_xao_nam | Cải thìa xào nấm | Bok choy with mushrooms | trua,toi | nha | nhanh | 🍄 |
| canh_rau_ngot | Canh rau ngót thịt băm | Katuk soup with minced pork | trua,toi | nha | nhanh | 🥣 |
| ca_hoi_ap_chao | Cá hồi áp chảo | Pan-seared salmon | toi | nha | vua | 🐟 |
| bo_luc_lac | Bò lúc lắc | Shaking beef | toi | nha,ngoai | vua | 🥩 |
| ech_xao_sa_ot | Ếch xào sả ớt | Frog with lemongrass & chili | toi | nha,ngoai | vua | 🐸 |
| lau_nha | Lẩu nấu ở nhà | Hotpot at home | toi | nha | cau_ky | 🍲 |
| ga_luoc_la_chanh | Gà luộc lá chanh | Boiled chicken with lime leaves | trua,toi | nha | vua | 🍗 |

## B. Bún · phở · mì · cháo

| id | Tên (vi) | Name (en) | Bữa | Nơi | Công | Emoji |
|---|---|---|---|---|---|---|
| pho_bo | Phở bò | Beef pho | sang,trua,toi | ngoai | nhanh | 🍜 |
| pho_ga | Phở gà | Chicken pho | sang,trua,toi | ngoai | nhanh | 🍜 |
| bun_cha | Bún chả | Bun cha (grilled pork & noodles) | trua | ngoai | nhanh | 🍢 |
| bun_bo_hue | Bún bò Huế | Hue beef noodle soup | sang,trua,toi | ngoai | nhanh | 🍜 |
| bun_rieu | Bún riêu cua | Crab noodle soup | sang,trua | ngoai | nhanh | 🦀 |
| bun_dau_mam_tom | Bún đậu mắm tôm | Bun dau mam tom | trua | ngoai | nhanh | 🍢 |
| bun_thit_nuong | Bún thịt nướng | Grilled pork vermicelli | trua,toi | ngoai | nhanh | 🍢 |
| bun_ca | Bún cá | Fish noodle soup | sang,trua | ngoai | nhanh | 🐟 |
| mi_quang | Mì Quảng | Mi Quang | trua,toi | ngoai | nhanh | 🍜 |
| hu_tieu_nam_vang | Hủ tiếu Nam Vang | Phnom Penh noodle soup | sang,trua | ngoai | nhanh | 🍜 |
| hu_tieu_go | Hủ tiếu gõ | Street hu tieu | toi | ngoai | nhanh | 🍜 |
| cao_lau | Cao lầu | Cao lau | trua,toi | ngoai | nhanh | 🍜 |
| banh_canh_cua | Bánh canh cua | Crab thick-noodle soup | trua,toi | ngoai | nhanh | 🦀 |
| mi_van_than | Mì vằn thắn | Wonton noodles | sang,trua,toi | ngoai | nhanh | 🥟 |
| chao_long | Cháo lòng | Pork offal congee | sang,toi | ngoai | nhanh | 🥣 |
| chao_ga | Cháo gà | Chicken congee | sang,toi | nha,ngoai | nhanh | 🥣 |
| bun_mam | Bún mắm | Fermented fish noodle soup | trua,toi | ngoai | nhanh | 🍜 |
| bun_moc | Bún mọc | Pork-ball noodle soup | sang,trua | ngoai | nhanh | 🍜 |
| mien_ga | Miến gà | Chicken glass noodles | sang,toi | ngoai | nhanh | 🍜 |
| mien_luon | Miến lươn | Eel glass noodles | sang,trua | ngoai | nhanh | 🍜 |
| banh_da_cua | Bánh đa cua | Hai Phong crab noodles | sang,trua | ngoai | nhanh | 🦀 |
| mi_xao_bo | Mì xào bò | Beef fried noodles | trua,toi | nha,ngoai | nhanh | 🍝 |
| mi_tom_trung | Mì tôm trứng | Instant noodles with egg | sang,toi | nha | nhanh | 🍜 |
| bun_cha_ca | Bún chả cá | Fish-cake noodle soup | sang,trua | ngoai | nhanh | 🍜 |

## C. Cơm quán

| id | Tên (vi) | Name (en) | Bữa | Nơi | Công | Emoji |
|---|---|---|---|---|---|---|
| com_tam | Cơm tấm sườn bì chả | Broken rice with pork chop | sang,trua,toi | ngoai | nhanh | 🍛 |
| com_ga_xoi_mo | Cơm gà xối mỡ | Crispy chicken rice | trua,toi | ngoai | nhanh | 🍗 |
| com_ga_hoi_an | Cơm gà Hội An | Hoi An chicken rice | trua,toi | ngoai | nhanh | 🍛 |
| com_rang_dua_bo | Cơm rang dưa bò | Beef & pickled-mustard fried rice | trua,toi | ngoai | nhanh | 🍚 |
| com_nieu | Cơm niêu | Clay-pot rice set | toi | ngoai | vua | 🍚 |
| com_binh_dan | Cơm bình dân | Rice at a local eatery | trua | ngoai | nhanh | 🍱 |
| xoi_ga | Xôi gà | Sticky rice with chicken | sang,toi | ngoai | nhanh | 🍚 |
| xoi_xeo | Xôi xéo | Xoi xeo (mung-bean sticky rice) | sang | ngoai | nhanh | 🍚 |
| com_chien_duong_chau | Cơm chiên Dương Châu | Yangzhou fried rice | trua,toi | nha,ngoai | nhanh | 🍚 |

## D. Bánh · ăn sáng · ăn vặt

| id | Tên (vi) | Name (en) | Bữa | Nơi | Công | Emoji |
|---|---|---|---|---|---|---|
| banh_mi_thit | Bánh mì thịt | Banh mi | sang,trua | ngoai | nhanh | 🥖 |
| banh_mi_chao | Bánh mì chảo | Banh mi with sizzling pan | sang | ngoai | nhanh | 🍳 |
| banh_cuon | Bánh cuốn | Steamed rice rolls | sang | ngoai | nhanh | 🥟 |
| banh_xeo | Bánh xèo | Sizzling crepe | toi | ngoai | vua | 🥞 |
| banh_khot | Bánh khọt | Mini savory pancakes | toi | ngoai | vua | 🥞 |
| banh_beo | Bánh bèo, bánh nậm | Hue steamed cakes | trua,toi | ngoai | nhanh | 🥟 |
| banh_gio | Bánh giò | Banh gio (pyramid dumpling) | sang | ngoai | nhanh | 🥟 |
| bot_chien | Bột chiên | Fried rice-flour cake | toi | ngoai | nhanh | 🍳 |
| goi_cuon | Gỏi cuốn | Fresh spring rolls | trua,toi | nha,ngoai | nhanh | 🌯 |
| nem_ran | Nem rán / chả giò | Fried spring rolls | trua,toi | nha | cau_ky | 🥟 |
| banh_trang_tron | Bánh tráng trộn | Rice-paper salad | toi | ngoai | nhanh | 🥗 |
| banh_trang_nuong | Bánh tráng nướng | Grilled rice paper | toi | ngoai | nhanh | 🍕 |
| goi_ga | Gỏi gà xé phay | Shredded chicken salad | toi | nha,ngoai | vua | 🥗 |
| oc | Ốc luộc, ốc xào | Snails (boiled / stir-fried) | toi | ngoai | nhanh | 🐚 |
| che | Chè tráng miệng | Vietnamese sweet soup | toi | ngoai | nhanh | 🍧 |
| banh_bao | Bánh bao | Steamed bun | sang | ngoai | nhanh | 🥟 |
| pha_lau | Phá lấu | Pha lau (braised offal) | toi | ngoai | nhanh | 🥘 |
| pho_cuon | Phở cuốn | Pho rolls | toi | ngoai | nhanh | 🌯 |

## E. Lẩu · nướng

| id | Tên (vi) | Name (en) | Bữa | Nơi | Công | Emoji |
|---|---|---|---|---|---|---|
| lau_thai | Lẩu Thái | Thai hotpot | toi | ngoai | vua | 🍲 |
| lau_bo | Lẩu bò | Beef hotpot | toi | ngoai | vua | 🍲 |
| lau_ga_la_e | Lẩu gà lá é | Chicken hotpot with la e basil | toi | ngoai | vua | 🍲 |
| lau_ca_keo | Lẩu cá kèo | Goby fish hotpot | toi | ngoai | vua | 🍲 |
| lau_mam | Lẩu mắm | Fermented fish hotpot | toi | ngoai | vua | 🍲 |
| lau_rieu_cua | Lẩu riêu cua bắp bò | Crab & beef hotpot | toi | ngoai | vua | 🍲 |
| lau_de | Lẩu dê | Goat hotpot | toi | ngoai | vua | 🍲 |
| bo_nuong_la_lot | Bò nướng lá lốt | Beef in betel leaves | toi | ngoai | vua | 🍢 |
| nuong_han | Thịt nướng Hàn Quốc | Korean BBQ | toi | ngoai | vua | 🥩 |
| nuong_nhat | Yakiniku | Yakiniku | toi | ngoai | vua | 🥩 |
| hai_san_nuong | Hải sản nướng | Grilled seafood | toi | ngoai | cau_ky | 🦞 |
| ga_nuong | Gà nướng | Grilled chicken | toi | ngoai | vua | 🍗 |
| vit_quay | Vịt quay | Roast duck | trua,toi | ngoai | nhanh | 🦆 |
| ca_nuong_muoi_ot | Cá nướng muối ớt | Chili-salt grilled fish | toi | ngoai | vua | 🐟 |
| nuong_bbq_nha | Nướng BBQ tại nhà | BBQ at home | toi | nha | cau_ky | 🔥 |

## F. Món Á · Tây

| id | Tên (vi) | Name (en) | Bữa | Nơi | Công | Emoji |
|---|---|---|---|---|---|---|
| sushi | Sushi | Sushi | trua,toi | ngoai | vua | 🍣 |
| ramen | Ramen | Ramen | trua,toi | ngoai | nhanh | 🍜 |
| pizza | Pizza | Pizza | trua,toi | nha,ngoai | nhanh | 🍕 |
| mi_y | Mì Ý sốt bò bằm | Spaghetti bolognese | trua,toi | nha,ngoai | vua | 🍝 |
| hamburger | Hamburger | Burger | trua,toi | ngoai | nhanh | 🍔 |
| ga_ran | Gà rán | Fried chicken | trua,toi | ngoai | nhanh | 🍗 |
| tokbokki | Tokbokki | Tteokbokki | toi | nha,ngoai | nhanh | 🌶️ |
| kimbap | Kimbap | Kimbap | trua,toi | nha,ngoai | nhanh | 🍙 |
| bibimbap | Cơm trộn Hàn Quốc | Bibimbap | trua,toi | ngoai | nhanh | 🍚 |
| ga_sot_cay | Gà sốt cay Hàn Quốc | Korean spicy chicken | toi | ngoai | nhanh | 🍗 |
| dimsum | Dimsum | Dim sum | sang,trua | ngoai | vua | 🥟 |
| pad_thai | Pad Thái | Pad Thai | trua,toi | ngoai | nhanh | 🍝 |
| bit_tet | Bò bít tết | Steak | toi | ngoai | vua | 🥩 |
| ca_ri_ga | Cà ri gà bánh mì | Chicken curry with bread | trua,toi | nha,ngoai | vua | 🍛 |
| mi_cay | Mì cay | Spicy noodle soup | toi | ngoai | nhanh | 🌶️ |
| sandwich | Sandwich | Sandwich | sang,trua | nha | nhanh | 🥪 |
| tacos | Tacos | Tacos | toi | ngoai | nhanh | 🌮 |
| sup_kem | Súp kem bí đỏ / nấm | Cream soup | toi | nha,ngoai | nhanh | 🥣 |

## G. Nhẹ · khoẻ

| id | Tên (vi) | Name (en) | Bữa | Nơi | Công | Emoji |
|---|---|---|---|---|---|---|
| salad_ga | Salad ức gà | Chicken salad | trua,toi | nha,ngoai | nhanh | 🥗 |
| uc_ga_ap_chao | Ức gà áp chảo + rau | Pan-seared chicken breast & greens | trua,toi | nha | nhanh | 🍗 |
| yen_mach | Yến mạch sữa chua trái cây | Overnight oats | sang | nha | nhanh | 🥣 |
| bun_gao_lut | Bún gạo lứt trộn | Brown-rice noodle salad | trua | nha | nhanh | 🥗 |
| canh_rong_bien | Canh rong biển + cơm | Seaweed soup with rice | trua,toi | nha | nhanh | 🍲 |
| khoai_lang_trung | Khoai lang luộc + trứng | Sweet potato & eggs | sang,toi | nha | nhanh | 🍠 |
| com_gao_lut_ca_hoi | Cơm gạo lứt cá hồi | Brown rice with salmon | trua,toi | nha | vua | 🐟 |
| smoothie_bowl | Smoothie bowl | Smoothie bowl | sang | nha | nhanh | 🥤 |
| chao_yen_mach | Cháo yến mạch thịt băm | Oat congee with minced pork | sang | nha | nhanh | 🥣 |

## Luật dùng trong `DecisionSuggester` (overview D4)
- Pool = bảng này + món nhập tay (`kind: eat`, `resultId == ''`) trong 90 ngày, trọng số ×2.
- Loại món có tên chuẩn hoá (bỏ dấu cách thừa, không phân biệt hoa thường) trùng món đã chốt trong 7 ngày.
- Chip lọc: Tuỳ = tất cả · Nhà nấu = `nha` · Ăn ngoài = `ngoai` · Nhanh gọn = `nhanh`.
- Giờ máy < 10:00 → thêm món `sang`; ≥ 14:00 → món `toi` trọng số ×2. Ngoài hai khung đó không cộng gì.
- Ngẫu nhiên thật mỗi lần quay (`Random()`), không lặp lại món vừa hiện trong cùng phiên quay cho tới khi hết pool.
