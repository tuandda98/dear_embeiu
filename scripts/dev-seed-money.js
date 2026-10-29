#!/usr/bin/env node
// Sổ tiền DEV (tonyembeiu-dev): xoá sạch dữ liệu Sổ tiền của 4 tài khoản test
// rồi seed lại theo mô hình D34 (chỉ Chi + Góp quỹ, không Thu / Thanh toán /
// chia tiền).
//
//   NODE_OPTIONS=--dns-result-order=ipv4first node scripts/dev-seed-money.js
//
//   test1, test2: sổ riêng trống (gặp màn lần đầu).
//   test3 (Tuấn) + test4 (Thảo), couple `widget_couple_dev`:
//     sổ riêng mỗi người: ví + vài chục khoản chi 2 tháng gần nhất + 1 mục tiêu
//     (có góp) + hạn mức tháng + 1 thử thách đang chạy;
//     sổ chung: Ví chung + quỹ "Đi Đà Lạt", khoản chi từ quỹ và từ tiền riêng,
//     góp quỹ của cả hai, hạn mức tháng, 1 thử thách "ăn ngoài dưới 500k".
// Chạy sau scripts/dev-seed-widget-accounts.js (cần tài khoản + couple có sẵn).
// Credential: refresh-token của `npx firebase-tools login`. TỪ CHỐI chạy prod.
'use strict';
const fs = require('fs'); const os = require('os'); const path = require('path');
const REPO = path.resolve(__dirname, '..');
const admin = require(path.join(REPO, 'functions', 'node_modules', 'firebase-admin'));
const PROJECT = process.env.FB_PROJECT || 'tonyembeiu-dev';
if (PROJECT === 'tonyembeiu') { console.error('TỪ CHỐI: script seed chỉ dành cho DEV.'); process.exit(2); }
const FT_CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FT_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

function bootstrap() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    const cfg = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config/configstore/firebase-tools.json'), 'utf8'));
    const refreshToken = cfg.tokens && cfg.tokens.refresh_token;
    if (!refreshToken) throw new Error('Chưa login firebase-tools');
    const adcPath = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'fb-adc-')), 'adc.json');
    fs.writeFileSync(adcPath, JSON.stringify({ type: 'authorized_user', client_id: FT_CLIENT_ID, client_secret: FT_CLIENT_SECRET, refresh_token: refreshToken, quota_project_id: PROJECT }), { mode: 0o600 });
    process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
    process.on('exit', () => { try { fs.rmSync(path.dirname(adcPath), { recursive: true, force: true }); } catch (_) {} });
  }
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT });
  return { db: admin.firestore(), auth: admin.auth() };
}

const NOW = admin.firestore.Timestamp.now();
const dayKey = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const daysAgo = (n) => { const d = new Date(); d.setDate(d.getDate() - n); return dayKey(d); };
const COLLS = ['moneyWallets', 'moneyTx', 'moneyBudgets', 'moneyMeta', 'moneyChallenges', 'moneyRecurring', 'moneyDebts'];

async function wipe(db, bookRef) {
  for (const c of COLLS) await db.recursiveDelete(bookRef.collection(c));
}

// [day, category, amount, note]
const OWN_SPEND = [
  [1, 'food_coffee', 45000, 'Trà sữa'], [2, 'food_out', 85000, 'Cơm trưa'], [3, 'move_fuel', 70000, ''],
  [5, 'food_market', 320000, 'Đi chợ'], [6, 'bill_phone', 150000, ''], [8, 'food_out', 120000, 'Bún chả'],
  [10, 'shop_clothes', 450000, 'Áo khoác'], [12, 'food_coffee', 55000, ''], [15, 'move_grab', 64000, ''],
  [18, 'food_out', 95000, ''], [21, 'home_net', 220000, 'Internet'], [24, 'food_snack', 30000, ''],
  [27, 'food_out', 110000, ''], [30, 'food_market', 280000, ''], [33, 'food_coffee', 40000, ''],
  [36, 'move_fuel', 80000, ''], [39, 'food_out', 150000, ''],
];
const SHARED_SPEND = [
  // [day, category, amount, note, payer: 'wallet' | 'a' | 'b']
  [0, 'food_out', 260000, 'Lẩu tối', 'wallet'], [2, 'date_movie', 180000, 'Xem phim', 'a'],
  [4, 'food_market', 420000, 'Đi siêu thị', 'wallet'], [7, 'date_out', 350000, 'Đi chơi hồ Tây', 'b'],
  [11, 'food_out', 190000, 'Phở', 'wallet'], [16, 'home_power', 600000, 'Tiền điện', 'wallet'],
  [20, 'date_gift', 300000, 'Hoa', 'a'], [25, 'food_out', 240000, '', 'wallet'],
  [31, 'travel_ticket', 900000, 'Vé xe', 'b'], [35, 'food_out', 210000, '', 'wallet'],
];

async function seedOwn(db, uid, name) {
  const book = db.collection('users').doc(uid);
  await wipe(db, book);
  const b = db.batch();
  const w = (id, data) => b.set(book.collection('moneyWallets').doc(id), { includeInTotal: true, archived: false, color: '', createdBy: uid, createdAt: NOW, ...data });
  w('cash', { name: 'Tiền mặt', type: 'cash', emoji: '💵', openingBalance: 1500000, order: 0 });
  w('bank', { name: name === 'Tuấn' ? 'Techcombank' : 'Vietcombank', type: 'bank', emoji: '🏦', openingBalance: 12000000, order: 1 });
  w('goal', { name: name === 'Tuấn' ? 'Mua máy ảnh' : 'Khoá học tiếng Anh', type: 'goal', emoji: '🎯', openingBalance: 0, includeInTotal: false, order: 2, goalTarget: 15000000 });
  OWN_SPEND.forEach(([d, cat, amount, note], i) => {
    b.set(book.collection('moneyTx').doc(`seed_e${i}`), {
      type: 'expense', amount, date: daysAgo(d), categoryId: cat, note,
      outWalletId: i % 3 === 0 ? 'bank' : 'cash', inWalletId: '', createdBy: uid, createdAt: NOW,
    });
  });
  [[3, 1000000], [20, 1500000], [34, 1000000]].forEach(([d, amount], i) => {
    b.set(book.collection('moneyTx').doc(`seed_g${i}`), {
      type: 'transfer', amount, date: daysAgo(d), categoryId: '', note: '',
      outWalletId: 'bank', inWalletId: 'goal', createdBy: uid, createdAt: NOW,
    });
  });
  b.set(book.collection('moneyBudgets').doc('total'), { categoryId: '', amount: 4000000, createdBy: uid, createdAt: NOW });
  b.set(book.collection('moneyChallenges').doc('seed_c1'), {
    title: '7 ngày không trà sữa, cà phê', kind: 'noSpend', categoryIds: ['food_coffee'], limit: 0,
    startDate: daysAgo(0), days: 7, templateId: 'no_coffee_7', cancelled: false, createdBy: uid, createdAt: NOW,
  });
  await b.commit();
  console.log(`[own] ${name}: 3 ví, ${OWN_SPEND.length} khoản chi, 3 lần góp, hạn mức, 1 thử thách`);
}

async function seedShared(db, coupleId, a, b2) {
  const book = db.collection('couples').doc(coupleId);
  const couple = (await book.get()).data();
  const pair = couple.memberIds;
  await wipe(db, book);
  const cut = (s) => s.slice(0, 8);
  const joint = `joint_${pair.map(cut).join('_')}`;
  const b = db.batch();
  const w = (id, data) => b.set(book.collection('moneyWallets').doc(id), { includeInTotal: true, archived: false, color: '', memberUids: pair, createdBy: a, createdAt: NOW, ...data });
  w(joint, { name: 'Ví chung', type: 'cash', emoji: '💞', openingBalance: 3000000, order: 0 });
  w('dalat', { name: 'Đi Đà Lạt', type: 'goal', emoji: '🏔️', openingBalance: 0, includeInTotal: false, order: 1, goalTarget: 10000000 });
  const who = { a, b: b2 };
  SHARED_SPEND.forEach(([d, cat, amount, note, p], i) => {
    const payer = p === 'wallet' ? 'wallet' : who[p];
    b.set(book.collection('moneyTx').doc(`seed_s${i}`), {
      type: 'expense', amount, date: daysAgo(d), categoryId: cat, note,
      outWalletId: p === 'wallet' ? joint : '', inWalletId: '', payer, memberUids: pair,
      createdBy: p === 'b' ? b2 : a, createdAt: NOW,
    });
  });
  [[1, a, 1000000], [6, b2, 1000000], [22, a, 1500000], [32, b2, 500000]].forEach(([d, uid, amount], i) => {
    b.set(book.collection('moneyTx').doc(`seed_c${i}`), {
      type: 'contribution', amount, date: daysAgo(d), categoryId: '', note: '',
      outWalletId: '', inWalletId: 'dalat', payer: uid, memberUids: pair, createdBy: uid, createdAt: NOW,
    });
  });
  b.set(book.collection('moneyBudgets').doc('total'), { categoryId: '', amount: 5000000, createdBy: a, createdAt: NOW });
  b.set(book.collection('moneyChallenges').doc('seed_c1'), {
    title: 'Tuần này ăn ngoài dưới 500k', kind: 'cap', categoryIds: ['food_out'], limit: 500000,
    startDate: daysAgo(2), days: 7, templateId: 'eat_out_cap_7', cancelled: false, createdBy: a, createdAt: NOW,
  });
  await b.commit();
  console.log(`[shared] ${coupleId}: Ví chung + quỹ Đà Lạt, ${SHARED_SPEND.length} khoản chi, 4 lần góp, hạn mức, 1 thử thách`);
}

(async () => {
  const { db, auth } = bootstrap();
  const uid = async (email) => (await auth.getUserByEmail(email)).uid;
  for (const email of ['test1@gmail.com', 'test2@gmail.com']) {
    await wipe(db, db.collection('users').doc(await uid(email)));
    console.log(`[own] ${email}: xoá sạch, sổ trống`);
  }
  const tuan = await uid('test3@gmail.com'), thao = await uid('test4@gmail.com');
  await seedOwn(db, tuan, 'Tuấn');
  await seedOwn(db, thao, 'Thảo');
  await seedShared(db, 'widget_couple_dev', tuan, thao);
  console.log('Xong.');
  process.exit(0);
})().catch((e) => { console.error(e); process.exit(1); });
