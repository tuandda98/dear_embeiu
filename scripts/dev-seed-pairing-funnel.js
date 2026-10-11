// Tạo các tài khoản email ĐÃ XÁC THỰC, CHƯA ghép đôi trên Firebase DEV (tonyembeiu-dev)
// để thử feature pairing-funnel (QR, gợi ý mã từ bộ nhớ tạm, ghép đôi, nhắc mời).
// Mật khẩu chung: 12345678. Chạy lại = đặt lại mật khẩu + cờ xác thực (không xoá dữ liệu).
// Credential: refresh-token của `npx firebase-tools login` (như dev-seed-test-couple.js).
// ⚠️ CHỈ DEV — từ chối mọi project khác.
//   node scripts/dev-seed-pairing-funnel.js
const fs = require('fs'); const os = require('os'); const path = require('path');
const REPO = path.resolve(__dirname, '..');
const admin = require(path.join(REPO, 'functions', 'node_modules', 'firebase-admin'));
const PROJECT = 'tonyembeiu-dev';
const ACCOUNTS = [
  ['pf.creator@dearembeiu.test', 'Tạo Thử'],
  ['pf.joiner@dearembeiu.test', 'Vào Thử'],
  ['pf.creator2@dearembeiu.test', 'Tạo Hai'],
  ['pf.joiner2@dearembeiu.test', 'Vào Hai'],
  ['pf.creator3@dearembeiu.test', 'Tạo Ba'],
  ['pf.joiner3@dearembeiu.test', 'Vào Ba'],
];
const src = fs.readFileSync(path.join(__dirname, 'prod-daily-answer.js'), 'utf8');
const FT_CLIENT_ID = src.match(/FT_CLIENT_ID\s*=\s*'([^']+)'/)[1];
const FT_CLIENT_SECRET = src.match(/FT_CLIENT_SECRET\s*=\s*'([^']+)'/)[1];
const cfg = JSON.parse(fs.readFileSync(path.join(os.homedir(), '.config/configstore/firebase-tools.json')));
const adc = path.join(os.tmpdir(), `pf-adc-${process.pid}.json`);
fs.writeFileSync(adc, JSON.stringify({ type: 'authorized_user', client_id: FT_CLIENT_ID, client_secret: FT_CLIENT_SECRET, refresh_token: cfg.tokens.refresh_token, quota_project_id: PROJECT }), { mode: 0o600 });
process.env.GOOGLE_APPLICATION_CREDENTIALS = adc;
admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT });
(async () => {
  try {
    for (const [email, displayName] of ACCOUNTS) {
      let user = null;
      try { user = await admin.auth().getUserByEmail(email); } catch (_) { /* not found */ }
      if (user) await admin.auth().updateUser(user.uid, { password: '12345678', emailVerified: true });
      else user = await admin.auth().createUser({ email, password: '12345678', displayName, emailVerified: true });
      console.log('ok', email, user.uid);
    }
  } finally {
    fs.unlinkSync(adc);
  }
})().catch((e) => { console.error('ERR', e.message); process.exit(1); });
