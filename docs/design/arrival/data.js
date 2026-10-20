// Dữ liệu mẫu cho mock arrival (Designer 2026-10-20). Cặp DEV Tuấn ♥ Thảo (test3/test4),
// ngày yêu 14/05/2023, "bây giờ" = thứ Ba 20/10/2026 19:05 giờ VN.
// Máy chủ chỉ giữ MỘT sự kiện mới nhất mỗi người (D3). Nhật ký trong ngày bên dưới chỉ có trên
// máy từng người (bộ lọc D6) — mock dùng nó để mọi con số trên thẻ, push, widget suy ra từ một nguồn.
(function () {
  const NOW = '2026-10-20T19:05';
  const ANNIVERSARY = '2023-05-14';

  const PALETTE = { rose: '#FF4D6D', purple: '#7C5CD6', blue: '#1C7ED6', teal: '#0E9384', orange: '#E8590C', green: '#2F9E44', magenta: '#C2255C', amber: '#B7791F' };
  const BLOCKED = { rose: ['orange', 'magenta'], orange: ['rose', 'amber'], magenta: ['rose'], purple: ['blue'], blue: ['purple'], teal: ['green'], green: ['teal', 'amber'], amber: ['orange', 'green'] };

  const people = {
    me: { uid: 'u_tuan', name: 'Tuấn', color: 'rose' },
    partner: { uid: 'u_thao', name: 'Thảo', color: 'teal' },
  };

  const PLACE = {
    home: { vi: 'Nhà', en: 'Home', enter: { vi: 'Đã về đến nhà', en: 'Got home' }, exit: { vi: 'Đã rời nhà', en: 'Left home' }, manual: { vi: 'Về nhà rồi', en: "I'm home" } },
    work: { vi: 'Chỗ làm', en: 'Work', enter: { vi: 'Đã đến chỗ làm', en: 'Got to work' }, exit: { vi: 'Đã rời chỗ làm', en: 'Left work' }, manual: { vi: 'Đến chỗ làm rồi', en: 'At work' } },
    school: { vi: 'Trường', en: 'School', enter: { vi: 'Đã đến trường', en: 'Got to school' }, exit: { vi: 'Đã rời trường', en: 'Left school' }, manual: { vi: 'Đến trường rồi', en: 'At school' } },
  };

  // Nhật ký hôm nay trên từng máy (giờ VN). Pin giảm dần vì cả ngày không sạc.
  const thaoToday = [
    { place: 'home', type: 'exit', at: '2026-10-20T07:20', battery: 96, source: 'auto' },
    { place: 'work', type: 'enter', at: '2026-10-20T07:58', battery: 91, source: 'auto' },
    { place: 'work', type: 'exit', at: '2026-10-20T17:32', battery: 19, source: 'auto' },
    { place: 'home', type: 'enter', at: '2026-10-20T18:42', battery: 12, source: 'auto' },
  ];
  const tuanToday = [
    { place: 'home', type: 'exit', at: '2026-10-20T07:35', battery: 88, source: 'auto' },
    { place: 'work', type: 'enter', at: '2026-10-20T08:05', battery: 64, source: 'auto' },
  ];

  // Địa điểm đã lưu (toạ độ chỉ trên máy; mock chỉ cần loại + ngày lưu).
  const savedPlaces = {
    u_tuan: [{ place: 'home', savedAt: '2026-10-12' }, { place: 'work', savedAt: '2026-10-13' }],
    u_thao: [{ place: 'home', savedAt: '2026-10-12' }, { place: 'work', savedAt: '2026-10-14' }],
  };

  // Doc Firestore couples/{c}/arrival/{uid} — đúng hình §5 overview.
  const docs = {
    u_thao: { share: true, auto: true, places: savedPlaces.u_thao.map((p) => p.place), last: thaoToday[thaoToday.length - 1] },
    u_tuan: { share: true, auto: true, places: savedPlaces.u_tuan.map((p) => p.place), last: tuanToday[tuanToday.length - 1] },
  };

  const RADIUS_M = 150;
  const LOW_BATTERY = 20;
  const BOUNCE_MIN = 10;
  const PUSH_MAX_PER_DAY = 6;

  const hm = (iso) => iso.slice(11, 16);
  const mins = (iso) => { const [h, m] = hm(iso).split(':').map(Number); return h * 60 + m; };
  const dayOf = (iso) => iso.slice(0, 10);

  // Bộ lọc D6 trên máy người gửi + quy tắc CF §7: trả về sự kiện nào thành push.
  function pushesFrom(log) {
    const out = [];
    let lastPushAt = {};
    log.forEach((e, i) => {
      if (e.type !== 'enter') return;
      const prevExit = log.slice(0, i).reverse().find((x) => x.place === e.place && x.type === 'exit');
      const bounce = prevExit && mins(e.at) - mins(prevExit.at) < BOUNCE_MIN;
      if (bounce) return;
      if (lastPushAt[e.place] != null && mins(e.at) - lastPushAt[e.place] < 30) return;
      if (out.length >= PUSH_MAX_PER_DAY) return;
      lastPushAt[e.place] = mins(e.at);
      out.push(e);
    });
    return out;
  }

  function pushCopy(e, name, lang) {
    const t = { home: { vi: `${name} đã về đến nhà`, en: `${name} got home` }, work: { vi: `${name} đã đến chỗ làm`, en: `${name} got to work` }, school: { vi: `${name} đã đến trường`, en: `${name} got to school` } }[e.place][lang];
    const low = e.battery != null && e.battery <= LOW_BATTERY;
    const b = low ? { vi: `Pin còn ${e.battery}%`, en: `Battery at ${e.battery}%` }[lang] : { vi: 'Nhắn một câu hỏi thăm nhé', en: 'Send a quick hello' }[lang];
    return { title: t, body: b };
  }

  const widgetCopy = {
    arrival_home: { vi: (n) => `${n} đã về đến nhà`, en: (n) => `${n} got home`, viShort: (n) => `${n} về nhà rồi`, enShort: (n) => `${n} is home` },
    arrival_work: { vi: (n) => `${n} đã đến chỗ làm`, en: (n) => `${n} got to work`, viShort: (n) => `${n} tới chỗ làm`, enShort: (n) => `${n} at work` },
    arrival_school: { vi: (n) => `${n} đã đến trường`, en: (n) => `${n} got to school`, viShort: (n) => `${n} tới trường`, enShort: (n) => `${n} at school` },
  };

  // Ngày bên nhau (đếm theo ngày lịch, khớp CounterCard: ngày yêu là ngày 1 thì +1 — ở đây hiện số ngày đã qua).
  const daysBetween = (a, b) => Math.round((Date.UTC(...b.split('-').map((v, i) => (i === 1 ? v - 1 : +v))) - Date.UTC(...a.split('-').map((v, i) => (i === 1 ? v - 1 : +v)))) / 86400000);
  const daysTogether = daysBetween(ANNIVERSARY, dayOf(NOW));

  const thaoPushes = pushesFrom(thaoToday);
  const tuanPushes = pushesFrom(tuanToday);
  const lastThao = docs.u_thao.last;
  const push = pushCopy(lastThao, people.partner.name, 'vi');
  const pushEn = pushCopy(lastThao, people.partner.name, 'en');
  const widgetKind = lastThao.type === 'enter' ? `arrival_${lastThao.place}` : null;

  // Kiểm chéo: mọi chỗ hiện cùng một sự thật phải khớp.
  console.assert(daysTogether === 1255, 'ngày bên nhau 14/05/2023 → 20/10/2026 = 1255', daysTogether);
  console.assert(lastThao === thaoToday[thaoToday.length - 1], 'doc.last = sự kiện cuối của nhật ký');
  console.assert(thaoToday.every((e, i) => i === 0 || mins(e.at) > mins(thaoToday[i - 1].at)), 'giờ tăng dần');
  console.assert(thaoToday.every((e, i) => i === 0 || e.battery <= thaoToday[i - 1].battery), 'pin không tăng khi không sạc');
  console.assert(thaoPushes.length === 2 && thaoPushes.length <= PUSH_MAX_PER_DAY, 'Thảo: 2 lần đến = 2 push', thaoPushes.length);
  console.assert(thaoPushes[1].at === lastThao.at, 'push mới nhất là 18:42');
  console.assert(push.title === 'Thảo đã về đến nhà' && push.body === 'Pin còn 12%', 'push 18:42 có dòng pin vì 12 ≤ 20');
  console.assert(pushCopy(thaoToday[1], 'Thảo', 'vi').body === 'Nhắn một câu hỏi thăm nhé', 'pin 91% thì body hỏi thăm');
  console.assert(pushEn.title === 'Thảo got home' && pushEn.body === 'Battery at 12%', 'bản EN');
  console.assert(widgetKind === 'arrival_home' && widgetCopy[widgetKind].vi('Thảo') === push.title, 'widget = tiêu đề push');
  console.assert(widgetCopy.arrival_home.viShort('Thảo').length <= 17, 'bản rút gọn vừa widget nhỏ (≤17 ký tự)');
  console.assert(mins(thaoToday[3].at) - mins(thaoToday[2].at) === 70, 'rời chỗ làm 17:32 → về nhà 18:42 = 70 phút, không phải bounce');
  console.assert(tuanPushes.length === 1 && docs.u_tuan.last.place === 'work', 'Tuấn: đến chỗ làm 08:05');
  console.assert(!BLOCKED[people.me.color].includes(people.partner.color) && people.me.color !== people.partner.color, 'màu 2 người không trùng/khoá');
  console.assert(docs.u_thao.places.length <= 3 && docs.u_thao.places.includes('home'), '≤3 địa điểm, có Nhà khi bật tự động');
  console.assert(mins(NOW) > mins(lastThao.at), 'sự kiện xảy ra trước "bây giờ"');
  // Trường hợp rìa vùng: ra đổ rác 20:10, vào lại 20:16 → bounce, không push.
  const bounceLog = [...thaoToday, { place: 'home', type: 'exit', at: '2026-10-20T20:10', battery: 11, source: 'auto' }, { place: 'home', type: 'enter', at: '2026-10-20T20:16', battery: 11, source: 'auto' }];
  console.assert(pushesFrom(bounceLog).length === 2, 'đi đổ rác 6 phút không sinh push thứ 3');

  window.D = {
    NOW, ANNIVERSARY, daysTogether, people, PALETTE, PLACE, docs, savedPlaces, thaoToday, tuanToday,
    RADIUS_M, LOW_BATTERY, push, pushEn, widgetKind, widgetCopy, pushCopy, hm,
    low: (e) => e.battery != null && e.battery <= LOW_BATTERY,
    color: (who) => PALETTE[people[who].color],
    yesterday: { place: 'home', type: 'enter', at: '2026-10-19T22:58', battery: 40, source: 'manual' },
  };
})();
