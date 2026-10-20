#!/usr/bin/env node
// ĐỌC-ONLY: ảnh chụp retention trên Firestore (mặc định PROD `tonyembeiu`).
// Không ghi gì. Dùng để đo trước/sau các feature "mở app mỗi ngày"
// (widget-today, what-to-eat — xem project/features/*/overview.md §1).
//
//   NODE_OPTIONS=--dns-result-order=ipv4first node scripts/prod-retention-stats.js
//   FB_PROJECT=tonyembeiu-dev node scripts/prod-retention-stats.js
//
// In ra: user/cặp theo tháng · bucket lastSeenAt + devices.updatedAt · cặp active
// mở app theo ngày (proxy = marker `dailyAnswers/{date}` tồn tại: máy nào mở Home
// là engine ghi marker) · cả hai trả lời theo ngày · hook nào đang kéo · cohort ·
// từng cặp active: mỗi người có token push không + số câu trả lời 7 ngày.
// Credential: refresh-token của `npx firebase-tools login` (như prod-daily-answer.js).
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const REPO = path.resolve(__dirname, '..');
// eslint-disable-next-line import/no-dynamic-require
const admin = require(path.join(REPO, 'functions', 'node_modules', 'firebase-admin'));

const PROJECT = process.env.FB_PROJECT || 'tonyembeiu';
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
      type: 'authorized_user', client_id: FT_CLIENT_ID, client_secret: FT_CLIENT_SECRET,
      refresh_token: refreshToken, quota_project_id: PROJECT,
    }), { mode: 0o600 });
    process.env.GOOGLE_APPLICATION_CREDENTIALS = adcPath;
    const cleanup = () => { try { fs.rmSync(path.dirname(adcPath), { recursive: true, force: true }); } catch (_) { /* ignore */ } };
    process.on('exit', cleanup);
    process.on('SIGINT', () => { cleanup(); process.exit(130); });
  }
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT });
  return admin.firestore();
}

const DAY = 86400000;
const NOW = new Date();
const ago = (n) => new Date(NOW.getTime() - n * DAY);
const toDate = (v) => (v && typeof v.toDate === 'function') ? v.toDate() : (typeof v === 'string' ? new Date(v) : (v instanceof Date ? v : null));
const dayKey = (d) => d.toISOString().slice(0, 10);
const bucket = (d) => !d ? 'never' : d >= ago(1) ? '≤1d' : d >= ago(7) ? '≤7d' : d >= ago(30) ? '≤30d' : d >= ago(90) ? '≤90d' : '>90d';
const inc = (m, k) => { m[k] = (m[k] || 0) + 1; };
async function pmap(items, fn, c = 25) {
  const out = []; let i = 0;
  await Promise.all(Array.from({ length: Math.min(c, items.length) }, async () => {
    while (i < items.length) { const idx = i++; out[idx] = await fn(items[idx]); }
  }));
  return out;
}

(async () => {
  const db = bootstrap();
  const t0 = Date.now();
  const users = (await db.collection('users').get()).docs.map((d) => ({ id: d.id, ...d.data() }));
  const couples = (await db.collection('couples').get()).docs.map((d) => ({ id: d.id, ...d.data() }));
  console.log(`PROJECT=${PROJECT} ngày=${dayKey(NOW)} users=${users.length} couples=${couples.length}`);

  const uCreated = {}; const uSeen = {}; const uCouple = { paired: 0, nocouple: 0 };
  for (const u of users) {
    inc(uCreated, dayKey(toDate(u.createdAt) || new Date(0)).slice(0, 7));
    inc(uSeen, bucket(toDate(u.lastSeenAt)));
    u.coupleId ? uCouple.paired++ : uCouple.nocouple++;
  }
  console.log('users.createdAt theo tháng:', JSON.stringify(uCreated));
  console.log('users.lastSeenAt bucket:', JSON.stringify(uSeen));
  console.log('users có coupleId / không:', JSON.stringify(uCouple));

  const latestDevice = {};
  const devs = (await db.collectionGroup('devices').get()).docs;
  const dPlat = {}; const dNotif = {};
  for (const d of devs) {
    const x = d.data(); const uid = d.ref.parent.parent.id; const t = toDate(x.updatedAt);
    if (!latestDevice[uid] || (t && t > latestDevice[uid])) latestDevice[uid] = t || new Date(0);
    inc(dPlat, x.platform); inc(dNotif, x.notificationsEnabled ? 'on' : 'off');
  }
  const dSeen = {}; for (const uid in latestDevice) inc(dSeen, bucket(latestDevice[uid]));
  console.log(`devices=${devs.length} users_with_device=${Object.keys(latestDevice).length} platform=${JSON.stringify(dPlat)} notif=${JSON.stringify(dNotif)}`);
  console.log('devices.updatedAt bucket (token refresh ~ mỗi lần mở app):', JSON.stringify(dSeen));

  const cStatus = {}; const cCreated = {};
  for (const c of couples) { inc(cStatus, c.status || '?'); inc(cCreated, dayKey(toDate(c.createdAt) || new Date(0)).slice(0, 7)); }
  console.log('couples.status:', JSON.stringify(cStatus));
  console.log('couples.createdAt theo tháng:', JSON.stringify(cCreated));
  const w = {};
  for (const c of couples.filter((c) => c.status === 'waiting_partner')) inc(w, bucket(latestDevice[c.createdByUserId || (c.memberIds || [])[0]]));
  console.log('waiting_partner: người tạo theo device.updatedAt:', JSON.stringify(w));

  const active = couples.filter((c) => c.status === 'active');
  const since30 = dayKey(ago(30)); const since14 = dayKey(ago(14)); const since7 = dayKey(ago(7));
  const rows = await pmap(active, async (c) => {
    const ref = db.collection('couples').doc(c.id);
    const [markers, lastMsg, lastPhoto, moods, msgCount, photoCount, careCount, gameCount, sleep, meals] = await Promise.all([
      ref.collection('dailyAnswers').where(admin.firestore.FieldPath.documentId(), '>=', since30).get(),
      ref.collection('messages').orderBy('createdAt', 'desc').limit(1).get(),
      ref.collection('photos').orderBy('uploadDate', 'desc').limit(1).get(),
      ref.collection('moods').get(),
      ref.collection('messages').count().get(),
      ref.collection('photos').count().get(),
      ref.collection('careMessages').count().get().catch(() => null),
      ref.collection('games').count().get().catch(() => null),
      ref.collection('sleep').get().catch(() => null),
      ref.collection('meals').where(admin.firestore.FieldPath.documentId(), '>=', since30).get().catch(() => null),
    ]);
    const days = {}; let any30 = 0; let both30 = 0; let any7 = 0; let both7 = 0;
    const perUser7 = {};
    for (const m of markers.docs) {
      const k = m.id; if (!/^\d{4}-\d{2}-\d{2}$/.test(k)) continue;
      const both = !!m.data().bothAnswered; days[k] = both; any30++; if (both) both30++;
      if (k >= since7) {
        any7++; if (both) both7++;
        const r = await m.ref.collection('responses').get();
        for (const x of r.docs) inc(perUser7, x.id);
      }
    }
    const lm = lastMsg.docs[0] ? toDate(lastMsg.docs[0].data().createdAt) : null;
    const lp = lastPhoto.docs[0] ? toDate(lastPhoto.docs[0].data().uploadDate) : null;
    const lastMood = moods.docs.map((d) => d.data().date).filter(Boolean).sort().slice(-1)[0] || null;
    const lastSignal = [lm, lp, lastMood ? new Date(lastMood) : null, ...Object.keys(days).map((k) => new Date(k))].filter(Boolean).sort((a, b) => b - a)[0] || null;
    const members = (c.memberIds || []).map((u) => `${u.slice(0, 5)} push=${bucket(latestDevice[u])} dq7=${perUser7[u] || 0}`);
    return {
      id: c.id, created: dayKey(toDate(c.createdAt) || new Date(0)), days, any30, both30, any7, both7, lm, lp, lastMood, lastSignal, members,
      msgs: msgCount.data().count, photos: photoCount.data().count, care: careCount ? careCount.data().count : 0,
      games: gameCount ? gameCount.data().count : 0, sleepShare: sleep ? sleep.docs.filter((d) => d.data().share === true).length : 0,
      meals30: meals ? meals.size : 0,
    };
  });

  const dac = {}; const dacBoth = {};
  for (const r of rows) for (const k in r.days) if (k >= since14) { inc(dac, k); if (r.days[k]) inc(dacBoth, k); }
  console.log(`\n== ${active.length} cặp active: mở app theo ngày (proxy marker) · cả hai trả lời ==`);
  for (const k of Object.keys(dac).sort()) console.log(`${k}  mở:${dac[k]}  cả-hai:${dacBoth[k] || 0}`);

  const lastSig = {}; for (const r of rows) inc(lastSig, bucket(r.lastSignal));
  console.log('\ncặp active theo tín hiệu cuối (marker/msg/photo/mood):', JSON.stringify(lastSig));
  const eng = { 'DQ any7≥1': 0, 'DQ both7≥1': 0, 'DQ both30≥7': 0, 'msg≤7d': 0, 'photo≤7d': 0, 'photo≤30d': 0, 'mood≤7d': 0, 'care>0': 0, 'games>0': 0, 'sleepShare>0': 0, 'meals30≥1': 0 };
  for (const r of rows) {
    if (r.any7) eng['DQ any7≥1']++; if (r.both7) eng['DQ both7≥1']++; if (r.both30 >= 7) eng['DQ both30≥7']++;
    if (r.lm && r.lm >= ago(7)) eng['msg≤7d']++; if (r.lp && r.lp >= ago(7)) eng['photo≤7d']++; if (r.lp && r.lp >= ago(30)) eng['photo≤30d']++;
    if (r.lastMood && r.lastMood >= since7) eng['mood≤7d']++; if (r.care > 0) eng['care>0']++; if (r.games > 0) eng['games>0']++;
    if (r.sleepShare > 0) eng['sleepShare>0']++; if (r.meals30 > 0) eng['meals30≥1']++;
  }
  console.log('hook nào đang kéo (số cặp active):', JSON.stringify(eng));
  const coh = {};
  for (const r of rows) {
    const m = r.created.slice(0, 7); coh[m] = coh[m] || { n: 0, alive7: 0, alive30: 0 }; coh[m].n++;
    if (r.lastSignal && r.lastSignal >= ago(7)) coh[m].alive7++; if (r.lastSignal && r.lastSignal >= ago(30)) coh[m].alive30++;
  }
  console.log('cohort theo tháng tạo cặp → còn tín hiệu ≤7d / ≤30d:', JSON.stringify(coh));

  console.log('\nTừng cặp active (xếp theo số ngày mở 30d): id | tạo | mở30 | cả-hai30 | mở7 | cả-hai7 | msgs | photos | meals30 | thành viên (push = token refresh gần nhất, dq7 = câu trả lời 7 ngày)');
  for (const r of rows.slice().sort((a, b) => b.any30 - a.any30)) {
    console.log([r.id.slice(0, 10), r.created, r.any30, r.both30, r.any7, r.both7, r.msgs, r.photos, r.meals30, r.members.join(' · ')].join(' | '));
  }
  console.log(`\nxong ${Date.now() - t0}ms`);
  process.exit(0);
})().catch((e) => { console.error('ERR', e); process.exit(1); });
