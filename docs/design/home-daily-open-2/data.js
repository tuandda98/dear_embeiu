// Dữ liệu mẫu cho bản ghép Home đợt 2 (Designer, 2026-10-20).
// Cặp DEV Tuấn ♥ Thảo (test3/test4), ngày yêu 14/05/2023. Người xem = Tuấn.
// Mọi con số trên Home được TÍNH từ dòng thời gian chép nguyên từ data.js của từng feature:
//   poke/data.js (lần chạm tim) · arrival/data.js (đến/rời nơi) · weather/data.js (dự báo theo giờ + luật §6.2)
//   caro-game/data.js (ván 14 nước, tỉ số) · expenses/data.js (sổ chung tháng 10) · sleep (đêm 19→20/10 như mock arrival).
// Đổi "bây giờ" là mọi khối đổi theo. Ba mốc dùng trong mock: 20/10 19:05 · 21/10 00:05 · 20/10 19:05 mất mạng.
(function () {
  const ANNIVERSARY = '2023-05-14';
  const ME = { uid: 'u_tuan', name: 'Tuấn', color: '#FF4D6D' };   // PersonPalette rose
  const PARTNER = { uid: 'u_thao', name: 'Thảo', color: '#0E9384' }; // PersonPalette teal (mock arrival + caro)
  // Màu không nằm trong 6 cặp khoá của PersonPalette.
  const BLOCKED = [['#FF4D6D', '#E8590C'], ['#FF4D6D', '#C2255C'], ['#7C5CD6', '#1C7ED6'], ['#0E9384', '#2F9E44'], ['#E8590C', '#B7791F'], ['#2F9E44', '#B7791F']];

  const day = (iso) => Date.UTC(+iso.slice(0, 4), +iso.slice(5, 7) - 1, +iso.slice(8, 10));
  const mins = (hm) => { const [h, m] = hm.split(':').map(Number); return h * 60 + m; };
  const fmtInt = (n) => new Intl.NumberFormat('vi-VN').format(n);
  const pad = (n) => String(n).padStart(2, '0'); // taste-skill-ignore: phút/giây của đồng hồ thẻ đếm

  // ---- Đồng hồ thẻ đếm (CounterCard): tổng giờ bên nhau, positional phút/giây.
  const milestones = [30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000];

  // ---- Poke: các lần chạm hôm 20/10 (poke/data.js, nguyên văn).
  const taps = [
    ['08:05', 'p'], ['08:06', 'p'], ['08:12', 'm'], ['11:30', 'p'], ['12:01', 'm'], ['12:01', 'm'],
    ['12:02', 'm'], ['13:45', 'm'], ['13:46', 'm'], ['14:28', 'p'], ['14:30', 'p'], ['14:31', 'm'],
  ];

  // ---- Arrival: nhật ký từng máy (arrival/data.js). Thêm 1 dòng cho Tuấn: bấm "Về nhà rồi" 19:20
  // (sau thời điểm mock chính 19:05, nên chỉ thấy ở trạng thái 00:05 hôm sau).
  const arrivals = {
    p: [
      { place: 'home', type: 'exit', at: '2026-10-20T07:20', battery: 96, source: 'auto' },
      { place: 'work', type: 'enter', at: '2026-10-20T07:58', battery: 91, source: 'auto' },
      { place: 'work', type: 'exit', at: '2026-10-20T17:32', battery: 19, source: 'auto' },
      { place: 'home', type: 'enter', at: '2026-10-20T18:42', battery: 12, source: 'auto' },
    ],
    m: [
      { place: 'home', type: 'exit', at: '2026-10-20T07:35', battery: 88, source: 'auto' },
      { place: 'work', type: 'enter', at: '2026-10-20T08:05', battery: 64, source: 'auto' },
      { place: 'home', type: 'enter', at: '2026-10-20T19:20', battery: 41, source: 'manual' },
    ],
  };
  const PLACE = {
    home: { enter: 'Đã về đến nhà', exit: 'Đã rời nhà', manual: 'Về nhà rồi' },
    work: { enter: 'Đã đến chỗ làm', exit: 'Đã rời chỗ làm', manual: 'Đến chỗ làm rồi' },
  };
  const LOW_BATTERY = 20;

  // ---- Weather: dự báo theo giờ 20/10 08:00 → 21/10 09:00 (weather/data.js, nguyên văn).
  const HOURS = [...Array(16).keys()].map((i) => 8 + i).concat([...Array(10).keys()].map((i) => 24 + i));
  const rep = (v, n) => Array(n).fill(v);
  const series = (temps, syms, rains) => HOURS.map((h, i) => ({ h, temp: temps[i], sym: syms[i], rain: rains[i] }));
  const forecasts = {
    hcm: { name: 'TP.HCM', hours: series(
      [29, 30, 31, 32, 33, 33, 32, 29, 28, 28, 27, 27, 26, 26, 26, 25, 25, 25, 25, 25, 25, 25, 25, 26, 27, 28],
      [...rep('partlycloudy', 6), 'rainshowers', 'rain', 'heavyrainshowers', 'lightrain', ...rep('cloudy', 6), ...rep('cloudy', 10)],
      [...rep(0, 6), 1.4, 3.2, 5.1, 0.6, ...rep(0, 16)]) },
    hn: { name: 'Hà Nội', hours: series(
      [23, 24, 25, 26, 27, 27, 27, 26, 25, 24, 23, 23, 22, 22, 22, 22, 22, 21, 21, 21, 21, 21, 21, 21, 22, 23],
      rep('cloudy', 26), rep(0, 26)) },
  };
  const isRain = (x) => x.rain >= 0.5 || /rain|sleet|thunder/.test(x.sym);
  const SKY = { partlycloudy: ['Ít mây', 0xe9d7], cloudy: ['Nhiều mây', 0xe9ca], lightrain: ['Mưa nhỏ', 0xe9cf], rain: ['Có mưa', 0xe9cf] };
  const skyOf = (sym) => SKY[sym.replace(/showers$/, '').replace(/^heavy/, '')] || ['Nhiều mây', 0xe9ca];
  // Luật §6.2 + D10 của weather (đang mưa > sắp mưa > nắng gắt > lạnh > trời). h = giờ trong chuỗi HOURS.
  function condition(hours, hNow) {
    let win = hours.filter((x) => x.h >= hNow && x.h <= Math.max(23, hNow + 23 - (hNow % 24)));
    if (hNow <= 23 && 23 - hNow + 1 < 3) win = hours.filter((x) => x.h >= hNow && x.h <= 33);
    const cur = win[0];
    const max = Math.max(...win.map((x) => x.temp)), min = Math.min(...win.map((x) => x.temp));
    if (isRain(cur)) return { kind: 'rain', text: 'Đang mưa' };
    const r = win.find(isRain);
    if (r) return { kind: 'rain', text: r.h >= 24 ? 'Sáng mai mưa' : r.h < 12 ? 'Sáng nay mưa' : r.h < 18 ? 'Chiều nay mưa' : 'Tối nay mưa' };
    if (max >= 35) return { kind: 'hot', text: `Nắng gắt, lên ${max}°` };
    if (min <= 15) return { kind: 'cold', text: `Lạnh, xuống ${min}°` };
    return { kind: 'sky', text: skyOf(cur.sym)[0] };
  }
  const CARE = { rain: 'Nhắc mang ô', hot: 'Nhắc uống nước', cold: 'Nhắc mặc ấm' };

  // ---- Sleep: đêm 19→20/10 (mock arrival "Đêm qua"): Bạn 00:15–07:05, Thảo 23:40–07:00.
  const nights = { m: { bed: '00:15', wake: '07:05' }, p: { bed: '23:40', wake: '07:00' } };
  const durMin = (n) => (mins(n.wake) - mins(n.bed) + 1440) % 1440;
  const fmtDur = (m) => `${Math.floor(m / 60)}g ${pad(m % 60)}p`.replace(' 0', ' ');

  // ---- Mood (hôm 20/10). Ngày mới thì cả hai trống.
  const MOODS = {
    happy: ['😄', 'Vui'], missing: ['🥹', 'Nhớ'], tired: ['😪', 'Mệt'], calm: ['😌', 'Bình yên'], // taste-skill-ignore: glyph tâm trạng là dữ liệu của app (MoodGlyph = Noto emoji động)
  };
  const moods20 = { m: { key: 'happy', at: '08:20' }, p: { key: 'missing', at: '12:10', note: 'mai gặp nha' } };

  // ---- Daily question.
  const QUESTIONS = { '2026-10-20': 'Mùi hương nào khiến bạn nghĩ đến người ấy?', '2026-10-21': 'Nếu viết một cuốn sách về chúng mình, tựa đề sẽ là gì?' };
  const answers20 = { p: '12:31', m: '21:30' }; // Thảo trả lời 12:31; Tuấn 21:30 (sau mock 19:05) ⇒ 20/10 đủ hai người, chuỗi lên 93.

  // ---- Caro (caro-game/data.js): ván hôm nay 14 nước, nước 14 của Thảo lúc 10:12, tới lượt Tuấn. Tỉ số 12 – 9.
  const caro = { moves: 14, lastBy: 'p', lastAt: '10:12', score: { m: 12, p: 9 }, rpsWeek: { w: 3, d: 1, l: 2 } };

  // ---- Sổ chung tháng 10 (expenses/data.js): chi 3.574.000 ₫ trên ngân sách 5.000.000 ₫.
  const money = { spent: 3574000, budget: 5000000, todayEntriesOwn: 3, cachedAt: '18:58' };

  // ---- Phân vân gì không? (decision-wheel): hôm nay Thảo quay "Bún chả" lúc 11:42.
  const decisions20 = { eat: { result: 'Bún chả', by: 'p', at: '11:42' } };

  // ---- Kỷ niệm gần đây (ảnh mẫu brand-v2, thay bằng ảnh cặp DEV khi Dev dựng).
  const photos = [{ src: 'img/p6.jpg', caption: 'Hoàng hôn ở Hồ Tây', by: 'Thảo', ago: '3 ngày trước' }, { src: 'img/p2.jpg', caption: 'Chiều vàng dưới hàng cây', by: 'Thảo', ago: '3 tháng trước' }];

  // ======== Một "bây giờ" → mọi khối Home ========
  function at(nowIso, opts = {}) {
    const date = nowIso.slice(0, 10), hm = nowIso.slice(11, 16);
    const isNewDay = date !== '2026-10-20';
    const daysTogether = Math.round((day(date) - day(ANNIVERSARY)) / 864e5);
    const [hh, mm] = hm.split(':').map(Number);
    const ss = opts.sec ?? 42;
    const clock = { h: fmtInt(daysTogether * 24 + hh), m: pad(mm), s: pad(ss) };
    const next = milestones.find((m) => daysTogether < m) ?? (Math.floor(daysTogether / 500) + 1) * 500;

    const tapsNow = isNewDay ? [] : taps.filter(([t]) => t <= hm);
    const poke = { m: tapsNow.filter((t) => t[1] === 'm').length, p: tapsNow.filter((t) => t[1] === 'p').length, queued: opts.pokeQueued || 0 };
    poke.m += poke.queued;

    const lastEvent = (who) => [...arrivals[who]].filter((e) => e.at <= nowIso).pop() || null;
    const arrival = { m: lastEvent('m'), p: lastEvent('p') };
    // Mất mạng mà bấm "Về nhà rồi": thẻ đổi ngay (lạc quan), tin nằm hàng đợi tới khi có sóng (arrival S2).
    if (opts.homeQueued) arrival.m = { place: 'home', type: 'enter', at: nowIso, battery: 41, source: 'manual', pending: true };
    // Nút "Hỏi thăm" chỉ khi người ấy vừa ĐẾN nơi trong 2 giờ (cùng ngày).
    const sinceArrive = arrival.p && arrival.p.type === 'enter' && arrival.p.at.slice(0, 10) === date ? mins(hm) - mins(arrival.p.at.slice(11, 16)) : null;

    const hIndex = (isNewDay ? 24 : 0) + hh;
    const place = (k) => { const f = forecasts[k]; const cur = f.hours.find((x) => x.h === hIndex); return { city: f.name, temp: cur.temp, icon: skyOf(cur.sym)[1], cond: condition(f.hours, hIndex) }; };
    const cachedAt = opts.offline ? '18:58' : hm; // một biến cho mọi "số lúc …" khi mất mạng
    const weather = { m: place('hn'), p: place('hcm'), fetchedAt: cachedAt };

    // Hành động phía người ấy ở chân bảng: mới đến nơi (≤120 phút) > thời tiết đáng nhắc > không có.
    let care = null;
    if (sinceArrive != null && sinceArrive <= 120) care = { kind: 'arrival', label: 'Hỏi thăm', icon: 0xeafe };
    else if (CARE[weather.p.cond.kind] && hh < 21) care = { kind: weather.p.cond.kind, label: CARE[weather.p.cond.kind], icon: 0xe9cf };

    const moodsNow = isNewDay ? {} : Object.fromEntries(Object.entries(moods20).filter(([, v]) => v.at <= hm));
    const answered = isNewDay ? {} : Object.fromEntries(Object.entries(answers20).filter(([, t]) => t <= hm));
    const stars = { question: { m: !!answered.m, p: !!answered.p }, mood: { m: !!moodsNow.m, p: !!moodsNow.p }, chat: isNewDay ? { m: false, p: false } : { m: true, p: true } };
    const lit = Object.values(stars).reduce((a, s) => a + (s.m ? 1 : 0) + (s.p ? 1 : 0), 0);

    return {
      nowIso, date, hm, isNewDay, daysTogether, clock, next, left: next - daysTogether, progress: daysTogether / next,
      greeting: hh < 4 ? 'Khuya rồi đó, Tuấn' : hh < 12 ? 'Chào buổi sáng, Tuấn' : hh < 18 ? 'Chào buổi chiều, Tuấn' : 'Chào buổi tối, Tuấn',
      greetIcon: hh < 4 || hh >= 18 ? 0xeb2c : 0xec15,
      poke, arrival, sinceArrive, weather, care,
      sleep: { m: { ...nights.m, min: durMin(nights.m) }, p: { ...nights.p, min: durMin(nights.p) } },
      moods: moodsNow, answered, question: QUESTIONS[date], stars, lit,
      streak: { n: isNewDay ? 93 : 92, doneToday: !!(answered.m && answered.p) },
      caro, money: { ...money, cachedAt }, decisions: isNewDay ? {} : decisions20, photos, unread: isNewDay ? 0 : 2,
      offline: !!opts.offline,
    };
  }

  const S = at('2026-10-20T19:05');
  const N = at('2026-10-21T00:05', { sec: 18 });
  const O = at('2026-10-20T19:05', { offline: true, pokeQueued: 2, homeQueued: true });

  // ======== Kiểm chéo (đọc console) ========
  console.assert(S.daysTogether === 1255 && N.daysTogether === 1256, 'ngày bên nhau 1.255 (20/10) · 1.256 (21/10)');
  console.assert(S.next === 1500 && S.left === 245, 'cột mốc 1.500, còn 245 ngày (khớp poke)');
  console.assert(S.clock.h === '30.139', 'tổng giờ 1.255×24 + 19 = 30.139');
  console.assert(S.poke.m === 7 && S.poke.p === 5 && S.poke.m + S.poke.p === 12, 'poke 19:05: mình 7, Thảo 5 = 12 (khớp poke mock 14:32, sau 14:31 không ai chạm)');
  console.assert(N.poke.m === 0 && N.poke.p === 0, 'qua 0:00 số chạm về 0');
  console.assert(O.poke.m === 9 && O.poke.queued === 2, 'mất mạng: 2 lần chạm xếp hàng, số mình hiện ngay 9');
  console.assert(S.arrival.p.at.endsWith('18:42') && S.arrival.p.battery === 12 && S.arrival.p.battery <= LOW_BATTERY, 'Thảo về nhà 18:42, pin 12% (≤20 ⇒ pill vàng)');
  console.assert(S.arrival.m.at.endsWith('08:05') && S.arrival.m.place === 'work', 'Tuấn 19:05 vẫn là "đến chỗ làm 08:05"');
  console.assert(S.sinceArrive === 23 && S.care.kind === 'arrival', 'Thảo đến nhà 23 phút trước ⇒ chân bảng là "Hỏi thăm"');
  console.assert(N.arrival.m.source === 'manual' && N.arrival.m.at.endsWith('19:20'), '00:05: tin cuối của Tuấn là bấm tay 19:20 hôm qua');
  console.assert(N.care === null, '00:05: không có việc phía người ấy (đến nơi từ hôm qua, sau 21:00 không nhắc thời tiết)');
  console.assert(S.weather.p.temp === 27 && S.weather.m.temp === 23 && S.weather.p.cond.text === 'Nhiều mây', '19:05: TP.HCM 27° nhiều mây (mưa 14–17h đã qua), Hà Nội 23°');
  console.assert(Math.abs(S.weather.p.temp - S.weather.m.temp) < 5, 'chênh 4° < 5 ⇒ không có câu chênh lệch (D11)');
  const noon = at('2026-10-20T12:40');
  console.assert(noon.weather.p.cond.text === 'Chiều nay mưa' && noon.care.label === 'Nhắc mang ô', '12:40: TP.HCM chiều nay mưa ⇒ chân bảng "Nhắc mang ô"');
  console.assert(noon.poke.m === 4 && noon.poke.p === 3, '12:40: mình 4, Thảo 3');
  console.assert(fmtDur(S.sleep.m.min) === '6g 50p' && fmtDur(S.sleep.p.min) === '7g 20p', 'đêm qua 6g 50p / 7g 20p (khớp mock arrival)');
  console.assert(O.arrival.m.pending && O.arrival.m.at.endsWith('19:05') && O.money.cachedAt === O.weather.fetchedAt, 'mất mạng: Về nhà rồi hiện ngay 19:05 (chờ mạng); sổ tiền và bảng cùng một giờ "số lúc"');
  console.assert(Math.floor(money.spent * 100 / money.budget) === 71, 'sổ chung 3.574.000 / 5.000.000 = 71%');
  console.assert(S.lit === 5 && N.lit === 0, 'chòm sao 19:05: 5/6 (thiếu câu hỏi của Tuấn) · 00:05: 0/6');
  console.assert(!S.streak.doneToday && N.streak.n === S.streak.n + 1, '19:05 chuỗi 92 chờ hôm nay · 20/10 xong lúc 21:30 nên 00:05 là 93');
  console.assert(caro.moves % 2 === 0 && caro.lastBy === 'p', 'nước 14 là của Thảo ⇒ tới lượt Tuấn');
  console.assert(!BLOCKED.some(([a, b]) => (a === ME.color && b === PARTNER.color) || (b === ME.color && a === PARTNER.color)), 'màu hai người không thuộc cặp khoá');

  window.D = { ME, PARTNER, PLACE, MOODS, LOW_BATTERY, CARE, fmtInt, fmtDur, pad, mins, at, S, N, O, noon };
})();
