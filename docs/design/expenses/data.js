// Sổ tiền — dữ liệu mẫu cho mockup (feature expenses, mốc A).
// Cặp DEV: Tuấn (test3, "mình") ♥ Thảo (test4). Ngày yêu 14/05/2023. Hôm nay: Thứ Ba 20/10/2026.
// Quy ước tính theo overview.md D7. Mọi tổng đều tính từ các dòng bên dưới, không gõ tay.
// Tháng trước tháng 10 lấy từ "aggregate theo tháng" (D19), nên chỉ lưu tổng tháng; tháng 10 tính từ dòng.
// Emoji ở đây là DỮ LIỆU (icon danh mục/ví do người dùng chọn, D6/D9), không phải trang trí giao diện.

(function () {
  const TODAY = '2026-10-20';
  const ME = 'tuan', PARTNER = 'thao';
  const people = {
    tuan: { id: 'tuan', name: 'Tuấn', initial: 'T', color: '#1C7ED6', tint: 'rgba(28,126,214,.14)' },   // personPalette 'blue'
    thao: { id: 'thao', name: 'Thảo', initial: 'T', color: '#0E9384', tint: 'rgba(14,147,132,.14)' },   // personPalette 'teal'
  };

  // ---- Danh mục mặc định (D9). id cố định; tên vi/en; emoji là dữ liệu.
  const C = (id, parent, vi, en, emoji) => ({ id, parent, vi, en, emoji });
  const categories = [
    C('food', '', 'Ăn uống', 'Food & drink', '🍜'), // taste-skill-ignore: emoji = dữ liệu danh mục (D9)
    C('food_out', 'food', 'Ăn ngoài', 'Eating out', '🍜'), // taste-skill-ignore
    C('food_market', 'food', 'Đi chợ, siêu thị', 'Groceries', '🛒'), // taste-skill-ignore
    C('food_coffee', 'food', 'Cà phê, trà sữa', 'Coffee & bubble tea', '☕'), // taste-skill-ignore
    C('food_snack', 'food', 'Ăn vặt', 'Snacks', '🥖'), // taste-skill-ignore
    C('date', '', 'Hẹn hò', 'Dates', '💕'), // taste-skill-ignore
    C('date_movie', 'date', 'Xem phim', 'Movies', '🎬'), // taste-skill-ignore
    C('date_out', 'date', 'Đi chơi', 'Going out', '🎡'), // taste-skill-ignore
    C('date_gift', 'date', 'Quà cho người ấy', 'Gifts for my love', '🎁'), // taste-skill-ignore
    C('move', '', 'Đi lại', 'Getting around', '🛵'), // taste-skill-ignore
    C('move_fuel', 'move', 'Xăng xe', 'Fuel', '⛽'), // taste-skill-ignore
    C('move_parking', 'move', 'Gửi xe', 'Parking', '🅿️'), // taste-skill-ignore
    C('move_grab', 'move', 'Grab, taxi', 'Grab & taxi', '🚕'), // taste-skill-ignore
    C('move_repair', 'move', 'Sửa xe', 'Repairs', '🔧'), // taste-skill-ignore
    C('home', '', 'Nhà cửa', 'Home', '🏠'), // taste-skill-ignore
    C('home_rent', 'home', 'Tiền nhà', 'Rent', '🔑'), // taste-skill-ignore
    C('home_power', 'home', 'Điện', 'Electricity', '💡'), // taste-skill-ignore
    C('home_water', 'home', 'Nước', 'Water', '🚿'), // taste-skill-ignore
    C('home_net', 'home', 'Internet', 'Internet', '📶'), // taste-skill-ignore
    C('home_goods', 'home', 'Đồ dùng nhà', 'Household items', '🧺'), // taste-skill-ignore
    C('bill', '', 'Hoá đơn & gói', 'Bills & subscriptions', '📱'), // taste-skill-ignore
    C('bill_phone', 'bill', 'Điện thoại', 'Phone plan', '📞'), // taste-skill-ignore
    C('bill_stream', 'bill', 'Xem phim, nghe nhạc', 'Streaming', '🎧'), // taste-skill-ignore
    C('bill_soft', 'bill', 'Phần mềm', 'Software', '💾'), // taste-skill-ignore
    C('shop', '', 'Mua sắm', 'Shopping', '🛍️'), // taste-skill-ignore
    C('shop_clothes', 'shop', 'Quần áo', 'Clothes', '👕'), // taste-skill-ignore
    C('shop_beauty', 'shop', 'Mỹ phẩm', 'Beauty', '💄'), // taste-skill-ignore
    C('shop_tech', 'shop', 'Đồ điện tử', 'Electronics', '🎮'), // taste-skill-ignore
    C('health', '', 'Sức khoẻ', 'Health', '💊'), // taste-skill-ignore
    C('health_med', 'health', 'Thuốc', 'Medicine', '💊'), // taste-skill-ignore
    C('health_doctor', 'health', 'Khám bệnh', 'Doctor', '🩺'), // taste-skill-ignore
    C('health_sport', 'health', 'Thể thao', 'Sport', '🏸'), // taste-skill-ignore
    C('edu', '', 'Học tập', 'Learning', '📚'), // taste-skill-ignore
    C('edu_fee', 'edu', 'Học phí', 'Tuition', '🎓'), // taste-skill-ignore
    C('edu_books', 'edu', 'Sách, khoá học', 'Books & courses', '📖'), // taste-skill-ignore
    C('gift', '', 'Quà & hiếu hỉ', 'Gifts & occasions', '🎁'), // taste-skill-ignore
    C('gift_present', 'gift', 'Quà tặng', 'Presents', '🎀'), // taste-skill-ignore
    C('gift_wedding', 'gift', 'Đám cưới, đám hiếu', 'Weddings & funerals', '💌'), // taste-skill-ignore
    C('gift_lixi', 'gift', 'Lì xì', 'Lucky money', '🧧'), // taste-skill-ignore
    C('family', '', 'Gia đình', 'Family', '👪'), // taste-skill-ignore
    C('family_parents', 'family', 'Biếu bố mẹ', 'For my parents', '🤲'), // taste-skill-ignore
    C('family_pet', 'family', 'Thú cưng', 'Pets', '🐶'), // taste-skill-ignore
    C('travel', '', 'Du lịch', 'Travel', '✈️'), // taste-skill-ignore
    C('travel_ticket', 'travel', 'Vé', 'Tickets', '🎫'), // taste-skill-ignore
    C('travel_stay', 'travel', 'Chỗ ở', 'Stays', '🏨'), // taste-skill-ignore
    C('travel_fun', 'travel', 'Ăn chơi', 'Fun', '🎢'), // taste-skill-ignore
    C('other', '', 'Khác', 'Other', '📦'), // taste-skill-ignore
    // Thu
    C('salary', '', 'Lương', 'Salary', '💼'), // taste-skill-ignore
    C('bonus', '', 'Thưởng', 'Bonus', '🎉'), // taste-skill-ignore
    C('side', '', 'Làm thêm', 'Side work', '🧑‍💻'), // taste-skill-ignore
    C('gifted', '', 'Được cho, tặng', 'Gifts received', '🧧'), // taste-skill-ignore
    C('interest', '', 'Lãi, đầu tư', 'Interest', '📈'), // taste-skill-ignore
    C('income_other', '', 'Thu khác', 'Other income', '💰'), // taste-skill-ignore
  ];
  const INCOME_IDS = ['salary', 'bonus', 'side', 'gifted', 'interest', 'income_other'];
  const cat = (id) => categories.find((c) => c.id === id) || categories.find((c) => c.id === 'other');
  const parentOf = (id) => { const c = cat(id); return c.parent ? cat(c.parent) : c; };

  // ---- Sổ của mình (users/tuan)
  const ownWallets = [
    { id: 'w_cash', name: 'Tiền mặt', type: 'cash', emoji: '💵', opening: 800000, includeInTotal: true }, // taste-skill-ignore
    { id: 'w_tcb', name: 'Techcombank', type: 'bank', emoji: '🏦', opening: 14200000, includeInTotal: true }, // taste-skill-ignore
    { id: 'w_momo', name: 'MoMo', type: 'ewallet', emoji: '📱', opening: 1500000, includeInTotal: true }, // taste-skill-ignore
    { id: 'w_vib', name: 'Thẻ VIB', type: 'credit', emoji: '💳', opening: -2000000, includeInTotal: true }, // taste-skill-ignore
    { id: 'w_laptop', name: 'Mua laptop', type: 'goal', emoji: '💻', opening: 6000000, includeInTotal: false, goalTarget: 25000000, goalDeadline: '2027-03-31' }, // taste-skill-ignore
  ];
  // Số dư cuối 30/09 do aggregate trả (openingBalance + mọi dòng trước tháng 10).
  const ownCarry = { w_cash: 412000, w_tcb: 9850000, w_momo: 1268000, w_vib: -1450000, w_laptop: 7500000 };

  const T = (id, date, type, amount, out, inn, categoryId, note, extra = {}) => ({ id, date, type, amount, outWalletId: out, inWalletId: inn, categoryId, note, ...extra });
  const ownTx = [
    T('o1', '2026-10-01', 'expense', 4500000, 'w_tcb', '', 'home_rent', 'Tiền nhà tháng 10'),
    T('o2', '2026-10-01', 'contribution', 1000000, 'w_tcb', '', '', 'Góp vào Ví chung', { linkId: 'L1' }),
    T('o3', '2026-10-03', 'expense', 480000, 'w_tcb', '', 'food_out', 'Lẩu Thái Phố Huế', { linkId: 'L2' }),
    T('o4', '2026-10-05', 'income', 18500000, '', 'w_tcb', 'salary', 'Lương tháng 10'),
    T('o5', '2026-10-05', 'expense', 1500000, 'w_tcb', '', 'family_parents', 'Biếu bố mẹ'),
    T('o6', '2026-10-06', 'expense', 200000, 'w_momo', '', 'date_movie', 'CGV Vincom Bà Triệu', { linkId: 'L3' }),
    T('o7', '2026-10-07', 'expense', 65000, 'w_cash', '', 'food_coffee', 'Cà phê sáng'),
    T('o8', '2026-10-08', 'expense', 399000, 'w_vib', '', 'shop_clothes', 'Áo phông Uniqlo'),
    T('o9', '2026-10-09', 'expense', 79000, 'w_vib', '', 'bill_stream', 'YouTube Premium'),
    T('o10', '2026-10-10', 'transfer', 500000, 'w_tcb', 'w_cash', '', 'Rút tiền mặt'),
    T('o11', '2026-10-11', 'expense', 150000, 'w_momo', '', 'food_out', 'Bún chả Hàng Mành', { linkId: 'L4' }),
    T('o12', '2026-10-12', 'income', 2000000, '', 'w_momo', 'side', 'Thiết kế logo cho anh Long'),
    T('o13', '2026-10-12', 'contribution', 1200000, 'w_momo', '', '', 'Góp Quỹ Đà Lạt', { linkId: 'L5' }),
    T('o14', '2026-10-13', 'expense', 30000, 'w_cash', '', 'food_snack', 'Bánh mì'),
    T('o15', '2026-10-14', 'expense', 80000, 'w_cash', '', 'move_fuel', 'Đổ xăng'),
    T('o16', '2026-10-15', 'expense', 1180000, 'w_tcb', '', 'home_power', 'Tiền điện tháng 9', { linkId: 'L6' }),
    T('o17', '2026-10-16', 'expense', 180000, 'w_vib', '', 'health_sport', 'Cầu lông tháng 10'),
    T('o18', '2026-10-17', 'expense', 59000, 'w_cash', '', 'food_coffee', 'Highlands'),
    T('o19', '2026-10-18', 'expense', 350000, 'w_vib', '', 'date_gift', 'Hoa tặng Thảo'),
    T('o20', '2026-10-19', 'expense', 110000, 'w_cash', '', 'food_coffee', 'Cà phê The Note', { linkId: 'L7' }),
    T('o21', '2026-10-19', 'adjust', 23000, 'w_cash', '', '', 'Điều chỉnh số dư'),
    T('o22', '2026-10-20', 'expense', 45000, 'w_cash', '', 'food_out', 'Phở sáng'),
    T('o23', '2026-10-20', 'expense', 120000, 'w_momo', '', 'food_out', 'Cơm trưa với team'),
    T('o24', '2026-10-20', 'expense', 25000, 'w_cash', '', 'move_parking', 'Gửi xe'),
  ];
  // Khoản cũ hơn tháng 10 (chỉ dùng cho màn Tìm kiếm, khoảng mặc định 3 tháng)
  const ownOlder = [
    T('o-s1', '2026-09-21', 'expense', 140000, 'w_momo', '', 'food_out', 'Bún chả Đắc Kim'),
    T('o-a1', '2026-08-30', 'expense', 120000, 'w_cash', '', 'food_out', 'Bún chả que tre'),
    T('o-a2', '2026-08-12', 'expense', 65000, 'w_cash', '', 'food_out', 'Bún bò Huế'),
  ];
  const ownBudgets = [
    { categoryId: '', amount: 11000000 },
    { categoryId: 'food', amount: 1800000 },
    { categoryId: 'date', amount: 800000 },
    { categoryId: 'shop', amount: 1000000 },
  ];
  // Aggregate tháng (chi, thu) từ 11/2025 tới 09/2026 (D19 — tháng đã qua cache).
  const ownHistory = [
    ['2025-11', 7850000, 18500000], ['2025-12', 8930000, 20000000], ['2026-01', 9410000, 18500000],
    ['2026-02', 13260000, 24500000], ['2026-03', 8120000, 18500000], ['2026-04', 7640000, 20200000],
    ['2026-05', 8870000, 18500000], ['2026-06', 9050000, 19800000], ['2026-07', 8310000, 18500000],
    ['2026-08', 10480000, 18500000], ['2026-09', 8760000, 20500000],
  ];

  // ---- Sổ chung (couples/{id}), memberUids = [tuan, thao]
  const sharedWallets = [
    { id: 'v_chung', name: 'Ví chung', type: 'cash', emoji: '👛', opening: 0, includeInTotal: true }, // taste-skill-ignore
    { id: 'v_dalat', name: 'Quỹ Đà Lạt', type: 'goal', emoji: '🏔️', opening: 0, includeInTotal: false, goalTarget: 5000000, goalDeadline: '2027-01-31' }, // taste-skill-ignore
  ];
  const sharedCarry = { v_chung: 0, v_dalat: 0 }; // sổ chung bắt đầu 01/10 sau lần thanh toán 30/09
  const S = (id, date, type, amount, out, inn, categoryId, note, payer, splitMode, payerShare, extra = {}) =>
    ({ id, date, type, amount, outWalletId: out, inWalletId: inn, categoryId, note, payer, splitMode, payerShare, ...extra });
  const sharedTx = [
    S('c1', '2026-10-01', 'contribution', 1000000, '', 'v_chung', '', 'Góp đầu tháng', 'tuan', 'none', 0, { linkId: 'L1' }),
    S('c2', '2026-10-01', 'contribution', 1000000, '', 'v_chung', '', 'Góp đầu tháng', 'thao', 'none', 0),
    S('s1', '2026-10-03', 'expense', 480000, '', '', 'food_out', 'Lẩu Thái Phố Huế', 'tuan', 'equal', 240000, { linkId: 'L2' }),
    S('s2', '2026-10-04', 'expense', 70000, '', '', 'move_fuel', 'Đổ xăng cho anh', 'thao', 'for_partner', 0),
    S('s3', '2026-10-06', 'expense', 200000, '', '', 'date_movie', 'CGV Vincom Bà Triệu', 'tuan', 'treat', 200000, { linkId: 'L3' }),
    S('s4', '2026-10-08', 'expense', 640000, 'v_chung', '', 'food_market', 'Đi chợ cuối tuần', 'wallet', 'none', 0),
    S('s5', '2026-10-10', 'expense', 90000, '', '', 'food_coffee', 'Trà sữa Phúc Long', 'thao', 'equal', 45000),
    S('s6', '2026-10-11', 'expense', 150000, '', '', 'food_out', 'Bún chả Hàng Mành', 'tuan', 'equal', 75000, { linkId: 'L4' }),
    S('c3', '2026-10-12', 'contribution', 1200000, '', 'v_dalat', '', 'Góp Quỹ Đà Lạt', 'tuan', 'none', 0, { linkId: 'L5' }),
    S('s7', '2026-10-13', 'expense', 86000, '', '', 'move_grab', 'Grab về nhà', 'thao', 'equal', 43000),
    S('c4', '2026-10-14', 'contribution', 800000, '', 'v_dalat', '', 'Góp Quỹ Đà Lạt', 'thao', 'none', 0),
    S('s9', '2026-10-15', 'expense', 1180000, '', '', 'home_power', 'Tiền điện tháng 9', 'tuan', 'equal', 590000, { linkId: 'L6' }),
    S('s8', '2026-10-16', 'settle', 400000, '', '', '', 'Thảo trả lại một phần', 'thao', 'none', 0),
    S('s10', '2026-10-17', 'expense', 412000, 'v_chung', '', 'food_market', 'Siêu thị Winmart', 'wallet', 'none', 0),
    S('s12', '2026-10-18', 'expense', 60000, '', '', 'food_snack', 'Bánh mì chảo', 'thao', 'treat', 60000),
    S('s11', '2026-10-19', 'expense', 110000, '', '', 'food_coffee', 'Cà phê The Note', 'tuan', 'custom', 50000, { linkId: 'L7', updatedBy: 'thao', updatedAt: '21:02', editCount: 1 }),
    S('s13', '2026-10-20', 'expense', 96000, '', '', 'home_water', 'Tiền nước', 'thao', 'equal', 48000),
  ];
  const sharedBudgets = [{ categoryId: '', amount: 5000000 }, { categoryId: 'food', amount: 2000000 }];
  const sharedHistory = []; // sổ chung mới có từ 10/2026

  // ---- MoneyMath (bản tham chiếu cho Dev, D7)
  const month = (d) => d.slice(0, 7);
  const sumBy = (rows, pred) => rows.filter(pred).reduce((s, r) => s + r.amount, 0);
  const monthTotals = (rows, m) => {
    const inM = rows.filter((r) => month(r.date) === m);
    const expense = sumBy(inM, (r) => r.type === 'expense');
    const income = sumBy(inM, (r) => r.type === 'income');
    return { expense, income, left: income - expense };
  };
  const walletBalance = (w, rows, carry) => (carry[w.id] ?? w.opening)
    + sumBy(rows, (r) => r.inWalletId === w.id) - sumBy(rows, (r) => r.outWalletId === w.id);
  const byCategory = (rows, m, parentLevel = true) => {
    const map = new Map();
    rows.filter((r) => r.type === 'expense' && month(r.date) === m).forEach((r) => {
      const key = parentLevel ? parentOf(r.categoryId).id : r.categoryId;
      map.set(key, (map.get(key) || 0) + r.amount);
    });
    return [...map.entries()].map(([id, amount]) => ({ id, amount })).sort((a, b) => b.amount - a.amount);
  };
  // Cân bằng sổ chung: số dương = người ấy đang được mình ứng (mình ứng nhiều hơn).
  const balance = (rows, me) => rows
    .filter((r) => (r.type === 'expense' || r.type === 'settle') && r.payer !== 'wallet')
    .reduce((s, r) => s + (r.payer === me ? 1 : -1) * (r.amount - r.payerShare), 0);
  const paidBy = (rows, m) => {
    const out = { tuan: 0, thao: 0, wallet: 0 };
    rows.filter((r) => r.type === 'expense' && month(r.date) === m).forEach((r) => { out[r.payer] += r.amount; });
    return out;
  };
  const contributionsBy = (rows, walletId) => {
    const out = { tuan: 0, thao: 0 };
    rows.filter((r) => r.type === 'contribution' && r.inWalletId === walletId).forEach((r) => { out[r.payer] += r.amount; });
    return out;
  };
  const monthsLeft = (today, deadline) => (+deadline.slice(0, 4) * 12 + +deadline.slice(5, 7)) - (+today.slice(0, 4) * 12 + +today.slice(5, 7));

  // ---- Định dạng (D10)
  const fmt = (n, locale = 'vi') => {
    const s = Math.abs(n).toString().replace(/\B(?=(\d{3})+(?!\d))/g, locale === 'vi' ? '.' : ',');
    const sign = n < 0 ? '−' : '';
    return locale === 'vi' ? `${sign}${s} ₫` : `${sign}₫${s}`;
  };
  const fmtShort = (n, locale = 'vi') => {
    const a = Math.abs(n), sign = n < 0 ? '−' : '';
    const dec = (x) => (Math.round(x * 10) / 10).toString().replace('.', locale === 'vi' ? ',' : '.');
    if (a >= 1e9) return sign + dec(a / 1e9) + (locale === 'vi' ? ' tỷ' : 'B');
    if (a >= 1e6) return sign + dec(a / 1e6) + (locale === 'vi' ? 'tr' : 'M');
    if (a >= 1e3) return sign + dec(a / 1e3) + (locale === 'vi' ? 'k' : 'K');
    return sign + a;
  };

  // ---- parseVndInput (D10) — bản tham chiếu; Dev viết lại bằng Dart + test cùng các ca dưới.
  const UNITS = { k: 1e3, 'nghìn': 1e3, 'ngàn': 1e3, 'ngan': 1e3, 'nghin': 1e3, tr: 1e6, 'triệu': 1e6, 'trieu': 1e6, 'củ': 1e6, 'cu': 1e6, m: 1e6, 'tỷ': 1e9, 'ty': 1e9, 'tỏi': 1e9, 'toi': 1e9, b: 1e9 };
  const MAX = 10000000000;
  function parseVndInput(raw) {
    const s = String(raw || '').trim().toLowerCase().replace(/\s+/g, ' ');
    if (!s) return { ok: false, reason: 'empty' };
    const m = s.match(/^(\d+(?:[.,]\d+)*)\s*([a-zà-ỹđ]+)?\s*(\d+)?$/u);
    if (!m) return { ok: false, reason: 'invalid' };
    const [, num, unitRaw, tail] = m;
    let value;
    if (unitRaw) {
      const unit = UNITS[unitRaw];
      if (!unit) return { ok: false, reason: 'invalid' };
      const n = parseFloat(num.replace(',', '.'));                 // "1.5tr", "1,5tr": dấu là thập phân
      if (num.split(/[.,]/).length > 2) return { ok: false, reason: 'invalid' };
      value = Math.round(n * unit);
      if (tail) value += Math.round(+('0.' + tail) * unit);        // "1tr2" = 1.200.000, "2tr05" = 2.050.000
    } else {
      if (tail) return { ok: false, reason: 'invalid' };
      if (/^\d{1,3}([.,]\d{3})+$/.test(num) || /^\d+$/.test(num)) value = +num.replace(/[.,]/g, ''); // "120.000"
      else return { ok: false, reason: 'invalid' };
    }
    if (value <= 0) return { ok: false, reason: 'zero' };
    if (value > MAX) return { ok: false, reason: 'tooBig', value };
    return { ok: true, value };
  }

  // ---- Tìm không dấu (D19): so chuỗi đã bỏ dấu, không phân biệt hoa thường
  const fold = (x) => String(x).normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();
  const search = (rows, q) => rows.filter((r) => fold(r.note + ' ' + (r.categoryId ? cat(r.categoryId).vi : '')).includes(fold(q)));

  // ---- Kiểm tra (đọc console khi mở mockup)
  const cases = [['50k', 50000], ['1tr', 1000000], ['1tr2', 1200000], ['1.5tr', 1500000], ['1,5tr', 1500000], ['2 triệu', 2000000],
    ['1 củ', 1000000], ['1 tỏi', 1000000000], ['120000', 120000], ['120.000', 120000], ['50 nghìn', 50000], ['2tr05', 2050000], ['75001', 75001]];
  cases.forEach(([i, v]) => console.assert(parseVndInput(i).ok && parseVndInput(i).value === v, 'parse', i, parseVndInput(i)));
  ['abc', '0', '', '0k', '1.2.3tr'].forEach((i) => console.assert(!parseVndInput(i).ok, 'parse phải khoá Lưu', i));
  console.assert(parseVndInput('10000000001').reason === 'tooBig', 'trần 10 tỷ');
  console.assert(fmt(1250000) === '1.250.000 ₫' && fmt(1250000, 'en') === '₫1,250,000' && fmt(-320000) === '−320.000 ₫', 'fmt');
  console.assert(fmtShort(1200000) === '1,2tr' && fmtShort(1200000, 'en') === '1.2M' && fmtShort(50000) === '50k', 'fmtShort');

  const M = '2026-10';
  const own = monthTotals(ownTx, M), shared = monthTotals(sharedTx, M);
  const ownBal = Object.fromEntries(ownWallets.map((w) => [w.id, walletBalance(w, ownTx, ownCarry)]));
  const sharedBal = Object.fromEntries(sharedWallets.map((w) => [w.id, walletBalance(w, sharedTx, sharedCarry)]));
  const ownAssets = ownWallets.filter((w) => w.includeInTotal && w.type !== 'goal').reduce((s, w) => s + ownBal[w.id], 0);
  const bal = balance(sharedTx, ME);
  const paid = paidBy(sharedTx, M);
  const dalat = contributionsBy(sharedTx, 'v_dalat');

  // Các con số hiện hai nơi phải là một biến (luật §2.1).
  console.assert(own.left === own.income - own.expense, 'còn lại = thu − chi');
  console.assert(paid.tuan + paid.thao + paid.wallet === shared.expense, 'ba làn cộng lại = chi chung tháng');
  console.assert(dalat.tuan + dalat.thao === sharedBal.v_dalat, 'góp Quỹ Đà Lạt = số dư quỹ');
  console.assert(bal === 359000, 'cân bằng mẫu khớp spec: 359.000', bal);
  console.assert(sharedBal.v_chung === 2000000 - 1052000, 'Ví chung = góp − chi từ ví');
  console.assert(byCategory(ownTx, M).reduce((s, x) => s + x.amount, 0) === own.expense, 'cơ cấu cộng lại = chi tháng');
  // Khoản riêng nối với khoản chung (linkId) phải cùng số tiền.
  ownTx.filter((r) => r.linkId).forEach((r) => { const s = sharedTx.find((x) => x.linkId === r.linkId); console.assert(s && s.amount === r.amount, 'linkId lệch tiền', r.id); });
  console.assert(search([...ownTx, ...ownOlder], 'bun cha').length === 3, 'tìm "bun cha" ra 3 khoản Bún chả');
  // ceil chia đôi số lẻ (D7)
  console.assert(Math.ceil(75001 / 2) === 37501, 'chia đôi số lẻ');

  window.D = {
    TODAY, ME, PARTNER, people, categories, INCOME_IDS, cat, parentOf, M,
    own: { wallets: ownWallets, tx: ownTx, older: ownOlder, budgets: ownBudgets, history: ownHistory, totals: own, balances: ownBal, assets: ownAssets },
    shared: { wallets: sharedWallets, tx: sharedTx, budgets: sharedBudgets, history: sharedHistory, totals: shared, balances: sharedBal, balance: bal, paid, dalat },
    fold, search, monthTotals, walletBalance, byCategory, balance, paidBy, contributionsBy, monthsLeft, fmt, fmtShort, parseVndInput, sumBy, month,
  };
})();
