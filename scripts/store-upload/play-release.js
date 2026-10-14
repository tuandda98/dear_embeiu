#!/usr/bin/env node
// Phát hành Google Play qua Play Developer API (thay Chrome + hộp thoại macOS — script cũ upload-android-play.sh giữ làm dự phòng).
// Khoá: service account ~/.config/play/dearembeiu.json (play-publisher@tonyembeiu.iam.gserviceaccount.com).
// Ghi chú lấy từ RELEASE_NOTES_<ver>.md: code block 1 = vi, block 2 = en-US (≤500 ký tự mỗi bản).
//
// Dùng (chạy từ gốc repo):
//   node scripts/store-upload/play-release.js --version 1.11.0                 # upload AAB mặc định + phát hành đầy đủ + gửi duyệt
//   node scripts/store-upload/play-release.js --version 1.11.0 --dry-run       # làm hết rồi validate, KHÔNG commit (xoá edit)
//   node scripts/store-upload/play-release.js --version 1.10.0 --version-code 29 --dry-run   # bỏ upload, dùng bundle đã có
// Tuỳ chọn: --aab <path> (mặc định build/app/outputs/bundle/release/app-release.aab) · --notes <file> · --track production
// ⚠️ Khai báo chính sách mới (vd quyền nhạy cảm, Ứng dụng sức khoẻ) API không làm được → commit sẽ báo lỗi, xử lý trên Play Console.
const fs = require('fs');
const path = require('path');
const { GoogleAuth } = require(path.resolve(__dirname, '../../functions/node_modules/google-auth-library'));

const PKG = 'com.tony.dearembeiu';
const KEY = path.join(process.env.HOME, '.config/play/dearembeiu.json');
const BASE = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PKG}`;
const UPLOAD = `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PKG}`;

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(`--${k}`); return i < 0 ? d : args[i + 1]; };
const version = opt('version');
if (!version) { console.error('✗ thiếu --version X.Y.Z'); process.exit(1); }
const dryRun = args.includes('--dry-run');
const track = opt('track', 'production');
const existingVc = opt('version-code');
const aab = opt('aab', 'build/app/outputs/bundle/release/app-release.aab');
const notesFile = opt('notes', `RELEASE_NOTES_${version}.md`);

function readNotes() {
  const blocks = [...fs.readFileSync(notesFile, 'utf8').matchAll(/```\n([\s\S]*?)```/g)].map((m) => m[1].trim());
  if (blocks.length < 2) throw new Error(`${notesFile}: cần ≥2 code block (vi, en)`);
  const [vi, en] = blocks;
  for (const [lang, t] of [['vi', vi], ['en-US', en]]) {
    if ([...t].length > 500) throw new Error(`ghi chú ${lang} dài ${[...t].length} > 500 ký tự (giới hạn Play)`);
  }
  // Play từ chối 'vi-VN' → dùng 'vi'.
  return [{ language: 'vi', text: vi }, { language: 'en-US', text: en }];
}

(async () => {
  const releaseNotes = readNotes();
  const client = await new GoogleAuth({ keyFile: KEY, scopes: ['https://www.googleapis.com/auth/androidpublisher'] }).getClient();
  const req = (o) => client.request(o).then((r) => r.data);

  const { id: edit } = await req({ url: `${BASE}/edits`, method: 'POST' });
  console.log(`→ edit ${edit}`);
  try {
    let vc = existingVc;
    if (!vc) {
      if (!fs.existsSync(aab)) throw new Error(`không thấy ${aab}`);
      console.log(`→ upload ${aab} (${(fs.statSync(aab).size / 1e6).toFixed(1)}MB)…`);
      const b = await req({
        url: `${UPLOAD}/edits/${edit}/bundles?uploadType=media`, method: 'POST',
        headers: { 'Content-Type': 'application/octet-stream' }, body: fs.readFileSync(aab), timeout: 15 * 60 * 1000,
      });
      vc = String(b.versionCode);
      console.log(`✓ bundle versionCode ${vc}`);
    }
    await req({
      url: `${BASE}/edits/${edit}/tracks/${track}`, method: 'PUT',
      data: { track, releases: [{ name: `${vc} (${version})`, versionCodes: [vc], status: 'completed', releaseNotes }] },
    });
    console.log(`✓ track ${track}: ${vc} (${version}) phát hành đầy đủ, ghi chú vi + en-US`);

    if (dryRun) {
      await req({ url: `${BASE}/edits/${edit}:validate`, method: 'POST' });
      console.log('✓ validate OK — dry-run, xoá edit, KHÔNG gửi duyệt');
      await req({ url: `${BASE}/edits/${edit}`, method: 'DELETE' });
      return;
    }
    await req({ url: `${BASE}/edits/${edit}:commit`, method: 'POST' });
    console.log('✓ commit — đã gửi duyệt (Play chạy kiểm tra nhanh rồi xem xét)');
  } catch (e) {
    await req({ url: `${BASE}/edits/${edit}`, method: 'DELETE' }).catch(() => {});
    throw e;
  }
})().catch((e) => {
  console.error('✗', e.response?.status || '', e.response?.data?.error?.message || e.message);
  process.exit(1);
});
