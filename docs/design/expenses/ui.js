// Sổ tiền — mảnh giao diện dùng chung cho mockup. Mỗi hàm ứng với 1 widget Flutter (ghi ở design.md).
(function () {
  const { fmt, people, cat } = D;
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  // Số tiền lớn: đơn vị ₫ nhỏ + xám (MoneyText)
  const money = (n, cls = 'fig-m') => {
    const s = fmt(n); const parts = s.split(' ');
    return `<span class="fig ${cls} num">${parts[0]}<span class="u">₫</span></span>`;
  };
  const WD = ['Chủ nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
  const dayLabel = (iso) => {
    const d = new Date(iso + 'T00:00:00'); const dd = `${d.getDate()}/${d.getMonth() + 1}`;
    if (iso === D.TODAY) return `Hôm nay, ${dd}`;
    if (iso === '2026-10-19') return `Hôm qua, ${dd}`;
    return `${WD[d.getDay()]}, ${dd}`;
  };
  const av = (pid) => pid === 'wallet' ? `<span class="av jt" aria-hidden="true">C</span>` : `<span class="av ${pid === D.ME ? 'me' : 'pa'}" aria-hidden="true">${people[pid].initial}</span>`;
  const who = (pid) => pid === 'wallet' ? 'Ví chung' : pid === D.ME ? 'Mình' : people[pid].name;
  const SPLIT = { equal: 'chia đôi', treat: 'mời', for_partner: 'trả hộ', custom: 'tuỳ', none: '' };

  const header = (title, iconName, trail = '', back = true) => `
    <header class="hdr">
      <div class="lead">${back ? `<button class="ibtn" aria-label="Quay lại">${icon('arrow_left', 24)}</button>` : ''}</div>
      <h1 class="chip-h">${icon(iconName, 13)}<span>${esc(title)}</span></h1>
      <div class="trail">${trail}</div>
    </header>`;
  const ibtn = (name, label) => `<button class="ibtn" aria-label="${label}">${icon(name, 24)}</button>`;

  const seg = (items, sel, role = 'tablist') => `
    <div class="seg" role="${role}" data-seg>
      <span class="thumb" style="width:calc((100% - 8px)/${items.length});transform:translateX(${sel * 100}%)"></span>
      ${items.map((t, i) => `<button role="${role === 'tablist' ? 'tab' : 'radio'}" ${role === 'tablist' ? 'aria-selected' : 'aria-checked'}="${i === sel}">${t}</button>`).join('')}
    </div>`;

  // Thanh kế hoạch: spent/budget, vạch hôm nay ở todayFrac
  const plan = (spent, budget, todayFrac, label = true) => {
    const r = spent / budget; const w = Math.min(r, 1) * 100;
    const cls = r >= 1 ? 'over' : r >= 0.8 ? 'warn' : '';
    return `<div class="plan${todayFrac != null && label ? " has-tick" : ""}" role="img" aria-label="Đã dùng ${Math.round(r * 100)}% ngân sách">
      <span class="fill ${cls}" style="width:${w}%"></span>${todayFrac != null ? `<span class="tick" style="left:calc(${todayFrac * 100}% - 1px)"></span>${label ? `<span class="tick-l meta" style="left:${todayFrac * 100}%">Hôm nay</span>` : ''}` : ''}</div>`;
  };

  const txAmount = (r, book) => {
    if (r.type === 'income') return `<span class="pos">+${fmt(r.amount)}</span>`;
    if (r.type === 'expense') return `−${fmt(r.amount)}`;
    if (r.type === 'settle') return `<span style="color:var(--sec)">${fmt(r.amount)}</span>`;
    if (r.type === 'contribution' && book === 'shared') return `<span class="pos">+${fmt(r.amount)}</span>`;
    return `<span style="color:var(--sec)">${fmt(r.amount)}</span>`;
  };
  const wname = (book, id) => (D[book].wallets.find((w) => w.id === id) || {}).name || '';
  const txRow = (r, book, opts = {}) => {
    const c = r.categoryId ? cat(r.categoryId) : null;
    let emoji = c ? c.emoji : '';
    let sub = '';
    if (r.type === 'transfer') { emoji = '↔'; sub = `${wname(book, r.outWalletId)} → ${wname(book, r.inWalletId)}`; }
    else if (r.type === 'adjust') { emoji = '±'; r = { ...r, note: r.note === 'Điều chỉnh số dư' ? 'Sửa số dư cho khớp' : r.note }; sub = `${wname(book, r.outWalletId || r.inWalletId)} · không tính là chi`; }
    else if (r.type === 'contribution') { emoji = '→'; sub = book === 'shared' ? `${av(r.payer)}<span>${who(r.payer)} góp</span>` : `${wname(book, r.outWalletId)} → sổ chung`; }
    else if (r.type === 'settle') { emoji = '='; sub = `${who(r.payer)} thanh toán · không tính vào chi`; }
    else if (book === 'shared') {
      const p = r.payer === 'wallet' ? 'Trả từ Ví chung' : `${who(r.payer)} trả${SPLIT[r.splitMode] ? ' · ' + SPLIT[r.splitMode] : ''}`;
      sub = `${av(r.payer)}<span>${p}</span>`;
    } else { sub = `${r.linkId ? `<span title="Có ở sổ chung" aria-label="Có ở sổ chung" style="display:inline-flex">${icon('people', 14)}</span>` : ''}<span>${c.vi}${opts.hideWallet ? '' : ' · ' + wname(book, r.outWalletId || r.inWalletId)}</span>`; }
    
    const glyph = /^[↔±→=]$/.test(emoji) ? `<span class="emo" style="font-size:16px;color:var(--sec)" aria-hidden="true">${emoji}</span>` : `<span class="emo" aria-hidden="true">${emoji}</span>`;
    return `<button class="row">${glyph}<div class="mid"><div class="t">${esc(r.note || (c && c.vi))}</div><div class="s">${sub}</div></div><div class="amt num">${txAmount(r, book)}${opts.pending ? `<div class="s pend">${icon('cloud_cross', 14)}chờ mạng</div>` : r.updatedBy ? `<div class="s">${who(r.updatedBy)} sửa ${r.updatedAt}</div>` : ''}</div></button>`;
  };
  const dayGroups = (rows, book, maxDays = 3, opts = {}) => {
    const days = [...new Set(rows.map((r) => r.date))].sort().reverse().slice(0, maxDays);
    return days.map((d) => {
      const list = rows.filter((r) => r.date === d).reverse();
      const spent = list.filter((r) => r.type === 'expense').reduce((s, r) => s + r.amount, 0);
      return `<div class="day"><span class="d">${dayLabel(d)}</span><span class="meta num">${spent ? 'Chi ' + fmt(spent) : ''}</span></div>
        <div class="rows">${list.map((r) => txRow(r, book, opts)).join('')}</div>`;
    }).join('');
  };
  const walletRow = (w, bal, extra = '') => `
    <button class="row"><span class="emo" aria-hidden="true">${w.emoji}</span>
      <div class="mid"><div class="t">${esc(w.name)}</div><div class="s">${({ cash: 'Tiền mặt', bank: 'Ngân hàng', ewallet: 'Ví điện tử', credit: 'Thẻ tín dụng', goal: 'Mục tiêu' })[w.type]}${!w.includeInTotal && w.type !== 'goal' ? ' · không tính vào tổng' : ''}${extra}</div></div>
      <div class="amt num">${fmt(bal)}</div></button>`;
  const fab = (label = 'Ghi khoản') => `<button class="fab" aria-label="${label}" title="${label}">${icon('add', 28)}</button>`;

  // Tab chuyển thumb (segmented) — tương tác cho mockup
  document.addEventListener('click', (e) => {
    const b = e.target.closest('[data-seg] > button'); if (!b) return;
    const seg = b.parentElement; const btns = [...seg.querySelectorAll('button')]; const i = btns.indexOf(b);
    const attr = b.hasAttribute('aria-selected') ? 'aria-selected' : 'aria-checked';
    btns.forEach((x, j) => x.setAttribute(attr, String(j === i)));
    seg.querySelector('.thumb').style.transform = `translateX(${i * 100}%)`;
    seg.dispatchEvent(new CustomEvent('seg', { detail: i, bubbles: true }));
  });
  document.addEventListener('click', (e) => {
    const s = e.target.closest('.switch'); if (s) s.setAttribute('aria-checked', String(s.getAttribute('aria-checked') !== 'true'));
  });

  // FAB thu lại khi cuộn xuống, hiện lại khi cuộn lên (Material pattern) để không che dòng cuối
  let lastY = 0;
  addEventListener('scroll', () => { const f = document.querySelector('.fab'); if (!f) return; const y = scrollY; f.classList.toggle('away', y > lastY && y > 80); lastY = y; }, { passive: true });
  window.UI = { esc, money, dayLabel, av, who, SPLIT, header, ibtn, seg, plan, txRow, dayGroups, walletRow, fab, wname };
})();
