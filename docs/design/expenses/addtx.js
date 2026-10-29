(function () {
const chev = (n) => icon('arrow_right_3', n).replace('class="ic"', 'class="ic" style="transform:rotate(90deg)"');
// AddTransactionSheet — mockup bấm thử. html(state) trả về sheet tĩnh cho trang trạng thái.
const { fmt, parseVndInput, cat } = D;
const DEFAULT = { book: 'shared', type: 'expense', raw: '', chipMode: false, cat: null, payer: 'tuan', split: 'equal', customShare: null, wallet: null, note: '', open: false };
const OWNW = D.own.wallets.filter((w) => w.type !== 'goal');
// Mặc định thông minh: danh mục dùng gần nhất của sổ; ví = ví dùng lần trước với chính danh mục đó.
const lastOf = (rows, pred) => rows.filter(pred).sort((a, b) => a.date.localeCompare(b.date)).pop();
// Danh mục mặc định = dùng nhiều nhất trong 14 ngày gần đây, hoà thì cái gần nhất (đề xuất thay "gần nhất" của D9: tránh mặc định "Nước" chỉ vì vừa ghi hoá đơn)
const lastCat = (book, type) => {
  const rows = D[book].tx.filter((r) => r.type === type && r.categoryId && r.date >= '2026-10-07');
  const score = new Map(); rows.forEach((r) => { const c = score.get(r.categoryId) || { n: 0, d: '' }; score.set(r.categoryId, { n: c.n + 1, d: r.date > c.d ? r.date : c.d }); });
  const best = [...score.entries()].sort((a, b) => b[1].n - a[1].n || b[1].d.localeCompare(a[1].d))[0];
  return best ? best[0] : (type === 'income' ? 'salary' : 'food_out');
};
const ownLinked = (r) => r.linkId ? (D.own.tx.find((o) => o.linkId === r.linkId) || {}).outWalletId : '';
const lastWallet = (book, catId) => {
  if (book === 'own') return (lastOf(D.own.tx, (r) => r.categoryId === catId && (r.outWalletId || r.inWalletId)) || {}).outWalletId || 'w_momo';
  const r = lastOf(D.shared.tx, (x) => x.categoryId === catId && x.payer === D.ME); return r ? (ownLinked(r) || '') : 'w_tcb';
};
// "Ghi lại": khoản gần nhất của 3 danh mục chi dùng nhiều nhất trong sổ (bấm = điền số, danh mục, ví, ghi chú)
const QUICK = (book) => {
  const cnt = new Map(); D[book].tx.filter((r) => r.type === 'expense').forEach((r) => cnt.set(r.categoryId, (cnt.get(r.categoryId) || 0) + 1));
  return [...cnt.entries()].sort((a, b) => b[1] - a[1]).slice(0, 3).map(([c]) => lastOf(D[book].tx, (r) => r.categoryId === c && r.type === 'expense'));
};
const RECENT = { expense: ['food_out', 'food_coffee', 'food_market', 'move_fuel', 'move_grab'], income: ['salary', 'side', 'bonus', 'gifted'] };
const SPLITS = () => [['equal', 'Chia đôi'], ['treat', st.payer === 'tuan' ? 'Mình mời' : 'Thảo mời'], ['for_partner', 'Trả hộ'], ['custom', 'Tuỳ']];

let st = {};
function norm(s) { // điền mặc định còn thiếu
  const x = { ...s };
  if (x.type !== 'transfer' && !x.cat) x.cat = lastCat(x.book, x.type);
  if (x.wallet == null) x.wallet = x.book === 'shared' && x.type === 'expense' ? (x.payer === D.ME ? lastWallet('shared', x.cat) : '') : lastWallet('own', x.cat);
  return x;
}
function parsed(x = st) { return parseVndInput(x.raw); }
function shares(v) {
  if (st.payer === 'wallet') return null;
  const other = st.payer === 'tuan' ? 'Thảo' : 'Mình'; const me = st.payer === 'tuan' ? 'Mình' : 'Thảo';
  let payerShare = st.split === 'equal' ? Math.ceil(v / 2) : st.split === 'treat' ? v : st.split === 'for_partner' ? 0 : Math.min(st.customShare ?? Math.ceil(v / 2), v);
  return `${me} chịu <b class="num">${fmt(payerShare)}</b> · ${other} chịu <b class="num">${fmt(v - payerShare)}</b>`;
}
const wchip = (w, on) => `<button class="chip" role="radio" aria-checked="${on}" data-wallet="${w ? w.id : ''}">${w ? `<span class="emo" aria-hidden="true">${w.emoji}</span>${w.name}` : 'Không trừ'}</button>`;
function html(s0) {
  const s = norm(s0);
  const prev = st; st = s; try {
  const p = parsed(); const v = p.ok ? p.value : 0;
  const hint = !st.raw ? 'Gõ 50k, 1tr2 hay 1 củ đều được'
    : !p.ok && p.reason === 'tooBig' ? 'Tối đa 10 tỷ một khoản. Kiểm tra lại số 0 nhé.'
    : !p.ok ? 'Chưa hiểu số này. Thử 120k hoặc 120000.'
    : /[a-zà-ỹ]/i.test(st.raw) ? `Bạn gõ “${st.raw}”` : st.note ? `Ghi lại “${st.note}”` : '';
  const shared = st.book === 'shared' && st.type === 'expense';
  const recent = [...new Set([st.cat, ...(RECENT[st.type] || [])])].slice(0, 5);
  const cats = recent.map((id) => `<button class="chip" role="radio" aria-checked="${st.cat === id}" data-cat="${id}"><span class="emo" aria-hidden="true">${cat(id).emoji}</span>${cat(id).vi}</button>`).join('')
    + `<a class="chip" href="add-tx-states.html#cat">${icon('category_2', 16)}Tất cả</a>`;
  const quick = st.type === 'expense' && !st.raw ? QUICK(st.book) : [];
  const quickRow = quick.length ? `<p class="row-l">Ghi lại khoản quen</p><div class="chips scroll">${quick.map((r) => `<button class="chip" data-quick="${r.id}"><span class="emo" aria-hidden="true">${cat(r.categoryId).emoji}</span>${UI.esc(r.note)} · <span class="num">${D.fmtShort(r.amount)}</span></button>`).join('')}</div>` : '';
  const showWallets = st.type !== 'transfer' && (!shared || st.payer === D.ME);
  const walletRow = showWallets ? `<p class="row-l">${shared ? 'Trừ vào ví của mình' : st.type === 'income' ? 'Vào ví' : 'Ví'}</p><div class="chips scroll" role="radiogroup">${OWNW.map((w) => wchip(w, st.wallet === w.id)).join('')}${shared ? wchip(null, st.wallet === '') : ''}</div>` : '';
  const payerName = st.payer === 'wallet' ? 'Ví chung trả' : st.payer === 'tuan' ? 'Mình trả' : 'Thảo trả';
  const summary = shared
    ? `${UI.av(st.payer)}<span class="grow">${payerName}${st.payer === 'wallet' ? '' : ' · ' + SPLITS().find((x) => x[0] === st.split)[1].toLowerCase()} · Hôm nay</span>`
    : `<span class="grow">${st.type === 'transfer' ? 'Techcombank → Tiền mặt' : 'Hôm nay'} · ${st.note ? UI.esc(st.note) : 'Thêm ghi chú'}</span>`;
  const detail = `
    <div class="detail">
      ${shared ? `
      <p class="row-l">Ai trả</p>
      ${UI.seg(['Mình', 'Thảo', 'Ví chung'], ['tuan', 'thao', 'wallet'].indexOf(st.payer), 'radiogroup').replace('data-seg', 'data-seg data-k="payer"')}
      ${st.payer !== 'wallet' ? `<p class="row-l">Chia thế nào</p>
      <div class="chips" role="radiogroup">${SPLITS().map(([k, l]) => `<button class="chip" role="radio" aria-checked="${st.split === k}" data-split="${k}">${l}</button>`).join('')}</div>
      ${st.split === 'custom' ? `<div class="stepper"><label class="meta" for="cs" style="flex:none">${st.payer === 'tuan' ? 'Mình' : 'Thảo'} chịu</label><input id="cs" class="field num" inputmode="numeric" value="${(st.customShare ?? Math.ceil(v / 2)).toLocaleString('vi-VN')}"><button class="ibtn" aria-label="Bớt 10%" data-step="-1">${icon('minus', 18)}</button><button class="ibtn" aria-label="Thêm 10%" data-step="1">${icon('add', 18)}</button></div>` : ''}
      <p class="share">${v ? shares(v) : 'Nhập số tiền để xem mỗi người chịu bao nhiêu'}</p>` : `<p class="share">Trả từ Ví chung nên không ai phải trả lại ai.</p>`}` : ''}
      <div style="margin-top:8px">
      ${st.type === 'transfer'
        ? `<button class="kv"><span class="k">Từ ví</span><span class="v"><span class="emo">${D.own.wallets[1].emoji}</span>Techcombank${icon('arrow_right_3', 16)}</span></button><button class="kv"><span class="k">Sang ví</span><span class="v"><span class="emo">${D.own.wallets[0].emoji}</span>Tiền mặt${icon('arrow_right_3', 16)}</span></button>`
        : shared && st.payer === 'wallet' ? `<button class="kv"><span class="k">Ví</span><span class="v"><span class="emo">${D.shared.wallets[0].emoji}</span>Ví chung${icon('arrow_right_3', 16)}</span></button>` : ''}
      <button class="kv"><span class="k">Ngày</span><span class="v">Hôm nay, 20/10${icon('arrow_right_3', 16)}</span></button>
      <label class="flabel" for="note">Ghi chú</label><input id="note" class="field" placeholder="Bún chả, quà sinh nhật…" maxlength="200" value="${UI.esc(st.note || '')}">
      </div>
    </div>`;
  const keys = [['1'], ['2'], ['3'], ['⌫', 'del'], ['4'], ['5'], ['6'], ['k', 'unit'], ['7'], ['8'], ['9'], ['tr', 'unit'], [','], ['0'], ['000'], ['củ', 'unit']];
  const saveOk = p.ok && (st.type === 'transfer' || st.cat);
  return `
  <div class="sheet" role="dialog" aria-modal="true" aria-labelledby="t">
    <div class="handle" aria-hidden="true"></div>
    <h1 id="t" class="sr">Ghi khoản</h1>
    <div class="sh-top2">
      <button class="ibtn" aria-label="Đóng">${icon('close_circle', 24)}</button>
      ${UI.seg(['Chi', 'Thu', 'Chuyển'], ['expense', 'income', 'transfer'].indexOf(st.type), 'radiogroup').replace('data-seg', 'data-seg data-k="type"').replace('class="seg"', 'class="seg seg-s"')}
      <button class="bookbtn" data-book aria-label="Đổi sổ, đang ở ${st.book === 'shared' ? 'sổ chung' : 'sổ của mình'}">${st.book === 'shared' ? 'Sổ chung' : 'Của mình'}${chev(14)}</button>
    </div>
    <div class="amount" data-amount>
      <p class="sr" id="amt-l">Số tiền</p>
      <p class="v num ${v ? '' : p.reason === 'tooBig' ? 'bad' : 'zero'}" aria-labelledby="amt-l" aria-live="polite">${fmt(v || p.value || 0).split(' ')[0]}<span class="u">₫</span></p>
      <p class="h ${st.raw && !p.ok ? 'bad' : ''}">${hint}</p>
    </div>
    <div class="chips" style="justify-content:center">${['50k', '100k', '200k', '500k'].map((c) => `<button class="chip num" data-chip="${c}">${c}</button>`).join('')}</div>
    ${quickRow}
    ${st.type !== 'transfer' ? `<p class="row-l">Danh mục</p><div class="chips scroll" role="radiogroup">${cats}</div>` : ''}
    ${walletRow}
    <button class="sum" data-open aria-expanded="${st.open}">${summary}${(st.open ? icon('keyboard', 18) : chev(18))}</button>
    ${st.open ? detail : `<div class="keys" aria-label="Bàn phím số">${keys.map(([k, c]) => `<button class="key ${c || ''}" data-key="${k}" ${k === '⌫' ? 'aria-label="Xoá một ký tự"' : ''}>${k === '⌫' ? icon('arrow_square_left', 24) : k}</button>`).join('')}</div>`}
    <div class="save-bar"><button class="btn primary" data-save ${saveOk ? '' : 'disabled'}>${saveOk ? `Lưu ${fmt(v)}` : st.raw ? 'Sửa số tiền để lưu' : 'Nhập số tiền để lưu'}</button></div>
    ${s.extra || ''}
  </div>`;
  } finally { if (prev !== s) st = prev; }
}
function render() { st = norm(st); document.getElementById('app').innerHTML = html(st); }
function snack(html) {
  const el = document.getElementById('snack');
  el.innerHTML = `<div class="snack"><div class="grow">${html}</div><button>Hoàn tác</button></div>`;
  clearTimeout(snack.t); snack.t = setTimeout(() => { el.innerHTML = ''; }, 4000);
}
document.addEventListener('click', (e) => {
  const t = e.target.closest('button, a'); if (!t) return;
  const d = t.dataset;
  if (d.key) {
    if (d.key === '⌫') st.raw = st.raw.slice(0, -1);
    else if (['k', 'tr', 'củ'].includes(d.key)) { if (st.raw && !/[a-zà-ỹ]/i.test(st.raw)) st.raw += d.key; }
    else { if (st.chipMode) { st.raw = ''; st.chipMode = false; } st.raw += d.key; }
  } else if (d.chip) {
    const add = parseVndInput(d.chip).value; const cur = parsed();
    st.raw = String((st.chipMode && cur.ok ? cur.value : 0) + add); st.chipMode = true;
  } else if (d.quick) { const r = D[st.book].tx.find((x) => x.id === d.quick); st.raw = String(r.amount); st.chipMode = true; st.cat = r.categoryId; st.note = r.note; st.wallet = st.book === 'own' ? r.outWalletId : r.payer === D.ME ? (ownLinked(r) || '') : st.wallet; if (st.book === 'shared') { st.payer = r.payer; st.split = r.splitMode === 'none' ? 'equal' : r.splitMode; }
  } else if (d.wallet != null) st.wallet = d.wallet;
  else if (d.cat) { st.cat = d.cat; st.wallet = null; }
  else if (d.split) st.split = d.split;
  else if (d.step) { const v = parsed().value || 0; const cur = st.customShare ?? Math.ceil(v / 2); st.customShare = Math.max(0, Math.min(v, cur + (+d.step) * Math.round(v / 10))); }
  else if ('open' in d) st.open = !st.open;
  else if ('book' in d) { st.book = st.book === 'shared' ? 'own' : 'shared'; st.cat = null; st.wallet = null; }
  else if ('save' in d) {
    const v = parsed().value; const c = cat(st.cat);
    let extra = '';
    if (st.book === 'shared' && st.type === 'expense' && D.parentOf(st.cat).id === 'food') {
      const after = 1942000 + v, b = 2000000;
      extra = after > b ? `<p class="s2">Ăn uống chung vượt ngân sách tháng ${fmt(after - b)}</p>` : after >= b * .8 ? `<p class="s2">Ăn uống chung đã dùng ${Math.round(after / b * 100)}% ngân sách tháng</p>` : '';
    }
    snack(`Đã ghi ${fmt(v)} · ${st.type === 'transfer' ? 'chuyển ví' : c.vi}${extra}`);
    st = { ...DEFAULT, book: st.book };
  } else return;
  });
document.addEventListener('seg', (e) => {
  const k = e.target.dataset.k; const i = e.detail;
  if (k === 'type') { st.type = ['expense', 'income', 'transfer'][i]; st.cat = null; st.wallet = null; }
  if (k === 'payer') { st.payer = ['tuan', 'thao', 'wallet'][i]; st.customShare = null; st.wallet = null; }
  });
window.AddTx = { html, DEFAULT, QUICK, norm, mount() { st = { ...DEFAULT }; render(); } };
})();
