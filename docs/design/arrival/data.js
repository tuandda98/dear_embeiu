// Dữ liệu mẫu cho mock arrival (Designer 2026-10-20, bản 2: nơi tự đặt + tìm địa chỉ).
// Cặp DEV Tuấn và Thảo (test3/test4), ngày yêu 14/05/2023, "bây giờ" = thứ Ba 20/10/2026 19:05 giờ VN.
// Địa chỉ theo địa giới 34 tỉnh (bỏ cấp quận/huyện, phường mới) — địa chỉ mẫu, Dev đo lại khi spike geocoder (§6.8 PO).
// Máy chủ chỉ giữ MỘT sự kiện mới nhất mỗi người, mang tên + biểu tượng chụp lúc xảy ra (D3, D23).
(function () {
  const NOW = '2026-10-20T19:05';
  const ANNIVERSARY = '2023-05-14';
  const PALETTE = { rose: '#FF4D6D', purple: '#7C5CD6', blue: '#1C7ED6', teal: '#0E9384', orange: '#E8590C', green: '#2F9E44', magenta: '#C2255C', amber: '#B7791F' };
  const BLOCKED = { rose: ['orange', 'magenta'], orange: ['rose', 'amber'], magenta: ['rose'], purple: ['blue'], blue: ['purple'], teal: ['green'], green: ['teal', 'amber'], amber: ['orange', 'green'] };
  const people = { me: { uid: 'u_tuan', name: 'Tuấn', color: 'rose' }, partner: { uid: 'u_thao', name: 'Thảo', color: 'teal' } };

  const ICONS = ['work', 'school', 'family', 'gym', 'cafe', 'shop', 'pin'];
  const NAME_CHIPS = ['Công ty', 'Trường', 'Nhà bố mẹ', 'Phòng gym', 'Quán quen'];
  const MAX_PLACES = 5, NAME_MAX = 24, R_ADDRESS = 250, R_CURRENT = 150, LOW_BATTERY = 20, BOUNCE_MIN = 10, PUSH_MAX_PER_DAY = 6;

  // Danh sách nơi CHỈ trên máy (Hive arrival_nobackup).
  const places = {
    u_tuan: [
      { slot: 'home', source: 'address', radius: R_ADDRESS, address: 'Ngõ 72 Nguyễn Trãi, Phường Thanh Xuân, Hà Nội', short: 'Ngõ 72 Nguyễn Trãi, P. Thanh Xuân', hasNumber: true, savedAt: '2026-10-12' },
      { slot: 'p1', name: 'Công ty', icon: 'work', source: 'address', radius: R_ADDRESS, address: '54 Liễu Giai, Phường Ngọc Hà, Hà Nội', short: '54 Liễu Giai, P. Ngọc Hà', hasNumber: true, savedAt: '2026-10-13' },
      { slot: 'p2', name: 'Phòng gym', icon: 'gym', source: 'current', radius: R_CURRENT, address: null, short: null, savedAt: '2026-10-18' },
    ],
    u_thao: [
      { slot: 'home', source: 'address', radius: R_ADDRESS, address: 'Ngõ 72 Nguyễn Trãi, Phường Thanh Xuân, Hà Nội', hasNumber: true, savedAt: '2026-10-12' },
      { slot: 'p1', name: 'Công ty', icon: 'work', source: 'address', radius: R_ADDRESS, address: '89 Láng Hạ, Phường Láng, Hà Nội', hasNumber: true, savedAt: '2026-10-14' },
      { slot: 'p2', name: 'Phòng gym', icon: 'gym', source: 'current', radius: R_CURRENT, address: null, savedAt: '2026-10-15' },
    ],
  };

  // Nhật ký hôm nay trên máy Thảo; sự kiện nơi tự đặt chụp sẵn name + icon (D23).
  const ev = (slot, type, at, battery, source = 'auto') => {
    const p = places.u_thao.find((x) => x.slot === slot);
    return { place: slot, ...(slot === 'home' ? {} : { name: p.name, icon: p.icon }), type, at: `2026-10-20T${at}`, battery, source };
  };
  const thaoToday = [ev('home', 'exit', '07:20', 96), ev('p1', 'enter', '07:58', 91), ev('p1', 'exit', '17:32', 24), ev('p2', 'enter', '17:50', 22), ev('p2', 'exit', '18:30', 15), ev('home', 'enter', '18:42', 12)];
  const tuanToday = [
    { place: 'home', type: 'exit', at: '2026-10-20T07:35', battery: 88, source: 'auto' },
    { place: 'p1', name: 'Công ty', icon: 'work', type: 'enter', at: '2026-10-20T08:05', battery: 64, source: 'auto' },
  ];
  const docs = {
    u_thao: { share: true, auto: true, last: thaoToday[thaoToday.length - 1] },
    u_tuan: { share: true, auto: true, last: tuanToday[tuanToday.length - 1] },
  };

  const hm = (iso) => iso.slice(11, 16);
  const mins = (iso) => { const [h, m] = hm(iso).split(':').map(Number); return h * 60 + m; };
  const placeName = (e, lang = 'vi') => (e.place === 'home' ? { vi: 'nhà', en: 'home' }[lang] : e.name);
  const sentence = (e, lang = 'vi') => {
    if (lang === 'en') return e.place === 'home' ? (e.type === 'enter' ? 'Got home' : 'Left home') : (e.type === 'enter' ? `Arrived at ${e.name}` : `Left ${e.name}`);
    return e.place === 'home' ? (e.type === 'enter' ? 'Đã về đến nhà' : 'Đã rời nhà') : (e.type === 'enter' ? `Đã đến ${e.name}` : `Đã rời ${e.name}`);
  };
  function pushesFrom(log) {
    const out = []; const lastPushAt = {};
    log.forEach((e, i) => {
      if (e.type !== 'enter') return;
      const prevExit = log.slice(0, i).reverse().find((x) => x.place === e.place && x.type === 'exit');
      if (prevExit && mins(e.at) - mins(prevExit.at) < BOUNCE_MIN) return;
      if (lastPushAt[e.place] != null && mins(e.at) - lastPushAt[e.place] < 30) return;
      if (out.length >= PUSH_MAX_PER_DAY) return;
      lastPushAt[e.place] = mins(e.at); out.push(e);
    });
    return out;
  }
  function pushCopy(e, who, lang) {
    const title = e.place === 'home' ? { vi: `${who} đã về đến nhà`, en: `${who} got home` }[lang] : { vi: `${who} đã đến ${e.name}`, en: `${who} arrived at ${e.name}` }[lang];
    const low = e.battery != null && e.battery <= LOW_BATTERY;
    const body = low ? { vi: `Pin còn ${e.battery}%`, en: `Battery at ${e.battery}%` }[lang] : { vi: 'Nhắn một câu hỏi thăm nhé', en: 'Send a quick hello' }[lang];
    return { title, body };
  }
  const widget = (e, who) => (e.place === 'home'
    ? { kind: 'arrival_home', vi: `${who} đã về đến nhà`, viShort: `${who} về nhà rồi`, en: `${who} got home`, enShort: `${who} is home` }
    : { kind: 'arrival_place', vi: `${who} đã đến ${e.name}`, viShort: `${who} tới ${e.name}`, en: `${who} arrived at ${e.name}`, enShort: `${who} at ${e.name}` });
  const daysBetween = (a, b) => Math.round((Date.parse(b + 'T00:00Z') - Date.parse(a + 'T00:00Z')) / 86400000);
  const daysTogether = daysBetween(ANNIVERSARY, NOW.slice(0, 10));

  const lastThao = docs.u_thao.last;
  const gym = thaoToday[3];
  const push = pushCopy(lastThao, 'Thảo', 'vi'), pushEn = pushCopy(lastThao, 'Thảo', 'en'), pushGym = pushCopy(gym, 'Thảo', 'vi');
  const thaoPushes = pushesFrom(thaoToday);

  console.assert(daysTogether === 1255, 'ngày bên nhau = 1255', daysTogether);
  console.assert(lastThao === thaoToday[thaoToday.length - 1], 'doc.last = sự kiện cuối');
  console.assert(thaoToday.every((e, i) => !i || mins(e.at) > mins(thaoToday[i - 1].at)), 'giờ tăng dần');
  console.assert(thaoToday.every((e, i) => !i || e.battery <= thaoToday[i - 1].battery), 'pin không tăng khi không sạc');
  console.assert(thaoPushes.map((e) => hm(e.at)).join() === '07:58,17:50,18:42', '3 lần đến = 3 push (Công ty, Phòng gym, Nhà)');
  console.assert(thaoPushes.length <= PUSH_MAX_PER_DAY, '≤ 6 push/ngày');
  console.assert(push.title === 'Thảo đã về đến nhà' && push.body === 'Pin còn 12%', 'push Nhà 18:42, pin 12 ≤ 20');
  console.assert(pushGym.title === 'Thảo đã đến Phòng gym' && pushGym.body === 'Nhắn một câu hỏi thăm nhé', 'push gym 17:50, pin 22 > 20');
  console.assert(pushEn.title === 'Thảo got home' && pushEn.body === 'Battery at 12%', 'bản EN');
  console.assert(widget(lastThao, 'Thảo').vi === push.title && widget(gym, 'Thảo').vi === pushGym.title, 'widget = tiêu đề push');
  console.assert(widget(gym, 'Thảo').viShort.length <= 20, 'rút gọn vừa widget nhỏ (≈17–20 ký tự, tên dài hơn thì cắt …)');
  console.assert(Object.values(places).every((l) => l.length <= MAX_PLACES && l[0].slot === 'home'), '≤ 5 nơi, Nhà luôn đầu');
  console.assert(Object.values(places).flat().every((p) => p.slot === 'home' || (p.name.trim().length >= 1 && p.name.length <= NAME_MAX && ICONS.includes(p.icon))), 'tên 1–24, icon hợp lệ');
  console.assert(Object.values(places).flat().every((p) => p.radius === (p.source === 'current' ? R_CURRENT : R_ADDRESS)), 'bán kính theo nguồn 150/250');
  console.assert('Nhà ngoại ở Thanh Xuân'.length <= NAME_MAX, 'tên dài mẫu vẫn ≤ 24');
  console.assert(!BLOCKED[people.me.color].includes(people.partner.color), 'màu 2 người không khoá');
  const bounce = [...thaoToday, ev('home', 'exit', '20:10', 11), ev('home', 'enter', '20:16', 11)];
  console.assert(pushesFrom(bounce).length === 3, 'đi đổ rác 6 phút không sinh push');

  window.D = {
    NOW, daysTogether, people, PALETTE, places, docs, thaoToday, tuanToday, ICONS, NAME_CHIPS, MAX_PLACES, NAME_MAX, R_ADDRESS, R_CURRENT,
    push, pushEn, pushGym, pushCopy, widget, hm, sentence, placeName,
    low: (e) => e.battery != null && e.battery <= LOW_BATTERY,
    gym, exitWork: thaoToday[2],
    yesterday: { place: 'home', type: 'enter', at: '2026-10-19T22:58', battery: 40, source: 'manual' },
    longName: { place: 'p3', name: 'Nhà ngoại ở Thanh Xuân', icon: 'family', type: 'enter', at: '2026-10-20T18:20', battery: 57, source: 'auto' },
  };
})();
