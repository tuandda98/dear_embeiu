// Thành phần dùng chung cho các trang mock "Chạm tim". Icon vẽ theo nét Iconsax (Linear 1.5 / Bold).
(function () {
  const z = Number(new URLSearchParams(location.search).get('zoom'));
  if (z > 1) document.documentElement.style.zoom = z; // ?zoom=3 để soi chi tiết
  const svg = (inner, fill = false) =>
    `<svg viewBox="0 0 24 24" aria-hidden="true" fill="${fill ? 'currentColor' : 'none'}" stroke="${fill ? 'none' : 'currentColor'}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">${inner}</svg>`;
  const heartPath = '<path d="M12 20.3c-.3 0-.6-.1-.8-.2C8.6 18.6 3.5 15.3 3.5 9.9 3.5 7.2 5.6 5 8.3 5c1.5 0 2.8.7 3.7 1.8C12.9 5.7 14.2 5 15.7 5c2.7 0 4.8 2.2 4.8 4.9 0 5.4-5.1 8.7-7.7 10.2-.2.1-.5.2-.8.2z"/>';
  const I = {
    heart: svg(heartPath),
    heartBold: svg(heartPath, true),
    bell: svg('<path d="M12 6.4v3.3M12 2.2a6.6 6.6 0 0 0-6.6 6.6v2.1c0 .7-.3 1.7-.6 2.3l-1.3 2.1c-.8 1.3-.2 2.8 1.2 3.2a23 23 0 0 0 14.6 0 2.2 2.2 0 0 0 1.2-3.2l-1.3-2.1c-.3-.6-.6-1.6-.6-2.3V8.8A6.6 6.6 0 0 0 12 2.2z"/><path d="M15.3 19.6a3.3 3.3 0 0 1-6.6 0"/>'),
    sun: svg('<circle cx="12" cy="12" r="4.5"/><path d="M12 2.5v1.5M12 20v1.5M4.2 4.2l1 1M18.8 18.8l1 1M2.5 12H4M20 12h1.5M4.2 19.8l1-1M18.8 5.2l1-1"/>'),
    flag: svg('<path d="M5.2 2v20M5.2 4h11.2c2.7 0 3.3 1.5 1.4 3.4l-1.2 1.2c-.8.8-.8 2.1 0 2.8l1.2 1.2c1.9 1.9 1.2 3.4-1.4 3.4H5.2"/>'),
    star: svg('<path d="M13.7 3.5l1.8 3.5c.2.5.9 1 1.4 1.1l3.2.5c2 .3 2.5 1.8 1 3.3l-2.4 2.4c-.4.4-.7 1.2-.6 1.8l.7 3c.6 2.3-.7 3.2-2.7 2l-3-1.8c-.5-.3-1.4-.3-1.9 0l-3 1.8c-2 1.2-3.3.3-2.7-2l.7-3c.1-.6-.1-1.4-.6-1.8l-2.4-2.4c-1.5-1.5-1-3 1-3.3l3.2-.5c.5-.1 1.2-.6 1.4-1.1l1.8-3.5c1-1.9 2.5-1.9 3.4 0z"/>', true),
    back: svg('<path d="M9.6 5.9L3.5 12l6.1 6.1M20.5 12H3.7"/>'),
    chev: svg('<path d="M8.9 19.9l6.5-6.5c.8-.8.8-2 0-2.8L8.9 4.1"/>'),
    question: svg('<path d="M17 18.4h-4l-4.5 3c-.7.4-1.5 0-1.5-.8v-2.2c-3 0-5-2-5-5v-6c0-3 2-5 5-5h10c3 0 5 2 5 5v6c0 3-2 5-5 5z"/><path d="M12 11.4v-.2c0-.7.4-1 .8-1.3.4-.3.8-.6.8-1.3a1.6 1.6 0 0 0-3.2 0M12 13.8h0"/>'),
    dice: svg('<path d="M9 22h6c5 0 7-2 7-7V9c0-5-2-7-7-7H9C4 2 2 4 2 9v6c0 5 2 7 7 7z"/><circle cx="8" cy="8" r=".8" fill="currentColor"/><circle cx="16" cy="16" r=".8" fill="currentColor"/><circle cx="12" cy="12" r=".8" fill="currentColor"/>'),
    bing: svg('<path d="M12 6.4v3.3M12 2.2a6.6 6.6 0 0 0-6.6 6.6v2.1c0 .7-.3 1.7-.6 2.3l-1.3 2.1c-.8 1.3-.2 2.8 1.2 3.2a23 23 0 0 0 14.6 0 2.2 2.2 0 0 0 1.2-3.2l-1.3-2.1c-.3-.6-.6-1.6-.6-2.3V8.8A6.6 6.6 0 0 0 12 2.2z"/>'),
  };

  // Sao + chòm sao trái tim của widget M2 (DayCounterView.swift NightSky/Constellation).
  const stars = `<svg class="stars" viewBox="0 0 100 100" preserveAspectRatio="none" aria-hidden="true">
    <circle cx="19" cy="38" r="1" fill="#fff" fill-opacity=".7"/><circle cx="41" cy="22" r=".8" fill="#fff" fill-opacity=".6"/>
    <circle cx="79" cy="47" r=".8" fill="#fff" fill-opacity=".6"/><circle cx="13" cy="63" r=".8" fill="#fff" fill-opacity=".6"/>
    <circle cx="55" cy="72" r=".8" fill="#fff" fill-opacity=".5"/></svg>`;
  const constellation = `<svg class="const" viewBox="0 0 52 48" aria-hidden="true">
    <path d="M26 44L8 26 10 10 26 16 42 10 44 26z" fill="none" stroke="#fff" stroke-opacity=".35"/>
    <circle cx="26" cy="44" r="2.6" fill="#fff"/><circle cx="8" cy="26" r="2.2" fill="#fff"/><circle cx="10" cy="10" r="2.6" fill="#a78bfa"/> // taste-skill-ignore: brand: sao lavender của chòm sao widget
    <circle cx="26" cy="16" r="2" fill="#fff"/><circle cx="42" cy="10" r="2.6" fill="#ff8fa3"/><circle cx="44" cy="26" r="2.2" fill="#fff"/></svg>`;

  // CounterCard với hàng tên + tim. o: { m, p, cap (html), state: 'idle'|'pop'|'recv', photo, waiting, sentIcon }
  function counter(o) {
    const { C, me, partner, daysTogether, clock, nextMilestone, daysLeft, progress, fmt } = D;
    const filled = o.m > 0;
    const head = o.waiting
      ? `<div class="names-plain">${me.name} ${I.heartBold} ${partner.name}</div>`
      : `<div class="poke-row">
          <span class="nm l">${me.name}</span>
          <button class="heart-btn${o.state === 'pop' ? ' pop' : ''}" type="button" aria-label="${C.heartLabel(partner.name)}. ${C.caption(o.m, o.p, partner.name)}">
            ${filled ? I.heartBold : I.heart}
            ${o.state === 'recv' ? `<span class="float-hearts" aria-hidden="true">
              <span style="position:absolute;left:-30px;top:-18px;opacity:.95">${I.heartBold}</span>
              <span style="position:absolute;left:-7px;top:-30px;opacity:.75">${I.heartBold}</span>
              <span style="position:absolute;left:16px;top:-16px;opacity:.55">${I.heartBold}</span></span>` : ''}
          </button>
          <span class="nm r">${partner.name}</span>
        </div>
        <p class="poke-cap"${o.live ? ' role="status"' : ''}>${o.cap}</p>`;
    return `<div class="counter${o.photo ? ' photo' : ''}">
      ${o.photo ? `<div class="bgphoto" style="background-image:url(${o.photo})"></div>` : '<span class="aurora a1"></span><span class="aurora a2"></span><span class="aurora a3"></span>'}
      <div class="inner">
        ${head}
        <div class="eb"><i></i>${C.eyebrow}<i></i></div>
        <div class="big num">${fmt(daysTogether)}</div>
        <div class="unit">${C.daysUnit}</div>
        <div class="clock num"><span class="seg"><span class="v">${clock.h}</span><span class="l">${C.h}</span></span><span class="sep">:</span><span class="seg"><span class="v">${clock.m}</span><span class="l">${C.m}</span></span><span class="sep">:</span><span class="seg"><span class="v">${clock.s}</span><span class="l">${C.s}</span></span></div>
        <div class="ms"><div class="row">${I.flag}<span>${C.milestone(nextMilestone)}</span><span class="left num">${C.left(daysLeft)}</span></div>
          <div class="track"><b style="width:${(progress * 100).toFixed(1)}%"></b></div></div>
        ${o.waiting ? '' : `<div class="streak">${I.star}${C.streak(92)}</div>`}
      </div>
    </div>`;
  }

  // Widget. o: { plat: 'ios'|'and', size: 's'|'m', bg: 'night'|'photo', poke: bool, m, p, status: bool, pending, tint }
  function widget(o) {
    const { C, me, partner, daysTogether, nextMilestone, daysLeft, progress, fmt } = D;
    const total = (o.m || 0) + (o.p || 0) + (o.pending || 0);
    const sent = (o.m || 0) + (o.pending || 0) > 0;
    const cls = ['w', o.plat, o.size, o.bg, o.poke ? '' : 'nopoke', o.tint ? 'tint' : ''].join(' ');
    const label = `${C.heartLabel(partner.name)}${total ? `. ${D.lang === 'vi' ? `Hôm nay nhớ nhau ${total} lần` : `${total} hearts today`}` : ''}${o.pending ? (D.lang === 'vi' ? '. Đang chờ mạng để gửi' : '. Waiting for a connection') : ''}`;
    const pcol = o.poke
      ? `<div class="pcol"><span class="hit" role="button" tabindex="0" aria-label="${label}"></span>
           <span class="pdisc${sent ? ' sent' : ''}${o.pending ? ' pending' : ''}${o.bump ? ' bump' : ''}">${sent ? I.heartBold : I.heart}</span>
           ${total ? `<span class="pcount num" aria-hidden="true">${total}</span>` : ''}</div>`
      : '';
    const statusShort = o.status ? `<div class="status"><span class="dot"></span>${C.statusShort(partner.name, o.p)}</div>` : '';
    const numBlock = `<div class="hrow"><div class="stack"><div class="days num">${fmt(daysTogether)}</div><div class="cap">${C.daysTogether}</div></div>${pcol}</div>`;
    const chip = `<span class="chip">${me.name}${I.heartBold}${partner.name}</span>`;
    const bg = o.bg === 'night' ? `${stars}${constellation}` : `<div class="ph" style="background-image:url(img/p2.jpg)"></div>`;
    if (o.size === 's') {
      return `<div class="${cls}" role="img" aria-label="Widget">${bg}<div class="body">${chip}<div class="grow"></div>${numBlock}${statusShort}</div></div>`;
    }
    const right = `<div class="right"><div class="msl">${C.milestone(nextMilestone)}</div><div class="pb"><b style="width:${(progress * 100).toFixed(1)}%"></b></div><div class="cap num">${C.left(daysLeft)}</div>
      ${o.status ? `<div class="status"><span class="dot"></span>${C.status(partner.name, o.p)}</div>` : `<div class="since">${C.since}</div>`}</div>`;
    return `<div class="${cls}" role="img" aria-label="Widget">${bg}<div class="cols"><div class="left">${chip}<div class="grow"></div>${numBlock}</div><div class="vr"></div>${right}</div></div>`;
  }

  // Giả lập minimumScaleFactor (iOS, sàn 0,6) và autoSize 24–40sp (Android): số ngày co cho vừa ô.
  function fit(root = document) {
    root.querySelectorAll('.w .days').forEach((el) => {
      let size = 40;
      const floor = el.closest('.and') ? 24 : 24;
      el.style.fontSize = size + 'px';
      while (el.scrollWidth > el.clientWidth + 0.5 && size > floor) { size -= 1; el.style.fontSize = size + 'px'; }
      el.dataset.fitted = size;
    });
    // Dòng trạng thái bản nhỏ: co 12 → 10 trước khi cắt "…" (widget-today §5.2).
    root.querySelectorAll('.w.s .status').forEach((el) => {
      let size = 12;
      while (el.scrollWidth > el.clientWidth + 0.5 && size > 10) { size -= 0.5; el.style.fontSize = size + 'px'; }
    });
  }
  window.UI = { I, counter, widget, fit };
})();
