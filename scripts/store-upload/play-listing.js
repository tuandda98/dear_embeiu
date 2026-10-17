#!/usr/bin/env node
// Thay ảnh điện thoại + video YouTube của trang Google Play qua Play Developer API (không cần build mới).
// Giữ nguyên N ảnh đầu (mặc định 1), xoá phần còn lại, tải ảnh mới theo thứ tự tên file. Play chỉ nhận video qua link YouTube.
//
//   node scripts/store-upload/play-listing.js --shots store-assets/2026-10/play [--video https://youtu.be/xxx] [--dry-run]
// Tuỳ chọn: --lang vi (mặc định: mọi ngôn ngữ đang có) · --keep N
const fs = require('fs');
const path = require('path');
const { GoogleAuth } = require(path.resolve(__dirname, '../../functions/node_modules/google-auth-library'));

const PKG = 'com.tony.dearembeiu';
const KEY = path.join(process.env.HOME, '.config/play/dearembeiu.json');
const BASE = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PKG}`;
const UPLOAD = `https://androidpublisher.googleapis.com/upload/androidpublisher/v3/applications/${PKG}`;

const args = process.argv.slice(2);
const opt = (k, d) => { const i = args.indexOf(`--${k}`); return i < 0 ? d : args[i + 1]; };
const shotsDir = opt('shots');
const video = opt('video');
const keep = Number(opt('keep', 1));
const dryRun = args.includes('--dry-run');

(async () => {
  const client = await new GoogleAuth({ keyFile: KEY, scopes: ['https://www.googleapis.com/auth/androidpublisher'] }).getClient();
  const req = (o) => client.request(o).then((r) => r.data);
  const shots = shotsDir ? fs.readdirSync(shotsDir).filter((f) => /\.png$/i.test(f)).sort().map((f) => path.join(shotsDir, f)) : [];
  if (keep + shots.length > 8) throw new Error(`Play tối đa 8 ảnh điện thoại (${keep} + ${shots.length})`);

  const { id: edit } = await req({ url: `${BASE}/edits`, method: 'POST' });
  try {
    const langs = opt('lang') ? [opt('lang')] : ((await req({ url: `${BASE}/edits/${edit}/listings` })).listings || []).map((l) => l.language);
    for (const lang of langs) {
      const L = `${BASE}/edits/${edit}/listings/${lang}`;
      if (shots.length) {
        const cur = (await req({ url: `${L}/phoneScreenshots` })).images || [];
        if (cur.length < keep) throw new Error(`${lang}: chỉ có ${cur.length} ảnh, không đủ để giữ ${keep}`);
        console.log(`${lang}: giữ ${keep} ảnh đầu · xoá ${cur.length - keep} · thêm ${shots.length}`);
        // Ảnh tải lên được nối vào cuối danh sách → giữ ảnh đầu = chỉ xoá phần sau rồi tải theo thứ tự.
        for (const im of cur.slice(keep)) await req({ url: `${L}/phoneScreenshots/${im.id}`, method: 'DELETE' });
        for (const f of shots) {
          await req({ url: `${UPLOAD}/edits/${edit}/listings/${lang}/phoneScreenshots?uploadType=media`, method: 'POST',
            headers: { 'Content-Type': 'image/png' }, body: fs.readFileSync(f) });
          console.log(`  ✓ ${path.basename(f)}`);
        }
      }
      if (video) {
        await req({ url: L, method: 'PATCH', data: { video } });
        console.log(`${lang}: ✓ video ${video}`);
      }
    }
    if (dryRun) {
      await req({ url: `${BASE}/edits/${edit}:validate`, method: 'POST' });
      console.log('✓ validate OK — dry-run, xoá edit, KHÔNG gửi');
      await req({ url: `${BASE}/edits/${edit}`, method: 'DELETE' });
      return;
    }
    await req({ url: `${BASE}/edits/${edit}:commit`, method: 'POST' });
    console.log('✓ commit — trang store đã gửi duyệt');
  } catch (e) {
    await req({ url: `${BASE}/edits/${edit}`, method: 'DELETE' }).catch(() => {});
    throw e;
  }
})().catch((e) => {
  console.error('✗', e.response?.status || '', e.response?.data?.error?.message || e.message);
  process.exit(1);
});
