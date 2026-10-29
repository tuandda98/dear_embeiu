// MoneyScreen (Sổ tiền) — tổng quan. window.SCREEN = { book: 'own'|'shared', state: 'normal'|'loading'|'error'|'offline'|'waiting'|'empty' }
(function () {
  const { fmt, people } = D; const { money, header, ibtn, seg, plan, dayGroups, walletRow, fab, av, txRow } = UI;
  const { book = 'own', state = 'normal' } = window.SCREEN || {};
  let B = D[book];
  const fresh = state === 'new'; // người mới: vừa xong màn chọn ví, chưa có khoản, chưa đặt ngân sách
  if (fresh) {
    const wallets = [{ ...D.own.wallets[0] }, { ...D.own.wallets[2] }];
    B = { ...B, tx: [], budgets: [], totals: { expense: 0, income: 0, left: 0 }, wallets, balances: { w_cash: 0, w_momo: 1500000 }, assets: 1500000 };
  }
  const PEND = { id: 'p1', date: D.TODAY, type: 'expense', amount: 35000, outWalletId: book === 'own' ? 'w_cash' : '', categoryId: 'food_coffee', note: 'Trà đá', payer: 'tuan', splitMode: 'equal', payerShare: 17500 };
  if (state === 'offline') { // khoản chờ mạng vào luôn các tổng (D21: hiện ngay, số dư tạm)
    const tx = [...B.tx, PEND];
    B = { ...B, tx, totals: D.monthTotals(tx, D.M), paid: B.paid && D.paidBy(tx, D.M), balance: B.balance != null ? D.balance(tx, D.ME) : undefined };
  }
  const dayFrac = 20 / 31;               // hôm nay 20/10, tháng 31 ngày
  const daysLeft = 31 - 20;
  const total = (B.budgets.find((b) => !b.categoryId) || {}).amount || 0;
  const empty = state === 'empty' || fresh;
  const spent = empty ? 0 : B.totals.expense;
  const sk = (w, h = 16) => `<span class="sk" style="width:${w}px;height:${h}px"></span>`;
  const loading = state === 'loading';
  const monthName = state === 'empty' ? 'Tháng 11, 2026' : 'Tháng 10, 2026';

  const trail = ibtn('search_normal_1', 'Tìm khoản') + ibtn('more', 'Ví, danh mục, ngân sách');
  const tabs = state === 'waiting' || fresh ? '' : seg(['Của mình', 'Chung'], book === 'own' ? 0 : 1);

  // Thẻ tháng
  const catRows = D.byCategory(B.tx, D.M);
  const food = catRows.find((c) => c.id === 'food');
  const foodBudget = B.budgets.find((b) => b.categoryId === 'food');
  const findingOwn = total ? `Tháng mới qua 20/31 ngày mà đã dùng ${Math.round(spent / total * 100)}% ngân sách, tức khoảng ${fmt(Math.floor((total - spent) / daysLeft / 1000) * 1000)} mỗi ngày từ giờ tới cuối tháng.` : '';
  const findingShared = book === 'own' ? '' : `Ăn uống chung đã dùng ${Math.round(food.amount / foodBudget.amount * 100)}% ngân sách, còn <b class="num">${fmt(foodBudget.amount - food.amount)}</b> cho ${daysLeft} ngày.`;
  const monthCard = `
  <section class="card" aria-labelledby="h-month">
    <div class="card-h">
      <div style="display:flex;align-items:center;margin-left:-14px">
        <button class="ibtn" aria-label="Tháng trước">${icon('arrow_right_3', 18).replace('class="ic"','class="ic" style="transform:scaleX(-1)"')}</button>
        <h2 id="h-month">${monthName}</h2>
        <button class="ibtn" aria-label="Tháng sau" ${state === 'empty' ? '' : 'disabled style="color:var(--ter)"'}>${icon('arrow_right_3', 18)}</button>
      </div>
      <a class="link" href="report.html">Báo cáo${icon('arrow_right_3', 16)}</a>
    </div>
    <div class="hero2">
      <div><p class="label">${book === 'own' ? 'Đã chi' : 'Chúng mình đã chi'}</p><div>${loading ? sk(170, 30) : money(spent, 'fig-xl')}</div></div>
      <div class="r">${total ? `<p class="label">Còn trong ngân sách</p><div>${loading ? sk(100, 20) : money(total - spent, 'fig-l')}</div>` : `<p class="label">Chưa đặt ngân sách</p><a class="link" href="budgets.html">Đặt${icon('arrow_right_3', 16)}</a>`}</div>
    </div>
    ${total ? `${loading ? `<div class="plan"></div>` : plan(spent, total, empty ? null : dayFrac)}
    <div class="plan-ends meta num"><span>${loading ? sk(90, 12) : `Đã dùng ${Math.round(spent / total * 100)}%`}</span><span>của ${fmt(total)}</span></div>` : ''}
    ${state === 'error' ? `<p class="err">${icon('warning_2', 18)}<span>Chưa tải được khoản mới. Số liệu đúng lúc 09:14.</span></p><button class="btn sm outline" style="margin-top:10px">Thử lại</button>` :
      loading ? `<p class="finding">${sk(300, 14)}<br>${sk(220, 14)}</p>` :
      fresh ? '' : empty ? `<p class="finding">Tháng 11 chưa có khoản nào. Nút hồng ở góc dưới để ghi khoản đầu tiên.</p>` :
      `<p class="finding">${book === 'own' ? findingOwn : findingShared}</p>`}
    ${book === 'own' && !fresh ? `<div class="split">
      <div><p class="meta">Thu</p><p class="fig fig-m num ${empty || loading ? '' : 'pos'}">${loading ? sk(100) : empty ? fmt(0) : '+' + fmt(B.totals.income)}</p></div>
      <div><p class="meta">Thu trừ chi</p><p class="fig fig-m num">${loading ? sk(100) : fmt(empty ? 0 : B.totals.left)}</p></div>
    </div>` : ''}
  </section>`;

  // Ba làn: Thảo · Chung · Mình (signature của sổ chung)
  const p = B.paid || {}; const tot = (p.thao + p.wallet + p.tuan) || 0;
  const lane = (cls, name, amt) => `<div class="lane ${cls}"><p class="lane-n">${cls === 'jt' ? `<span class="av jt" aria-hidden="true">C</span>` : av(cls === 'me' ? 'tuan' : 'thao')}${name}</p><p class="fig fig-m num">${loading ? sk(70) : fmt(amt)}</p></div>`;
  const lanesCard = `
  <section class="card" aria-labelledby="h-lanes">
    <div class="card-h"><h2 id="h-lanes">Ai trả tháng này</h2><span class="meta num">${loading ? '' : 'Tổng ' + fmt(tot)}</span></div>
    <div class="lanes">${lane('pa', 'Thảo', p.thao)}${lane('jt', 'Ví chung', p.wallet)}${lane('me', 'Mình', p.tuan)}</div>
    <div class="stack" role="img" aria-label="Thảo trả ${fmt(p.thao)}, Ví chung ${fmt(p.wallet)}, mình trả ${fmt(p.tuan)}">
      ${loading ? '' : `<span style="flex:${p.thao};background:var(--pa)"></span><span style="flex:${p.wallet};background:rgba(26,26,46,.35)"></span><span style="flex:${p.tuan};background:var(--me)"></span>`}
    </div>
    <div class="bal">
      <div><p class="label">Mình đang ứng nhiều hơn</p><p>${loading ? sk(120, 20) : money(B.balance, 'fig-l')}</p><p class="meta">Thảo trả lại mình chừng này là hai bên ngang nhau</p></div>
      <a class="btn sm outline" href="settle.html">Thanh toán</a>
    </div>
  </section>`;

  // Ví
  const walletsOwn = B.wallets.filter((w) => w.type !== 'goal');
  const goals = B.wallets.filter((w) => w.type === 'goal');
  const goalRow = (w) => {
    const bal = B.balances[w.id]; const r = bal / w.goalTarget;
    return `<a class="row goal" href="goal.html"><span class="emo" aria-hidden="true">${w.emoji}</span><div class="mid"><div class="t">${w.name}</div>
      <div class="gbar" role="img" aria-label="${Math.round(r * 100)}% mục tiêu"><span style="width:${loading ? 0 : r * 100}%"></span></div>
      <div class="s num">${loading ? sk(110, 12) : `${Math.round(r * 100)}% của ${fmt(w.goalTarget)}`}</div></div><div class="amt num">${loading ? sk(80) : fmt(bal)}</div></a>`;
  };
  const walletsCard = `
  <section class="card" aria-labelledby="h-wallets">
    <div class="card-h"><h2 id="h-wallets">${book === 'own' ? 'Ví' : 'Ví chung & quỹ'}</h2>${book === 'own' ? `<span class="meta num">Tổng tiền đang có ${loading ? '' : fmt(B.assets)}</span>` : ''}</div>
    <div class="rows">${walletsOwn.map((w) => loading ? `<div class="row"><span class="emo">${w.emoji}</span><div class="mid"><div class="t">${w.name}</div></div><div class="amt">${sk(90)}</div></div>` : (book === 'shared' ? walletRow(w, B.balances[w.id]).replace('<div class="s">Tiền mặt', `<div class="s">Mỗi người góp ${fmt(D.contributionsBy(B.tx, w.id).tuan)} tháng này`) : walletRow(w, B.balances[w.id]))).join('')}${goals.map(goalRow).join('')}</div>
    <a class="link" href="wallets.html" style="margin-top:6px">${book === 'own' ? 'Quản lý ví' : 'Góp vào quỹ'}${icon('arrow_right_3', 16)}</a>
  </section>`;

  // Tiêu vào đâu (chỉ sổ riêng; sổ chung đã có ba làn)
  const top = loading ? [] : catRows.slice(0, 4); const max = top[0] ? top[0].amount : 1;
  const whereCard = `
  <section class="card" aria-labelledby="h-where">
    <div class="card-h"><h2 id="h-where">Tiêu vào đâu</h2><a class="link" href="budgets.html">Ngân sách${icon('arrow_right_3', 16)}</a></div>
    <div class="blist">${loading ? [150, 120, 100, 80].map((w) => `<div class="bl"><div class="bl-l">${sk(w, 15)}</div>${sk(80, 15)}</div>`).join('') : ''}${top.map((c, i) => {
      const cc = D.cat(c.id); const b = B.budgets.find((x) => x.categoryId === c.id);
      const pct = b ? Math.round(c.amount / b.amount * 100) : null;
      return `<div class="bl"><div class="bl-l"><span class="emo" aria-hidden="true">${cc.emoji}</span><span class="t">${cc.vi}</span>${pct != null ? `<span class="meta num">${pct}% ngân sách</span>` : ''}</div><span class="num bl-v">${fmt(c.amount)}</span>
        <span class="bl-bar ${i === 0 ? 'top' : ''}" style="width:${c.amount / max * 100}%"></span></div>`;
    }).join('')}</div>
  </section>`;

  // Gần đây
  let rows = B.tx;
  let recent = dayGroups(rows, book, book === 'own' ? 3 : 4);
  if (state === 'offline') recent = recent.replace(UI.txRow(PEND, book), UI.txRow(PEND, book, { pending: true }));
  const recentCard = `
  <section class="card" aria-labelledby="h-recent">
    <div class="card-h"><h2 id="h-recent">Gần đây</h2><a class="link" href="search.html">Tất cả${icon('arrow_right_3', 16)}</a></div>
    ${loading ? [1, 2, 3].map(() => `<div class="row"><span class="emo"></span><div class="mid">${sk(150, 15)}<br>${sk(90, 12)}</div>${sk(80, 15)}</div>`).join('') :
      empty ? `<p class="empty">Chưa có khoản nào trong tháng 11. Mở tháng 10 bằng nút ‹ ở trên để xem lại.</p>` : recent}
  </section>`;

  const waitingCard = `<section class="card" aria-labelledby="h-wait" style="padding:16px 20px">
    <h2 id="h-wait" class="sr">Sổ chung</h2>
    <p class="finding" style="margin:0">Khi người ấy vào, chúng mình sẽ có thêm sổ chung: ai trả, chia đôi, quỹ đi chơi.</p>
    <a class="link" href="#" style="margin-top:6px">Gửi lời mời${icon('arrow_right_3', 16)}</a></section>`;

  const firstCard = `<section class="card" aria-labelledby="h-first">
    <h2 id="h-first" class="card-h">Ghi khoản đầu tiên</h2>
    <p class="finding" style="margin-top:6px">Hôm nay vừa trả gì? Chạm một mục, gõ số tiền rồi Lưu.</p>
    <div class="chips" style="margin-top:12px">${['food_coffee', 'food_out', 'move_fuel', 'food_market'].map((id) => `<a class="chip" href="add-tx.html"><span class="emo" aria-hidden="true">${D.cat(id).emoji}</span>${D.cat(id).vi}</a>`).join('')}</div>
    <a class="btn primary" href="add-tx.html" style="margin-top:16px">${icon('add', 20)}Ghi khoản</a>
    <p class="meta" style="margin-top:12px">Ghi vài hôm, mình sẽ thấy tiền đi đâu nhiều nhất và đặt ngân sách cho tháng sau.</p></section>`;
  const offline = state === 'offline' ? `<p class="notice" role="status">${icon('cloud_cross', 20)}<span>Đang mất mạng. Số dư tính tạm từ lúc 11:58 cộng 1 khoản chờ gửi.</span></p>` : '';

  const body = book === 'own'
    ? fresh ? monthCard + firstCard + walletsCard + waitingCard
      : monthCard + recentCard + (empty || state === 'error' ? '' : whereCard) + walletsCard + (state === 'waiting' ? waitingCard : '')
    : monthCard + lanesCard + recentCard + walletsCard;

  document.getElementById('app').innerHTML = `<div class="app">${header('Sổ tiền', 'wallet_2', trail)}${tabs}${offline}<main>${body}</main></div>${fresh ? '' : fab()}`;
  document.addEventListener('seg', (e) => { if (state === 'normal') location.href = e.detail === 0 ? 'money-own.html' : 'money-shared.html'; });
})();
