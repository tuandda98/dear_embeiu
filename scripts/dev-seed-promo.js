#!/usr/bin/env node
// Seed dữ liệu "đẹp" cho video quảng cáo (feature `promo-video`, 2026-10-15) trên DEV
// (tonyembeiu-dev) — CHỈ đụng cặp Tuấn ♥ Thảo của dev-seed-widget-accounts.js
// (test3@gmail.com / test4@gmail.com, couple `widget_couple_dev`). Chạy SAU script đó.
//
//   node scripts/dev-seed-promo.js [--photos <dir>]
//
// --photos <dir>: thư mục có manifest.json ([{file, photographer, orientation, …}])
//   + captions.json tuỳ chọn ({ "01.jpg": "chú thích", …, "cover": "03.jpg" }).
//   Thay TOÀN BỘ ảnh gallery + ảnh couple bằng ảnh trong thư mục (Storage DEV).
// Luôn làm:
//   - Tâm trạng hôm nay: Tuấn = Nhớ (`missing`); XOÁ mood của Thảo để quay cảnh chọn trực tiếp.
//   - Giấc ngủ: cả hai bật chia sẻ, 30 đêm gần nhất (đêm khoá theo ngày THỨC DẬY).
//   - Câu hỏi hôm nay: marker + câu trả lời của Tuấn; Thảo trả lời trực tiếp khi quay → reveal.
// Idempotent (set merge). ⚠️ TỪ CHỐI chạy trên project prod.
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
const daysAgo = (n, h = 20, m = 0) => { const d = new Date(); d.setDate(d.getDate() - n); d.setHours(h, m, 0, 0); return d; };
const argv = process.argv.slice(2);
const photosDir = (() => { const i = argv.indexOf('--photos'); return i < 0 ? null : path.resolve(argv[i + 1]); })();

const PAIR = [
  { email: 'test3@gmail.com', displayName: 'Tuấn' },
  { email: 'test4@gmail.com', displayName: 'Thảo' },
];
const COUPLE_ID = 'widget_couple_dev';

// Câu hỏi hôm nay + câu trả lời của Tuấn (Thảo trả lời trực tiếp lúc quay).
const TODAY_Q = ['Điều nhỏ nhặt nào người ấy làm khiến bạn thấy được yêu thương?', 'What little thing your partner does makes you feel loved?'];
const TODAY_A = 'Em hay để lại mẩu giấy nhỏ trong túi áo anh, mỗi lần lấy ra là cười một mình.';

// Chú thích mặc định khi captions.json không có (theo thứ tự ảnh).
const DEFAULT_CAPTIONS = [
  'Chiều nay nắng đẹp quá', 'Cà phê cuối tuần của chúng mình', 'Lạc giữa phố đêm', 'Lần đầu em chịu chụp chung',
  'Đi đâu cũng được, miễn là có nhau', 'Biển gọi, mình đi', 'Tay trong tay', 'Hoàng hôn hôm ấy', 'Ngày thường cũng vui',
  'Kỷ niệm 1000 ngày', 'Về quê anh', 'Sinh nhật em',
];
// Ảnh thứ i đăng cách nay bao nhiêu ngày (rải đều mấy tháng, 2 ảnh gần nhất trong tuần).
const AGO = [150, 128, 101, 84, 66, 49, 37, 24, 15, 9, 3, 1];

async function uploadLocal(bucket, file, dest) {
  const token = crypto.randomUUID();
  await bucket.upload(file, { destination: dest, metadata: { contentType: 'image/jpeg', metadata: { firebaseStorageDownloadTokens: token } } });
  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeURIComponent(dest)}?alt=media&token=${token}`;
}

(async () => {
  const { db, auth, bucket } = bootstrap();
  console.log(`[project] ${PROJECT}`);
  const now = new Date();
  const uids = [];
  for (const a of PAIR) uids.push((await auth.getUserByEmail(a.email)).uid);
  const [uidA, uidB] = uids;
  const coupleRef = db.collection('couples').doc(COUPLE_ID);
  const couple = await coupleRef.get();
  if (!couple.exists) throw new Error(`Chưa có couple ${COUPLE_ID} — chạy dev-seed-widget-accounts.js trước`);
  console.log(`[pair] ${PAIR[0].displayName}=${uidA} ${PAIR[1].displayName}=${uidB}`);

  // --- Ảnh (tuỳ chọn)
  if (photosDir) {
    const manifest = JSON.parse(fs.readFileSync(path.join(photosDir, 'manifest.json'), 'utf8'));
    const capPath = path.join(photosDir, 'captions.json');
    const captions = fs.existsSync(capPath) ? JSON.parse(fs.readFileSync(capPath, 'utf8')) : {};
    const old = await coupleRef.collection('photos').get();
    let b = db.batch(); old.docs.forEach((d) => b.delete(d.ref)); await b.commit();
    await bucket.deleteFiles({ prefix: `couple_photos/${COUPLE_ID}/` });
    console.log(`[photos] xoá ${old.size} ảnh cũ`);
    const docs = [];
    for (let i = 0; i < manifest.length; i++) {
      const m = manifest[i];
      const dest = `couple_photos/${COUPLE_ID}/promo_${String(i + 1).padStart(2, '0')}.jpg`;
      const url = await uploadLocal(bucket, path.join(photosDir, m.file), dest);
      docs.push({ id: `promo_photo_${String(i + 1).padStart(2, '0')}`, file: m.file, url, dest, orientation: m.orientation, who: i % 2,
        caption: captions[m.file] || DEFAULT_CAPTIONS[i % DEFAULT_CAPTIONS.length], ago: AGO[i] ?? (i + 1) });
      console.log(`[photos] ${i + 1}/${manifest.length} ${m.file}`);
    }
    const coverFile = captions.cover;
    const cover = docs.find((d) => d.file === coverFile) || docs.find((d) => d.orientation === 'portrait') || docs[0];
    b = db.batch();
    docs.forEach((p) => b.set(coupleRef.collection('photos').doc(p.id), {
      path: '', remoteUrl: p.url, storagePath: p.dest, coupleId: COUPLE_ID, authorUserId: p.who === 0 ? uidA : uidB,
      authorName: PAIR[p.who].displayName, uploadDate: TS(daysAgo(p.ago, 15 + (p.ago % 5))), caption: p.caption, updatedAt: null,
    }));
    b.set(coupleRef, { couplePhotoUrl: cover.url, couplePhotoStoragePath: cover.dest, updatedAt: TS(now) }, { merge: true });
    b.set(coupleRef.collection('prefs').doc('home'), { counterBgPhotoId: 'couple' }, { merge: true });
    await b.commit();
    console.log(`[photos] ${docs.length} ảnh mới, ảnh couple = ${cover.file}`);
  }

  // --- Tâm trạng hôm nay
  let batch = db.batch();
  batch.set(coupleRef.collection('moods').doc(uidA), { authorUserId: uidA, mood: 'missing', note: 'Nhớ em quá, tối gọi nha', date: dayKey(now), updatedAt: TS(now) });
  batch.delete(coupleRef.collection('moods').doc(uidB));

  // --- Giấc ngủ: 30 đêm, khoá theo ngày thức dậy (hôm nay = đêm qua).
  const plans = [
    { uid: uidA, color: 'purple', bed: [23, 10], wake: [6, 40] }, // purple = accentLavenderDeep: màu "người ấy" của app (phim 50 s dùng cùng vai màu)
    { uid: uidB, color: 'rose', bed: [0, 5], wake: [7, 20] },
  ];
  for (const p of plans) {
    batch.set(coupleRef.collection('sleep').doc(p.uid), { share: true, color: p.color, updatedAt: TS(now) }, { merge: true });
    for (let n = 0; n < 30; n++) {
      const wake = daysAgo(n, p.wake[0], p.wake[1] + ((n * 7) % 25) - 12); // lệch ±12 phút cho tự nhiên
      const bed = new Date(wake); bed.setDate(bed.getDate() - (p.bed[0] >= 12 ? 1 : 0)); bed.setHours(p.bed[0], p.bed[1] + ((n * 11) % 41) - 20, 0, 0);
      if (bed >= wake) bed.setDate(bed.getDate() - 1);
      // Đêm qua của Tuấn: ngủ 23:10 → dậy 06:00 (6g50) để khớp copy trong video.
      if (n === 0 && p.uid === uidA) { bed.setHours(23, 10, 0, 0); wake.setHours(6, 0, 0, 0); }
      batch.set(coupleRef.collection('sleep').doc(p.uid).collection('nights').doc(dayKey(wake)), {
        date: dayKey(wake), bedAt: TS(bed), wakeAt: TS(wake), wakeUps: [], source: 'auto', tz: -wake.getTimezoneOffset(), updatedAt: TS(now),
      });
    }
  }

  // --- Câu hỏi hôm nay: marker + Tuấn đã trả lời.
  const key = dayKey(now);
  const mref = coupleRef.collection('dailyAnswers').doc(key);
  batch.set(mref, { date: key, questionVi: TODAY_Q[0], questionEn: TODAY_Q[1], source: 'bank', bothAnswered: false, updatedAt: TS(now) }, { merge: true });
  batch.set(mref.collection('responses').doc(uidA), { authorUserId: uidA, text: TODAY_A, answeredAt: TS(daysAgo(0, 12, 20)), backfill: true });
  batch.delete(mref.collection('responses').doc(uidB));
  await batch.commit();
  console.log(`[data] mood Tuấn=missing · sleep 2×30 đêm (share on) · câu hỏi ${key}: Tuấn đã trả lời, Thảo chưa`);
})().catch((e) => { console.error('ERROR', e.message || e); process.exit(1); });
