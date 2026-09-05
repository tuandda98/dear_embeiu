#!/usr/bin/env node
// Seed 2 tài khoản test ĐÃ GHÉP ĐÔI + dữ liệu mẫu trên Firebase DEV (tonyembeiu-dev)
// để test 2 máy: test1@gmail.com / test2@gmail.com, mật khẩu 12345678.
//
//   node scripts/dev-seed-test-couple.js            # seed / re-seed (idempotent)
//   MOOD_KEY=happy node scripts/dev-seed-test-couple.js
//
// Idempotent: id cố định (couple `test_couple_dev`, mã ghép `TEST22`), mọi doc
// ghi bằng set(merge). Dữ liệu: users + invite_codes + couple + couple_codes,
// 45 ngày dailyAnswers cả hai đã trả lời (hôm nay để trống để test live),
// 2 reaction câu trả lời, mood hôm nay, 3 ảnh (upload Storage DEV), 6 tin chat,
// 1 lời quan tâm (CF notifyCareMessage sẽ ghi inbox cho test2).
// Credential: refresh-token của `npx firebase-tools login` (như prod-daily-answer.js).
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

const ACCOUNTS = [
  { email: 'test1@gmail.com', password: '12345678', displayName: 'Anh Test', inviteCode: 'TESTA2' },
  { email: 'test2@gmail.com', password: '12345678', displayName: 'Em Test', inviteCode: 'TESTB3' },
];
const COUPLE_ID = 'test_couple_dev';
const COUPLE_CODE = 'TEST22';
const ANNIVERSARY = new Date(2025, 0, 1, 12);

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
const CHAT = [[0, 'Em ăn cơm chưa? 🍚'], [1, 'Em ăn rồi nè, anh thì sao?'], [0, 'Anh vừa xong, tối nay xem phim nha'], [1, 'Okii, em chọn phim nhé 😚'], [0, 'Ừ, anh mua bắp rang'], [1, 'Yêu anh 💕']];

async function upsertAuth(auth, acc) {
  try {
    const u = await auth.getUserByEmail(acc.email);
    await auth.updateUser(u.uid, { password: acc.password, emailVerified: true, displayName: acc.displayName, disabled: false });
    return u.uid;
  } catch (e) {
    if (e.code !== 'auth/user-not-found') throw e;
    const u = await auth.createUser({ email: acc.email, password: acc.password, emailVerified: true, displayName: acc.displayName });
    return u.uid;
  }
}

async function uploadSeedPhoto(bucket, localPath, dest) {
  const token = crypto.randomUUID();
  await bucket.upload(localPath, { destination: dest, metadata: { contentType: 'image/png', metadata: { firebaseStorageDownloadTokens: token } } });
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(dest)}?alt=media&token=${token}`;
}

(async () => {
  const { db, auth, bucket } = bootstrap();
  console.log(`[project] ${PROJECT}  bucket=${BUCKET}`);
  const now = new Date();
  const uids = [];
  for (const acc of ACCOUNTS) uids.push(await upsertAuth(auth, acc));
  const [uidA, uidB] = uids;
  console.log(`[auth] ${ACCOUNTS[0].email} → ${uidA}\n[auth] ${ACCOUNTS[1].email} → ${uidB}`);

  const coupleRef = db.collection('couples').doc(COUPLE_ID);
  const batch = db.batch();
  ACCOUNTS.forEach((acc, i) => {
    batch.set(db.collection('users').doc(uids[i]), {
      email: acc.email, displayName: acc.displayName, avatarUrl: '', coupleId: COUPLE_ID, inviteCode: acc.inviteCode,
      status: 'in_couple', createdAt: TS(daysAgo(50)), updatedAt: TS(now), lastSeenAt: TS(now),
    }, { merge: true });
    batch.set(db.collection('invite_codes').doc(acc.inviteCode), {
      userId: uids[i], displayName: acc.displayName, coupleId: COUPLE_ID, createdAt: TS(daysAgo(50)), updatedAt: TS(now),
    }, { merge: true });
  });
  batch.set(coupleRef, {
    person1Name: ACCOUNTS[0].displayName, person2Name: ACCOUNTS[1].displayName, anniversaryDate: TS(ANNIVERSARY),
    couplePhotoPath: '', couplePhotoUrl: '', couplePhotoStoragePath: '', inviteCode: ACCOUNTS[0].inviteCode, coupleCode: COUPLE_CODE,
    memberIds: [uidA, uidB], memberCount: 2, createdByUserId: uidA, status: 'active', createdAt: TS(daysAgo(50)), updatedAt: TS(now),
  }, { merge: true });
  batch.set(db.collection('couple_codes').doc(COUPLE_CODE), { coupleId: COUPLE_ID, createdAt: TS(daysAgo(50)), updatedAt: TS(now) }, { merge: true });
  await batch.commit();
  console.log(`[couple] ${COUPLE_ID} active, mã ghép ${COUPLE_CODE}, ngày yêu ${dayKey(ANNIVERSARY)}`);

  // 45 ngày câu hỏi cả hai đã trả lời (hôm nay để trống)
  let b = db.batch(); let ops = 0;
  const flush = async () => { if (ops) { await b.commit(); b = db.batch(); ops = 0; } };
  for (let n = 1; n <= 45; n++) {
    const d = daysAgo(n); const key = dayKey(d); const q = QUESTIONS[n % QUESTIONS.length];
    const mref = coupleRef.collection('dailyAnswers').doc(key);
    b.set(mref, { date: key, questionVi: q[0], questionEn: q[1], source: 'bank', bothAnswered: true, revealedAt: TS(daysAgo(n, 21)), updatedAt: TS(daysAgo(n, 21)) }, { merge: true });
    b.set(mref.collection('responses').doc(uidA), { authorUserId: uidA, text: ANSWERS_A[n % ANSWERS_A.length], answeredAt: TS(daysAgo(n, 19)) }, { merge: true });
    b.set(mref.collection('responses').doc(uidB), { authorUserId: uidB, text: ANSWERS_B[n % ANSWERS_B.length], answeredAt: TS(daysAgo(n, 21)) }, { merge: true });
    ops += 3; if (ops >= 400) await flush();
  }
  // 2 reaction của test2 lên câu trả lời test1 (hôm qua, hôm kia)
  for (const n of [1, 2]) {
    const key = dayKey(daysAgo(n));
    b.set(coupleRef.collection('dailyAnswers').doc(key).collection('responses').doc(uidA).collection('answerReactions').doc(uidB),
      { reactorUserId: uidB, emoji: n === 1 ? '❤️' : '🥹', coupleId: COUPLE_ID, date: key, reactedAt: TS(daysAgo(n, 22)) }, { merge: true });
    ops++;
  }
  // Mood hôm nay của test1
  b.set(coupleRef.collection('moods').doc(uidA), { authorUserId: uidA, mood: process.env.MOOD_KEY || 'happy', note: 'Hôm nay trời đẹp', date: dayKey(now), updatedAt: TS(now) }, { merge: true }); ops++;
  // 6 tin chat
  CHAT.forEach(([who, text], i) => {
    b.set(coupleRef.collection('messages').doc(`seed_${String(i).padStart(2, '0')}`), { authorUserId: who === 0 ? uidA : uidB, text, createdAt: TS(daysAgo(1, 8 + i)) }, { merge: true }); ops++;
  });
  await flush();
  console.log('[data] 45 ngày dailyAnswers (bothAnswered) + 2 reaction + mood + 6 tin chat');

  // 3 ảnh
  const photos = [
    ['assets/branding/app_icon.png', 'Ảnh đầu tiên của chúng mình 💞', uidA, 20],
    ['assets/branding/store_icon_512x512.png', 'Cà phê cuối tuần', uidB, 9],
    ['assets/branding/feature_graphic_1024x500.png', 'Đi chơi xa', uidA, 3],
  ];
  let pb = db.batch();
  for (let i = 0; i < photos.length; i++) {
    const [local, caption, author, ago] = photos[i];
    const dest = `couple_photos/${COUPLE_ID}/seed_${i + 1}.png`;
    const url = await uploadSeedPhoto(bucket, path.join(REPO, local), dest);
    pb.set(coupleRef.collection('photos').doc(`seed_photo_${i + 1}`), {
      path: '', remoteUrl: url, storagePath: dest, coupleId: COUPLE_ID, authorUserId: author,
      authorName: author === uidA ? ACCOUNTS[0].displayName : ACCOUNTS[1].displayName, uploadDate: TS(daysAgo(ago, 15)), caption, updatedAt: null,
    }, { merge: true });
  }
  await pb.commit();
  console.log('[photos] 3 ảnh upload Storage + doc');

  // 1 lời quan tâm test1 → test2 (CF ghi inbox cho test2)
  await coupleRef.collection('careMessages').doc('seed_care_1').set({ authorUserId: uidA, title: 'Nhớ em 💕', body: 'Anh đang nghĩ về em nè, hôm nay em ổn không?', createdAt: TS(daysAgo(0, Math.max(0, now.getHours() - 1))) }, { merge: true });
  console.log('[care] 1 lời quan tâm');

  // Kiểm tra lại
  const mk = await coupleRef.collection('dailyAnswers').where('bothAnswered', '==', true).count().get();
  const ph = await coupleRef.collection('photos').count().get();
  console.log(`[verify] bothAnswered=${mk.data().count} photos=${ph.data().count}`);
  console.log(`\nĐĂNG NHẬP (DEV): ${ACCOUNTS.map((a) => `${a.email} / ${a.password}`).join('  |  ')}\nMã ghép đôi: ${COUPLE_CODE}`);
})().catch((e) => { console.error('ERROR', e.message || e); process.exit(1); });
