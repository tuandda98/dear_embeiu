#!/usr/bin/env node
// Tạo cặp tài khoản cho NGƯỜI DUYỆT STORE trên PROD (tonyembeiu) — user chốt 2026-10-13
// (Play báo "Thiếu thông tin đăng nhập"; KHÔNG dùng tài khoản thật dodaoanhtuan@gmail.com).
//
//   node scripts/prod-seed-review-accounts.js
//
//   testprod1@gmail.com / 12345678  — ĐÃ ghép đôi với testprod2
//   testprod2@gmail.com / 12345678
//
// Chỉ đụng 2 email này + couple `review_couple_prod` + mã REVPR1/REVPA1/REVPB1 của chính nó.
// Chạy lại = dọn dữ liệu cũ của cặp này rồi seed lại (ảnh Unsplash, 30 ngày câu hỏi, chat, mood).
// Từ chối ghi nếu một mã mời/mã couple đã thuộc về người khác.
// Credential: refresh-token của `npx firebase-tools login` (như prod-daily-answer.js).
'use strict';
const fs = require('fs'); const os = require('os'); const path = require('path'); const crypto = require('crypto');
const REPO = path.resolve(__dirname, '..');
const admin = require(path.join(REPO, 'functions', 'node_modules', 'firebase-admin'));
const PROJECT = 'tonyembeiu';
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


const PAIR = [
  { email: 'testprod1@gmail.com', displayName: 'Minh', inviteCode: 'REVPA1' },
  { email: 'testprod2@gmail.com', displayName: 'An', inviteCode: 'REVPB1' },
];
const PAIR_COUPLE_ID = 'review_couple_prod';
const PAIR_CODE = 'REVPR1';
const PAIR_ANNIVERSARY = new Date(2024, 1, 14, 12); // 14/02/2024

/** Mã đã tồn tại mà không thuộc cặp review → dừng, không ghi đè người thật. */
async function assertCodesFree(db, uids) {
  for (const acc of PAIR) {
    const s = await db.collection('invite_codes').doc(acc.inviteCode).get();
    if (s.exists && !uids.includes(s.get('userId'))) throw new Error(`invite_codes/${acc.inviteCode} thuộc người khác`);
  }
  const c = await db.collection('couple_codes').doc(PAIR_CODE).get();
  if (c.exists && c.get('coupleId') !== PAIR_COUPLE_ID) throw new Error(`couple_codes/${PAIR_CODE} thuộc couple khác`);
  for (const uid of uids) {
    const u = await db.collection('users').doc(uid).get();
    const cid = u.exists ? u.get('coupleId') : null;
    if (cid && cid !== PAIR_COUPLE_ID) throw new Error(`users/${uid} đang ở couple khác (${cid})`);
  }
}

(async () => {
  const { db, auth, bucket } = bootstrap();
  console.log(`[project] ${PROJECT}  bucket=${BUCKET}`);
  const now = new Date();
  // Email đã có trên PROD mà không phải tài khoản review (đang ở couple khác) → dừng TRƯỚC khi đổi mật khẩu.
  for (const a of PAIR) {
    try {
      const u = await auth.getUserByEmail(a.email);
      const doc = await db.collection('users').doc(u.uid).get();
      const cid = doc.exists ? doc.get('coupleId') : null;
      if (cid && cid !== PAIR_COUPLE_ID) throw new Error(`${a.email} là tài khoản đang dùng (couple ${cid}) — dừng`);
    } catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
  }
  const pairUids = []; for (const a of PAIR) pairUids.push(await upsertAuth(auth, a));
  const [uidA, uidB] = pairUids;
  PAIR.forEach((a, i) => console.log(`[auth] ${a.email} → ${pairUids[i]}`));
  await assertCodesFree(db, pairUids);

  const coupleRef = db.collection('couples').doc(PAIR_COUPLE_ID);
  await db.recursiveDelete(coupleRef);
  await bucket.deleteFiles({ prefix: `couple_photos/${PAIR_COUPLE_ID}/` });
  for (const uid of pairUids) await db.recursiveDelete(db.collection('users').doc(uid));
  console.log('[clean] đã dọn dữ liệu cũ của cặp review');

  const photoDocs = [];
  for (let i = 0; i < UNSPLASH.length; i++) {
    const [id, caption, who, ago] = UNSPLASH[i];
    const dest = `couple_photos/${PAIR_COUPLE_ID}/unsplash_${i + 1}.jpg`;
    const url = await uploadUnsplash(bucket, id, dest);
    photoDocs.push({ docId: `unsplash_photo_${i + 1}`, url, dest, caption, author: who === 0 ? uidA : uidB, authorName: PAIR[who].displayName, ago });
    console.log(`[photo] ${i + 1}/${UNSPLASH.length} ${id}`);
  }
  const cover = photoDocs[0];
  let batch = db.batch();
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
  batch.set(coupleRef.collection('prefs').doc('home'), { counterBgPhotoId: 'couple' });
  photoDocs.forEach((p) => batch.set(coupleRef.collection('photos').doc(p.docId), {
    path: '', remoteUrl: p.url, storagePath: p.dest, coupleId: PAIR_COUPLE_ID, authorUserId: p.author, authorName: p.authorName,
    uploadDate: TS(daysAgo(p.ago, 15)), caption: p.caption, updatedAt: null,
  }));
  await batch.commit();
  console.log(`[pair] ${PAIR_COUPLE_ID} active, mã ${PAIR_CODE}, ảnh couple + ${photoDocs.length} ảnh gallery`);

  // 30 ngày câu hỏi (hôm nay trống); `backfill:true` để CF không bắn inbox/push.
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

  const ph = await coupleRef.collection('photos').count().get();
  const mk = await coupleRef.collection('dailyAnswers').where('bothAnswered', '==', true).count().get();
  console.log(`[verify] photos=${ph.data().count} bothAnswered=${mk.data().count}`);
  console.log(`\nĐĂNG NHẬP (PROD), mật khẩu ${PASSWORD}: ${PAIR.map((p) => p.email).join(' · ')}`);
})().catch((e) => { console.error('ERROR', e.message || e); process.exit(1); });
