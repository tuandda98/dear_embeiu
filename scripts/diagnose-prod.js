#!/usr/bin/env node
/**
 * Chẩn đoán sự cố production: "không đăng ảnh được" + "push không hoạt động".
 *
 * Chỉ ĐỌC (trừ 1 file test tí hon ghi rồi xoá ngay trong Storage, và --test-push
 * nếu bạn bật). Mục tiêu: trong ~1 phút tách bạch được lỗi nằm ở đâu —
 *   1) RULES trên prod có khác file trong repo không (bị sửa tay trên Console,
 *      hoặc quên deploy) → đây là nguyên nhân số 1 của "permission-denied".
 *   2) STORAGE có ghi được không (bucket sai tên / billing Blaze bị ngắt →
 *      upload chết, mà Firestore vẫn chạy nên app trông như chỉ hỏng đăng ảnh).
 *   3) DỮ LIỆU: ảnh cuối cùng lên lúc nào, device token còn cập nhật không
 *      (token cũ hàng tháng = client ghi devices thất bại → push chết âm thầm).
 *   4) FCM: gửi thử tới đúng token của máy bạn, in mã lỗi thật
 *      (messaging/third-party-auth-error = APNs key hết hạn/sai — iOS chết sạch;
 *       registration-token-not-registered = token chết, cần mở app đăng ký lại).
 *
 * Chạy:
 *   cd functions && npm i
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json \
 *     node ../scripts/diagnose-prod.js --project tonyembeiu --email dodaoanhtuan@gmail.com
 *
 *   Thêm --test-push để bắn thử 1 push tới mọi device của account đó.
 *   Thêm --skip-storage-write nếu không muốn ghi file test.
 */

const fs = require('fs');
const path = require('path');

function loadAdmin() {
  try {
    return require('firebase-admin');
  } catch (_) {
    return require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
  }
}

function parseArgs(argv) {
  const args = { testPush: false, skipStorageWrite: false };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--test-push') args.testPush = true;
    else if (a === '--skip-storage-write') args.skipStorageWrite = true;
    else if (a === '--project') args.project = argv[++i];
    else if (a === '--email') args.email = argv[++i];
    else throw new Error(`Tham số lạ: ${a}`);
  }
  if (!args.project) throw new Error('Thiếu --project (vd: tonyembeiu)');
  return args;
}

const line = (s = '') => console.log(s);
const head = (s) => { line(); line(`── ${s} ${'─'.repeat(Math.max(0, 58 - s.length))}`); };
const ok = (s) => line(`  ✓ ${s}`);
const bad = (s) => line(`  ✗ ${s}`);
const info = (s) => line(`  • ${s}`);

/** Rules đang CHẠY trên prod, lấy qua Firebase Rules REST API. */
async function fetchLiveRules(admin, projectId) {
  const token = await admin.app().options.credential.getAccessToken();
  const auth = { Authorization: `Bearer ${token.access_token}` };

  const releasesRes = await fetch(
    `https://firebaserules.googleapis.com/v1/projects/${projectId}/releases`, { headers: auth });
  if (!releasesRes.ok) {
    throw new Error(`Không đọc được releases (${releasesRes.status}) — service account cần quyền firebaserules.viewer`);
  }
  const releases = (await releasesRes.json()).releases || [];

  const out = {};
  for (const release of releases) {
    const name = release.name.split('/').pop(); // cloud.firestore | firebase.storage/<bucket>
    const rulesetRes = await fetch(
      `https://firebaserules.googleapis.com/v1/${release.rulesetName}`, { headers: auth });
    if (!rulesetRes.ok) continue;
    const ruleset = await rulesetRes.json();
    const file = (ruleset.source && ruleset.source.files && ruleset.source.files[0]) || {};
    out[name] = { content: file.content || '', updateTime: ruleset.createTime, release: release.name };
  }
  return out;
}

function compareRules(label, liveEntry, repoFile) {
  if (!liveEntry) { bad(`${label}: không tìm thấy release đang chạy`); return; }
  const live = liveEntry.content.replace(/\r\n/g, '\n').trim();
  const repo = fs.readFileSync(path.join(__dirname, '..', repoFile), 'utf8').replace(/\r\n/g, '\n').trim();
  if (live === repo) {
    ok(`${label}: prod TRÙNG ${repoFile} (ruleset tạo ${liveEntry.updateTime})`);
    return;
  }
  bad(`${label}: prod KHÁC ${repoFile} (ruleset tạo ${liveEntry.updateTime}) — đây là nghi phạm số 1`);
  const liveLines = live.split('\n');
  const repoLines = repo.split('\n');
  let shown = 0;
  for (let i = 0; i < Math.max(liveLines.length, repoLines.length) && shown < 12; i++) {
    if (liveLines[i] !== repoLines[i]) {
      line(`      dòng ${i + 1}:`);
      line(`        prod: ${liveLines[i] === undefined ? '(không có)' : liveLines[i].trim()}`);
      line(`        repo: ${repoLines[i] === undefined ? '(không có)' : repoLines[i].trim()}`);
      shown++;
    }
  }
  line(`      → Sửa: deploy lại rules từ repo, hoặc kéo bản prod về nếu prod mới hơn.`);
}

async function checkStorage(admin, args) {
  const bucket = admin.storage().bucket();
  info(`bucket: ${bucket.name}`);
  const [exists] = await bucket.exists();
  if (!exists) {
    bad('bucket KHÔNG tồn tại / không truy cập được → mọi upload ảnh đều fail');
    return;
  }
  ok('bucket tồn tại');
  if (args.skipStorageWrite) { info('bỏ qua ghi thử (--skip-storage-write)'); return; }
  const testPath = `diagnostics/_write_test_${Date.now()}.txt`;
  try {
    await bucket.file(testPath).save('ok', { contentType: 'text/plain' });
    await bucket.file(testPath).delete();
    ok('ghi + xoá thử THÀNH CÔNG → bucket/billing bình thường (lỗi nếu có nằm ở rules hoặc client)');
  } catch (e) {
    bad(`ghi thử FAIL: ${e.message}`);
    line('      → Hay gặp: billing Blaze bị ngắt/quá hạn, hoặc bucket bị khoá. Storage chết thì');
    line('        Cloud Functions thường cũng chết theo ⇒ khớp đúng "ảnh + push cùng hỏng".');
  }
}

async function checkData(admin, db, args) {
  if (!args.email) { info('không có --email → bỏ qua phần dữ liệu account'); return; }

  const user = await admin.auth().getUserByEmail(args.email);
  info(`uid: ${user.uid} · tạo ${user.metadata.creationTime} · đăng nhập cuối ${user.metadata.lastSignInTime}`);

  const userSnap = await db.collection('users').doc(user.uid).get();
  if (!userSnap.exists) { bad('users/{uid} KHÔNG tồn tại → mọi rule isCoupleMember sẽ fail'); return; }
  const coupleId = userSnap.data().coupleId;
  info(`coupleId: ${coupleId || '(chưa có couple)'}`);

  if (coupleId) {
    const coupleSnap = await db.collection('couples').doc(coupleId).get();
    if (!coupleSnap.exists) {
      bad('couples/{coupleId} KHÔNG tồn tại nhưng user vẫn trỏ tới → đăng ảnh CHẮC CHẮN fail (rule isCoupleMember đọc doc này)');
    } else {
      const c = coupleSnap.data();
      const isMember = (c.memberIds || []).includes(user.uid);
      (isMember ? ok : bad)(`couple status=${c.status} memberIds=${JSON.stringify(c.memberIds)} → user ${isMember ? 'CÓ' : 'KHÔNG'} trong memberIds`);
      if (!isMember) line('      → Rule chặn cả upload Storage lẫn ghi doc ảnh. Đây là nguyên nhân đủ để "không đăng ảnh được".');

      const photos = await db.collection('couples').doc(coupleId).collection('photos')
        .orderBy('uploadDate', 'desc').limit(3).get();
      if (photos.empty) info('chưa có ảnh nào trong couple');
      else photos.docs.forEach((d) => {
        const p = d.data();
        const when = p.uploadDate && p.uploadDate.toDate ? p.uploadDate.toDate().toISOString() : String(p.uploadDate);
        info(`ảnh ${d.id.slice(0, 8)}… · ${when} · author ${String(p.authorUserId).slice(0, 8)}… · url ${p.remoteUrl ? 'có' : 'THIẾU'}`);
      });
    }
  }

  const devices = await db.collection('users').doc(user.uid).collection('devices').get();
  if (devices.empty) {
    bad('KHÔNG có device nào đăng ký → push không thể tới. Client ghi users/{uid}/devices thất bại (rules?) hoặc user chưa cấp quyền thông báo.');
  } else {
    devices.docs.forEach((d) => {
      const dev = d.data();
      const when = dev.updatedAt && dev.updatedAt.toDate ? dev.updatedAt.toDate() : null;
      const ageDays = when ? Math.round((Date.now() - when.getTime()) / 86400000) : null;
      info(`device ${d.id.slice(0, 8)}… · ${dev.platform} · lang=${dev.languageCode || '(thiếu)'} · notif=${dev.notificationsEnabled} · cập nhật ${when ? when.toISOString() : '?'}${ageDays !== null ? ` (${ageDays} ngày trước)` : ''}`);
      if (ageDays !== null && ageDays > 30) {
        line('      → Token cũ >30 ngày dù app vẫn dùng: client KHÔNG ghi được devices (hay gặp nhất là rule hasOnly thiếu field) ⇒ push chết âm thầm.');
      }
    });
  }
  return { uid: user.uid, devices: devices.docs };
}

async function testPush(admin, devices) {
  if (!devices || devices.length === 0) { info('không có token để thử'); return; }
  for (const doc of devices) {
    const token = doc.data().token;
    try {
      const id = await admin.messaging().send({
        token,
        notification: { title: 'Dear Embeiu', body: 'Kiểm tra push (diagnose-prod)' },
        data: { type: 'diagnostic' },
        apns: { payload: { aps: { sound: 'default' } } },
      });
      ok(`${doc.data().platform} ${doc.id.slice(0, 8)}… → GỬI ĐƯỢC (${id})`);
      line('      → FCM/APNs phía server OK. Máy không hiện = quyền thông báo trên máy, hoặc app đang foreground.');
    } catch (e) {
      bad(`${doc.data().platform} ${doc.id.slice(0, 8)}… → ${e.errorInfo ? e.errorInfo.code : e.code || e.message}`);
      const code = (e.errorInfo && e.errorInfo.code) || e.code || '';
      if (code.includes('third-party-auth')) {
        line('      → APNs key/cert của iOS hết hạn, bị xoá, hoặc sai Team ID/Key ID.');
        line('        Sửa: Firebase Console → Project settings → Cloud Messaging → Apple app configuration → nạp lại APNs Auth Key (.p8).');
      } else if (code.includes('registration-token-not-registered')) {
        line('      → Token chết (app gỡ/cài lại, hoặc token xoay). Mở app để đăng ký token mới rồi thử lại.');
      } else if (code.includes('mismatched-credential') || code.includes('sender-id-mismatch')) {
        line('      → Token này thuộc project KHÁC (rất có thể là bản dev .dev). Bạn đang test nhầm build.');
      }
    }
  }
}

async function main() {
  const args = parseArgs(process.argv);
  const admin = loadAdmin();
  admin.initializeApp({ projectId: args.project, storageBucket: `${args.project}.firebasestorage.app` });
  const db = admin.firestore();

  line(`Chẩn đoán project: ${args.project}`);

  head('1. Rules đang chạy trên prod vs repo');
  try {
    const live = await fetchLiveRules(admin, args.project);
    const firestoreKey = Object.keys(live).find((k) => k.startsWith('cloud.firestore'));
    const storageKey = Object.keys(live).find((k) => k.startsWith('firebase.storage'));
    compareRules('Firestore', live[firestoreKey], 'firestore.rules');
    compareRules('Storage  ', live[storageKey], 'storage.rules');
  } catch (e) {
    bad(`không đọc được rules: ${e.message}`);
  }

  head('2. Storage (bucket + khả năng ghi)');
  try { await checkStorage(admin, args); } catch (e) { bad(e.message); }

  head('3. Dữ liệu account / couple / devices');
  let data;
  try { data = await checkData(admin, db, args); } catch (e) { bad(e.message); }

  if (args.testPush) {
    head('4. Gửi thử FCM');
    try { await testPush(admin, data && data.devices); } catch (e) { bad(e.message); }
  } else {
    head('4. Gửi thử FCM');
    info('bỏ qua — thêm --test-push để bắn thử (sẽ hiện thông báo thật trên máy)');
  }

  line();
  line('Xong. Dòng nào có ✗ chính là chỗ cần sửa.');
}

main().catch((err) => { console.error('✗', err.message); process.exit(1); });
