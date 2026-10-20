// Dữ liệu mẫu cho mockup caro-game. Cặp DEV Tuấn ♥ Thảo (test3/test4), ngày yêu 14/05/2023,
// "hôm nay" = thứ Ba 20/10/2026. Mọi con số trên các màn đều lấy từ file này; kiểm bằng console.assert.
// Mình = Tuấn (máy đang xem). Màu: Tuấn rose, Thảo teal (giả định đã chọn ở Giấc ngủ; mặc định là rose/purple).
(function () {
  const N = 15;
  const at = (r, c) => r * N + c;
  const rc = (i) => [Math.floor(i / N), i % N];

  // Hàm tham khảo cho Dev (khớp PO §6.2): chỉ xét đường qua nước vừa đi.
  // rule 'vn' = chặn hai đầu (mép bàn không tính chặn), 'free' = tự do.
  function caroWinner(cells, rule) {
    if (!cells.length) return { winner: null, line: [], full: false };
    const board = new Map(cells.map((c, i) => [c, i % 2 ? 'o' : 'x']));
    const last = cells[cells.length - 1];
    const side = board.get(last);
    const [r0, c0] = rc(last);
    for (const [dr, dc] of [[0, 1], [1, 0], [1, 1], [1, -1]]) {
      const line = [last];
      let r = r0 + dr, c = c0 + dc;
      while (r >= 0 && r < N && c >= 0 && c < N && board.get(at(r, c)) === side) { line.push(at(r, c)); r += dr; c += dc; }
      const endA = r >= 0 && r < N && c >= 0 && c < N ? board.get(at(r, c)) : 'edge';
      r = r0 - dr; c = c0 - dc;
      while (r >= 0 && r < N && c >= 0 && c < N && board.get(at(r, c)) === side) { line.unshift(at(r, c)); r -= dr; c -= dc; }
      const endB = r >= 0 && r < N && c >= 0 && c < N ? board.get(at(r, c)) : 'edge';
      const other = side === 'x' ? 'o' : 'x';
      const blockedBoth = endA === other && endB === other;
      if (line.length >= 5 && (rule === 'free' || !blockedBoth)) return { winner: side, line, full: false };
    }
    return { winner: null, line: [], full: cells.length === N * N };
  }

  // Bộ test nhỏ của luật (PO §6.2).
  const row = (r, cs) => cs.map((c) => at(r, c));
  const seq = (xs, os) => { const out = []; for (let i = 0; i < Math.max(xs.length, os.length); i++) { if (i < xs.length) out.push(xs[i]); if (i < os.length) out.push(os[i]); } return out; };
  console.assert(caroWinner(seq(row(7, [3, 4, 5, 6, 7]), row(9, [1, 2, 3, 4])), 'vn').winner === 'x', '5 ngang thắng');
  console.assert(caroWinner(seq(row(7, [3, 4, 5, 6]), row(9, [1, 2, 3])), 'vn').winner === null, '4 quân chưa thắng');
  console.assert(caroWinner(seq(row(7, [3, 4, 5, 6, 7]), [...row(7, [2, 8]), ...row(9, [1, 2])]), 'vn').winner === null, 'chặn hai đầu: không thắng');
  console.assert(caroWinner(seq(row(7, [3, 4, 5, 6, 7]), [...row(7, [2, 8]), ...row(9, [1, 2])]), 'free').winner === 'x', 'tự do: vẫn thắng');
  console.assert(caroWinner(seq(row(7, [0, 1, 2, 3, 4]), [...row(7, [5]), ...row(9, [1, 2, 3])]), 'vn').winner === 'x', 'sát mép: mép không tính chặn');

  // Ván đang chơi hôm nay: Tuấn rủ (phục thù sau ván thua hôm qua), Tuấn cầm X.
  const openMoves = [
    [7, 7, '07:58'], [6, 8, '08:41'], [8, 8, '08:45'], [9, 9, '09:02'], [6, 6, '09:03'], [5, 5, '09:30'],
    [7, 8, '09:31'], [7, 9, '09:47'], [7, 6, '09:50'], [7, 5, '09:55'], [8, 7, '09:58'], [8, 10, '10:03'],
    [9, 7, '10:05'], [6, 7, '10:12'],
  ];
  const openGame = {
    id: 'g_2026_10_20', rule: 'vn', createdBy: 'tuan', players: { x: 'tuan', o: 'thao' },
    cells: openMoves.map(([r, c]) => at(r, c)), times: openMoves.map((m) => m[2]),
    turn: 'tuan', startedOn: '20/10',
  };
  const lastOpen = openGame.cells.length - 1;
  console.assert(openGame.cells.length === 14, 'ván hôm nay: 14 nước');
  console.assert(new Set(openGame.cells).size === openGame.cells.length, 'không đặt đè ô');
  console.assert(lastOpen % 2 === 1 && openGame.turn === 'tuan', 'nước 14 là O (Thảo) nên tới lượt Tuấn (X)');
  console.assert(caroWinner(openGame.cells, 'vn').winner === null, 'ván hôm nay chưa ai thắng');

  // Ô gợi ý Tuấn đang chọn trong mockup: chặn đầu trên đường chéo 3 quân O (6,8)-(7,9)-(8,10).
  const selected = at(5, 7);
  console.assert(!openGame.cells.includes(selected), 'ô đang chọn còn trống');

  // ---- Lịch sử: 21 ván đã xong (mới nhất trước). [ngày, người rủ, người thắng, cách thắng, số nước, luật]
  const T = 'tuan', H = 'thao';
  const spec = [
    ['19/10', H, H, 'five', 31, 'vn'], ['18/10', T, T, 'five', 27, 'vn'], ['17/10', H, T, 'resign', 22, 'vn'],
    ['16/10', T, H, 'five', 40, 'vn'], ['14/10', H, T, 'five', 36, 'free'], ['13/10', T, T, 'five', 25, 'vn'],
    ['12/10', H, H, 'five', 33, 'vn'], ['11/10', T, T, 'five', 29, 'vn'], ['10/10', H, T, 'five', 44, 'vn'],
    ['08/10', T, H, 'resign', 18, 'free'], ['07/10', H, T, 'five', 30, 'vn'], ['06/10', T, T, 'five', 23, 'free'],
    ['05/10', H, H, 'five', 35, 'vn'], ['03/10', T, H, 'five', 38, 'vn'], ['02/10', H, T, 'five', 26, 'vn'],
    ['01/10', T, T, 'five', 21, 'vn'], ['29/09', H, H, 'five', 41, 'vn'], ['28/09', T, H, 'five', 32, 'vn'],
    ['26/09', H, T, 'resign', 24, 'vn'], ['24/09', T, T, 'five', 19, 'free'], ['23/09', T, H, 'five', 34, 'vn'],
  ];
  const spans = [12, 5, 9, 26, 7, 3, 14, 6, 31, 2, 8, 4, 11, 19, 6, 3, 22, 10, 7, 2, 15];

  // Bàn cuối dựng có kiểm: đường thắng + quân rải quanh tâm, không ai khác có 5.
  function rng(seed) { return () => { seed |= 0; seed = (seed + 0x6d2b79f5) | 0; let t = Math.imul(seed ^ (seed >>> 15), 1 | seed); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; }; }
  function anyFive(cells, side) {
    const set = new Set(cells.filter((_, i) => (i % 2 ? 'o' : 'x') === side));
    for (const c of set) { const [r, cc] = rc(c); for (const [dr, dc] of [[0, 1], [1, 0], [1, 1], [1, -1]]) { let k = 0; while (k < 5 && set.has(at(r + dr * k, cc + dc * k)) && cc + dc * k >= 0 && cc + dc * k < N) k++; if (k === 5) return true; } }
    return false;
  }
  function buildBoard(n, winSide, reason, rule, seed) {
    const rand = rng(seed);
    for (let attempt = 0; attempt < 400; attempt++) {
      const used = new Set(); const xs = []; const os = [];
      let line = [];
      if (reason === 'five') {
        const dirs = [[0, 1], [1, 0], [1, 1], [1, -1]]; const [dr, dc] = dirs[Math.floor(rand() * 4)];
        const r0 = 4 + Math.floor(rand() * 4), c0 = 3 + Math.floor(rand() * 5);
        line = [0, 1, 2, 3, 4].map((k) => at(r0 + dr * k, c0 + dc * k));
        line.forEach((c) => used.add(c));
      }
      const need = { x: Math.ceil(n / 2), o: Math.floor(n / 2) };
      const mine = winSide === 'x' ? xs : os; line.slice(0, 4).forEach((c) => mine.push(c));
      // Quân mới luôn sát một quân đã có (ván thật mọc thành cụm quanh nước đầu).
      let seedCenter = false; if (!used.size) { used.add(at(7, 7)); seedCenter = true; }
      const pick = () => { const all = [...used]; for (;;) { const [r0, c0] = rc(all[Math.floor(rand() * all.length)]); const r = r0 + Math.floor(rand() * 3) - 1, c = c0 + Math.floor(rand() * 3) - 1; if (r < 0 || r > 14 || c < 0 || c > 14) continue; const i = at(r, c); if (!used.has(i)) { used.add(i); return i; } } };
      const lastWin = line[4];
      if (seedCenter) xs.push(at(7, 7));
      while (xs.length < need.x - (winSide === 'x' && lastWin != null ? 1 : 0)) xs.push(pick());
      while (os.length < need.o - (winSide === 'o' && lastWin != null ? 1 : 0)) os.push(pick());
      if (lastWin != null) (winSide === 'x' ? xs : os).push(lastWin);
      // xen kẽ, đặt nước thắng cuối cùng
      const cells = []; for (let i = 0; i < n; i++) cells.push(i % 2 ? os[(i - 1) / 2] : xs[i / 2]);
      if (reason === 'five') {
        if (cells[n - 1] !== lastWin) continue;
        const w = caroWinner(cells, rule);
        if (w.winner !== winSide) continue;
        const loser = winSide === 'x' ? 'o' : 'x';
        if (anyFive(cells, loser)) continue;
        if (anyFive(cells.slice(0, -1), winSide)) continue;
        return { cells, line: w.line };
      }
      if (anyFive(cells, 'x') || anyFive(cells, 'o')) continue;
      return { cells, line: [] };
    }
    throw new Error('không dựng được bàn ' + seed);
  }

  const history = spec.map(([date, creator, winner, reason, moves, rule], i) => {
    const players = { x: creator, o: creator === T ? H : T };
    const winSide = players.x === winner ? 'x' : 'o';
    if (reason === 'five') console.assert((winSide === 'x') === (moves % 2 === 1), 'chẵn lẻ nước thắng ' + date);
    const b = buildBoard(moves, winSide, reason, rule, 1000 + i * 37);
    console.assert(b.cells.length === moves, 'số nước khớp bàn ' + date);
    return { date, creator, winner, loser: winner === T ? H : T, reason, moves, rule, players, spanHours: spans[i], ...b };
  });

  const wins = { tuan: history.filter((g) => g.winner === T).length, thao: history.filter((g) => g.winner === H).length };
  const draws = 0;
  console.assert(wins.tuan === 12 && wins.thao === 9, 'tỉ số Tuấn 12 – 9 Thảo đếm từ lịch sử');
  console.assert(history.length === wins.tuan + wins.thao + draws, 'mọi ván xong đều có kết quả');

  // Ván hôm qua (dùng cho màn kết quả): Thảo rủ, Thảo cầm X, thắng 5 quân ở nước 31.
  const yesterday = history[0];
  console.assert(yesterday.winner === H && yesterday.moves === 31 && yesterday.players.x === H, 'ván 19/10');
  Object.assign(yesterday, { startedAt: '09:40', finishedAt: '21:40' });
  console.assert(+yesterday.finishedAt.slice(0, 2) - +yesterday.startedAt.slice(0, 2) === yesterday.spanHours, 'ván 19/10 kéo dài 12 giờ');
  // Tỉ số TRƯỚC ván 19/10 (màn kết quả hiện +1 cho Thảo).
  const before = { tuan: wins.tuan, thao: wins.thao - 1 };

  // Nhắc người ấy (màn chờ): Tuấn đi nước 15 lúc 10:20, giờ là 10:38 ⇒ còn 12 phút.
  const nudge = { myMoveAt: '10:20', now: '10:38', cooldownMin: 30 };
  const mins = (s) => +s.slice(0, 2) * 60 + +s.slice(3);
  nudge.leftMin = nudge.cooldownMin - (mins(nudge.now) - mins(nudge.myMoveAt));
  console.assert(nudge.leftMin === 12, 'Nhắc được sau 12 phút');

  // Ván treo: không ai đi từ 12/10 ⇒ 8 ngày tới 20/10.
  const stale = { lastMoveOn: '12/10', days: 20 - 12 };
  console.assert(stale.days >= 7, 'ván treo đủ 7 ngày mới cho kết thúc');

  window.D = {
    N, at, rc, caroWinner, today: '20/10/2026', loveSince: '14/05/2023',
    people: { tuan: { name: 'Tuấn', initial: 'T', hue: '#FF4D6D', tint: 'rgba(255,77,109,.10)' },
              thao: { name: 'Thảo', initial: 'T', hue: '#0E9384', tint: 'rgba(14,147,132,.10)' } },
    me: 'tuan', partner: 'thao', before, openGame, selected, history, wins, draws, yesterday, nudge, stale,
    rps: { week: { wins: 3, draws: 1, losses: 2 } },
  };
})();
