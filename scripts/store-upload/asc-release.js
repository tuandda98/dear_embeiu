#!/usr/bin/env node
// Phát hành App Store qua altool + App Store Connect API (thay Transporter + Chrome — upload-ios-transporter.sh giữ làm dự phòng).
// Khoá: ~/.appstoreconnect/asc.env (ASC_KEY_ID, ASC_ISSUER_ID) + ~/.appstoreconnect/private_keys/AuthKey_<id>.p8.
// What's New lấy từ RELEASE_NOTES_<ver>.md: code block 3 = vi, block 4 = en (bản App Store, KHÔNG emoji — ASC từ chối emoji).
//
// Dùng (chạy từ gốc repo; version/build mặc định đọc từ pubspec.yaml):
//   node scripts/store-upload/asc-release.js                 # upload IPA → chờ build xử lý → tạo version → What's New → gắn build → gửi duyệt
//   node scripts/store-upload/asc-release.js --dry-run       # chỉ ĐỌC: in ra sẽ làm gì, không upload/ghi gì
//   node scripts/store-upload/asc-release.js --skip-upload   # IPA đã upload rồi (vd qua Transporter), làm tiếp phần ASC
//   node scripts/store-upload/asc-release.js --no-submit     # làm hết trừ bước gửi duyệt
// Tuỳ chọn: --version X.Y.Z · --build N · --ipa <path> (mặc định .ipa mới nhất trong build/ios/ipa) · --notes <file>
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execFileSync } = require('child_process');

const BUNDLE = 'com.tony.dearembeiu';
const API = 'https://api.appstoreconnect.apple.com/v1';
const env = Object.fromEntries(fs.readFileSync(path.join(process.env.HOME, '.appstoreconnect/asc.env'), 'utf8')
  .split('\n').filter((l) => l.includes('=')).map((l) => l.split('=')));
const KEY_ID = env.ASC_KEY_ID;
const ISSUER = env.ASC_ISSUER_ID;
const P8 = fs.readFileSync(path.join(process.env.HOME, `.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`), 'utf8');

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(`--${k}`); return i < 0 ? d : args[i + 1]; };
const [pv, pb] = fs.readFileSync('pubspec.yaml', 'utf8').match(/^version:\s*([\d.]+)\+(\d+)/m).slice(1);
const version = opt('version', pv);
const build = opt('build', pb);
const dryRun = args.includes('--dry-run');
const skipUpload = args.includes('--skip-upload');
const noSubmit = args.includes('--no-submit'); // dừng sau khi gắn build (vd để tải ảnh/video bằng asc-media.js rồi mới gửi)
const notesFile = opt('notes', `RELEASE_NOTES_${version}.md`);
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function jwt() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })}.${b64({ iss: ISSUER, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' })}`;
  const sig = crypto.sign('sha256', Buffer.from(unsigned), { key: P8, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${unsigned}.${sig}`;
}

async function api(method, p, body) {
  const r = await fetch(p.startsWith('http') ? p : API + p, {
    method, headers: { Authorization: `Bearer ${jwt()}`, 'Content-Type': 'application/json' },
    body: body && JSON.stringify(body),
  });
  const t = await r.text();
  if (!r.ok) throw new Error(`${method} ${p} → ${r.status} ${t.slice(0, 600)}`);
  return t ? JSON.parse(t) : {};
}

function readNotes() {
  const blocks = [...fs.readFileSync(notesFile, 'utf8').matchAll(/```\n([\s\S]*?)```/g)].map((m) => m[1].trim());
  if (blocks.length < 4) throw new Error(`${notesFile}: cần 4 code block (Play vi, Play en, ASC vi, ASC en)`);
  const [, , vi, en] = blocks;
  for (const t of [vi, en]) if (/\p{Extended_Pictographic}/u.test(t)) throw new Error('What\'s New bản App Store còn emoji — ASC sẽ từ chối');
  return { vi, en };
}

(async () => {
  const notes = readNotes();
  const say = (s) => console.log((dryRun ? '[dry-run] ' : '') + s);

  // 1. Upload IPA
  if (!skipUpload) {
    const ipa = opt('ipa', fs.readdirSync('build/ios/ipa').filter((f) => f.endsWith('.ipa'))
      .map((f) => `build/ios/ipa/${f}`).sort((a, b) => fs.statSync(b).mtimeMs - fs.statSync(a).mtimeMs)[0]);
    say(`→ upload ${ipa} bằng altool`);
    if (!dryRun) execFileSync('xcrun', ['altool', '--upload-app', '-f', ipa, '-t', 'ios', '--apiKey', KEY_ID, '--apiIssuer', ISSUER], { stdio: 'inherit' });
  }

  const app = (await api('GET', `/apps?filter[bundleId]=${BUNDLE}`)).data[0];
  say(`✓ app ${app.id} (${app.attributes.name})`);

  // 2. Chờ build xử lý xong
  let b;
  for (let i = 0; ; i++) {
    b = (await api('GET', `/builds?filter[app]=${app.id}&filter[version]=${build}&filter[preReleaseVersion.version]=${version}`)).data[0];
    const st = b?.attributes.processingState;
    if (st === 'VALID') break;
    if (st === 'FAILED' || st === 'INVALID') throw new Error(`build ${build} ${st}`);
    if (dryRun) { say(`build ${version}(${build}): ${st || 'chưa có'} — thật sẽ chờ tới VALID`); break; }
    if (i >= 60) throw new Error('chờ build quá 30 phút');
    if (i % 4 === 0) console.log(`… build ${build}: ${st || 'chưa thấy'} — chờ`);
    await sleep(30000);
  }
  if (b) say(`✓ build ${version}(${build}) ${b.id} ${b.attributes.processingState}`);

  // 3. Version (tạo nếu chưa có)
  let ver = (await api('GET', `/apps/${app.id}/appStoreVersions?filter[versionString]=${version}&filter[platform]=IOS`)).data[0];
  if (ver) say(`✓ version ${version} có sẵn (${ver.attributes.appStoreState})`);
  else if (dryRun) say(`→ sẽ tạo version ${version}`);
  else {
    ver = (await api('POST', '/appStoreVersions', { data: { type: 'appStoreVersions',
      attributes: { platform: 'IOS', versionString: version },
      relationships: { app: { data: { type: 'apps', id: app.id } } } } })).data;
    say(`✓ tạo version ${version}`);
  }

  // 4. What's New cho mọi localization đang có (vi → bản vi, còn lại → bản en)
  if (ver) {
    for (const loc of (await api('GET', `/appStoreVersions/${ver.id}/appStoreVersionLocalizations`)).data) {
      const text = loc.attributes.locale.startsWith('vi') ? notes.vi : notes.en;
      say(`→ What's New ${loc.attributes.locale} (${text.length} ký tự)`);
      if (!dryRun) await api('PATCH', `/appStoreVersionLocalizations/${loc.id}`, { data: { type: 'appStoreVersionLocalizations', id: loc.id, attributes: { whatsNew: text } } });
    }
  }

  if (dryRun) { say('→ sẽ gắn build + gửi duyệt. Dừng (dry-run).'); return; }

  // 5. Gắn build
  await api('PATCH', `/appStoreVersions/${ver.id}/relationships/build`, { data: { type: 'builds', id: b.id } });
  console.log(`✓ gắn build ${build}`);
  if (noSubmit) { console.log('→ --no-submit: dừng trước khi gửi duyệt'); return; }

  // 6. Gửi duyệt (dùng lại submission đang mở nếu có)
  let sub = (await api('GET', `/reviewSubmissions?filter[app]=${app.id}&filter[platform]=IOS&filter[state]=READY_FOR_REVIEW`)).data[0];
  if (!sub) sub = (await api('POST', '/reviewSubmissions', { data: { type: 'reviewSubmissions', attributes: { platform: 'IOS' },
    relationships: { app: { data: { type: 'apps', id: app.id } } } } })).data;
  await api('POST', '/reviewSubmissionItems', { data: { type: 'reviewSubmissionItems', relationships: {
    reviewSubmission: { data: { type: 'reviewSubmissions', id: sub.id } },
    appStoreVersion: { data: { type: 'appStoreVersions', id: ver.id } } } } });
  await api('PATCH', `/reviewSubmissions/${sub.id}`, { data: { type: 'reviewSubmissions', id: sub.id, attributes: { submitted: true } } });
  console.log(`✓ đã gửi duyệt ${version}(${build}) — Waiting for Review`);
})().catch((e) => { console.error('✗', e.message); process.exit(1); });
