#!/usr/bin/env node
/**
 * Hàn gắn chuỗi (streak) cho MỘT couple trên Firestore.
 *
 * Vì sao cần: cờ `bothAnswered` trên `couples/{coupleId}/dailyAnswers/{date}`
 * trước đây chỉ được ghi ĐÚNG MỘT LẦN — bởi người trả lời thứ hai, ngay trong
 * lượt lưu câu trả lời. Lượt ghi đó hỏng (mất mạng, app bị kill, lượt đọc
 * `responses` rơi vào cache offline chưa thấy câu của partner) là ngày đó mất
 * cờ VĨNH VIỄN: cả hai đã trả lời nhưng streak vẫn bỏ qua ngày ấy → đứt chuỗi.
 * App (từ bản vá này) tự vá khi mở lại, script này vá NGAY trên data hiện có —
 * dùng khi không muốn chờ user cập nhật app.
 *
 * Chạy (mặc định DRY-RUN, chỉ in ra, không ghi gì):
 *   cd functions && npm i            # để có node_modules/firebase-admin
 *   GOOGLE_APPLICATION_CREDENTIALS=/duong/dan/service-account.json \
 *     node ../scripts/heal-streak-markers.js --project tonyembeiu \
 *       --email dodaoanhtuan@gmail.com
 *
 * Ghi thật: thêm cờ --apply
 *
 * Chỉ định couple thay vì email: --couple <coupleId>
 * Giới hạn số ngày quét ngược: --days 120 (mặc định 180)
 */

const path = require('path');

function loadAdmin() {
  try {
    return require('firebase-admin');
  } catch (_) {
    return require(path.join(__dirname, '..', 'functions', 'node_modules', 'firebase-admin'));
  }
}

function parseArgs(argv) {
  const args = { apply: false, days: 180 };
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--apply') args.apply = true;
    else if (arg === '--project') args.project = argv[++i];
    else if (arg === '--email') args.email = argv[++i];
    else if (arg === '--couple') args.couple = argv[++i];
    else if (arg === '--days') args.days = Number(argv[++i]);
    else throw new Error(`Tham số lạ: ${arg}`);
  }
  if (!args.project) throw new Error('Thiếu --project (vd: tonyembeiu cho PROD, tonyembeiu-dev cho DEV)');
  if (!args.email && !args.couple) throw new Error('Cần --email <email> hoặc --couple <coupleId>');
  if (!Number.isFinite(args.days) || args.days <= 0) throw new Error('--days phải là số dương');
  return args;
}

async function resolveCoupleId(admin, db, args) {
  if (args.couple) return args.couple;
  const user = await admin.auth().getUserByEmail(args.email);
  const snap = await db.collection('users').doc(user.uid).get();
  const coupleId = snap.exists ? snap.data().coupleId : null;
  if (!coupleId) throw new Error(`User ${args.email} (${user.uid}) chưa thuộc couple nào`);
  console.log(`• ${args.email} → uid ${user.uid} → couple ${coupleId}`);
  return coupleId;
}

async function main() {
  const args = parseArgs(process.argv);
  const admin = loadAdmin();
  admin.initializeApp({ projectId: args.project });
  const db = admin.firestore();

  console.log(`• Project: ${args.project}${args.apply ? ' (GHI THẬT)' : ' (dry-run)'}`);
  const coupleId = await resolveCoupleId(admin, db, args);

  const cutoff = new Date();
  cutoff.setHours(0, 0, 0, 0);
  cutoff.setDate(cutoff.getDate() - args.days);

  const markers = await db
    .collection('couples').doc(coupleId).collection('dailyAnswers')
    .orderBy('date', 'desc')
    .limit(args.days)
    .get();

  const healed = [];
  for (const marker of markers.docs) {
    const data = marker.data();
    if (data.bothAnswered === true) continue;

    const dateKey = (typeof data.date === 'string' && data.date.trim()) || marker.id;
    const parsed = new Date(`${dateKey}T00:00:00`);
    if (Number.isNaN(parsed.getTime()) || parsed < cutoff) continue;

    const responses = await marker.ref.collection('responses').get();
    const answered = responses.docs.filter((doc) => {
      const text = doc.data().text;
      return typeof text === 'string' && text.trim().length > 0;
    }).length;
    if (answered < 2) continue;

    healed.push(dateKey);
    if (args.apply) {
      await marker.ref.set(
        { bothAnswered: true, revealedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
  }

  if (healed.length === 0) {
    console.log('✓ Không có ngày nào thiếu cờ — chuỗi đứt (nếu có) là do thật sự không trả lời.');
    return;
  }
  console.log(`${args.apply ? '✓ Đã vá' : '→ Sẽ vá'} ${healed.length} ngày: ${healed.join(', ')}`);
  if (!args.apply) console.log('  (chạy lại kèm --apply để ghi thật)');
}

main().catch((err) => {
  console.error('✗', err.message);
  process.exit(1);
});
