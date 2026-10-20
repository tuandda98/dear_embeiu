// Dữ liệu mẫu cho mockup "Thời tiết hai nơi" (feature weather).
// Cặp DEV Tuấn ♥ Thảo (test3/test4), ngày yêu 14/05/2023, hôm nay thứ Ba 20/10/2026, bây giờ 08:10.
// Mọi câu chữ trên thẻ được TÍNH từ giờ dự báo theo luật §6.2 + D10/D11/D16 của overview.md,
// không gõ tay, để mockup và test Dart của Dev cho cùng một kết quả.
(function () {
  const TODAY = '2026-10-20';
  const ANNIVERSARY = '2023-05-14';
  const NOW = { h: 8, m: 10 };
  const nowMin = NOW.h * 60 + NOW.m;

  const people = {
    me: { uid: 'u_tuan', name: 'Tuấn', label: 'Mình', labelEn: 'You', color: '#FF4D6D' }, // rose
    partner: { uid: 'u_thao', name: 'Thảo', color: '#7C5CD6' }, // purple (PersonPalette.resolve mặc định)
  };

  // ---- Danh sách thành phố (Phụ lục A). region '' = thành phố trực thuộc TW, chỉ hiện tên.
  // id|tên vi|tên en|vùng vi|vùng en|aliases (tỉnh cũ, tên khác) cách nhau bởi /
  const VN = `vn-ha-noi|Hà Nội|Hanoi|||
vn-tp-hcm|TP.HCM|Ho Chi Minh City|||Sài Gòn/Saigon/Hồ Chí Minh
vn-thu-dau-mot|Thủ Dầu Một|Thu Dau Mot|TP. Hồ Chí Minh|Ho Chi Minh City|Bình Dương
vn-vung-tau|Vũng Tàu|Vung Tau|TP. Hồ Chí Minh|Ho Chi Minh City|Bà Rịa–Vũng Tàu/Bà Rịa
vn-hai-phong|Hải Phòng|Hai Phong|||
vn-hai-duong|Hải Dương|Hai Duong|Hải Phòng|Hai Phong|Hải Dương
vn-da-nang|Đà Nẵng|Da Nang|||
vn-tam-ky|Tam Kỳ|Tam Ky|Đà Nẵng|Da Nang|Quảng Nam
vn-hoi-an|Hội An|Hoi An|Đà Nẵng|Da Nang|Quảng Nam
vn-hue|Huế|Hue|||Thừa Thiên Huế
vn-can-tho|Cần Thơ|Can Tho|||
vn-soc-trang|Sóc Trăng|Soc Trang|Cần Thơ|Can Tho|Sóc Trăng
vn-vi-thanh|Vị Thanh|Vi Thanh|Cần Thơ|Can Tho|Hậu Giang
vn-tuyen-quang|Tuyên Quang|Tuyen Quang|Tuyên Quang|Tuyen Quang|
vn-ha-giang|Hà Giang|Ha Giang|Tuyên Quang|Tuyen Quang|Hà Giang
vn-lao-cai|Lào Cai|Lao Cai|Lào Cai|Lao Cai|
vn-yen-bai|Yên Bái|Yen Bai|Lào Cai|Lao Cai|Yên Bái
vn-sa-pa|Sa Pa|Sa Pa|Lào Cai|Lao Cai|Sapa
vn-thai-nguyen|Thái Nguyên|Thai Nguyen|Thái Nguyên|Thai Nguyen|
vn-bac-kan|Bắc Kạn|Bac Kan|Thái Nguyên|Thai Nguyen|Bắc Kạn
vn-viet-tri|Việt Trì|Viet Tri|Phú Thọ|Phu Tho|
vn-vinh-yen|Vĩnh Yên|Vinh Yen|Phú Thọ|Phu Tho|Vĩnh Phúc
vn-hoa-binh|Hoà Bình|Hoa Binh|Phú Thọ|Phu Tho|Hoà Bình
vn-bac-ninh|Bắc Ninh|Bac Ninh|Bắc Ninh|Bac Ninh|
vn-bac-giang|Bắc Giang|Bac Giang|Bắc Ninh|Bac Ninh|Bắc Giang
vn-hung-yen|Hưng Yên|Hung Yen|Hưng Yên|Hung Yen|
vn-thai-binh|Thái Bình|Thai Binh|Hưng Yên|Hung Yen|Thái Bình
vn-ninh-binh|Ninh Bình|Ninh Binh|Ninh Bình|Ninh Binh|
vn-phu-ly|Phủ Lý|Phu Ly|Ninh Bình|Ninh Binh|Hà Nam
vn-nam-dinh|Nam Định|Nam Dinh|Ninh Bình|Ninh Binh|Nam Định
vn-dong-ha|Đông Hà|Dong Ha|Quảng Trị|Quang Tri|
vn-dong-hoi|Đồng Hới|Dong Hoi|Quảng Trị|Quang Tri|Quảng Bình
vn-quang-ngai|Quảng Ngãi|Quang Ngai|Quảng Ngãi|Quang Ngai|
vn-kon-tum|Kon Tum|Kon Tum|Quảng Ngãi|Quang Ngai|Kon Tum
vn-pleiku|Pleiku|Pleiku|Gia Lai|Gia Lai|
vn-quy-nhon|Quy Nhơn|Quy Nhon|Gia Lai|Gia Lai|Bình Định
vn-nha-trang|Nha Trang|Nha Trang|Khánh Hoà|Khanh Hoa|
vn-phan-rang|Phan Rang|Phan Rang|Khánh Hoà|Khanh Hoa|Ninh Thuận/Phan Rang–Tháp Chàm
vn-da-lat|Đà Lạt|Da Lat|Lâm Đồng|Lam Dong|
vn-gia-nghia|Gia Nghĩa|Gia Nghia|Lâm Đồng|Lam Dong|Đắk Nông
vn-phan-thiet|Phan Thiết|Phan Thiet|Lâm Đồng|Lam Dong|Bình Thuận/Mũi Né
vn-buon-ma-thuot|Buôn Ma Thuột|Buon Ma Thuot|Đắk Lắk|Dak Lak|
vn-tuy-hoa|Tuy Hoà|Tuy Hoa|Đắk Lắk|Dak Lak|Phú Yên
vn-bien-hoa|Biên Hoà|Bien Hoa|Đồng Nai|Dong Nai|
vn-dong-xoai|Đồng Xoài|Dong Xoai|Đồng Nai|Dong Nai|Bình Phước
vn-tay-ninh|Tây Ninh|Tay Ninh|Tây Ninh|Tay Ninh|
vn-tan-an|Tân An|Tan An|Tây Ninh|Tay Ninh|Long An
vn-vinh-long|Vĩnh Long|Vinh Long|Vĩnh Long|Vinh Long|
vn-ben-tre|Bến Tre|Ben Tre|Vĩnh Long|Vinh Long|Bến Tre
vn-tra-vinh|Trà Vinh|Tra Vinh|Vĩnh Long|Vinh Long|Trà Vinh
vn-cao-lanh|Cao Lãnh|Cao Lanh|Đồng Tháp|Dong Thap|
vn-my-tho|Mỹ Tho|My Tho|Đồng Tháp|Dong Thap|Tiền Giang
vn-ca-mau|Cà Mau|Ca Mau|Cà Mau|Ca Mau|
vn-bac-lieu|Bạc Liêu|Bac Lieu|Cà Mau|Ca Mau|Bạc Liêu
vn-long-xuyen|Long Xuyên|Long Xuyen|An Giang|An Giang|
vn-rach-gia|Rạch Giá|Rach Gia|An Giang|An Giang|Kiên Giang
vn-phu-quoc|Phú Quốc|Phu Quoc|An Giang|An Giang|Kiên Giang
vn-lai-chau|Lai Châu|Lai Chau|Lai Châu|Lai Chau|
vn-dien-bien-phu|Điện Biên Phủ|Dien Bien Phu|Điện Biên|Dien Bien|
vn-son-la|Sơn La|Son La|Sơn La|Son La|
vn-lang-son|Lạng Sơn|Lang Son|Lạng Sơn|Lang Son|
vn-cao-bang|Cao Bằng|Cao Bang|Cao Bằng|Cao Bang|
vn-ha-long|Hạ Long|Ha Long|Quảng Ninh|Quang Ninh|
vn-thanh-hoa|Thanh Hoá|Thanh Hoa|Thanh Hoá|Thanh Hoa|
vn-vinh|Vinh|Vinh|Nghệ An|Nghe An|
vn-ha-tinh|Hà Tĩnh|Ha Tinh|Hà Tĩnh|Ha Tinh|`;
  const INTL = `kr-seoul|Seoul|Seoul|Hàn Quốc|South Korea|
kr-busan|Busan|Busan|Hàn Quốc|South Korea|
kr-incheon|Incheon|Incheon|Hàn Quốc|South Korea|
kr-daegu|Daegu|Daegu|Hàn Quốc|South Korea|
jp-tokyo|Tokyo|Tokyo|Nhật Bản|Japan|
jp-osaka|Osaka|Osaka|Nhật Bản|Japan|
jp-nagoya|Nagoya|Nagoya|Nhật Bản|Japan|
jp-fukuoka|Fukuoka|Fukuoka|Nhật Bản|Japan|
jp-saitama|Saitama|Saitama|Nhật Bản|Japan|
tw-taipei|Đài Bắc|Taipei|Đài Loan|Taiwan|Taipei
tw-taichung|Đài Trung|Taichung|Đài Loan|Taiwan|Taichung
tw-kaohsiung|Cao Hùng|Kaohsiung|Đài Loan|Taiwan|Kaohsiung
tw-taoyuan|Đào Viên|Taoyuan|Đài Loan|Taiwan|Taoyuan
sg-singapore|Singapore|Singapore|Singapore|Singapore|
my-kuala-lumpur|Kuala Lumpur|Kuala Lumpur|Malaysia|Malaysia|KL
th-bangkok|Bangkok|Bangkok|Thái Lan|Thailand|
kh-phnom-penh|Phnom Penh|Phnom Penh|Campuchia|Cambodia|Phnôm Pênh
la-vientiane|Viêng Chăn|Vientiane|Lào|Laos|Vientiane
cn-beijing|Bắc Kinh|Beijing|Trung Quốc|China|Beijing
cn-shanghai|Thượng Hải|Shanghai|Trung Quốc|China|Shanghai
cn-guangzhou|Quảng Châu|Guangzhou|Trung Quốc|China|Guangzhou
hk-hong-kong|Hồng Kông|Hong Kong|Trung Quốc|China|Hong Kong
au-sydney|Sydney|Sydney|Úc|Australia|
au-melbourne|Melbourne|Melbourne|Úc|Australia|
au-brisbane|Brisbane|Brisbane|Úc|Australia|
au-adelaide|Adelaide|Adelaide|Úc|Australia|
au-perth|Perth|Perth|Úc|Australia|
nz-auckland|Auckland|Auckland|New Zealand|New Zealand|
gb-london|London|London|Anh|United Kingdom|Luân Đôn
gb-manchester|Manchester|Manchester|Anh|United Kingdom|
fr-paris|Paris|Paris|Pháp|France|
de-berlin|Berlin|Berlin|Đức|Germany|
de-frankfurt|Frankfurt|Frankfurt|Đức|Germany|
de-munich|München|Munich|Đức|Germany|Munich
cz-prague|Praha|Prague|Séc|Czechia|Prague
pl-warsaw|Warszawa|Warsaw|Ba Lan|Poland|Warsaw/Vác-sa-va
ru-moscow|Moskva|Moscow|Nga|Russia|Moscow/Mát-xcơ-va
nl-amsterdam|Amsterdam|Amsterdam|Hà Lan|Netherlands|
fi-helsinki|Helsinki|Helsinki|Phần Lan|Finland|
ca-toronto|Toronto|Toronto|Canada|Canada|
ca-vancouver|Vancouver|Vancouver|Canada|Canada|
ca-montreal|Montréal|Montreal|Canada|Canada|Montreal
us-los-angeles|Los Angeles|Los Angeles|Mỹ|United States|LA
us-san-jose|San Jose|San Jose|Mỹ|United States|
us-houston|Houston|Houston|Mỹ|United States|
us-seattle|Seattle|Seattle|Mỹ|United States|
us-new-york|New York|New York|Mỹ|United States|NYC
us-boston|Boston|Boston|Mỹ|United States|
us-chicago|Chicago|Chicago|Mỹ|United States|
ae-dubai|Dubai|Dubai|UAE|UAE|`;
  const parse = (block, group) => block.trim().split('\n').map((line) => {
    const [id, nameVi, nameEn, regionVi, regionEn, aliases] = line.split('|');
    return { id, nameVi, nameEn, regionVi, regionEn, aliases: aliases ? aliases.split('/') : [], group };
  });
  const cities = [...parse(VN, 'vn'), ...parse(INTL, 'intl')];
  const city = (id) => cities.find((c) => c.id === id);

  // Bỏ dấu + đ→d + thường hoá: "Bình Thuận" → "binh thuan". Dev dùng y hệt cho ô tìm kiếm.
  const fold = (s) => s.normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'd').toLowerCase().replace(/[^a-z0-9 ]+/g, ' ').replace(/\s+/g, ' ').trim();
  // Trả { city, via }: via = alias khớp (tên tỉnh cũ) để dòng kết quả nói vì sao nó ra.
  function search(q) {
    const k = fold(q);
    if (!k) return cities.map((c) => ({ city: c, via: null }));
    const out = [];
    for (const c of cities) {
      if ([c.nameVi, c.nameEn, c.regionVi, c.regionEn].some((n) => n && fold(n).includes(k))) { out.push({ city: c, via: null }); continue; }
      const a = c.aliases.find((x) => fold(x).includes(k));
      if (a) out.push({ city: c, via: a });
    }
    return out;
  }

  // ---- Dự báo theo giờ (giờ thành phố). 08:00 hôm nay → 09:00 sáng mai (26 mốc).
  // sym = symbol_code MET đã bỏ hậu tố _day/_night; rain = mm/giờ.
  const HOURS = [...Array(16).keys()].map((i) => 8 + i).concat([...Array(10).keys()].map((i) => 24 + i));
  const series = (temps, syms, rains) => HOURS.map((h, i) => ({ h, temp: temps[i], sym: syms[i], rain: rains[i] }));
  const rep = (v, n) => Array(n).fill(v);
  const forecasts = {
    // TP.HCM: nắng sáng, mưa rào 14–17h.
    'vn-tp-hcm': series(
      [29, 30, 31, 32, 33, 33, 32, 29, 28, 28, 27, 27, 26, 26, 26, 25, 25, 25, 25, 25, 25, 25, 25, 26, 27, 28],
      [...rep('partlycloudy', 6), 'rainshowers', 'rain', 'heavyrainshowers', 'lightrain', ...rep('cloudy', 6), ...rep('cloudy', 10)],
      [...rep(0, 6), 1.4, 3.2, 5.1, 0.6, ...rep(0, 16)]),
    // Hà Nội: nhiều mây, khô.
    'vn-ha-noi': series(
      [23, 24, 25, 26, 27, 27, 27, 26, 25, 24, 23, 23, 22, 22, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 22, 23],
      rep('cloudy', 26), rep(0, 26)),
    // Hà Nội, phương án "cùng thành phố": tối nay mưa nhỏ.
    'vn-ha-noi@tonight-rain': series(
      [23, 24, 25, 26, 27, 27, 27, 26, 25, 24, 23, 23, 22, 22, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 22, 23],
      [...rep('cloudy', 11), 'lightrain', 'rain', 'lightrain', ...rep('cloudy', 12)],
      [...rep(0, 11), 0.6, 1.1, 0.5, ...rep(0, 12)]),
    // Đà Lạt: mát, không mưa: dùng cho câu chênh lệch.
    'vn-da-lat': series(
      [17, 18, 19, 20, 21, 21, 20, 19, 18, 17, 17, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 17, 18],
      rep('partlycloudy', 26), rep(0, 26)),
    // Hải Phòng: gần giống Hà Nội (lệch 1°): trạng thái không có hàng chung.
    'vn-hai-phong': series(
      [22, 23, 24, 25, 26, 26, 26, 25, 24, 23, 22, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22],
      rep('partlycloudy', 26), rep(0, 26)),
    // Buôn Ma Thuột (tên dài nhất danh sách) với mã MET lạ → ẩn mô tả, chỉ hiện nhiệt độ.
    'vn-buon-ma-thuot': series(
      [24, 25, 26, 27, 28, 28, 27, 26, 25, 24, 23, 23, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 23],
      rep('xyzunknown', 26), rep(0, 26)),
    // Biên Hoà: nắng gắt 36°.
    'vn-bien-hoa': series(
      [29, 31, 33, 34, 35, 36, 36, 35, 33, 31, 30, 29, 28, 28, 27, 27, 27, 27, 27, 26, 26, 26, 26, 27, 28, 29],
      rep('clearsky', 26), rep(0, 26)),
    // Sa Pa: lạnh, xuống 13°.
    'vn-sa-pa': series(
      [15, 16, 17, 18, 18, 18, 17, 16, 15, 14, 14, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 14, 15],
      rep('fog', 26), rep(0, 26)),
  };

  // ---- Luật §6.2 + D10 (đúng thứ tự ưu tiên: đang mưa > sắp mưa > nắng gắt > lạnh > mô tả trời).
  const RAIN = /rain|sleet|thunder/; // nhóm mưa / mưa rào / dông (tuyết tách riêng)
  const isRain = (x) => x.rain >= 0.5 || RAIN.test(x.sym);
  const SKY = {
    clearsky: ['Trời quang', 'Clear', 0xec15], fair: ['Trời quang', 'Clear', 0xec15],
    partlycloudy: ['Ít mây', 'Partly cloudy', 0xe9d7], cloudy: ['Nhiều mây', 'Cloudy', 0xe9ca],
    fog: ['Có sương mù', 'Foggy', 0xe9d0], lightrain: ['Mưa nhỏ', 'Light rain', 0xe9cf],
    rain: ['Có mưa', 'Rain', 0xe9cf], heavyrain: ['Mưa to', 'Heavy rain', 0xe9cf],
  };
  function skyOf(sym) {
    if (/thunder/.test(sym)) return ['Có dông', 'Thunderstorms', 0xe9d1];
    if (/snow|sleet/.test(sym)) return ['Có tuyết', 'Snow', 0xe9d6];
    const base = sym.replace(/showers$/, '');
    return SKY[base] || [null, null, 0xe9ca]; // mã lạ: ẩn mô tả, chỉ hiện nhiệt độ
  }
  function condition(hours, hNow) {
    let win = hours.filter((x) => x.h >= hNow && x.h <= 23);
    if (23 - hNow + 1 < 3) win = hours.filter((x) => x.h >= hNow && x.h <= 24 + 9); // nới tới 09:00 sáng mai
    const cur = win[0];
    const max = Math.max(...win.map((x) => x.temp));
    const min = Math.min(...win.map((x) => x.temp));
    if (isRain(cur)) return { kind: 'rain', vi: 'Đang mưa', en: 'Raining now', max, min };
    const r = win.find(isRain);
    if (r) {
      const at = r.h >= 24 ? ['Sáng mai mưa', 'Rain tomorrow morning'] : r.h < 12 ? ['Sáng nay mưa', 'Rain this morning'] : r.h < 18 ? ['Chiều nay mưa', 'Rain this afternoon'] : ['Tối nay mưa', 'Rain tonight'];
      return { kind: 'rain', vi: at[0], en: at[1], max, min, rainAt: r.h };
    }
    if (max >= 35) return { kind: 'hot', vi: `Nắng gắt, lên ${max}°`, en: `Hot, up to ${max}°`, max, min };
    if (min <= 15 || win.some((x) => /snow/.test(x.sym))) return { kind: 'cold', vi: `Lạnh, xuống ${min}°`, en: `Cold, down to ${min}°`, max, min };
    const s = skyOf(cur.sym);
    return { kind: 'sky', vi: s[0], en: s[1], max, min };
  }

  // ---- Một nơi trên thẻ (đã tính sẵn mọi thứ thẻ cần).
  function place(cityId, fcKey) {
    const c = city(cityId);
    const hours = forecasts[fcKey || cityId];
    const cur = hours.find((x) => x.h === NOW.h);
    const day = hours.filter((x) => x.h <= 23);
    return {
      city: c, temp: cur.temp, icon: skyOf(cur.sym)[2],
      cond: condition(hours, NOW.h),
      low: Math.min(...day.map((x) => x.temp)), high: Math.max(...day.map((x) => x.temp)),
      slots: [9, 12, 15, 18, 21].map((h) => { const x = hours.find((y) => y.h === h); return { h, temp: x.temp, icon: skyOf(x.sym)[2], rain: isRain(x) }; }),
    };
  }
  const CTA = {
    rain: { vi: 'Nhắc mang ô', en: 'Remind: umbrella', icon: 0xe9cf },
    hot: { vi: 'Nhắc uống nước', en: 'Remind: water', icon: 0xea28 },
    cold: { vi: 'Nhắc mặc ấm', en: 'Remind: dress warm', icon: 0xec7d },
  };
  // D11: chênh ≥ 5° mới nói; câu luôn nói về chỗ người ấy.
  function gap(me, partner, name) {
    const d = partner.temp - me.temp;
    if (Math.abs(d) < 5) return null;
    return d < 0 ? { n: -d, vi: `Chỗ ${name} lạnh hơn ${-d}°`, en: `${-d}° colder where ${name} is` }
      : { n: d, vi: `Chỗ ${name} nóng hơn ${d}°`, en: `${d}° warmer where ${name} is` };
  }
  // §6.6: lời quan tâm điền sẵn.
  function prefill(kind, p) {
    const n = p.city.nameVi;
    return {
      rain: { title: 'Nhớ mang ô nhé', body: `${n} sắp mưa đó. Ra ngoài nhớ mang ô theo nha.`, titleEn: 'Take an umbrella', bodyEn: `Looks like rain in ${p.city.nameEn}. Grab an umbrella if you head out.` },
      hot: { title: 'Uống nước nhiều nha', body: `${n} hôm nay lên tới ${p.cond.max}°. Ra đường nhớ che nắng, uống đủ nước nhé.`, titleEn: 'Stay hydrated', bodyEn: `${p.city.nameEn} is hitting ${p.cond.max}° today. Cover up in the sun and keep drinking water.` },
      cold: { title: 'Mặc ấm vào nhé', body: `${n} xuống còn ${p.cond.min}° đó. Ra ngoài nhớ mặc thêm áo.`, titleEn: 'Dress warm', bodyEn: `${p.city.nameEn} is dropping to ${p.cond.min}°. Bring an extra layer when you go out.` },
    }[kind];
  }
  // §6.7: thông báo sáng.
  function morning(kind, p, name) {
    const n = p.city.nameVi, e = p.city.nameEn;
    return {
      rain: { title: `Hôm nay ${n} có mưa`, body: `Nhắc ${name} mang ô nhé?`, titleEn: `Rain in ${e} today`, bodyEn: `Remind ${name} to take an umbrella?` },
      hot: { title: `Hôm nay ${n} lên ${p.cond.max}°`, body: `Nhắc ${name} uống đủ nước nhé?`, titleEn: `${e} hits ${p.cond.max}° today`, bodyEn: `Remind ${name} to drink enough water?` },
      cold: { title: `${n} xuống ${p.cond.min}° hôm nay`, body: `Nhắc ${name} mặc ấm nhé?`, titleEn: `${e} drops to ${p.cond.min}° today`, bodyEn: `Remind ${name} to dress warm?` },
    }[kind];
  }
  // D16: độ tươi của số liệu.
  const AGE = (fetchedMinAgo) => (fetchedMinAgo <= 360 ? 'fresh' : fetchedMinAgo <= 1440 ? 'stale' : 'none');
  const hhmm = (min) => { const m = ((min % 1440) + 1440) % 1440; return `${String(Math.floor(m / 60)).padStart(2, '0')}:${String(m % 60).padStart(2, '0')}`; };

  const P = people.partner.name;
  const hcm = place('vn-tp-hcm'), hn = place('vn-ha-noi'), dl = place('vn-da-lat');
  const bh = place('vn-bien-hoa'), sp = place('vn-sa-pa'), hnRain = place('vn-ha-noi', 'vn-ha-noi@tonight-rain');
  const hp = place('vn-hai-phong'), bmt = place('vn-buon-ma-thuot');

  const fetched = { fresh: nowMin - 58, stale: nowMin - 630, none: nowMin - 1520 }; // 07:12 · 21:40 hôm qua · 06:50 hôm kia

  window.WX = {
    TODAY, ANNIVERSARY, NOW, nowMin, people, cities, city, fold, search, forecasts, condition, place,
    CTA, gap, prefill, morning, AGE, hhmm, fetched,
    places: { hcm, hn, dl, bh, sp, hnRain, hp, bmt },
    daysTogether: Math.round((Date.parse(TODAY) - Date.parse(ANNIVERSARY)) / 864e5),
  };

  // ---- Các con số phải khớp nhau (đọc console khi mở mockup).
  console.assert(window.WX.daysTogether === 1255, 'Ngày bên nhau 14/05/2023 → 20/10/2026 = 1255');
  console.assert(hcm.cond.kind === 'rain' && hcm.cond.vi === 'Chiều nay mưa' && hcm.cond.rainAt === 14, 'TP.HCM: chiều nay mưa (14:00)');
  console.assert(hn.cond.kind === 'sky' && hn.cond.vi === 'Nhiều mây', 'Hà Nội: nhiều mây');
  console.assert(hcm.temp === 29 && hn.temp === 23, 'Nhiệt độ lúc 08:00: 29° / 23°');
  console.assert(gap(hn, hcm, P).vi === 'Chỗ Thảo nóng hơn 6°', 'Chênh 6° (bị nút gợi ý che vì nút ưu tiên hơn)');
  console.assert(dl.cond.kind === 'sky' && dl.cond.min === 16, 'Đà Lạt 16° chưa tới ngưỡng lạnh 15° → không có nút');
  const hnWarm = { ...hn, temp: 25 };
  console.assert(gap(hnWarm, dl, P).vi === 'Chỗ Thảo lạnh hơn 8°', 'Ví dụ trong brief: chỗ Thảo lạnh hơn 8°');
  console.assert(gap(hn, dl, P).vi === 'Chỗ Thảo lạnh hơn 6°', 'Hà Nội 23° với Đà Lạt 17° = lạnh hơn 6°');
  console.assert(bh.cond.kind === 'hot' && bh.cond.max === 36, 'Biên Hoà: nắng gắt 36°');
  console.assert(sp.cond.kind === 'cold' && sp.cond.min === 13, 'Sa Pa: lạnh 13°');
  console.assert(hnRain.cond.vi === 'Tối nay mưa', 'Hà Nội cùng thành phố: tối nay mưa');
  const lateRain = forecasts['vn-ha-noi'].map((x) => (x.h === 31 ? { ...x, sym: 'lightrain', rain: 0.8 } : x)); // 07:00 sáng mai
  console.assert(condition(lateRain, 22).vi === 'Sáng mai mưa', 'Sau 21:00 cửa sổ nới tới 09:00 sáng mai');
  console.assert(condition(lateRain, 20).vi === 'Nhiều mây', 'Trước 21:00 chưa nới cửa sổ');
  console.assert(AGE(58) === 'fresh' && AGE(630) === 'stale' && AGE(1520) === 'none', 'D16: ≤6 giờ / 6–24 giờ / >24 giờ');
  console.assert(hhmm(fetched.fresh) === '07:12' && hhmm(fetched.stale) === '21:40', 'Giờ cập nhật 07:12, số cũ 21:40');
  // Lời điền sẵn lọt giới hạn care-message với tên thành phố dài nhất (D: tiêu đề ≤ 60, nội dung ≤ 200).
  const longest = cities.reduce((a, c) => (c.nameVi.length > a.nameVi.length ? c : a));
  const longP = { ...hcm, city: longest, cond: { max: 40, min: -10 } };
  for (const k of ['rain', 'hot', 'cold']) {
    const f = prefill(k, longP);
    console.assert(f.title.length <= 60 && f.body.length <= 200 && f.bodyEn.length <= 200, `Điền sẵn ${k} vượt giới hạn`);
  }
  console.assert(search('binh thuan').some((r) => r.city.id === 'vn-phan-thiet' && r.via === 'Bình Thuận'), '"binh thuan" ra Phan Thiết · Lâm Đồng');
  console.assert(search('seoul')[0].city.id === 'kr-seoul', '"seoul" ra Seoul');
  console.assert(search('xyz').length === 0, '"xyz" không ra gì');
  console.assert(search('sai gon').some((r) => r.city.id === 'vn-tp-hcm'), '"sai gon" ra TP.HCM');
  console.assert(gap(hn, hp, P) === null && hp.cond.kind === 'sky', 'Hải Phòng 22° với Hà Nội 23°: lệch 1°, không có hàng chung');
  console.assert(bmt.cond.vi === null && bmt.cond.kind === 'sky', 'Mã MET lạ → ẩn mô tả');
  console.assert(new Set(cities.map((c) => c.id)).size === cities.length, 'id thành phố không trùng');
})();
