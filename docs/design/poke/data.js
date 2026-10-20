// Dữ liệu mẫu cho mock "Chạm tim" (feature poke). Cặp DEV Tuấn ♥ Thảo (test3/test4),
// ngày yêu 14/05/2023, hôm nay 20/10/2026. Người xem = Tuấn (máy của Tuấn).
// Mọi con số trên mock đều tính từ dòng thời gian bên dưới, không gõ tay.
(function () {
  const lang = new URLSearchParams(location.search).get('lang') === 'en' ? 'en' : 'vi';

  const me = { uid: 'uid_tuan', name: 'Tuấn' };
  const partner = { uid: 'uid_thao', name: 'Thảo' };
  const anniversary = '2023-05-14';
  const today = '2026-10-20';
  const now = '14:32:05';

  const dayMs = 86400000;
  const daysTogether = Math.round((Date.UTC(2026, 9, 20) - Date.UTC(2023, 4, 14)) / dayMs);
  const [hh, mm, ss] = now.split(':').map(Number);
  const totalHours = daysTogether * 24 + hh;

  const milestones = [30, 50, 100, 180, 365, 500, 730, 1000, 1500, 2000, 3000];
  const nextMilestone = milestones.find((m) => daysTogether < m) ?? (Math.floor(daysTogether / 500) + 1) * 500;
  const daysLeft = nextMilestone - daysTogether;
  const progress = daysTogether / nextMilestone;

  // Mỗi lần chạm tim hôm nay (giờ máy người gửi). from = ai chạm.
  const taps = [
    { at: '08:05', from: 'uid_thao' },
    { at: '08:06', from: 'uid_thao' },
    { at: '08:12', from: 'uid_tuan' },
    { at: '11:30', from: 'uid_thao' },
    { at: '12:01', from: 'uid_tuan' },
    { at: '12:01', from: 'uid_tuan' },
    { at: '12:02', from: 'uid_tuan' },
    { at: '13:45', from: 'uid_tuan' },
    { at: '13:46', from: 'uid_tuan' },
    { at: '14:28', from: 'uid_thao' },
    { at: '14:30', from: 'uid_thao' },
    { at: '14:31', from: 'uid_tuan' },
  ];
  const countUpTo = (uid, at) => taps.filter((t) => t.from === uid && t.at <= at).length;
  const mine = countUpTo(me.uid, now);
  const theirs = countUpTo(partner.uid, now);
  const total = mine + theirs;
  const lastFromPartner = taps.filter((t) => t.from === partner.uid).at(-1).at;

  // Push mà máy Tuấn nhận: chụp tại lần chạm thứ nhất và lần chạm cuối của Thảo.
  const pushAt = (at) => ({ at, n: countUpTo(partner.uid, at), total: countUpTo(partner.uid, at) + countUpTo(me.uid, at) });
  const firstPush = pushAt('08:05');
  const lastPush = pushAt(lastFromPartner);

  // Trạng thái mất mạng trên widget: sáng 07:40, Tuấn chưa chạm lần nào, chạm 3 lần khi mất sóng.
  const offline = { at: '07:40', queued: 3 };

  const fmt = (n) => new Intl.NumberFormat(lang === 'vi' ? 'vi-VN' : 'en-US').format(n);
  const pad = (n) => String(n).padStart(2, '0');

  // Copy. Chuỗi push và widget lấy nguyên văn spec PO (D6, D8); câu Home do Designer đề xuất.
  const C = {
    vi: {
      eyebrow: 'HAI BẠN ĐÃ BÊN NHAU', daysUnit: 'NGÀY', h: 'GIỜ', m: 'PHÚT', s: 'GIÂY',
      greeting: 'CHÀO BUỔI CHIỀU, TUẤN',
      milestone: (d) => `Cột mốc ${fmt(d)} ngày`, left: (d) => `còn ${fmt(d)} ngày`,
      streak: (n) => `${n} ngày kết nối · hôm nay xong rồi`,
      todayTitle: 'Hôm nay của chúng mình',
      heartLabel: (p) => `Gửi nhớ thương tới ${p}`,
      // Câu dưới hàng tên (Home), theo số của mình (m) và người ấy (p).
      caption(m, p, name) {
        if (m === 0 && p === 0) return `Chạm tim để ${name} biết mình đang nhớ`;
        if (m === 0) return `${name} nhớ mình ${p} lần hôm nay`;
        if (p === 0) return `Mình đã nhớ ${name} ${m} lần hôm nay`;
        // Liệt kê theo thứ tự hàng tên (Tuấn trái, Thảo phải); máy người bên phải thì đảo lại.
        return `Hôm nay nhớ nhau ${m + p} lần: mình ${m}, ${name} ${p}`;
      },
      justNow: (name) => `${name} vừa nhớ mình`,
      queued: (q) => `Mất mạng. ${q} lần chạm sẽ tự gửi khi có sóng`,
      limit: 'Hôm nay chạm nhiều lắm rồi, mai chạm tiếp nhé',
      loadError: 'Chưa xem được số hôm nay.', retry: 'Thử lại',
      // Widget (D8)
      daysTogether: 'ngày bên nhau',
      status: (name, n) => (n === 1 ? `${name} vừa nhớ mình` : `${name} nhớ mình ${n} lần hôm nay`),
      statusShort: (name, n) => (n === 1 ? `${name} nhớ mình` : `${name} nhớ mình ${n} lần`),
      since: 'Bắt đầu từ 14 thg 5, 2023',
      // Push (D6)
      pushTitle: (name, n) => (n === 1 ? `${name} vừa nhớ bạn 💗` : `${name} nhớ bạn ${n} lần rồi 💗`), // taste-skill-ignore: emoji: copy push chốt trong spec PO D6
      pushBody: (n, t) => (n === 1 ? 'Chạm tim để gửi lại một cái nhé.' : `Hôm nay chúng mình nhớ nhau ${t} lần.`),
      // Cài đặt (D11)
      settingTitle: 'Báo khi người ấy chạm tim',
      settingOn: (name) => `Kiểu “${name} nhớ bạn 5 lần rồi”. Chạm nhiều vẫn chỉ một thông báo.`,
      settingOff: (name) => `Đang tắt. Máy im, mở app vẫn thấy ${name} nhớ mình mấy lần.`,
    },
    en: {
      eyebrow: "YOU'VE BEEN TOGETHER FOR", daysUnit: 'DAYS', h: 'HRS', m: 'MIN', s: 'SEC',
      greeting: 'GOOD AFTERNOON, TUẤN',
      milestone: (d) => `Milestone: ${fmt(d)} days`, left: (d) => `${fmt(d)} days left`,
      streak: (n) => `${n}-day connection · done for today`,
      todayTitle: 'Our today',
      heartLabel: (p) => `Send ${p} a heart`,
      caption(m, p, name) {
        if (m === 0 && p === 0) return `Tap the heart to let ${name} know you're thinking of them`;
        if (m === 0) return `${name} thought of you ${p} times today`;
        if (p === 0) return `You thought of ${name} ${m} times today`;
        return `${m + p} hearts today: you ${m}, ${name} ${p}`;
      },
      justNow: (name) => `${name} is thinking of you`,
      queued: (q) => `Offline. ${q} taps will send when you're back`,
      limit: "That's a lot of hearts for one day. More tomorrow.",
      loadError: "Couldn't load today's count.", retry: 'Retry',
      daysTogether: 'days together',
      status: (name, n) => (n === 1 ? `${name} is thinking of you` : `${name} thought of you ${n} times today`),
      statusShort: (name, n) => (n === 1 ? `${name} misses you` : `${name} misses you ×${n}`),
      since: 'Since May 14, 2023',
      pushTitle: (name, n) => (n === 1 ? `${name} is thinking of you 💗` : `${name} thought of you ${n} times 💗`), // taste-skill-ignore: emoji: copy push chốt trong spec PO D6
      pushBody: (n, t) => (n === 1 ? 'Tap the heart to send one back.' : `${t} hearts between you two today.`),
      settingTitle: 'When your partner taps the heart',
      settingOn: (name) => `Like “${name} thought of you 5 times”. Many taps, one notification.`,
      settingOff: (name) => `Off. Your phone stays quiet; the app still shows the count.`,
    },
  }[lang];

  window.D = {
    lang, me, partner, anniversary, today, now, taps, mine, theirs, total, lastFromPartner,
    daysTogether, totalHours, minutes: mm, seconds: ss, nextMilestone, daysLeft, progress,
    firstPush, lastPush, offline, fmt, pad, C,
    clock: { h: fmt(totalHours), m: pad(mm), s: pad(ss) },
  };

  // Các con số phải khớp nhau.
  console.assert(daysTogether === 1255, 'Số ngày bên nhau 14/05/2023 → 20/10/2026 = 1255', daysTogether);
  console.assert(totalHours === 30134, 'Tổng giờ lúc 14:32 = 1255 × 24 + 14', totalHours);
  console.assert(nextMilestone === 1500 && daysLeft === 245, 'Cột mốc kế 1500, còn 245 ngày');
  console.assert(mine === 7 && theirs === 5 && total === 12, 'Hôm nay Tuấn 7, Thảo 5, tổng 12');
  console.assert(total === taps.length, 'Tổng = số lần chạm trong dòng thời gian');
  console.assert(firstPush.n === 1 && firstPush.total === 1, 'Push đầu: Thảo chạm lần 1, tổng 1');
  console.assert(lastPush.n === 5 && lastPush.total === 11, 'Push cuối 14:30: Thảo 5 lần, tổng 11 (Tuấn mới chạm 6 lần)');
  console.assert(lastFromPartner === '14:30', 'Lần chạm cuối của Thảo 14:30');
  console.assert(taps.every((t, i) => i === 0 || taps[i - 1].at <= t.at), 'Dòng thời gian theo thứ tự');
})();
