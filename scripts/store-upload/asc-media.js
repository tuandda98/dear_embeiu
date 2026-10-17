#!/usr/bin/env node
// Thay ảnh chụp màn hình + video App Preview của 1 version App Store đang soạn (Prepare for Submission) qua ASC API.
// Giữ nguyên N ảnh đầu (mặc định 1), xoá phần còn lại, tải ảnh mới theo thứ tự tên file, rồi tải video preview.
// Chạy SAU `asc-release.js --no-submit` (version đã tạo + gắn build), TRƯỚC khi gửi duyệt.
//
//   node scripts/store-upload/asc-media.js --shots store-assets/2026-10/asc --preview store-assets/2026-10/app-preview-886x1920.mp4 [--dry-run]
// Tuỳ chọn: --version X.Y.Z (mặc định từ pubspec) · --keep N · --display APP_IPHONE_67 · --preview-type IPHONE_67
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const BUNDLE = 'com.tony.dearembeiu';
const API = 'https://api.appstoreconnect.apple.com/v1';
const env = Object.fromEntries(fs.readFileSync(path.join(process.env.HOME, '.appstoreconnect/asc.env'), 'utf8')
  .split('\n').filter((l) => l.includes('=')).map((l) => l.split('=')));
const KEY_ID = env.ASC_KEY_ID;
const P8 = fs.readFileSync(path.join(process.env.HOME, `.appstoreconnect/private_keys/AuthKey_${KEY_ID}.p8`), 'utf8');

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(`--${k}`); return i < 0 ? d : args[i + 1]; };
const version = opt('version', fs.readFileSync('pubspec.yaml', 'utf8').match(/^version:\s*([\d.]+)\+/m)[1]);
const shotsDir = opt('shots');
const preview = opt('preview');
const keep = Number(opt('keep', 1));
const display = opt('display', 'APP_IPHONE_67');
const previewType = opt('preview-type', 'IPHONE_67');
const dryRun = args.includes('--dry-run');
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const say = (s) => console.log((dryRun ? '[dry-run] ' : '') + s);

function jwt() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' })}.${b64({ iss: env.ASC_ISSUER_ID, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' })}`;
  return `${unsigned}.${crypto.sign('sha256', Buffer.from(unsigned), { key: P8, dsaEncoding: 'ieee-p1363' }).toString('base64url')}`;
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

// Tạo asset → PUT từng phần theo uploadOperations → đánh dấu uploaded kèm md5.
async function uploadAsset(kind, relName, setType, setId, file, extra = {}) {
  const buf = fs.readFileSync(file);
  const created = (await api('POST', `/${kind}`, { data: { type: kind,
    attributes: { fileName: path.basename(file), fileSize: buf.length, ...extra },
    relationships: { [relName]: { data: { type: setType, id: setId } } } } })).data;
  for (const op of created.attributes.uploadOperations) {
    const headers = Object.fromEntries(op.requestHeaders.map((h) => [h.name, h.value]));
    const r = await fetch(op.url, { method: op.method, headers, body: buf.subarray(op.offset, op.offset + op.length) });
    if (!r.ok) throw new Error(`upload ${path.basename(file)} → ${r.status}`);
  }
  const md5 = crypto.createHash('md5').update(buf).digest('hex');
  await api('PATCH', `/${kind}/${created.id}`, { data: { type: kind, id: created.id, attributes: { uploaded: true, sourceFileChecksum: md5 } } });
  return created.id;
}

async function waitDone(kind, id, file) {
  for (let i = 0; i < 60; i++) {
    const st = (await api('GET', `/${kind}/${id}`)).data.attributes.assetDeliveryState?.state;
    if (st === 'COMPLETE') return;
    if (st === 'FAILED') throw new Error(`${path.basename(file)}: Apple xử lý FAILED`);
    await sleep(5000);
  }
  throw new Error(`${path.basename(file)}: chờ xử lý quá 5 phút`);
}

(async () => {
  const app = (await api('GET', `/apps?filter[bundleId]=${BUNDLE}`)).data[0];
  const ver = (await api('GET', `/apps/${app.id}/appStoreVersions?filter[versionString]=${version}&filter[platform]=IOS`)).data[0];
  if (!ver) throw new Error(`chưa có version ${version} — chạy asc-release.js --no-submit trước`);
  say(`✓ version ${version} (${ver.attributes.appStoreState})`);
  const shots = shotsDir ? fs.readdirSync(shotsDir).filter((f) => /\.png$/i.test(f)).sort().map((f) => path.join(shotsDir, f)) : [];

  for (const loc of (await api('GET', `/appStoreVersions/${ver.id}/appStoreVersionLocalizations`)).data) {
    const L = loc.attributes.locale;
    if (shots.length) {
      let set = (await api('GET', `/appStoreVersionLocalizations/${loc.id}/appScreenshotSets`)).data
        .find((s) => s.attributes.screenshotDisplayType === display);
      if (!set) throw new Error(`${L}: không có bộ ${display} — ảnh giữ lại phải nằm trong bộ này`);
      const cur = (await api('GET', `/appScreenshotSets/${set.id}/appScreenshots`)).data;
      if (cur.length < keep) throw new Error(`${L}: bộ ${display} chỉ có ${cur.length} ảnh, không đủ để giữ ${keep}`);
      if (keep + shots.length > 10) throw new Error(`App Store tối đa 10 ảnh/bộ (${keep} + ${shots.length})`);
      say(`${L}: giữ ${cur.slice(0, keep).map((s) => s.attributes.fileName).join(', ')} · xoá ${cur.length - keep} · thêm ${shots.length}`);
      if (!dryRun) {
        for (const s of cur.slice(keep)) await api('DELETE', `/appScreenshots/${s.id}`);
        const ids = cur.slice(0, keep).map((s) => s.id);
        for (const f of shots) {
          const id = await uploadAsset('appScreenshots', 'appScreenshotSet', 'appScreenshotSets', set.id, f);
          await waitDone('appScreenshots', id, f);
          ids.push(id);
          console.log(`  ✓ ${path.basename(f)}`);
        }
        await api('PATCH', `/appScreenshotSets/${set.id}/relationships/appScreenshots`, { data: ids.map((id) => ({ type: 'appScreenshots', id })) });
        console.log(`  ✓ thứ tự ${ids.length} ảnh`);
      }
    }
    if (preview) {
      let pset = (await api('GET', `/appStoreVersionLocalizations/${loc.id}/appPreviewSets`)).data
        .find((s) => s.attributes.previewType === previewType);
      const old = pset ? (await api('GET', `/appPreviewSets/${pset.id}/appPreviews`)).data : [];
      say(`${L}: video ${path.basename(preview)} → ${previewType} (thay ${old.length} video cũ)`);
      if (!dryRun) {
        if (!pset) pset = (await api('POST', '/appPreviewSets', { data: { type: 'appPreviewSets', attributes: { previewType },
          relationships: { appStoreVersionLocalization: { data: { type: 'appStoreVersionLocalizations', id: loc.id } } } } })).data;
        for (const p of old) await api('DELETE', `/appPreviews/${p.id}`);
        const id = await uploadAsset('appPreviews', 'appPreviewSet', 'appPreviewSets', pset.id, preview,
          { mimeType: 'video/mp4', previewFrameTimeCode: opt('poster', '00:00:01:00') });
        await waitDone('appPreviews', id, preview);
        console.log('  ✓ video preview');
      }
    }
  }
})().catch((e) => { console.error('✗', e.message); process.exit(1); });
