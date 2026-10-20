// Dựng chung cho các trang mockup caro. Đọc window.D (data.js).
(function () {
  const P = D.people;
  const ICON = {
    back: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M15 5l-7 7 7 7"/></svg>',
    more: '<svg viewBox="0 0 24 24" fill="currentColor"><circle cx="5" cy="12" r="1.7"/><circle cx="12" cy="12" r="1.7"/><circle cx="19" cy="12" r="1.7"/></svg>',
    clock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/></svg>',
    grid: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 9h18M3 15h18M9 3v18M15 3v18"/></svg>',
    zoomIn: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5M8 11h6M11 8v6"/></svg>',
    zoomOut: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5M8 11h6"/></svg>',
    warn: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"><circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.5v.01"/></svg>',
    wifi: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><path d="M2 8.5a15 15 0 0120 0M5 12a10 10 0 0114 0M8.5 15.5a5 5 0 017 0M12 19h.01M3 3l18 18"/></svg>',
    game: '<svg viewBox="0 0 24 24" fill="currentColor"><path d="M7 6h10a5 5 0 015 5v2a5 5 0 01-8.6 3.5L12 15l-1.4 1.5A5 5 0 012 13v-2a5 5 0 015-5zm1 4v1.5H6.5v1.5H8v1.5h1.5V13H11v-1.5H9.5V10H8zm7.5.5a1 1 0 100 2 1 1 0 000-2zm2 2a1 1 0 100 2 1 1 0 000-2z"/></svg>',
  };
  // Quân X / O vẽ trong ô cỡ s (đơn vị SVG), tâm (cx, cy).
  function mark(side, cx, cy, s, color, extra = '') {
    const k = s * 0.26, w = Math.max(2.2, s * 0.11);
    if (side === 'x') return `<g ${extra} stroke="${color}" stroke-width="${w}" stroke-linecap="round"><path d="M${cx - k} ${cy - k}L${cx + k} ${cy + k}M${cx + k} ${cy - k}L${cx - k} ${cy + k}"/></g>`;
    return `<circle ${extra} cx="${cx}" cy="${cy}" r="${s * 0.28}" fill="none" stroke="${color}" stroke-width="${w}"/>`;
  }
  const sideOf = (game, who) => (game.players.x === who ? 'x' : 'o');
  const hueOfSide = (game, side) => P[game.players[side]].hue;
  function glyph(side, color) { return `<svg viewBox="0 0 16 16" aria-hidden="true">${mark(side, 8, 8, 16, color)}</svg>`; }

  // Bàn 15×15. opts: {px (bề rộng hiển thị ở 1×), zoom, selected, line, lastMark, pending, cellsOverride}
  function board(game, o = {}) {
    const S = 24, N = D.N, cells = o.cells || game.cells;
    const sizePx = (o.px || 346) * (o.zoom || 1);
    let g = '';
    for (let k = 1; k < N; k++) g += `M${k * S} 0V${N * S}M0 ${k * S}H${N * S}`;
    let fills = '', band = '', marks = '';
    const lastIdx = o.noLast ? -1 : cells.length - 1;
    if (lastIdx >= 0) { const [r, c] = D.rc(cells[lastIdx]); const side = lastIdx % 2 ? 'o' : 'x'; fills += `<rect x="${c * S}" y="${r * S}" width="${S}" height="${S}" fill="${hueOfSide(game, side)}" fill-opacity=".16"/>`; }
    if (o.line && o.line.length) {
      const side = (cells.indexOf(o.line[0]) % 2) ? 'o' : 'x'; const hue = hueOfSide(game, side);
      o.line.forEach((i) => { const [r, c] = D.rc(i); fills += `<rect x="${c * S}" y="${r * S}" width="${S}" height="${S}" fill="${hue}" fill-opacity=".16"/>`; });
      const [r1, c1] = D.rc(o.line[0]), [r2, c2] = D.rc(o.line[o.line.length - 1]);
      band = `<path d="M${c1 * S + S / 2} ${r1 * S + S / 2}L${c2 * S + S / 2} ${r2 * S + S / 2}" stroke="${hue}" stroke-opacity=".30" stroke-width="${S * 0.55}" stroke-linecap="round"/>`;
    }
    cells.forEach((i, n) => { const [r, c] = D.rc(i); const side = n % 2 ? 'o' : 'x'; marks += mark(side, c * S + S / 2, r * S + S / 2, S, hueOfSide(game, side), n === lastIdx && o.drop ? 'class="drop"' : ''); });
    if (o.selected != null) {
      const [r, c] = D.rc(o.selected); const side = cells.length % 2 ? 'o' : 'x';
      fills += `<rect x="${c * S + 1.5}" y="${r * S + 1.5}" width="${S - 3}" height="${S - 3}" rx="4" fill="none" stroke="#1A1A2E" stroke-width="2"/>`;
      marks += mark(side, c * S + S / 2, r * S + S / 2, S, hueOfSide(game, side), `opacity="${o.pending ? 0.6 : 0.45}"`);
    }
    return `<svg width="${sizePx}" height="${sizePx}" viewBox="0 0 ${N * S} ${N * S}" role="img" aria-label="${o.label || 'Bàn cờ 15 x 15'}">
      <rect width="${N * S}" height="${N * S}" fill="#fff"/>${fills}
      <path d="${g}" stroke="#1A1A2E" stroke-opacity=".12" stroke-width="1" vector-effect="non-scaling-stroke"/>${band}${marks}</svg>`;
  }

  // Bàn thu nhỏ cho dòng lịch sử (44 px).
  function thumb(game) {
    const S = 4, N = D.N; let s = '';
    if (game.line.length) { const [r1, c1] = D.rc(game.line[0]), [r2, c2] = D.rc(game.line[4]); const hue = P[game.winner].hue; s += `<path d="M${c1 * S + 2} ${r1 * S + 2}L${c2 * S + 2} ${r2 * S + 2}" stroke="${hue}" stroke-opacity=".35" stroke-width="5" stroke-linecap="round"/>`; }
    game.cells.forEach((i, n) => { const [r, c] = D.rc(i); s += `<circle cx="${c * S + 2}" cy="${r * S + 2}" r="1.3" fill="${P[game.players[n % 2 ? 'o' : 'x']].hue}"/>`; });
    return `<svg width="44" height="44" viewBox="0 0 ${N * S} ${N * S}" aria-hidden="true"><rect width="60" height="60" rx="8" fill="#F5F0F5"/>${s}</svg>`;
  }

  function header(chip, trailing) {
    return `<header class="hdr"><button class="icon-btn" aria-label="Quay lại">${ICON.back}</button>
      <span class="chip">${ICON.game}${chip}</span>
      ${trailing ? `<button class="icon-btn" aria-label="${trailing.label}">${ICON[trailing.icon]}</button>` : '<span></span>'}</header>`;
  }

  // Ba làn: mình (trái) · luật + nước (giữa) · người ấy (phải). turn: 'me'|'partner'|null.
  function lanes(game, { turn = null, watching = false, wins = D.wins, plus = null, move, me = D.me, skeleton = false, midText } = {}) {
    const pa = me === 'tuan' ? 'thao' : 'tuan';
    if (skeleton) return `<div class="lanes" aria-hidden="true"><div class="lane"><span class="bar" style="width:64px;height:20px"></span><span class="bar" style="width:28px;height:26px;margin-top:2px"></span><span class="bar" style="width:40px;height:14px"></span></div><div class="mid"><span class="bar" style="width:84px;height:16px"></span></div><div class="lane" style="justify-items:end"><span class="bar" style="width:64px;height:20px"></span><span class="bar" style="width:28px;height:26px;margin-top:2px"></span><span class="bar" style="width:40px;height:14px"></span></div></div>`;
    const capMe = plus === 'me' ? `<span class="cap on">+1 ván này</span>` : `<span class="cap">thắng</span>`;
    const capPa = watching ? `<span class="cap on"><span class="dot" style="background:${P[pa].hue}"></span> đang xem</span>` : plus === 'partner' ? `<span class="cap on">+1 ván này</span>` : `<span class="cap">thắng</span>`;
    const rule = game.rule === 'free' ? 'Tự do' : 'Chặn hai đầu';
    return `<div class="lanes">
      <div class="lane me"${turn === 'me' ? ` style="background:${P[me].tint}"` : ''}><span class="who">${glyph(sideOf(game, me), P[me].hue)}${P[me].name}</span><span class="score num">${wins[me]}</span>${capMe}</div>
      <div class="mid"><span class="rule">${midText || rule}</span><span class="move num">${move == null ? '' : move === 0 ? 'ván mới' : 'nước ' + move}</span></div>
      <div class="lane partner"${turn === 'partner' ? ` style="background:${P[pa].tint}"` : ''}><span class="who">${P[pa].name}${glyph(sideOf(game, pa), P[pa].hue)}</span><span class="score num">${wins[pa]}</span>${capPa}</div>
    </div>`;
  }

  window.UI = { ICON, mark, glyph, board, thumb, header, lanes, sideOf, P };
})();
