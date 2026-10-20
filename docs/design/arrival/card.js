// Thẻ Home "Về đến nhà chưa?" — render mọi trạng thái từ data.js (dùng chung cho home-card.html + manage.html).
(function () {
  const { I, placeIcon } = UI;
  const P = D.PLACE;
  const pn = D.people.partner.name;

  function when(e) {
    const day = e.at.slice(0, 10);
    const t = D.hm(e.at);
    if (day === D.NOW.slice(0, 10)) return t;
    if (day === '2026-10-19') return `hôm qua ${t}`;
    return `${+day.slice(8, 10)}/${+day.slice(5, 7)} ${t}`;
  }
  function battery(e) {
    if (e.battery == null) return '';
    return D.low(e)
      ? `<span class="bat low">${I.batLow(14)}Pin còn ${e.battery}%</span>`
      : `<span class="bat">${I.bat(14)}pin ${e.battery}%</span>`;
  }
  function partnerLane(kind, e) {
    const label = `<div class="who"><i style="background:var(--thao)"></i>${pn}</div>`;
    if (kind === 'off') {
      return `<div class="lane neutral">${label}<p class="lead s" style="margin-top:6px">Chưa bật báo về nhà</p></div>`;
    }
    if (kind === 'quiet') {
      return `<div class="lane">${label}<p class="lead s" style="margin-top:6px">Đang bật báo về nhà</p><p class="sub">Khi ${pn} đến nơi, tin sẽ hiện ở đây.</p></div>`;
    }
    const sentence = P[e.place][e.type].vi;
    const sr = `${pn} ${sentence.charAt(0).toLowerCase() + sentence.slice(1)} lúc ${when(e)}${e.battery != null ? (D.low(e) ? `, pin còn ${e.battery}%` : `, pin ${e.battery}%`) : ''}${e.source === 'manual' ? ', báo bằng tay' : ''}`;
    return `<div class="lane" role="group" aria-label="${sr}">${label}
      <div class="lane-row"><div class="txt" aria-hidden="true">
        <p class="lead">${sentence}</p>
        <p class="meta"><span class="time num">${when(e)}</span>${battery(e)}${e.source === 'manual' ? '<span>bấm tay</span>' : ''}</p>
      </div>
      <button class="btn white" data-act="care">${I.care(16)}Hỏi thăm</button></div></div>`;
  }
  function placeButtons(places, sentPlace) {
    return places.map((p) => sentPlace === p
      ? `<button class="btn outline sent" aria-pressed="true">${I.tick(16)}${P[p].manual.vi}</button>`
      : `<button class="btn outline" data-act="manual" data-place="${p}">${placeIcon[p](16)}${P[p].manual.vi}</button>`).join('');
  }
  function mineLane(kind, opts = {}) {
    const label = `<div class="who"><i style="background:var(--tuan)"></i>Bạn</div>`;
    const places = opts.places || D.docs.u_tuan.places;
    const status = (txt, chev = true, icon = I.loc(18), live = false) => `<div class="status tap" ${chev ? `role="button" tabindex="0" aria-label="${txt}. Mở cài đặt Về đến nhà"` : ''} ${live ? 'role="status" aria-live="polite"' : ''}><span class="ic">${icon}</span><span class="s">${txt}</span>${chev ? `<span class="chev">${I.chev()}</span>` : ''}</div>`;
    let html = '';
    if (kind === 'auto') html = (opts.sent ? status(`Đã báo ${pn}: ${P[opts.sent].manual.vi} · 19:05`, false, I.tick(18), true) : status(`Tự báo khi đến ${places.map((p) => P[p].vi).join(' · ')}`)) + `<div class="row-btns">${placeButtons(places, opts.sent)}</div>`;
    if (kind === 'off') html = status('Bạn chưa bật báo về nhà', false, I.locOff(18)) + `<div class="row-btns"><button class="btn primary" data-act="setup">Bật báo về nhà</button>${placeButtons(['home'])}</div>`;
    if (kind === 'needAlways') html = status('Chưa tự báo được: cần quyền vị trí Luôn luôn', false, I.locOff(18)) + `<div class="row-btns"><button class="btn primary">Mở Cài đặt</button>${placeButtons(['home'])}</div>`;
    if (kind === 'remoteOff') html = status('Tạm thời chỉ báo bằng tay', true, I.locOff(18)) + `<div class="row-btns">${placeButtons(places)}</div>`;
    if (kind === 'noHome') html = status('Về đến nhà thì lưu chỗ đó để máy tự báo', true, I.locOff(18)) + `<div class="row-btns"><button class="btn primary" data-act="saveHome">${I.home(16)}Lưu Nhà</button>${placeButtons(['home'])}</div>`;
    if (kind === 'manualOnly') html = status('Đang báo bằng tay') + `<div class="row-btns">${placeButtons(places)}</div>`;
    if (kind === 'offline') html = status(`Tự báo khi đến ${places.map((p) => P[p].vi).join(' · ')}`) + `<div class="row-btns"><button class="btn outline sent" aria-pressed="true">${I.offline(16)}${P.home.manual.vi}</button>${placeButtons(places.filter((p) => p !== 'home'))}</div><div class="strip" role="status">${I.offline(18)}<span class="s">Sẽ báo khi có mạng. Quá 30 phút thì ${pn} chỉ thấy trên thẻ, không nhận thông báo.</span></div>`;
    if (kind === 'error') html = status(`Tự báo khi đến ${places.map((p) => P[p].vi).join(' · ')}`) + `<div class="row-btns">${placeButtons(places)}</div><div class="strip" role="alert"><span class="ic-err">${I.err(18)}</span><span class="s">Chưa gửi được tin “Về nhà rồi”.</span><button class="btn text">Thử lại</button></div>`;
    return `<div class="mine">${label}${html}</div>`;
  }
  function card(o) {
    const head = `<div class="card-h tap" ${o.pitch ? '' : 'role="button" tabindex="0" aria-label="Về đến nhà chưa? Mở cài đặt"'}><span class="badge">${I.home(20)}</span><span class="t">Về đến nhà chưa?</span>${o.pitch ? '' : `<span class="chev">${I.chev()}</span>`}</div>`;
    if (o.loading) {
      const bar = (w, h, mt = 0) => `<div style="width:${w};height:${h}px;border-radius:8px;background:rgba(26,26,46,.07);margin-top:${mt}px"></div>`;
      return `<article class="card" aria-busy="true">${head}<div style="margin-top:12px" class="lane neutral">${bar('30%', 11)}${bar('70%', 26, 8)}${bar('45%', 18, 6)}</div><div class="mine">${bar('22%', 11)}${bar('80%', 18, 14)}<div style="display:flex;gap:8px">${bar('128px', 44, 12)}${bar('160px', 44, 12)}</div></div></article>`;
    }
    if (o.pitch) {
      return `<article class="card">${head}<p class="body" style="margin-top:12px">Về đến nhà là máy tự báo cho ${pn}. Đang chạy xe thì khỏi phải nhắn.</p><div class="row-btns" style="margin-top:14px"><button class="btn primary" data-act="setup">Bật báo về nhà</button>${placeButtons(['home'])}</div></article>`;
    }
    return `<article class="card">${head}<div style="margin-top:12px">${partnerLane(o.partner, o.event)}</div>${mineLane(o.mine, o)}</article>`;
  }
  window.ArrivalCard = { card, when };
})();
