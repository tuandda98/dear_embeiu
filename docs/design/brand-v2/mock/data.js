// Dữ liệu mẫu cho mockup Brand v2 (Home + Hồ sơ). Mọi tổng đều tính từ các dòng bên dưới,
// không gõ tay. Mở console để xem assert. Mốc thời gian giả định: Thứ Ba 20/10/2026, 12:20.
// Đây là dữ liệu MẪU (cặp test DEV Tuấn ♥ Thảo), không phải dữ liệu thật của người dùng.
(function () {
  const NOW = new Date(2026, 9, 20, 12, 20); // tháng 0-based: 9 = tháng 10
  const day = (y, m, d) => new Date(Date.UTC(y, m - 1, d));
  const ANNIV = day(2023, 5, 14);
  const TODAY = day(2026, 10, 20);
  const daysBetween = (a, b) => Math.round((b - a) / 86400000);

  // Cùng công thức LoveTreeService.daysTogether: chênh lệch ngày lịch, không +1.
  const daysTogether = daysBetween(ANNIV, TODAY);

  // Đề xuất v2: Home và Hồ sơ dùng CHUNG một danh sách mốc (MilestoneTrail._stations).
  // Code hiện tại lệch: Home dùng [.., 1000, 1500, ..] (còn 245 ngày), Hồ sơ dùng 1314 (còn 59 ngày).
  const TRAIL = [100, 365, 520, 1000, 1314, 1825, 3650];
  const nextMilestone = TRAIL.find((m) => m > daysTogether);

  const mDate = new Date(ANNIV.getTime() + nextMilestone * 86400000);
  const milestoneDateText = `${String(mDate.getUTCDate()).padStart(2, '0')}/${String(mDate.getUTCMonth() + 1).padStart(2, '0')}/${mDate.getUTCFullYear()}`;
  const people = {
    partner: { id: 'thao', name: 'Thảo', initial: 'T', hue: 'orange', color: '#E8590C' },
    me: { id: 'tuan', name: 'Tuấn', initial: 'T', hue: 'blue', color: '#1C7ED6' },
  };

  // ---- Câu hỏi hằng ngày: lịch sử ngày cả hai cùng trả lời (bothAnswered) ----
  // Từ 01/09/2025 tới hôm qua, trừ vài ngày lỡ. Chuỗi = số ngày liên tục kết thúc hôm qua.
  const missed = new Set(['2025-11-02', '2025-12-24', '2026-01-17', '2026-02-10', '2026-03-03',
    '2026-04-21', '2026-05-30', '2026-07-12', '2026-08-28', '2026-09-26']);
  const iso = (d) => d.toISOString().slice(0, 10);
  const answeredDays = [];
  for (let d = day(2025, 9, 1); d < TODAY; d = new Date(d.getTime() + 86400000)) {
    if (!missed.has(iso(d))) answeredDays.push(iso(d));
  }
  let streak = 0;
  for (let d = new Date(TODAY.getTime() - 86400000); answeredDays.includes(iso(d)); d = new Date(d.getTime() - 86400000)) streak++;
  let longest = 0, run = 0, prev = null;
  for (const s of answeredDays) {
    const d = new Date(s + 'T00:00:00Z');
    run = prev && daysBetween(prev, d) === 1 ? run + 1 : 1;
    longest = Math.max(longest, run); prev = d;
  }

  // ---- Hôm nay ----
  const today = {
    question: { text: 'Món ăn nào làm bạn nhớ nhà nhất?', partnerAt: '08:12', meAt: null },
    mood: { partner: { word: 'Hơi mệt', note: 'Họp cả sáng', at: '07:55' }, me: null },
    chat: { partner: { count: 3, unread: 2, lastAt: '11:58' }, me: { count: 1, lastAt: '07:30' } },
    poke: { partner: 5, me: 7 }, // partner = Thảo chạm tim gửi Tuấn; me = Tuấn gửi Thảo
    sleep: { partner: { bed: '23:40', wake: '06:30' }, me: { bed: '23:55', wake: '07:05' } },
    arrival: { partner: { place: 'Đến chỗ làm', at: '08:05', battery: 64 }, me: { place: 'Ở nhà', at: '07:05', battery: null } },
    weather: { partner: { city: 'TP.HCM', temp: 31, sky: 'Chiều nay mưa', rain: true }, me: { city: 'Hà Nội', temp: 24, sky: 'Nhiều mây', rain: false } },
  };
  const mins = (t) => { const [h, m] = t.split(':').map(Number); return h * 60 + m; };
  const sleepMin = (s) => (mins(s.wake) - mins(s.bed) + 1440) % 1440;
  const fmtDur = (m) => `${Math.floor(m / 60)}g ${String(m % 60).padStart(2, '0')}p`;
  today.sleep.partner.min = sleepMin(today.sleep.partner);
  today.sleep.me.min = sleepMin(today.sleep.me);
  today.poke.total = today.poke.partner + today.poke.me;

  // Chòm sao: mỗi người 3 sao (Câu hỏi · Tâm trạng · Nhắn tin).
  const stars = {
    partner: [!!today.question.partnerAt, !!today.mood.partner, today.chat.partner.count > 0],
    me: [!!today.question.meAt, !!today.mood.me, today.chat.me.count > 0],
  };
  stars.lit = [...stars.partner, ...stars.me].filter(Boolean).length;

  // ---- Trò chơi ----
  const games = [
    { id: 'rps', name: 'Oẳn tù tì', state: 'invited', line: 'Thảo đang rủ một ván', at: '12:05', needsMe: true, action: 'Vào chơi' },
    { id: 'caro', name: 'Cờ caro', state: 'myTurn', line: 'Đến lượt mình, nước 14', at: '11:47', needsMe: true, action: 'Đi tiếp' },
  ];
  const gamesWaiting = games.filter((g) => g.needsMe).length;

  // ---- Phân vân gì không? (decision-wheel) ----
  const decisions = [
    { kind: 'eat', label: 'Ăn gì', result: 'Cơm tấm', by: 'Thảo', at: '11:52' },
    { kind: 'go', label: 'Đi đâu', result: null },
    { kind: 'custom', label: 'Phân vân khác', result: null },
  ];

  // ---- Sổ chung tháng này (chỉ sổ chung; sổ riêng không lên Home) ----
  const sharedOctober = [
    ['2026-10-02', 'Đi chợ cuối tuần', 420000], ['2026-10-04', 'Xem phim', 260000],
    ['2026-10-06', 'Tiền điện', 715000], ['2026-10-09', 'Lẩu Thái', 540000],
    ['2026-10-11', 'Quà sinh nhật mẹ Thảo', 850000], ['2026-10-14', 'Đổ xăng', 120000],
    ['2026-10-17', 'Cà phê Tranquil', 95000], ['2026-10-18', 'Đi chợ', 360000],
    ['2026-10-20', 'Cơm tấm trưa', 120000],
  ].map(([date, note, amount]) => ({ date, note, amount }));
  const monthSpent = sharedOctober.reduce((s, r) => s + r.amount, 0);
  const todaySpent = sharedOctober.filter((r) => r.date === iso(TODAY)).reduce((s, r) => s + r.amount, 0);
  const budget = 5000000;

  // ---- Ảnh ----
  const photos = [
    { src: 'img/p6.jpg', caption: 'Hoàng hôn ở Hồ Tây', by: 'Thảo', ago: '3 ngày trước' },
    { src: 'img/p5.jpg', caption: 'Nhảy giữa rừng thông Đà Lạt', by: 'Tuấn', ago: '12 ngày trước' },
    { src: 'img/p4.jpg', caption: 'Tối nến nhìn xuống thành phố', by: 'Thảo', ago: '1 tháng trước' },
    { src: 'img/p3.jpg', caption: 'Cõng em qua bãi cát', by: 'Tuấn', ago: '2 tháng trước' },
    { src: 'img/p2.jpg', caption: 'Chiều vàng dưới hàng cây', by: 'Thảo', ago: '3 tháng trước' },
    { src: 'img/p1.jpg', caption: 'Hôn lên trán', by: 'Tuấn', ago: '4 tháng trước' },
  ];
  // Tổng ảnh của cặp: 6 ảnh gần nhất ở trên + 136 ảnh cũ hơn (đếm theo tháng, cộng lại).
  const olderPhotosByMonth = [9, 14, 11, 8, 12, 10, 7, 13, 9, 11, 6, 10, 8, 8];
  const photoTotal = photos.length + olderPhotosByMonth.reduce((a, b) => a + b, 0);

  // ---- Hộp thông báo ----
  const inbox = [
    { type: 'daily_question', text: 'Thảo đã trả lời câu hỏi hôm nay', at: '08:12', read: false },
    { type: 'poke', text: 'Thảo nhớ bạn 5 lần hôm nay', at: '11:30', read: false },
    { type: 'rps_invite', text: 'Thảo rủ bạn chơi oẳn tù tì', at: '12:05', read: false },
    { type: 'photo_posted', text: 'Thảo đã đăng 1 ảnh', at: 'hôm qua', read: true },
  ];
  const unread = inbox.filter((n) => !n.read).length;

  // ---- Hồ sơ ----
  const careMessages = 36;
  const reminders = [
    { name: 'Mốc 1.314 ngày', on: true }, { name: 'Kỷ niệm 3 năm', on: true },
    { name: 'Sinh nhật Thảo 02/12', on: true }, { name: 'Đóng tiền nhà ngày 5', on: true },
    { name: 'Nhắc uống nước', on: false }, { name: 'Mốc 100 ngày', on: true },
  ];
  const remindersOn = reminders.filter((r) => r.on).length;


  // ---- Cặp đang chờ người ấy (tài khoản DEV test1: Minh, chờ Ngọc) ----
  const W_ANNIV = day(2026, 9, 28);
  const waiting = {
    me: 'Minh', partner: 'Ngọc', code: 'MN7K2Q', link: 'dearembeiu.com/get?code=MN7K2Q',
    days: daysBetween(W_ANNIV, TODAY), anniversaryText: '28/09/2026',
    steps: [
      { text: 'Gửi mã cho Ngọc', sub: 'Đã gửi lúc 21:10 hôm 18/10', done: true },
      { text: 'Ngọc tải app và đăng ký', sub: 'Bước này app không thấy được', done: false },
      { text: 'Ngọc nhập mã MN7K2Q', sub: 'Hai máy tự nối với nhau', done: false },
    ],
    sleep: { bed: '00:10', wake: '07:15' }, weather: { city: 'Đà Nẵng', temp: 27, sky: 'Ít mây' },
  };
  waiting.sleepMin = sleepMin(waiting.sleep);
  waiting.doneSteps = waiting.steps.filter((x) => x.done).length;

  const fmtMoney = (v) => v.toLocaleString('vi-VN') + 'đ';
  const fmtInt = (v) => v.toLocaleString('vi-VN');

  const D = {
    NOW, people, daysTogether, nextMilestone, toMilestone: nextMilestone - daysTogether,
    TRAIL, milestoneDateText, anniversaryText: '14/05/2023', todayText: 'Thứ Ba, 20/10',
    answeredCount: answeredDays.length, streak, longest,
    today, stars, games, gamesWaiting, decisions,
    money: { monthSpent, todaySpent, budget, rows: sharedOctober.length },
    photos, photoTotal, inbox, unread, careMessages, remindersOn,
    fmtDur, fmtMoney, fmtInt, waiting,
  };

  // ---- Các số phải khớp ----
  console.assert(daysTogether === 1255, 'Số ngày bên nhau 14/05/2023 → 20/10/2026 phải là 1255', daysTogether);
  console.assert(nextMilestone === 1314 && D.toMilestone === 59, 'Mốc kế tiếp (chung Home + Hồ sơ): 1314, còn 59 ngày');
  console.assert(TRAIL.filter((m) => m <= daysTogether).length === 4, 'Đã qua 4 mốc: 100, 365, 520, 1000');
  console.assert(today.poke.total === 12, 'Tổng nhớ nhau hôm nay = 5 + 7');
  console.assert(today.sleep.partner.min === 410 && today.sleep.me.min === 430, 'Thảo ngủ 6g50p, Tuấn ngủ 7g10p');
  console.assert(stars.lit === 4, 'Chòm sao hôm nay 4/6');
  console.assert(gamesWaiting === 2, 'Hai ván đang chờ mình');
  console.assert(monthSpent === 3480000, 'Sổ chung tháng 10 = 3.480.000đ', monthSpent);
  console.assert(todaySpent === 120000, 'Hôm nay chi 120.000đ');
  console.assert(monthSpent < budget, 'Chưa vượt ngân sách');
  console.assert(photoTotal === 142, 'Tổng ảnh = 142', photoTotal);
  console.assert(today.chat.partner.unread <= today.chat.partner.count, 'Tin chưa đọc không vượt số tin Thảo gửi');
  console.assert(unread === 3, 'Chuông: 3 chưa đọc');
  console.assert(streak === 23, 'Chuỗi hiện tại 23 ngày (26/09 lỡ → 27/09..19/10)', streak);
  console.assert(longest >= streak, 'Chuỗi dài nhất không nhỏ hơn chuỗi hiện tại');
  console.assert(D.answeredCount === 404, 'Số ngày cả hai đã trả lời', D.answeredCount);
  console.assert(remindersOn === 5, '5 lời nhắc đang bật');
  console.assert(Math.abs(today.weather.partner.temp - today.weather.me.temp) === 7, 'Chênh 7°');
  console.assert(waiting.days === 22, 'Minh: 28/09 → 20/10 = 22 ngày', waiting.days);
  console.assert(waiting.doneSteps === 1 && waiting.sleepMin === 425, 'Chờ: 1/3 bước, ngủ 7g05p');
  console.assert(milestoneDateText === '18/12/2026', 'Mốc 1314 rơi vào 18/12/2026', milestoneDateText);
  window.D = D;
})();
