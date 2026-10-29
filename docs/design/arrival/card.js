// Thẻ Home "Về đến nhà chưa?" bản 2: hai làn, Bạn trái · người ấy phải (Lead chốt 2026-10-20), thẻ đứng riêng.
(function () {
  const { I, iconOf } = UI;
  const pn = D.people.partner.name;
  function when(e) {
    const day = e.at.slice(0, 10), t = D.hm(e.at);
    if (day === D.NOW.slice(0, 10)) return t;
    if (day === '2026-10-19') return `hôm qua ${t}`;
    return `${+day.slice(8, 10)}/${+day.slice(5, 7)} ${t}`;
  }
  const battery = (e) => (e.battery == null ? '' : D.low(e)
    ? `<span class="bat low">${I.batLow(14)}Pin còn ${e.battery}%</span>`
    : `<span class="bat">${I.bat(14)}${e.battery}%</span>`);
  const label = (who) => `<div class="who"><i style="background:var(--${who === 'me' ? 'tuan' : 'thao'})"></i>${who === 'me' ? 'Bạn' : pn}</div>`;
  const srText = (who, e) => `${who} ${D.sentence(e).replace(/^Đ/, 'đ')} lúc ${when(e)}${e.battery != null ? `, pin ${D.low(e) ? 'còn ' : ''}${e.battery}%` : ''}${e.source === 'manual' ? ', bấm tay' : ''}`;
  const eventBlock = (who, e) => `<div aria-hidden="true"><p class="lead2">${D.sentence(e)}</p>
      <p class="meta"><span class="pic">${iconOf(e)(16)}</span><span class="time num">${when(e)}</span>${battery(e)}</p>${e.source === 'manual' ? '<p class="sub">bấm tay</p>' : ''}</div>`;

  function partnerLane(kind, e) {
    if (kind === 'off') return `<div class="lane neutral">${label('p')}<p class="lead2 s">Chưa bật báo về nhà</p></div>`;
    if (kind === 'quiet') return `<div class="lane">${label('p')}<p class="lead2 s">Đang bật báo về nhà</p><p class="sub">Khi ${pn} đến nơi, tin sẽ hiện ở đây.</p></div>`;
    return `<div class="lane" role="group" aria-label="${srText(pn, e)}">${label('p')}${eventBlock(pn, e)}
      <button class="btn text care" data-act="care">${I.care(16)}Hỏi thăm</button></div>`;
  }
  // m: { last, status, link, sent, places }
  function mineLane(m) {
    const ev = m.last ? `<div role="group" aria-label="${srText('Bạn', m.last)}">${eventBlock('Bạn', m.last)}</div>` : `<p class="lead2 s">Chưa có tin hôm nay</p>`;
    const confirm = m.confirm ? `<p class="okline" role="status">${I.tick(14)}${m.confirm}</p>` : '';
    const status = m.status ? `<div class="mstat tap" ${m.statusTap === false ? '' : 'role="button" tabindex="0"'}><span class="ic">${m.statusIcon || I.loc(14)}</span><span>${m.status}</span></div>` : '';
    const link = m.link ? `<button class="btn text mlink">${m.link}</button>` : '';
    return `<div class="lane me">${label('me')}${m.off ? '<p class="lead2 s">Chưa bật báo về nhà</p>' : ev}${confirm}${status}${link}</div>`;
  }
  function footer(o) {
    if (o.footer === 'enable') return `<div class="row-btns"><button class="btn primary" data-act="setup">Bật báo về nhà</button><button class="btn outline" data-act="home">${I.home(16)}Về nhà rồi</button></div>`;
    // Lead 2026-10-20: trên Home nút này là viền, không đặc (Home đã có nút đặc của câu hỏi + caro).
    const homeBtn = o.sent ? `<button class="btn outline sent" aria-pressed="true">${I.tick(16)}Về nhà rồi</button>`
      : o.queued ? `<button class="btn outline sent" aria-pressed="true">${I.offline(16)}Về nhà rồi</button>`
      : `<button class="btn outline" data-act="home">${I.home(16)}Về nhà rồi</button>`;
    const other = o.noOther ? '' : `<button class="btn outline" data-act="other" aria-haspopup="dialog">${I.loc(16)}Đến nơi rồi${I.chevDown(16)}</button>`;
    return `<div class="row-btns">${homeBtn}${other}</div>`;
  }
  function card(o) {
    const head = `<div class="card-h tap" ${o.pitch ? '' : 'role="button" tabindex="0" aria-label="Về đến nhà chưa? Mở cài đặt"'}><span class="badge">${I.home(20)}</span><span class="t">Về đến nhà chưa?</span>${o.pitch ? '' : `<span class="chev">${I.chev()}</span>`}</div>`;
    if (o.loading) {
      const bar = (w, h, mt = 0) => `<div style="width:${w};height:${h}px;border-radius:8px;background:rgba(26,26,46,.07);margin-top:${mt}px"></div>`;
      const lane = `<div class="lane neutral">${bar('40%', 11)}${bar('85%', 22, 8)}${bar('60%', 18, 6)}</div>`;
      return `<article class="card" aria-busy="true">${head}<div class="lanes">${lane}${lane}</div><div class="row-btns">${bar('128px', 44, 0)}${bar('140px', 44, 0)}</div></article>`;
    }
    if (o.pitch) return `<article class="card">${head}<p class="body" style="margin-top:12px">Về đến nhà là máy tự báo cho ${pn}. Đang chạy xe thì khỏi phải nhắn.</p>${footer({ footer: 'enable' })}</article>`;
    const strip = o.strip === 'offline' ? `<div class="strip" role="status">${I.offline(18)}<span class="s">Sẽ báo khi có mạng. Quá 30 phút thì ${pn} chỉ thấy trên thẻ, không nhận thông báo.</span></div>`
      : o.strip === 'error' ? `<div class="strip" role="alert"><span class="ic-err">${I.err(18)}</span><span class="s">Chưa gửi được tin “Về nhà rồi”.</span><button class="btn text">Thử lại</button></div>` : '';
    return `<article class="card">${head}<div class="lanes">${mineLane(o.me)}${partnerLane(o.partner, o.event)}</div>${footer(o)}${strip}</article>`;
  }
  const nw = (xs) => xs.map((x) => `<span class="nw">${x}</span>`).join(' · ');
  const auto = { last: D.docs.u_tuan.last, status: `Tự báo: ${nw(['Nhà và 2 nơi khác'])}` }; // làn nửa bề ngang: từ 3 nơi trở lên ghi số, 1–2 nơi ghi tên
  window.ArrivalCard = { card, when, auto };
})();
