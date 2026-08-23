#!/usr/bin/env node
// Data-ops cho daily-question trên Firestore (mặc định PROD `tonyembeiu`):
//   inspect  — tra couple của 1 email, in N marker `dailyAnswers` gần nhất +
//              responses + chuỗi hiện tại (tính y hệt StreakProvider._recompute)
//   restore  — backfill câu trả lời THIẾU của 1 member cho 1 ngày + stamp marker
//              `bothAnswered` để chuỗi nối lại (từ chối nếu đã có câu trả lời).
//
// Dùng:
//   node scripts/prod-daily-answer.js inspect <email> [days=14]
//   node scripts/prod-daily-answer.js restore <email> <YYYY-MM-DD> "<text>"
//   FB_PROJECT=tonyembeiu-dev node scripts/prod-daily-answer.js inspect <email>
//
// Credential: firebase-admin qua refresh-token của `npx firebase-tools login`
// (~/.config/configstore/firebase-tools.json) → dựng file ADC `authorized_user`
// tạm (0600, xoá khi thoát). KHÔNG cần service-account key. firebase-admin lấy
// từ functions/node_modules (chạy `npm i` trong functions/ nếu thiếu).
//
// ⚠️ `restore` TẠO doc `responses/{uid}` ⇒ CF `notifyDailyAnswer` (onCreate,
// KHÔNG guard theo ngày) vẫn chạy: người ấy nhận 1 inbox + 1 push "cả hai đã
// trả lời" cho ngày cũ, và push `bothAnswered=true` làm máy người ấy huỷ dải
// nhắc local HÔM NAY (1040–1049 + EOD 1050–1052; backstop 1020–1033 giữ) tới
// khi họ mở app (HomeScreen.sync arm lại). Chấp nhận — không tránh được nếu
// không deploy CF. Xem project/features/streak/dev.md (2026-08-23).
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
// eslint-disable-next-line import/no-dynamic-require
const admin = require(path.join(REPO, 'functions', 'node_modules', 'firebase-admin'));

const PROJECT = process.env.FB_PROJECT || 'tonyembeiu';
// OAuth client của firebase-tools (public constant trong firebase-tools/lib/api.js).
const FT_CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const FT_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

function bootstrap() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    const cfgPath = path.join(os.homedir(), '.config/configstore/firebase-tools.json');
    const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
    const refreshToken = cfg.tokens && cfg.tokens.refresh_token;
    if (!refreshToken) throw new Error(`Không có refresh_token trong ${cfgPath} — chạy: npx firebase-tools login`);
    const adcPath = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'fb-adc-')), 'adc.json');
    fs.writeFileSync(adcPath, JSON.stringify({
      type: 'authorized_user',
      client_id: FT_CLIENT_ID,
      client_secret: FT_CLIENT_SECRET,
      refresh_token: refreshToken,
      quota_project_id: PROJECT,
    }), { mode: 0o600 });
    process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
    const cleanup = () => { try { fs.rmSync(path.dirname(adcPath), { recursive: true, force: true }); } catch (_) { /* ignore */ } };
    process.on('exit', cleanup);
    process.on('SIGINT', () => { cleanup(); process.exit(130); });
  }
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT });
  return { db: admin.firestore(), auth: admin.auth() };
}

function iso(ts) { return ts && typeof ts.toDate === 'function' ? ts.toDate().toISOString() : (ts == null ? null : String(ts)); }
function addDays(key, n) {
  const [y, m, d] = key.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
}
function localTodayKey() {
  const now = new Date();
  const y = now.getFullYear(); const m = String(now.getMonth() + 1).padStart(2, '0'); const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

async function resolveCouple(db, auth, email) {
  const user = await auth.getUserByEmail(email);
  const userDoc = await db.collection('users').doc(user.uid).get();
  const coupleId = (userDoc.data() || {}).coupleId;
  if (!coupleId) throw new Error(`${email} (uid ${user.uid}) không có coupleId`);
  const couple = await db.collection('couples').doc(coupleId).get();
  const memberIds = (couple.data() || {}).memberIds || [];
  const names = {};
  for (const m of memberIds) {
    const md = await db.collection('users').doc(m).get();
    names[m] = (md.data() || {}).displayName || m;
  }
  return { uid: user.uid, coupleId, memberIds, names, status: (couple.data() || {}).status };
}

// Y hệt StreakProvider._recompute (window 180, bothAnswered==true, anchor
// today/yesterday/day-before, đếm lùi liên tiếp) — để verify mà không cần app.
async function computeStreak(db, coupleId, todayKey) {
  const snap = await db.collection('couples').doc(coupleId).collection('dailyAnswers')
    .orderBy('date', 'desc').limit(180).get();
  const revealed = new Set();
  for (const doc of snap.docs) {
    const d = doc.data();
    if (d.bothAnswered === true) revealed.add(((d.date || doc.id) + '').trim());
  }
  let anchor = null; let state = 'noStreak';
  if (revealed.has(todayKey)) { anchor = todayKey; state = 'activeToday'; }
  else if (revealed.has(addDays(todayKey, -1))) { anchor = addDays(todayKey, -1); state = 'inProgress'; }
  else if (revealed.has(addDays(todayKey, -2))) { anchor = addDays(todayKey, -2); state = 'atRisk'; }
  let current = 0;
  if (anchor) { let c = anchor; while (revealed.has(c)) { current++; c = addDays(c, -1); } }
  let longest = 0;
  for (const day of revealed) {
    if (revealed.has(addDays(day, -1))) continue;
    let run = 0; let c = day;
    while (revealed.has(c)) { run++; c = addDays(c, 1); }
    longest = Math.max(longest, run);
  }
  const sorted = [...revealed].sort();
  const gaps = [];
  for (let i = 1; i < sorted.length; i++) {
    const expect = addDays(sorted[i - 1], 1);
    if (expect !== sorted[i]) gaps.push(`${expect}..${addDays(sorted[i], -1)}`);
  }
  return { state, anchor, current, longest, revealedDays: revealed.size, gaps, runStart: anchor ? addDays(anchor, -(current - 1)) : null };
}

async function inspect(db, auth, email, days) {
  const c = await resolveCouple(db, auth, email);
  console.log(`[project] ${PROJECT}`);
  console.log(`[user] ${email} uid=${c.uid} → couple ${c.coupleId} (${c.status}) members=${JSON.stringify(c.names)}`);
  const snap = await db.collection('couples').doc(c.coupleId).collection('dailyAnswers')
    .orderBy('date', 'desc').limit(days).get();
  console.log(`\n[dailyAnswers] ${snap.size} marker gần nhất:`);
  for (const doc of snap.docs) {
    const d = doc.data();
    const resp = await doc.ref.collection('responses').get();
    console.log(`  ${doc.id}  bothAnswered=${d.bothAnswered === true ? 'TRUE ' : 'false'}  responses=${resp.size}  revealedAt=${iso(d.revealedAt)}`);
    for (const r of resp.docs) {
      const a = r.data();
      console.log(`      - ${c.names[r.id] || r.id}: "${(a.text || '').slice(0, 60)}" @${iso(a.answeredAt)}`);
    }
  }
  const s = await computeStreak(db, c.coupleId, localTodayKey());
  console.log(`\n[streak] today=${localTodayKey()} state=${s.state} current=${s.current} longest=${s.longest} revealedDays=${s.revealedDays} runStart=${s.runStart} gaps=${s.gaps.length ? s.gaps.join(', ') : 'none'}`);
}

async function restore(db, auth, email, date, text) {
  const t = (text || '').trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error('date phải là YYYY-MM-DD');
  if (!t || t.length > 280) throw new Error('text 1..280 ký tự (khớp rules)');
  const c = await resolveCouple(db, auth, email);
  const markerRef = db.collection('couples').doc(c.coupleId).collection('dailyAnswers').doc(date);
  const respRef = markerRef.collection('responses').doc(c.uid);
  const marker = await markerRef.get();
  if (!marker.exists) throw new Error(`marker ${date} chưa tồn tại (không có ai trả lời ngày đó) — từ chối, cần snapshot questionVi/En`);
  if ((await respRef.get()).exists) throw new Error(`${email} ĐÃ có câu trả lời ngày ${date} — từ chối ghi đè`);
  const before = await computeStreak(db, c.coupleId, localTodayKey());
  console.log(`[pre] ${date} bothAnswered=${marker.get('bothAnswered')} · streak hiện tại=${before.current} (${before.state})`);

  await respRef.create({ authorUserId: c.uid, text: t, answeredAt: admin.firestore.FieldValue.serverTimestamp() });
  const others = await markerRef.collection('responses').get();
  const allAnswered = c.memberIds.every((m) => others.docs.some((d) => d.id === m));
  if (allAnswered) {
    await markerRef.set({ bothAnswered: true, revealedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
  }
  const after = await computeStreak(db, c.coupleId, localTodayKey());
  console.log(`[post] created responses/${c.uid} "${t}" · bothAnswered=${allAnswered} · streak=${after.current} (${after.state}) runStart=${after.runStart} gaps=${after.gaps.length ? after.gaps.join(', ') : 'none'}`);
}

(async () => {
  const [cmd, email, a, b] = process.argv.slice(2);
  if (!cmd || !email) {
    console.error('usage: prod-daily-answer.js inspect <email> [days] | restore <email> <YYYY-MM-DD> "<text>"');
    process.exit(2);
  }
  const { db, auth } = bootstrap();
  if (cmd === 'inspect') await inspect(db, auth, email, parseInt(a || '14', 10));
  else if (cmd === 'restore') await restore(db, auth, email, a, b);
  else throw new Error(`lệnh lạ: ${cmd}`);
})().catch((e) => { console.error('ERROR', e.message || e); process.exit(1); });
