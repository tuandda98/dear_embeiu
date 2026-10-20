(function () {
const chev = (n) => icon('arrow_right_3', n).replace('class="ic"', 'class="ic" style="transform:rotate(90deg)"');
// AddTransactionSheet — mockup bấm thử. html(state) trả về sheet tĩnh cho trang trạng thái.
const { fmt, parseVndInput, cat } = D;
const DEFAULT = { book: 'shared', type: 'expense', raw: '', chipMode: false, cat: 'food_out', payer: 'tuan', split: 'equal', customShare: null, link: true, linkWallet: 'Techcombank', wallet: 'MoMo', open: false };
const RECENT = { expense: ['food_out', 'food_market', 'food_coffee', 'move_fuel', 'move_grab'], income: ['salary', 'side', 'bonus', 'gifted'] };
const SPLITS = () => [['equal', 'Chia đôi'], ['treat', st.payer === 'tuan' ? 'Mình mời' : 'Thảo mời'], ['for_partner', 'Trả hộ'], ['custom', 'Tuỳ']];

let st = {};
function parsed(x = st) { return parseVndInput(x.raw); }
function shares(v) {
  if (st.payer === 'wallet') return null;
  const other = st.payer === 'tuan' ? 'Thảo' : 'Mình'; const me = st.payer === 'tuan' ? 'Mình' : 'Thảo';
  let payerShare = st.split === 'equal' ? Math.ceil(v / 2) : st.split === 'treat' ? v : st.split === 'for_partner' ? 0 : Math.min(st.customShare ?? Math.ceil(v / 2), v);
  return `${me} chịu <b class="num">${fmt(payerShare)}</b> · ${other} chịu <b class="num">${fmt(v - payerShare)}</b>`;
}
function html(s) {
  const prev = st; st = s; try {
  const p = parsed(); const v = p.ok ? p.value : 0;
  const hint = !st.raw ? 'Gõ 50k, 1tr2 hay 1 củ đều được'
    : !p.ok && p.reason === 'tooBig' ? 'Tối đa 10 tỷ một khoản. Kiểm tra lại số 0 nhé.'
    : !p.ok ? 'Chưa hiểu số này. Thử 120k hoặc 120000.'
    : /[a-zà-ỹ]/i.test(st.raw) ? `Bạn gõ “${st.raw}”` : '';
  const cats = (RECENT[st.type] || []).map((id) => `<button class="chip" aria-pressed="${st.cat === id}" data-cat="${id}"><span class="emo" aria-hidden="true">${cat(id).emoji}</span>${cat(id).vi}</button>`).join('')
    + `<a class="chip" href="add-tx-states.html#cat">${icon('category_2', 16)}Tất cả</a>`;
  const shared = st.book === 'shared' && st.type === 'expense';
  const payerName = st.payer === 'wallet' ? 'Ví chung trả' : st.payer === 'tuan' ? 'Mình trả' : 'Thảo trả';
  const summary = shared
    ? `${UI.av(st.payer)}<span class="grow">${payerName}${st.payer === 'wallet' ? '' : ' · ' + SPLITS().find((s) => s[0] === st.split)[1].toLowerCase()} · ${st.payer === 'tuan' && st.link ? 'trừ ' + st.linkWallet : st.payer === 'wallet' ? 'không ai ứng' : 'Hôm nay'}</span>`
    : `<span class="grow">${st.type === 'transfer' ? 'Techcombank → Tiền mặt' : st.wallet} · Hôm nay · Thêm ghi chú</span>`;
  const detail = `
    <div class="detail">
      ${shared ? `
      <p class="row-l">Ai trả</p>
      ${UI.seg(['Mình', 'Thảo', 'Ví chung'], ['tuan', 'thao', 'wallet'].indexOf(st.payer), 'radiogroup').replace('data-seg', 'data-seg data-k="payer"')}
      ${st.payer !== 'wallet' ? `<p class="row-l">Chia thế nào</p>
      <div class="chips" role="radiogroup">${SPLITS().map(([k, l]) => `<button class="chip" role="radio" aria-checked="${st.split === k}" data-split="${k}">${l}</button>`).join('')}</div>
      ${st.split === 'custom' ? `<div class="stepper"><label class="meta" for="cs" style="flex:none">${st.payer === 'tuan' ? 'Mình' : 'Thảo'} chịu</label><input id="cs" class="field num" inputmode="numeric" value="${(st.customShare ?? Math.ceil(v / 2)).toLocaleString('vi-VN')}"><button class="ibtn" aria-label="Bớt 10%" data-step="-1">${icon('minus', 18)}</button><button class="ibtn" aria-label="Thêm 10%" data-step="1">${icon('add', 18)}</button></div>` : ''}
      <p class="share">${v ? shares(v) : 'Nhập số tiền để xem mỗi người chịu bao nhiêu'}</p>` : `<p class="share">Trả từ Ví chung nên không ai ứng cho ai.</p>`}
      ${st.payer === 'tuan' ? `<div class="kv" style="margin-top:8px"><span class="k">Trừ vào ví của mình<span class="meta" style="display:block;font-weight:500">${st.linkWallet}, ghi thêm 1 khoản ở sổ của mình</span></span><button class="switch" role="switch" aria-checked="${st.link}" aria-label="Trừ vào ví của mình" data-link></button></div>` : ''}` : ''}
      <div style="margin-top:8px">
      ${st.type === 'transfer'
        ? `<button class="kv"><span class="k">Từ ví</span><span class="v"><span class="emo">${D.own.wallets[1].emoji}</span>Techcombank${icon('arrow_right_3', 16)}</span></button><button class="kv"><span class="k">Sang ví</span><span class="v"><span class="emo">${D.own.wallets[0].emoji}</span>Tiền mặt${icon('arrow_right_3', 16)}</span></button>`
        : !shared || st.payer === 'wallet' ? `<button class="kv"><span class="k">Ví</span><span class="v"><span class="emo">${st.payer === 'wallet' && shared ? D.shared.wallets[0].emoji : D.own.wallets[2].emoji}</span>${st.payer === 'wallet' && shared ? 'Ví chung' : st.wallet}${icon('arrow_right_3', 16)}</span></button>` : ''}
      <button class="kv"><span class="k">Ngày</span><span class="v">Hôm nay, 20/10${icon('arrow_right_3', 16)}</span></button>
      <label class="flabel" for="note">Ghi chú</label><input id="note" class="field" placeholder="Bún chả, quà sinh nhật…" maxlength="200">
      </div>
    </div>`;
  const keys = [['1'], ['2'], ['3'], ['⌫', 'del'], ['4'], ['5'], ['6'], ['k', 'unit'], ['7'], ['8'], ['9'], ['tr', 'unit'], [','], ['0'], ['000'], ['củ', 'unit']];
  const saveOk = p.ok && (st.type === 'transfer' || st.cat);
  return `
  <div class="sheet" role="dialog" aria-modal="true" aria-labelledby="t">
    <div class="handle" aria-hidden="true"></div>
    <div class="sh-top">
      <button class="ibtn l" aria-label="Đóng">${icon('close_circle', 24)}</button>
      <h1 id="t">Ghi khoản</h1>
      <button class="bookbtn r" data-book aria-label="Đổi sổ, đang ở ${st.book === 'shared' ? 'sổ chung' : 'sổ của mình'}">${st.book === 'shared' ? 'Sổ chung' : 'Của mình'}${chev(14)}</button>
    </div>
    ${UI.seg(['Chi', 'Thu', 'Chuyển'], ['expense', 'income', 'transfer'].indexOf(st.type), 'radiogroup').replace('data-seg', 'data-seg data-k="type"')}
    <div class="amount" data-amount>
      <p class="sr" id="amt-l">Số tiền</p>
      <p class="v num ${v ? '' : p.reason === 'tooBig' ? 'bad' : 'zero'}" aria-labelledby="amt-l" aria-live="polite">${fmt(v || p.value || 0).split(' ')[0]}<span class="u">₫</span></p>
      <p class="h ${st.raw && !p.ok ? 'bad' : ''}">${hint}</p>
    </div>
    <div class="chips" style="justify-content:center">${['50k', '100k', '200k', '500k'].map((c) => `<button class="chip num" data-chip="${c}">${c}</button>`).join('')}</div>
    ${st.type !== 'transfer' ? `<p class="row-l">Danh mục</p><div class="chips scroll">${cats}</div>` : ''}
    <button class="sum" data-open aria-expanded="${st.open}">${summary}${(st.open ? icon('keyboard', 18) : chev(18))}</button>
    ${st.open ? detail : `<div class="keys" aria-label="Bàn phím số">${keys.map(([k, c]) => `<button class="key ${c || ''}" data-key="${k}" ${k === '⌫' ? 'aria-label="Xoá một ký tự"' : ''}>${k === '⌫' ? icon('arrow_square_left', 24) : k}</button>`).join('')}</div>`}
    <button class="btn primary save" data-save ${saveOk ? '' : 'disabled'}>${saveOk ? `Lưu ${fmt(v)}` : st.raw ? 'Sửa số tiền để lưu' : 'Nhập số tiền để lưu'}</button>
    ${s.extra || ''}
  </div>`;
  } finally { if (prev !== s) st = prev; }
}
function render() { document.getElementById('app').innerHTML = html(st); }
function snack(html) {
  const el = document.getElementById('snack');
  el.innerHTML = `<div class="snack"><div class="grow">${html}</div><a href="money-shared.html">Xem</a></div>`;
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
  } else if (d.cat) st.cat = d.cat;
  else if (d.split) st.split = d.split;
  else if (d.step) { const v = parsed().value || 0; const cur = st.customShare ?? Math.ceil(v / 2); st.customShare = Math.max(0, Math.min(v, cur + (+d.step) * Math.round(v / 10))); }
  else if ('link' in d) st.link = !st.link;
  else if ('open' in d) st.open = !st.open;
  else if ('book' in d) st.book = st.book === 'shared' ? 'own' : 'shared';
  else if ('save' in d) {
    const v = parsed().value; const c = cat(st.cat);
    let extra = '';
    if (st.book === 'shared' && st.type === 'expense' && D.parentOf(st.cat).id === 'food') {
      const after = 1942000 + v, b = 2000000;
      extra = after > b ? `<p class="s2">Ăn uống chung vượt ngân sách tháng ${fmt(after - b)}</p>` : after >= b * .8 ? `<p class="s2">Ăn uống chung đã dùng ${Math.round(after / b * 100)}% ngân sách tháng</p>` : '';
    }
    snack(`Đã ghi ${fmt(v)} · ${st.type === 'transfer' ? 'chuyển ví' : c.vi}${extra}`);
    st.raw = ''; st.chipMode = false; st.open = false;
  } else return;
  });
document.addEventListener('seg', (e) => {
  const k = e.target.dataset.k; const i = e.detail;
  if (k === 'type') { st.type = ['expense', 'income', 'transfer'][i]; st.cat = st.type === 'income' ? 'salary' : st.type === 'expense' ? 'food_out' : ''; }
  if (k === 'payer') { st.payer = ['tuan', 'thao', 'wallet'][i]; st.customShare = null; }
  });
window.AddTx = { html, DEFAULT, mount() { st = { ...DEFAULT }; render(); } };
})();
