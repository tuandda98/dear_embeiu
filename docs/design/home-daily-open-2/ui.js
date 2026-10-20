// Dựng từng khối Home đợt 2 từ một trạng thái D.at(...). Icon = glyph Iconsax thật (fonts/), mã ghi tên cạnh.
(function () {
  // ?w=360 ép bề ngang để soát máy Android nhỏ (Chrome headless không thu cửa sổ dưới ~500px).
  const W0 = +new URLSearchParams(location.search).get('w');
  if (W0) document.documentElement.style.width = W0 + 'px';
  const ic = (cp, bold) => `<i class="ic${bold ? ' b' : ''}" aria-hidden="true">&#x${cp.toString(16)};</i>`;
  const I = {
    sun: 0xec15, moon: 0xeb2c, care: 0xeafe /* message_favorite */, bell: 0xeb4b /* notification */,
    heart: 0xea98, heartB: 0xea9c, flag: 0xea50, starB: 0xec0e, edit: 0xea2a, lock: 0xead9,
    mood: 0xea33 /* emoji_normal */, home: 0xeaa8 /* home_2 */, weather: 0xe9d7 /* cloud_sunny */, people: 0xeb72 /* profile_2user */,
    chev: 0xe936, game: 0xea73, wallet: 0xec6d /* wallet_2 */, add: 0xe907, shuffle: 0xebe9, eat: 0xeba6 /* reserve */,
    go: 0xead3 /* location */, ask: 0xeb02 /* message_question */, offline: 0xe9ce /* cloud_cross */, clock: 0xe9c6,
    chat: 0xeb04, gallery: 0xea6a, user: 0xec4a, batLow: 0xe95a /* battery_empty */,
  };
  const { ME, PARTNER, PLACE, MOODS, LOW_BATTERY, fmtInt, fmtDur, mins } = D;
  const P = PARTNER.name;
  const hm = (iso) => iso.slice(11, 16);

  // ---------- Header pinned: chip lời chào (h1 ở trang chính) + nút quan tâm + chuông ----------
  function header(s, tag = 'h1') {
    return `<header class="tabhead"><div class="grow"><${tag} class="chip">${ic(s.greetIcon)}${s.greeting}</${tag}></div>
      <a class="hbtn" href="#" aria-label="Gửi lời quan tâm">${ic(I.care)}</a>
      <a class="hbtn" href="#" aria-label="Thông báo${s.unread ? `, ${s.unread} chưa đọc` : ''}">${ic(I.bell)}${s.unread ? `<span class="count num" aria-hidden="true">${s.unread}</span>` : ''}</a></header>`;
  }

  // ---------- CounterCard: hàng tên + tim (poke) · eyebrow · số ngày · đồng hồ · cột mốc · chuỗi ----------
  function pokeCaption(s) {
    const { m, p, queued } = s.poke;
    if (queued) return `Mất mạng. ${queued} lần chạm sẽ tự gửi khi có sóng`;
    if (!m && !p) return `Chạm tim để ${P} biết mình đang nhớ`;
    if (!m) return `${P} nhớ mình ${p} lần hôm nay`;
    if (!p) return `Mình đã nhớ ${P} ${m} lần hôm nay`;
    return `Hôm nay nhớ nhau ${m + p} lần: mình ${m}, ${P} ${p}`;
  }
  function counter(s, o = {}) {
    const head = o.waiting || o.plain
      ? `<div class="names-plain">${ME.name} <svg viewBox="0 0 24 24" aria-label="và" role="img"><path fill="currentColor" d="M12 21s-7.5-4.6-10-9.2C.3 8.5 2.2 4.5 6 4.5c2.1 0 3.4 1.1 4.2 2.3h.1c.8-1.2 2-2.3 4.1-2.3 3.8 0 5.7 4 4 7.3C19.5 16.4 12 21 12 21z"/></svg> ${P}</div>`
      : `<div class="poke-row"><span class="nm l">${ME.name}</span>
          <button class="heart-btn" type="button" aria-label="Gửi nhớ thương tới ${P}. ${pokeCaption(s)}">${s.poke.m ? ic(I.heartB, true) : ic(I.heart)}</button>
          <span class="nm r">${P}</span></div>
        <p class="poke-cap" aria-hidden="true">${pokeCaption(s)}</p>`;
    const streak = o.waiting ? '' : `<div class="streak">${ic(I.starB, true)}${s.streak.doneToday ? `${s.streak.n} ngày kết nối · hôm nay xong rồi` : `${s.streak.n} ngày kết nối · chờ trả lời hôm nay 🌸${/* taste-skill-ignore: emoji có sẵn trong chuỗi ARB đang chạy */''}`}</div>`;
    return `<section class="counter" aria-label="Thẻ đếm ngày">
      <span class="aurora a1"></span><span class="aurora a2"></span>
      <div class="inner">${head}
        <div class="eb"><i></i>HAI BẠN ĐÃ BÊN NHAU<i></i></div>
        <div class="big num">${fmtInt(s.daysTogether)}</div>
        <div class="unit">NGÀY</div>
        <div class="clock num" aria-label="Đã bên nhau ${s.clock.h} giờ"><span class="seg"><span class="v">${s.clock.h}</span><span class="l">GIỜ</span></span><span class="sep">:</span><span class="seg"><span class="v">${s.clock.m}</span><span class="l">PHÚT</span></span><span class="sep">:</span><span class="seg"><span class="v">${s.clock.s}</span><span class="l">GIÂY</span></span></div>
        <div class="ms"><div class="row">${ic(I.flag)}<span>Cột mốc ${fmtInt(s.next)} ngày</span><span class="left num">còn ${s.left} ngày</span></div>
          <div class="track"><b style="width:${(s.progress * 100).toFixed(1)}%"></b></div></div>
        ${streak}
      </div></section>`;
  }

  // ---------- Tiêu đề nhóm + ConstellationPill ----------
  function constellation(lit) {
    const pts = [[10, 18], [4, 9], [7, 3], [10, 6], [13, 3], [16, 9]];
    return `<svg viewBox="0 0 20 20" aria-hidden="true"><path d="M10 18 4 9 7 3 10 6 13 3 16 9z" fill="none" stroke="#1A1A2E" stroke-opacity=".25" stroke-width=".8"/>${pts.map(([x, y], i) => `<circle cx="${x}" cy="${y}" r="1.7" fill="${i < lit ? (i % 2 ? '#0E9384' : '#FF4D6D') : 'rgba(26,26,46,.22)'}"/>`).join('')}</svg>`;
  }
  const sectionToday = (s, waiting) => `<div class="sec"><h2>Hôm nay của chúng mình</h2>${waiting ? '' : `<a class="pill-c num" href="#" aria-label="Cây tình yêu, ${s.lit} trên 6 sao hôm nay">${constellation(s.lit)}${s.lit}/6</a>`}</div>`;

  // ---------- Câu hỏi hôm nay (TodayRitualCard — không đổi) ----------
  function ritual(s, o = {}) {
    let body;
    if (o.waiting) body = `<p style="margin-top:14px;font-size:13px;line-height:19px;color:var(--ink2)">Ghép đôi xong là chúng mình sẽ cùng trả lời một câu hỏi như vầy mỗi ngày 💞${/* taste-skill-ignore: emoji có sẵn trong chuỗi ARB đang chạy */''}</p>`;
    else if (s.answered.p && !s.answered.m) body = `<div class="locked" aria-label="Câu trả lời của ${P} đang khoá"><div class="bar"></div><div class="bar" style="width:88%"></div><div class="bar" style="width:55%"></div>
        <div class="who">${ic(I.lock)}${P} đã trả lời rồi đó 👀${/* taste-skill-ignore: emoji có sẵn trong chuỗi ARB đang chạy */''}</div></div>
        <button class="compose em" type="button">${ic(I.edit)}Trả lời để mở khoá câu trả lời của người ấy</button>`;
    else body = `<button class="compose" type="button">${ic(I.edit)}Chạm để trả lời…</button>`;
    return `<article class="card ritual" aria-label="Câu hỏi hôm nay"><p class="q">${s.question}</p>${body}</article>`;
  }

  // ---------- MỚI: bảng "Thảo hôm nay thế nào?" ----------
  const lane = (who, inner) => `<div class="cell ${who === 'm' ? 'me' : 'p'}">${inner}</div>`;
  const mid = (icon, label, cls = '') => `<div class="mid ${cls}">${ic(icon)}<span>${label}</span></div>`;
  const main = (who, parts) => `<div class="main">${who === 'm' ? parts.join('') : parts.slice().reverse().join('')}</div>`;

  function moodCell(s, who) {
    const v = s.moods[who];
    if (!v) return who === 'm' ? `<button class="mini" type="button">${ic(I.mood)}Chọn</button>` : `<p class="muted">Chưa chọn</p>`;
    const [glyph, word] = MOODS[v.key];
    return main(who, [`<span class="glyph" aria-hidden="true">${glyph}</span>`, `<span class="t">${word}</span>`]) + (v.note ? `<p class="sub one">“${v.note}”</p>` : '');
  }
  function when(s, e) { const d = e.at.slice(0, 10); return d === s.date ? hm(e.at) : `hôm qua ${hm(e.at)}`; }
  function arrivalCell(s, who) {
    const e = s.arrival[who];
    if (!e) return who === 'm' ? `<p class="muted">Chưa bật</p><p class="sub"><b>Bật báo về nhà</b></p>` : `<p class="muted">Chưa bật</p>`;
    const low = who === 'p' && e.battery != null && e.battery <= LOW_BATTERY;
    let line1 = `<span class="num">${when(s, e)}</span>`;
    if (who === 'p' && !low && e.battery != null) line1 += ` · pin ${e.battery}%`;
    // Dòng 2 của bạn = mình đang chia sẻ thế nào (arrival D11); của người ấy = pin yếu.
    const line2 = who === 'm'
      ? `<p class="sub one">${e.pending ? `${ic(I.offline)} chờ mạng` : e.source === 'manual' ? 'Báo bằng tay' : 'Tự báo đang bật'}</p>`
      : low ? `<span class="batt">${ic(I.batLow)}Pin còn ${e.battery}%</span>` : '';
    return main(who, [`<span class="t">${PLACE[e.place][e.type]}</span>`]) + `<p class="sub one">${line1}</p>` + line2;
  }
  function weatherCell(s, who) {
    const w = s.weather[who];
    const notable = w.cond.kind !== 'sky';
    return main(who, [`<span class="fig num">${w.temp}°</span>`, ic(w.icon)]) + `<p class="sub one">${w.city}</p><p class="sub">${notable ? `<b>${w.cond.text}</b>` : w.cond.text}</p>`;
  }
  function sleepCell(s, who) {
    const n = s.sleep[who];
    const [h, m] = [Math.floor(n.min / 60), n.min % 60];
    return main(who, [`<span class="fig num">${h}<small>g</small> ${m}<small>p</small></span>`]) + `<p class="sub num">${n.bed}–${n.wake}</p>`;
  }
  const rowAria = (label, mine, theirs) => `${label}. Bạn: ${mine}. ${P}: ${theirs}`;
  const strip = (html) => html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
  function brow(s, label, icon, fn, o = {}) {
    const a = fn(s, 'm'), b = fn(s, 'p');
    return `<div class="brow tap" role="button" tabindex="0" aria-label="${rowAria(label, strip(a), strip(b))}">${lane('m', a)}${mid(icon, label, o.cls)}${lane('p', b)}</div>`;
  }
  function board(s, o = {}) {
    if (o.waiting) {
      const row = (label, icon, fn) => `<div class="brow tap" role="button" tabindex="0">${mid(icon, label)}${lane('m', fn(s, 'm'))}</div>`;
      return `<article class="card board solo" aria-labelledby="bd-t"><div class="chead"><span class="badge">${ic(I.people)}</span><h2 id="bd-t">Hôm nay của bạn</h2></div>
        <div style="margin-top:8px">${row('Thời tiết', I.weather, weatherCell)}${(o.rows || ['weather', 'sleep']).includes('sleep') ? row('Đêm qua', I.moon, sleepCell) : ''}</div></article>`;
    }
    const matched = s.moods.m && s.moods.p && s.moods.m.key === s.moods.p.key;
    const stamp = s.offline ? `<span class="stamp">${ic(I.offline)}Mất mạng · số lúc ${s.weather.fetchedAt}</span>` : '';
    const sent = o.sentHome;
    const homeBtn = sent
      ? `<button class="btn outline sent" type="button" aria-pressed="true">${ic(sent === 'queued' ? I.offline : 0xec2a)}Về nhà rồi</button>`
      : `<button class="btn outline" type="button">${ic(I.home)}Về nhà rồi</button>`;
    const careBtn = s.care ? `<button class="btn outline" type="button">${ic(s.care.icon)}${s.care.label}</button>` : '';
    const note = sent === 'queued' ? `<div class="strip" role="status">${ic(I.offline)}<span>Sẽ báo khi có mạng. Quá 30 phút thì ${P} chỉ thấy trên thẻ, không nhận thông báo.</span></div>` : '';
    return `<article class="card board" id="board" aria-labelledby="bd-t">
      <div class="chead"><span class="badge">${ic(I.people)}</span><div style="flex:1;min-width:0"><h2 id="bd-t">${P} hôm nay thế nào?</h2>${stamp}</div></div>
      <div class="lanes-h" aria-hidden="true"><span class="person"><i style="background:${ME.color}"></i>Bạn</span><span></span><span class="person r">${P}<i style="background:${PARTNER.color}"></i></span></div>
      ${(o.rows || ['mood', 'arrival', 'weather', 'sleep']).map((r) => ({
        mood: () => brow(s, matched ? 'Giống nhau' : 'Tâm trạng', matched ? I.heartB : I.mood, moodCell, { cls: matched ? 'match' : '' }),
        arrival: () => brow(s, 'Đến nơi', I.home, arrivalCell),
        weather: () => brow(s, 'Thời tiết', I.weather, weatherCell),
        sleep: () => brow(s, 'Đêm qua', I.moon, sleepCell),
      })[r]()).join('')}
      <div class="bfoot">${homeBtn}${careBtn}</div>${note}
    </article>`;
  }

  // ---------- Chơi cùng nhau (spec caro-game §3.1) ----------
  const caroBadge = (ping) => `<span class="badge soft" aria-hidden="true"><svg viewBox="0 0 26 26"><path d="M13 3v20M3 13h20" stroke="#1A1A2E" stroke-opacity=".18" stroke-width="1.2"/><path d="M4.5 4.5l6 6M10.5 4.5l-6 6" stroke="${ME.color}" stroke-width="2.2" stroke-linecap="round"/><circle cx="18.5" cy="18.5" r="3.6" fill="none" stroke="${PARTNER.color}" stroke-width="2.2"/></svg>${ping ? '<span class="ping"></span>' : ''}</span>`;
  function play(s) {
    const c = s.caro, myTurn = c.moves % 2 === 0;
    const caroLine = myTurn ? `Đến lượt bạn. ${P} vừa đi nước ${c.moves}.` : `Đang chờ ${P}.`;
    return `<article class="card play" aria-labelledby="pl-t"><h2 class="ttl" id="pl-t">Chơi cùng nhau</h2>
      <a class="game-row" href="#" aria-label="Cờ caro. ${caroLine}">${caroBadge(myTurn)}<span><span class="t">Cờ caro</span><br><span class="s${myTurn ? ' on' : ''}">${caroLine}</span></span><span class="btn h40${myTurn ? '' : ' outline'}">${myTurn ? 'Đi tiếp' : 'Xem'}</span></a>
      <a class="game-row" href="#" aria-label="Oẳn tù tì. Tuần này ${c.rpsWeek.w} thắng ${c.rpsWeek.d} hoà ${c.rpsWeek.l} thua"><span class="badge rps" aria-hidden="true">${ic(I.game)}</span><span><span class="t">Oẳn tù tì</span><br><span class="s num">Tuần này ${c.rpsWeek.w} – ${c.rpsWeek.d} – ${c.rpsWeek.l}</span></span><span class="btn h40 outline">Chơi</span></a></article>`;
  }

  // ---------- Sổ tiền (spec expenses §3.1, IconBadge theo Lead) ----------
  function money(s, o = {}) {
    const m = s.money;
    const pct = Math.floor(m.spent * 100 / m.budget);
    const t = o.waiting ? 'Sổ tiền của mình' : 'Sổ chung tháng 10';
    const sub = o.waiting ? `Hôm nay đã ghi ${m.todayEntriesOwn} khoản`
      : s.offline ? `<b class="num">${fmtInt(m.spent)} ₫</b> · số lúc ${m.cachedAt}`
      : `Đã chi <b class="num">${fmtInt(m.spent)} ₫</b> · ${pct}% ngân sách`;
    return `<article class="card"><div class="money"><span class="badge">${ic(I.wallet)}</span>
      <a class="txt" href="#"><h2 class="t">${t}</h2><p class="s">${sub}</p></a>
      <button class="round" type="button" aria-label="Ghi khoản">${ic(I.add)}</button></div></article>`;
  }

  // ---------- Phân vân gì không? (DecisionCard — không đổi) ----------
  function decide(s) {
    const e = s.decisions.eat;
    const eat = e ? `<div class="drow done"><span class="badge sm">${ic(I.eat)}</span><div class="txt"><p class="lab">HÔM NAY ĂN</p><p class="t">${e.result}</p><p class="s">${e.by === 'p' ? P : 'Mình'} quay · ${e.at}</p></div><span class="chev">${ic(I.chev)}</span></div>`
      : `<div class="drow"><span class="badge sm">${ic(I.eat)}</span><div class="txt"><p class="t">Ăn gì?</p><p class="s">Chưa ai quay hôm nay</p></div><span class="spin">${ic(I.shuffle)}Quay</span></div>`;
    return `<article class="card decide" aria-labelledby="dc-t"><div class="chead"><span class="badge">${ic(I.shuffle)}</span><h2 id="dc-t">Phân vân gì không?</h2><a class="textlink" href="#">Đã quay</a></div>
      ${eat}<div class="hl"></div>
      <div class="drow"><span class="badge sm lav">${ic(I.go)}</span><div class="txt"><p class="t">Đi đâu?</p><p class="s">Chưa ai quay hôm nay</p></div><span class="spin">${ic(I.shuffle)}Quay</span></div><div class="hl"></div>
      <div class="drow"><span class="badge sm navy">${ic(I.ask)}</span><div class="txt"><p class="t">Phân vân khác</p><p class="s">Ai rửa bát, xem phim gì…</p></div><span class="spin">${ic(I.edit)}Nhập &amp; quay</span></div></article>`;
  }

  // ---------- Kỷ niệm gần đây (MemoryCinema — không đổi) ----------
  function memories(s) {
    const p = s.photos[0];
    return `<div class="sec"><h2>Kỷ niệm gần đây</h2><a class="link" href="#">Xem tất cả</a></div>
      <a class="cinema" href="#" style="display:block;background-image:url(${p.src})" role="img" aria-label="${p.caption}, ${p.by} đăng ${p.ago}. Ảnh 1 trên 5"><div class="cap"><p class="t">${p.caption}</p><p class="s">${p.by} · ${p.ago}</p></div><div class="dots" aria-hidden="true"><i class="on"></i><i></i><i></i><i></i><i></i></div></a>`;
  }

  // ---------- Banner chờ người ấy (giữ nguyên) ----------
  const waitBanner = () => `<article class="card wait" aria-label="Chờ người ấy"><span class="wbadge">${ic(I.heartB, true)}CHỜ NGƯỜI ẤY</span>
    <div class="step"><span class="n">1</span><div><p class="t">Gửi lời mời</p><p class="d">Gửi mã qua tin nhắn, hoặc cho người ấy quét mã QR nếu đang ở cạnh nhau.</p>
      <p class="code num">HN7Q2K</p><button class="btn" type="button">Gửi cho người ấy 💌${/* taste-skill-ignore: emoji có sẵn trong chuỗi ARB đang chạy */''}</button>
      <div class="twin"><a class="textlink" href="#">Sao chép mã</a><a class="textlink" href="#">Mã QR</a></div></div></div>
    <div class="step"><span class="n">2</span><div><p class="t">Người ấy tải app và đăng ký</p><p class="d">Người ấy cần cài Dear Embeiu (iOS/Android), đăng ký rồi chọn &lt;Tham gia bằng mã&gt;.</p></div></div>
    <div class="step"><span class="n">3</span><div><p class="t">Nhập mã là xong</p><p class="d">Ghép xong app tự chuyển, bạn sẽ nhận thông báo.</p></div></div></article>`;


  // ======== BẢN B (không gộp): MoodCard + SleepCard đúng khuôn app ========
  // mood_card.dart: ContentCard pad 20 · ô 36 r12 rose .12 + emoji_happy Bold 20 · tiêu đề sectionTitleStyle
  // · 16 · hai cột (nhãn 11 w700 textTertiary IN HOA · 10 · mặt 56 nền rose .10 · 8 · chữ 14 w700 · 4 · ghi chú 12)
  // · vạch dọc surfaceLight · 16 · nút pill h48 surfaceLight "Đổi tâm trạng" (chưa chia sẻ: sunsetRomance "Chia sẻ tâm trạng").
  function moodSide(s, who) {
    const v = s.moods[who];
    const label = who === 'm' ? 'Bạn' : P;
    if (!v) return `<div class="mside"><p class="ml">${label}</p><span class="mface empty">${ic(who === 'm' ? I.add : I.mood)}</span><p class="mempty">${who === 'm' ? 'Chạm để chia sẻ' : `${P} chưa chia sẻ hôm nay`}</p></div>`;
    const [glyph, word] = MOODS[v.key];
    return `<div class="mside"><p class="ml">${label}</p><span class="mface" aria-hidden="true">${glyph}</span><p class="mw">${word}</p>${v.note ? `<p class="mn">“${v.note}”</p>` : ''}</div>`;
  }
  function moodCard(s) {
    const shared = !!s.moods.m;
    return `<article class="card mood" aria-labelledby="md-t"><div class="mhead"><span class="msq">${ic(0xea36, true)}</span><h2 id="md-t">Tâm trạng hôm nay</h2></div>
      <div class="mcols">${moodSide(s, 'm')}<span class="mvr"></span>${moodSide(s, 'p')}</div>
      <button class="mbtn${shared ? '' : ' first'}" type="button">${shared ? ic(I.edit) + 'Đổi tâm trạng' : ic(I.heartB, true) + 'Chia sẻ tâm trạng'}</button></article>`;
  }
  // sleep_card.dart: ContentCard pad 16 · IconBadge moon lavenderDeep + "Đêm qua" 16 w800 + chevron · 14
  // · hai cột (PersonLabel · 8 · MoonGlyph 30 + DurationText 22 w800 / giờ 12) · vạch α.10 · 14 · vạch ngang · 12 · tim 12 + "Ngủ cùng lúc …".
  const moon = (color) => `<svg class="moon" viewBox="0 0 30 30" aria-hidden="true"><circle cx="15" cy="15" r="13" fill="${color}" fill-opacity=".16"/><path d="M19 4.5a11 11 0 1 0 6.5 15A9 9 0 0 1 19 4.5z" fill="${color}"/></svg>`;
  function sleepCol(s, who) {
    const n = s.sleep[who];
    const [h, m] = [Math.floor(n.min / 60), n.min % 60];
    const color = who === 'm' ? ME.color : PARTNER.color;
    return `<div class="scol"><span class="person"><i style="background:${color}"></i>${who === 'm' ? 'Bạn' : P}</span>
      <div class="srow">${moon(color)}<div><p class="sdur num">${h}<small>g</small> ${m}<small>p</small></p><p class="srange num">${n.bed}–${n.wake}</p></div></div></div>`;
  }
  function sleepCard(s, o = {}) {
    const ov = Math.min(D.mins(s.sleep.m.wake), D.mins(s.sleep.p.wake)) - Math.max(D.mins(s.sleep.m.bed) + (D.mins(s.sleep.m.bed) > 720 ? -1440 : 0), D.mins(s.sleep.p.bed) + (D.mins(s.sleep.p.bed) > 720 ? -1440 : 0));
    const gap = (D.mins(s.sleep.m.bed) + (D.mins(s.sleep.m.bed) > 720 ? -1440 : 0)) - (D.mins(s.sleep.p.bed) + (D.mins(s.sleep.p.bed) > 720 ? -1440 : 0));
    const first = Math.abs(gap) >= 10 ? ` · ${gap > 0 ? P : 'Bạn'} ngủ trước ${Math.abs(gap)}p` : '';
    const together = `Ngủ cùng lúc ${D.fmtDur(ov)}${first}`;
    if (o.waiting) return `<article class="card sleep"><div class="chead"><span class="badge lav">${ic(I.moon)}</span><h2>Đêm qua</h2><span class="chev">${ic(I.chev)}</span></div><div class="scols one">${sleepCol(s, 'm')}</div></article>`;
    return `<article class="card sleep" aria-labelledby="sl-t"><div class="chead"><span class="badge lav">${ic(I.moon)}</span><h2 id="sl-t">Đêm qua</h2><span class="chev">${ic(I.chev)}</span></div>
      <div class="scols">${sleepCol(s, 'm')}<span class="svr"></span>${sleepCol(s, 'p')}</div>
      <div class="sfoot">${ic(I.heartB, true)}<span>${together}</span></div></article>`;
  }
  // Thứ tự B: thẻ đếm → câu hỏi → Tâm trạng → bảng (Đến nơi + Thời tiết) → Đêm qua → Chơi → Sổ tiền → Phân vân → Kỷ niệm.
  function homeB(s, o = {}) {
    const blocks = [counter(s), sectionToday(s), `<div class="stack">${ritual(s)}${moodCard(s)}${board(s, { ...o, rows: ['arrival', 'weather'] })}${sleepCard(s)}${play(s)}${money(s)}${decide(s)}</div>`, memories(s)];
    return `<div class="home">${header(s, o.h1 === false ? 'p' : 'h1')}<main class="scroll">${blocks.join('')}${o.after || ''}</main>${nav()}</div>`;
  }

  // ======== BẢN C (bản chọn, 2026-10-20): không poke, mỗi thứ một thẻ ========
  // Thẻ "Về đến nhà chưa?" (arrival/home-card.html) đảo thành hai làn như SleepCard: Bạn trái · người ấy phải.
  // Spec arrival D7 mới: nút chính "Về nhà rồi" + nút phụ "Đến nơi rồi" (mở sheet chọn nơi tự đặt tên), cả hai ở làn Bạn.
  function arrivalLane(s, who) {
    const e = s.arrival[who];
    const color = who === 'm' ? ME.color : PARTNER.color;
    const label = `<span class="person"><i style="background:${color}"></i>${who === 'm' ? 'Bạn' : P}</span>`;
    if (!e) return `<div class="alane">${label}<p class="aline muted">Chưa bật báo về nhà</p></div>`;
    const low = who === 'p' && e.battery != null && e.battery <= LOW_BATTERY;
    let meta = `<span class="num">${when(s, e)}</span>`;
    if (who === 'p' && !low && e.battery != null) meta += ` · pin ${e.battery}%`;
    if (who === 'm') meta += e.pending ? ' · chờ mạng' : e.source === 'manual' ? ' · bấm tay' : ' · tự báo';
    return `<div class="alane">${label}<p class="aline">${D.placeLine(who, e)}</p><p class="ameta">${meta}</p>${low ? `<span class="batt">${ic(I.batLow)}Pin còn ${e.battery}%</span>` : ''}
      ${who === 'm' ? `<div class="abtns"><button class="btn outline h40" type="button">${ic(I.home)}Về nhà rồi</button><button class="textlink abtn2" type="button" aria-haspopup="dialog">${ic(I.go)}Đến nơi rồi</button></div>` : ''}</div>`;
  }
  function arrivalCardC(s) {
    return `<article class="card arrive" aria-labelledby="ar-t"><div class="chead"><span class="badge">${ic(I.home)}</span><h2 id="ar-t">Về đến nhà chưa?</h2><span class="chev">${ic(I.chev)}</span></div>
      <div class="alanes">${arrivalLane(s, 'm')}<span class="svr"></span>${arrivalLane(s, 'p')}</div></article>`;
  }
  // Thẻ "Thời tiết hai nơi" (weather/home.html) đảo làn: Bạn trái · người ấy phải. Hàng chung chỉ khi có nút gợi ý hoặc chênh ≥ 5°.
  function wxLane(s, who) {
    const w = s.weather[who];
    const color = who === 'm' ? ME.color : PARTNER.color;
    return `<div class="wlane"><p class="who"><i class="dot" style="background:${color}"></i><span class="name">${who === 'm' ? 'Bạn' : P}</span><span class="city">· ${w.city}</span></p>
      <div class="now"><span class="temp num">${w.temp}°</span>${ic(w.icon)}</div><p class="cond">${w.cond.text}</p></div>`;
  }
  function weatherCardC(s, o = {}) {
    const k = s.weather.p.cond.kind;
    const gap = Math.abs(s.weather.p.temp - s.weather.m.temp);
    const shared = o.waiting ? '' : D.CARE[k] ? `<div class="wshared"><button class="btn" type="button">${ic(0xe9cf)}${D.CARE[k]}</button></div>`
      : gap >= 5 ? `<div class="wshared"><span>Chỗ ${P} ${s.weather.p.temp < s.weather.m.temp ? 'lạnh' : 'nóng'} hơn ${gap}°</span></div>` : '';
    const stamp = `<span class="sub">${s.offline ? `Số lúc ${s.weather.fetchedAt}` : `Cập nhật ${s.weather.fetchedAt}`}</span>`;
    return `<article class="card weather" aria-labelledby="wx-t"><div class="chead"><span class="badge">${ic(I.weather)}</span><div style="flex:1;min-width:0"><h2 id="wx-t">Thời tiết hai nơi</h2>${stamp}</div><span class="chev">${ic(I.chev)}</span></div>
      <div class="wlanes${o.waiting ? ' one' : ''}">${wxLane(s, 'm')}${o.waiting ? '' : `<span class="svr"></span>${wxLane(s, 'p')}`}</div>${shared}</article>`;
  }
  // Thứ tự C: thẻ đếm → câu hỏi → Tâm trạng → Về đến nhà chưa? → Thời tiết → Đêm qua → Chơi → Sổ tiền → Phân vân → Kỷ niệm.
  function homeC(s, o = {}) {
    const W = !!o.waiting;
    const blocks = W
      ? [counter(s, { waiting: true }), `<div style="margin-top:16px">${waitBanner()}</div>`, sectionToday(s, true),
         `<div class="stack">${ritual(s, { waiting: true })}${weatherCardC(s, { waiting: true })}${sleepCard(s, { waiting: true })}${money(s, { waiting: true })}${decide(s)}</div>`, memories(s)]
      : [counter(s, { plain: true }), sectionToday(s),
         `<div class="stack">${ritual(s)}${moodCard(s)}${arrivalCardC(s)}${weatherCardC(s)}${sleepCard(s)}${play(s)}${money(s)}${decide(s)}</div>`, memories(s)];
    return `<div class="home">${header(s, o.h1 === false ? 'p' : 'h1')}<main class="scroll">${blocks.join('')}${o.after || ''}</main>${nav()}</div>`;
  }

  const nav = () => `<nav class="nav" aria-label="Điều hướng chính"><a href="#" aria-current="page">${ic(I.heartB, true)}<span>Trang chủ</span></a><a href="#">${ic(I.chat)}<span>Trò chuyện</span></a><a href="#">${ic(I.gallery)}<span>Thư viện</span></a><a href="#">${ic(I.user)}<span>Hồ sơ</span></a></nav>`;

  // ---------- Cả màn Home theo thứ tự đã chốt ----------
  function home(s, o = {}) {
    const W = !!o.waiting;
    const blocks = W
      ? [counter(s, o), `<div style="margin-top:16px">${waitBanner()}</div>`, sectionToday(s, true), `<div class="stack">${ritual(s, o)}${board(s, o)}${money(s, o)}${decide(s)}</div>`, memories(s)]
      : [counter(s), sectionToday(s), `<div class="stack">${ritual(s)}${board(s, o)}${play(s)}${money(s)}${decide(s)}</div>`, memories(s)];
    return `<div class="home">${header(s, o.h1 === false ? 'p' : 'h1')}<main class="scroll">${blocks.join('')}${o.after || ''}</main>${nav()}</div>`;
  }

  // ?measure=1: ghi chiều cao từng khối (px CSS) vào #measure để Designer đối chiếu với ước tính trong design.md.
  if (new URLSearchParams(location.search).get('measure')) {
    addEventListener('load', () => document.fonts.ready.then(() => {
      const q = (sel) => [...document.querySelectorAll(sel)].map((el) => Math.round(el.getBoundingClientRect().height));
      const out = { counter: q('.counter'), ritual: q('.ritual'), board: q('.board'), play: q('.play'), money: q('.money'), decide: q('.decide'), cinema: q('.cinema'), mood: q('.mood'), sleep: q('.sleep'), arrive: q('.arrive'), weather: q('.weather'), wait: q('.wait'), scroll: q('.scroll') };
      const pre = document.createElement('pre'); pre.id = 'measure'; pre.textContent = JSON.stringify(out); document.body.append(pre);
    }));
  }

  window.UI = { ic, I, homeC, homeB, moodCard, sleepCard, home, header, counter, ritual, board, play, money, decide, memories, nav };
})();
