#!/usr/bin/env node
// Seed 4 tài khoản DEV cho feature home-widget (tonyembeiu-dev), dữ liệu "như
// thật": ảnh couple lấy từ Unsplash, câu hỏi/chat tiếng Việt, ngày yêu thật.
//
//   node scripts/dev-seed-widget-accounts.js        # xoá sạch dữ liệu cũ của 4 tài khoản rồi seed lại
//
//   test1@gmail.com / 12345678  — Android, chưa ghép đôi (chờ người ấy)
//   test2@gmail.com / 12345678  — iOS, chưa ghép đôi (chờ người ấy)
//   test3@gmail.com / 12345678  — Android, ĐÃ ghép đôi với test4
//   test4@gmail.com / 12345678  — iOS, ĐÃ ghép đôi với test3
// (user đổi tên 2026-10-13; test1/test2 từng là cặp của dev-seed-test-couple.js —
//  script này dọn luôn couple cũ `test_couple_dev` + 4 tài khoản widget.* cũ.)
//
// Cặp ghép đôi: ngày yêu 14/05/2023 (1.247 ngày tính tới 12/10/2026), ảnh
// couple + 6 ảnh gallery từ Unsplash (giấy phép Unsplash, chỉ dùng DEV), 30
// ngày câu hỏi cả hai đã trả lời, 8 tin chat, ảnh nền thẻ đếm = ảnh couple.
// Hai tài khoản lẻ: couple `waiting_partner` đủ 2 tên như Setup nhập.
// Credential: refresh-token của `npx firebase-tools login` (như dev-seed-test-couple.js).
// ⚠️ TỪ CHỐI chạy trên project prod.
'use strict';
const fs = require('fs'); const os = require('os'); const path = require('path'); const crypto = require('crypto');
const REPO = path.resolve(__dirname, '..');
const admin = require(path.join(REPO, 'functions', 'node_modules', 'firebase-admin'));
const PROJECT = process.env.FB_PROJECT || 'tonyembeiu-dev';
if (PROJECT === 'tonyembeiu') { console.error('TỪ CHỐI: script seed chỉ dành cho DEV.'); process.exit(2); }
const BUCKET = `${PROJECT}.firebasestorage.app`;
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
    const cleanup = () => { try { fs.rmSync(path.dirname(adcPath), { recursive: true, force: true }); } catch (_) {} };
    process.on('exit', cleanup); process.on('SIGINT', () => { cleanup(); process.exit(130); });
  }
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT, storageBucket: BUCKET });
  return { db: admin.firestore(), auth: admin.auth(), bucket: admin.storage().bucket(BUCKET) };
}
const TS = (d) => admin.firestore.Timestamp.fromDate(d);
const dayKey = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const daysAgo = (n, h = 20) => { const d = new Date(); d.setDate(d.getDate() - n); d.setHours(h, 0, 0, 0); return d; };
const PASSWORD = '12345678';

// Tài khoản lẻ: mỗi người đã tạo couple ở Setup (nhập cả 2 tên) và đang chờ mã.
const SOLO = [
  { email: 'test1@gmail.com', displayName: 'Minh', partnerName: 'Ngọc', inviteCode: 'WGAND1', coupleId: 'widget_solo_android', coupleCode: 'WGAN01', anniversary: new Date(2025, 1, 14, 12) },
  { email: 'test2@gmail.com', displayName: 'Linh', partnerName: 'Khoa', inviteCode: 'WGIOS1', coupleId: 'widget_solo_ios', coupleCode: 'WGIO01', anniversary: new Date(2024, 10, 20, 12) },
];
// Cặp đã ghép đôi.
const PAIR = [
  { email: 'test3@gmail.com', displayName: 'Tuấn', inviteCode: 'WGPRA1' },
  { email: 'test4@gmail.com', displayName: 'Thảo', inviteCode: 'WGPRB1' },
];
const PAIR_COUPLE_ID = 'widget_couple_dev';
const PAIR_CODE = 'WGPR01';
const PAIR_ANNIVERSARY = new Date(2023, 4, 14, 12); // 14/05/2023 → 1.247 ngày vào 12/10/2026

// Ảnh Unsplash (id ảnh, tác giả, chú thích, ai đăng, bao nhiêu ngày trước). Ảnh đầu = ảnh couple.
const UNSPLASH = [
  ['1490723186985-6d7672633c86', 'Hôn lên trán ở Sedona 🏜️', 0, 120],
  ['1496602910407-bacda74a0fe4', 'Chiều vàng dưới hàng cây', 1, 90],
  ['1501901609772-df0848060b33', 'Cõng em đi khắp thế gian', 0, 60],
  ['1513279922550-250c2129b13a', 'Tối nến nhìn xuống thành phố', 1, 30],
  ['1531747056595-07f6cbbe10ad', 'Nhảy giữa rừng cây', 0, 12],
  ['1511405889574-b01de1da5441', 'Hoàng hôn của chúng mình', 1, 3],
];
const QUESTIONS = [
  ['Khoảnh khắc nào khiến bạn nhận ra mình thích người ấy?', 'What moment made you realize you liked your partner?'],
  ['Hôm nay bạn biết ơn điều gì ở người ấy?', 'What are you grateful for about your partner today?'],
  ['Nếu được đi du lịch cùng nhau ngay bây giờ, bạn muốn đến đâu?', 'If you could travel together right now, where would you go?'],
  ['Món ăn nào luôn nhắc bạn nhớ đến người ấy?', 'What food always reminds you of your partner?'],
  ['Điều nhỏ nhặt nào người ấy làm khiến bạn thấy được yêu thương?', 'What little thing your partner does makes you feel loved?'],
  ['Bài hát nào bạn muốn dành tặng cho người ấy?', 'What song would you dedicate to your partner?'],
  ['Kỷ niệm nào của chúng mình khiến bạn mỉm cười mỗi khi nhớ lại?', 'Which memory of the two of you makes you smile every time?'],
  ['Tuần này điều gì làm bạn vui nhất?', 'What made you happiest this week?'],
  ['Bạn muốn cùng người ấy làm gì vào cuối tuần tới?', 'What would you like to do together next weekend?'],
  ['Điều gì ở người ấy khiến bạn tự hào?', 'What about your partner makes you proud?'],
];
const ANSWERS_A = ['Lúc em cười khi trời mưa', 'Cảm ơn em đã nấu bữa tối', 'Đà Lạt, chắc chắn rồi', 'Bún chả ở phố cũ', 'Em hay để lại mẩu giấy nhỏ', 'Một bài của Đen', 'Chuyến xe đêm về quê', 'Được ôm em lúc tan làm', 'Đi bộ ven hồ rồi ăn kem', 'Sự kiên nhẫn của em'];
const ANSWERS_B = ['Khi anh nhường em cái ô', 'Cảm ơn anh đã đón em', 'Hội An buổi tối', 'Phở gà mẹ anh nấu', 'Anh luôn nhắn "về chưa"', 'Một bài của Vũ.', 'Sinh nhật năm ngoái', 'Được ngủ nướng cùng anh', 'Xem phim ở nhà thôi', 'Cách anh chăm em lúc ốm'];
const CHAT = [[0, 'Em ăn cơm chưa? 🍚'], [1, 'Em ăn rồi nè, anh thì sao?'], [0, 'Anh vừa xong, tối nay xem phim nha'], [1, 'Okii, em chọn phim nhé 😚'], [0, 'Ừ, anh mua bắp rang'], [1, 'Yêu anh 💕'], [0, 'Mai anh đón em 7h nha'], [1, 'Dạ, nhớ mang áo mưa đó']];

async function upsertAuth(auth, acc) {
  try {
    const u = await auth.getUserByEmail(acc.email);
    await auth.updateUser(u.uid, { password: PASSWORD, emailVerified: true, displayName: acc.displayName, disabled: false });
    return u.uid;
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    const u = await auth.createUser({ email: acc.email, password: PASSWORD, emailVerified: true, displayName: acc.displayName });
    return u.uid;
  }
}

// Dọn di sản: cặp test1/test2 cũ + 4 tài khoản widget.* (đổi tên 2026-10-13).
const LEGACY_COUPLES = ['test_couple_dev'];
const LEGACY_CODES = ['TEST22'];
const LEGACY_EMAILS = ['widget.android@gmail.com', 'widget.ios@gmail.com', 'widget.pair.a@gmail.com', 'widget.pair.b@gmail.com'];
const LEGACY_INVITES = ['TESTA2', 'TESTB3', 'WGAND1', 'WGIOS1', 'WGPRA1', 'WGPRB1'];

async function deleteLegacyUsers(auth, db) {
  for (const email of LEGACY_EMAILS) {
    try { const u = await auth.getUserByEmail(email); await db.recursiveDelete(db.collection('users').doc(u.uid)); await auth.deleteUser(u.uid); console.log(`[legacy] xoá ${email}`); }
    catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
  }
  for (const code of LEGACY_INVITES) await db.collection('invite_codes').doc(code).delete();
}

/** Xoá sạch dữ liệu cũ: couple (đệ quy), mã, ảnh Storage, inbox/devices của user. */
async function clean(db, bucket, uids, coupleIds, codes) {
  for (const id of coupleIds) {
    await db.recursiveDelete(db.collection('couples').doc(id));
    await bucket.deleteFiles({ prefix: `couple_photos/${id}/` });
  }
  for (const code of codes) await db.collection('couple_codes').doc(code).delete();
  for (const uid of uids) await db.recursiveDelete(db.collection('users').doc(uid));
}

async function uploadUnsplash(bucket, id, dest) {
  const cache = path.join(os.tmpdir(), `unsplash-${id}.jpg`);
  if (!fs.existsSync(cache)) {
    const res = await fetch(`https://images.unsplash.com/photo-${id}?w=1600&q=80&fm=jpg`, { headers: { 'User-Agent': 'Mozilla/5.0' } });
    if (!res.ok) throw new Error(`Unsplash ${id}: HTTP ${res.status}`);
    fs.writeFileSync(cache, Buffer.from(await res.arrayBuffer()));
  }
  const token = crypto.randomUUID();
  await bucket.upload(cache, { destination: dest, metadata: { contentType: 'image/jpeg', metadata: { firebaseStorageDownloadTokens: token } } });
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(dest)}?alt=media&token=${token}`;
}

(async () => {
  const { db, auth, bucket } = bootstrap();
  console.log(`[project] ${PROJECT}  bucket=${BUCKET}`);
  const now = new Date();
  const soloUids = []; for (const a of SOLO) soloUids.push(await upsertAuth(auth, a));
  const pairUids = []; for (const a of PAIR) pairUids.push(await upsertAuth(auth, a));
  const [uidA, uidB] = pairUids;
  [...SOLO, ...PAIR].forEach((a, i) => console.log(`[auth] ${a.email} → ${[...soloUids, ...pairUids][i]}`));

  await deleteLegacyUsers(auth, db);
  await clean(db, bucket, [...soloUids, ...pairUids], [...SOLO.map((s) => s.coupleId), PAIR_COUPLE_ID, ...LEGACY_COUPLES], [...SOLO.map((s) => s.coupleCode), PAIR_CODE, ...LEGACY_CODES]);
  console.log('[clean] đã xoá dữ liệu cũ của 4 tài khoản (+ di sản test_couple_dev, widget.*)');

  // --- 2 tài khoản lẻ: couple đang chờ người ấy
  let batch = db.batch();
  SOLO.forEach((acc, i) => {
    const uid = soloUids[i];
    batch.set(db.collection('users').doc(uid), { email: acc.email, displayName: acc.displayName, avatarUrl: '', coupleId: acc.coupleId, inviteCode: acc.inviteCode, status: 'waiting_partner', createdAt: TS(daysAgo(2)), updatedAt: TS(now), lastSeenAt: TS(now) });
    batch.set(db.collection('invite_codes').doc(acc.inviteCode), { userId: uid, displayName: acc.displayName, coupleId: acc.coupleId, createdAt: TS(daysAgo(2)), updatedAt: TS(now) });
    batch.set(db.collection('couples').doc(acc.coupleId), {
      person1Name: acc.displayName, person2Name: acc.partnerName, anniversaryDate: TS(acc.anniversary),
      couplePhotoPath: '', couplePhotoUrl: '', couplePhotoStoragePath: '', inviteCode: acc.inviteCode, coupleCode: acc.coupleCode,
      memberIds: [uid], memberCount: 1, createdByUserId: uid, status: 'waiting_partner', createdAt: TS(daysAgo(2)), updatedAt: TS(now),
    });
    batch.set(db.collection('couple_codes').doc(acc.coupleCode), { coupleId: acc.coupleId, createdAt: TS(daysAgo(2)), updatedAt: TS(now) });
  });
  await batch.commit();
  console.log(`[solo] ${SOLO.map((s) => `${s.email} (${s.displayName} ♥ ${s.partnerName}, mã ${s.coupleCode})`).join(' · ')}`);

  // --- Cặp ghép đôi: ảnh trước (cần URL cho couplePhotoUrl)
  const coupleRef = db.collection('couples').doc(PAIR_COUPLE_ID);
  const photoDocs = [];
  for (let i = 0; i < UNSPLASH.length; i++) {
    const [id, caption, who, ago] = UNSPLASH[i];
    const dest = `couple_photos/${PAIR_COUPLE_ID}/unsplash_${i + 1}.jpg`;
    const url = await uploadUnsplash(bucket, id, dest);
    photoDocs.push({ docId: `unsplash_photo_${i + 1}`, url, dest, caption, author: who === 0 ? uidA : uidB, authorName: PAIR[who].displayName, ago });
    console.log(`[photo] ${i + 1}/${UNSPLASH.length} ${id}`);
  }
  const cover = photoDocs[0];
  batch = db.batch();
  PAIR.forEach((acc, i) => {
    batch.set(db.collection('users').doc(pairUids[i]), { email: acc.email, displayName: acc.displayName, avatarUrl: '', coupleId: PAIR_COUPLE_ID, inviteCode: acc.inviteCode, status: 'in_couple', createdAt: TS(daysAgo(130)), updatedAt: TS(now), lastSeenAt: TS(now) });
    batch.set(db.collection('invite_codes').doc(acc.inviteCode), { userId: pairUids[i], displayName: acc.displayName, coupleId: PAIR_COUPLE_ID, createdAt: TS(daysAgo(130)), updatedAt: TS(now) });
  });
  batch.set(coupleRef, {
    person1Name: PAIR[0].displayName, person2Name: PAIR[1].displayName, anniversaryDate: TS(PAIR_ANNIVERSARY),
    couplePhotoPath: '', couplePhotoUrl: cover.url, couplePhotoStoragePath: cover.dest, inviteCode: PAIR[0].inviteCode, coupleCode: PAIR_CODE,
    memberIds: [uidA, uidB], memberCount: 2, createdByUserId: uidA, status: 'active', createdAt: TS(daysAgo(130)), updatedAt: TS(now),
  });
  batch.set(db.collection('couple_codes').doc(PAIR_CODE), { coupleId: PAIR_COUPLE_ID, createdAt: TS(daysAgo(130)), updatedAt: TS(now) });
  // Ảnh nền thẻ đếm = ảnh couple (widget lấy đúng ảnh này); gallery = 6 ảnh.
  batch.set(coupleRef.collection('prefs').doc('home'), { counterBgPhotoId: 'couple' });
  photoDocs.forEach((p) => batch.set(coupleRef.collection('photos').doc(p.docId), {
    path: '', remoteUrl: p.url, storagePath: p.dest, coupleId: PAIR_COUPLE_ID, authorUserId: p.author, authorName: p.authorName,
    uploadDate: TS(daysAgo(p.ago, 15)), caption: p.caption, updatedAt: null,
  }));
  await batch.commit();
  console.log(`[pair] ${PAIR_COUPLE_ID} active, mã ${PAIR_CODE}, ngày yêu ${dayKey(PAIR_ANNIVERSARY)}, ảnh couple + ${photoDocs.length} ảnh gallery`);

  // 30 ngày câu hỏi cả hai đã trả lời (hôm nay trống); `backfill:true` để CF không bắn inbox.
  let b = db.batch(); let ops = 0;
  const flush = async () => { if (ops) { await b.commit(); b = db.batch(); ops = 0; } };
  for (let n = 1; n <= 30; n++) {
    const d = daysAgo(n); const key = dayKey(d); const q = QUESTIONS[n % QUESTIONS.length];
    const mref = coupleRef.collection('dailyAnswers').doc(key);
    b.set(mref, { date: key, questionVi: q[0], questionEn: q[1], source: 'bank', bothAnswered: true, revealedAt: TS(daysAgo(n, 21)), updatedAt: TS(daysAgo(n, 21)) });
    b.set(mref.collection('responses').doc(uidA), { authorUserId: uidA, text: ANSWERS_A[n % ANSWERS_A.length], answeredAt: TS(daysAgo(n, 19)), backfill: true });
    b.set(mref.collection('responses').doc(uidB), { authorUserId: uidB, text: ANSWERS_B[n % ANSWERS_B.length], answeredAt: TS(daysAgo(n, 21)), backfill: true });
    ops += 3; if (ops >= 400) await flush();
  }
  CHAT.forEach(([who, text], i) => {
    b.set(coupleRef.collection('messages').doc(`seed_${String(i).padStart(2, '0')}`), { authorUserId: who === 0 ? uidA : uidB, text, createdAt: TS(daysAgo(1, 8 + i)) }); ops++;
  });
  b.set(coupleRef.collection('moods').doc(uidB), { authorUserId: uidB, mood: 'happy', note: 'Cuối tuần đi chơi nha', date: dayKey(now), updatedAt: TS(now) }); ops++;
  await flush();
  console.log('[data] 30 ngày dailyAnswers + 8 tin chat + mood');

  const ph = await coupleRef.collection('photos').count().get();
  const mk = await coupleRef.collection('dailyAnswers').where('bothAnswered', '==', true).count().get();
  console.log(`[verify] photos=${ph.data().count} bothAnswered=${mk.data().count}`);
  console.log(`\nĐĂNG NHẬP (DEV), mật khẩu ${PASSWORD}:\n  Android lẻ  ${SOLO[0].email}\n  iOS lẻ      ${SOLO[1].email}\n  Android cặp ${PAIR[0].email}\n  iOS cặp     ${PAIR[1].email}`);
})().catch((e) => { console.error('ERROR', e.message || e); process.exit(1); });
