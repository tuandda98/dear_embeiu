// ReportScreen (Báo cáo) — window.SCREEN = { book, range: 6|12 }
(function () {
  const { fmt, fmtShort } = D; const { book = 'own' } = window.SCREEN || {}; let range = (window.SCREEN || {}).range || 6;
  const B = D[book];
  const cats = D.byCategory(B.tx, D.M); const totalExp = B.totals.expense;
  const monthKey = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`; // taste-skill-ignore: khoá tháng YYYY-MM
  function trend() {
    const hist = [...B.history.map(([m, e]) => ({ m, e })), { m: D.M, e: totalExp, now: true }];
    const all = []; // đủ range tháng, tháng chưa có sổ = không có cột (không vẽ 0 giả)
    for (let i = range - 1; i >= 0; i--) { const d = new Date(2026, 9 - i, 1); const m = monthKey(d); all.push(hist.find((h) => h.m === m) || { m, e: null }); }
    const budget = B.budgets.find((b) => !b.categoryId).amount;
    const max = Math.max(budget, ...all.map((a) => a.e || 0)); const top = Math.ceil(max / 4e6) * 4e6; const ticks = []; for (let t = 0; t <= top; t += 4e6) ticks.push(t);
    const W = 318, H = 168, L = 34, R = 4, T = 22, Bt = 22; const pw = W - L - R, ph = H - T - Bt; const bw = pw / all.length;
    const y = (v) => T + ph - v / top * ph;
    const bars = all.map((a, i) => a.e == null ? '' : `<rect x="${L + i * bw + bw * .22}" y="${y(a.e)}" width="${bw * .56}" height="${T + ph - y(a.e)}" rx="3" fill="${a.now ? 'var(--rose)' : 'rgba(26,26,46,.30)'}"><title>${a.m}: ${fmt(a.e)}</title></rect>`).join('');
    const xl = all.map((a, i) => (range === 12 && i % 2 === 1 && !a.now) ? '' : `<text x="${L + i * bw + bw / 2}" y="${H - 6}" text-anchor="middle" class="tk">T${+a.m.slice(5)}</text>`).join('');
    const grid = ticks.map((t) => `<line x1="${L}" x2="${W - R}" y1="${y(t)}" y2="${y(t)}" stroke="${t ? '#EFE7EF' : 'rgba(26,26,46,.25)'}" stroke-width="1"/><text x="${L - 6}" y="${y(t) + 4}" text-anchor="end" class="tk">${t ? fmtShort(t) : '0'}</text>`).join('');
    const ref = `<line x1="${L}" x2="${W - R}" y1="${y(budget)}" y2="${y(budget)}" stroke="var(--navy)" stroke-dasharray="4 3" stroke-width="1"/><text x="${W - R}" y="${y(budget) - 5}" text-anchor="end" class="tk ink">Ngân sách ${fmtShort(budget)}</text>`;
    const feb = all.findIndex((a) => a.m === '2026-02'); const ann = feb >= 0 ? `<text x="${L + feb * bw + bw / 2}" y="${y(all[feb].e) - 5}" text-anchor="middle" class="tk ink">Tết</text>` : '';
    const now = all[all.length - 1];
    return `<svg viewBox="0 0 ${W} ${H}" width="100%" role="img" aria-label="Chi mỗi tháng, ${range} tháng gần đây">${grid}${ref}${bars}${ann}${xl}<text x="${L + (all.length - .5) * bw}" y="${y(now.e) - 5}" text-anchor="middle" class="tk ink">${fmtShort(now.e)}</text></svg>`;
  }
  const byWallet = () => { const m = new Map(); B.tx.filter((r) => r.type === 'expense' && D.month(r.date) === D.M && r.outWalletId).forEach((r) => m.set(r.outWalletId, (m.get(r.outWalletId) || 0) + r.amount)); return [...m.entries()].sort((a, b) => b[1] - a[1]); };
  function render() {
    const top = cats[0].amount;
    const kids = D.byCategory(B.tx, D.M, false).filter((c) => D.cat(c.id).parent === cats[0].id);
    const p = B.paid || {};
    const contrib = { tuan: 0, thao: 0 }; B.tx.filter((r) => r.type === 'contribution' && D.month(r.date) === D.M).forEach((r) => { contrib[r.payer] += r.amount; });
    document.getElementById('app').innerHTML = `
    ${UI.header('Báo cáo', 'chart_2', '')}
    ${UI.seg(['Của mình', 'Chung'], book === 'own' ? 0 : 1)}
    <main>
    <section class="card" aria-labelledby="h-m">
      <div class="card-h"><h2 id="h-m">Tháng 10, 2026</h2><span class="meta">tới 20/10</span></div>
      ${book === 'own' ? `<div class="kpi3">
        <div><p class="meta">Thu</p><p class="fig fig-m num pos">+${fmt(B.totals.income)}</p></div>
        <div><p class="meta">Chi</p><p class="fig fig-m num">${fmt(totalExp)}</p></div>
        <div><p class="meta">Còn lại</p><p class="fig fig-m num">${fmt(B.totals.left)}</p></div></div>
        <p class="finding">Chi nhiều nhất là Nhà cửa, chiếm ${Math.round(top / totalExp * 100)}% cả tháng, phần lớn là tiền nhà ${fmt(4500000)}.</p>` :
        `<p style="margin-top:12px">${UI.money(totalExp, 'fig-xl')}</p><p class="finding">Ăn uống chiếm ${Math.round(top / totalExp * 100)}% chi chung, gần một nửa là đi chợ.</p>`}
    </section>
    ${book === 'shared' ? `<section class="card" aria-labelledby="h-p">
      <div class="card-h"><h2 id="h-p">Theo người</h2></div>
      <div class="lanes">${[['pa', 'Thảo', p.thao], ['jt', 'Ví chung', p.wallet], ['me', 'Mình', p.tuan]].map(([c, n, v]) => `<div class="lane"><p class="lane-n">${c === 'jt' ? '<span class="av jt" aria-hidden="true">C</span>' : UI.av(c === 'me' ? 'tuan' : 'thao')}${n}</p><p class="fig fig-m num">${fmt(v)}</p><p class="meta num">${Math.round(v / totalExp * 100)}%</p></div>`).join('')}</div>
      <p class="finding">Góp vào ví chung và quỹ tháng này: Thảo ${fmt(contrib.thao)}, mình ${fmt(contrib.tuan)}.</p></section>` : ''}
    <section class="card" aria-labelledby="h-c">
      <div class="card-h"><h2 id="h-c">Chi theo danh mục</h2><span class="meta">chạm để xem mục con</span></div>
      <div class="blist">${cats.map((c, i) => { const cc = D.cat(c.id); return `<button class="bl" aria-expanded="${i === 0}"><div class="bl-l"><span class="emo" aria-hidden="true">${cc.emoji}</span><span class="t">${cc.vi}</span><span class="meta num">${Math.round(c.amount / totalExp * 100)}%</span></div><span class="num bl-v">${fmt(c.amount)}</span><span class="bl-bar ${i === 0 ? 'top' : ''}" style="width:${c.amount / top * 100}%"></span></button>
        ${i === 0 ? kids.map((k) => `<div class="bl kid"><div class="bl-l"><span class="t">${D.cat(k.id).vi}</span></div><span class="num bl-v">${fmt(k.amount)}</span></div>`).join('') : ''}`; }).join('')}</div>
    </section>
    <section class="card" aria-labelledby="h-tr">
      <div class="card-h"><h2 id="h-tr">Chi mỗi tháng</h2>
        <div class="mini-seg" role="radiogroup" aria-label="Khoảng"><button role="radio" aria-checked="${range === 6}" data-r="6">6 tháng</button><button role="radio" aria-checked="${range === 12}" data-r="12">12 tháng</button></div></div>
      ${B.history.length ? `<div class="chart">${trend()}</div><p class="meta" style="margin-top:4px">Tháng 10 mới tính tới 20/10. Đường đứt là ngân sách tổng hiện tại.</p>` :
        `<div class="chart">${trend()}</div><p class="meta" style="margin-top:4px">Sổ chung mới có từ tháng 10, nên các tháng trước để trống.</p>`}
    </section>
    <section class="card" aria-labelledby="h-w">
      <div class="card-h"><h2 id="h-w">Chi theo ví</h2></div>
      <div class="rows">${byWallet().map(([id, v]) => { const w = B.wallets.find((x) => x.id === id); return `<div class="row"><span class="emo" aria-hidden="true">${w.emoji}</span><div class="mid"><div class="t">${w.name}</div></div><div class="amt num">${fmt(v)}</div></div>`; }).join('')}</div>
    </section>
    </main>`;
  }
  document.addEventListener('click', (e) => { const b = e.target.closest('[data-r]'); if (b) { range = +b.dataset.r; render(); } });
  render();
})();
