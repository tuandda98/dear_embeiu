// Dựng thẻ "Thời tiết hai nơi" theo từng trạng thái, từ dữ liệu trong data.js.
(function () {
  const W = window.WX;
  const ic = (cp, bold) => `<i class="ic${bold ? ' b' : ''}" aria-hidden="true">&#x${cp.toString(16)};</i>`;
  const I = { cloudSunny: 0xe9d7, chev: 0xe936, location: 0xead3, refresh: 0xeb9c, close: 0xe9c8, clock: 0xe9c6, search: 0xebc3,
    back: 0xe92f, bell: 0xeb4b, heart: 0xea98, heartB: 0xea9c, tick: 0xec2a, tickB: 0xec30, info: 0xeab5, global: 0xea7c, edit: 0xea2a, sun: 0xec15, wifi: 0xec7b };
  const P = W.people.partner, ME = W.people.me;
  const deg = (n) => `${n}°`;
  let EN = false; // UI.en(true) dựng bản tiếng Anh để soát độ dài chữ
  const t = (vi, en) => (EN ? en : vi);
  const cityLabel = (c) => t(c.nameVi, c.nameEn);

  function lane(who, p, o = {}) {
    const dotCls = who === 'me' ? 'me' : 'partner';
    const name = who === 'me' ? t(ME.label, ME.labelEn) : P.name;
    const head = `<div class="who"><span class="dot ${dotCls}"></span><span class="name">${name}</span>${p ? `<span class="city">· ${cityLabel(p.city)}</span>` : ''}</div>`;
    if (o.unset) {
      const q = who === 'me' ? t('Mình đang ở đâu?', 'Where are you?') : t(`${P.name} đang ở đâu?`, `Where is ${P.name}?`);
      const b = who === 'me' ? t('Chọn', 'Choose') : t('Chọn giúp', 'Choose for them');
      const href = who === 'me' ? 'picker.html' : 'picker.html?for=partner';
      return `<div class="lane"><p class="who ask-who"><span class="dot ${dotCls}"></span><span class="ask">${q}</span></p><a class="btn outline sm" href="${href}" data-stop>${ic(I.location)}${b}</a></div>`;
    }
    if (o.loading) {
      return `<div class="lane" aria-hidden="true">${head}<div class="now"><span class="sk" style="width:58px;height:33px"></span><span class="sk" style="width:24px;height:24px;border-radius:12px"></span></div><span class="sk" style="width:96px;height:16px;margin-top:6px"></span></div>`;
    }
    if (o.error) {
      return `<div class="lane">${head}</div>`;
    }
    const cond = t(p.cond.vi, p.cond.en);
    const label = `${name}, ${cityLabel(p.city)}, ${p.temp} độ${cond ? ', ' + cond.toLowerCase() : ''}`;
    return `<div class="lane${o.stale ? ' stale' : ''}" role="group" aria-label="${label}">${head}
      <div class="now"><span class="temp">${deg(p.temp)}</span>${ic(p.icon)}</div>
      ${cond ? `<p class="cond" style="margin-bottom:0">${cond}</p>` : ''}</div>`;
  }

  function header(stamp, tappable = true) {
    const title = t('Thời tiết hai nơi', 'Weather here and there');
    return `<div class="chead"><span class="badge">${ic(I.cloudSunny)}</span>
      <div class="ttl"><h2 id="wx-title">${tappable ? `<a href="detail.html">${title}</a>` : title}</h2>${stamp || ''}</div>
      ${tappable ? `<span class="chev">${ic(I.chev)}</span>` : ''}</div>`;
  }
  const stampFresh = () => `<span class="stamp">${t('Cập nhật', 'Updated')} ${W.hhmm(W.fetched.fresh)}</span>`;
  const stampStale = () => `<span class="stamp">${ic(I.clock)}${t('Số liệu lúc', 'As of')} ${W.hhmm(W.fetched.stale)}</span>`;

  function ctaRow(kind) {
    const c = W.CTA[kind];
    return `<div class="shared"><a class="btn" href="care.html?c=${kind}" data-stop>${ic(c.icon)}${t(c.vi, c.en)}</a></div>`;
  }
  function gapRow(me, partner) {
    const g = W.gap(me, partner, P.name);
    return g ? `<div class="shared"><span class="gap">${t(g.vi, g.en)}</span></div>` : '';
  }

  // Mỗi trạng thái trả HTML của nguyên thẻ.
  const card = {
    // A: cả hai đã chọn, chỗ người ấy có mưa: nút gợi ý (ưu tiên hơn câu chênh lệch).
    both: (partner = W.places.hcm, me = W.places.hn) => {
      const k = partner.cond.kind;
      const foot = k === 'rain' || k === 'hot' || k === 'cold' ? ctaRow(k) : gapRow(me, partner);
      return `<article class="card tap" data-href="detail.html" aria-labelledby="wx-title">${header(stampFresh())}
        <div class="lanes">${lane('partner', partner)}<div class="vr"></div>${lane('me', me)}</div>${foot}</article>`;
    },
    // B: cùng thành phố: một làn, hai chấm.
    same: (p = W.places.hnRain) => {
      const k = p.cond.kind;
      return `<article class="card tap" data-href="detail.html" aria-labelledby="wx-title">${header(stampFresh())}
        <div class="lanes one"><div class="lane" role="group" aria-label="Cả hai cùng ở ${p.city.nameVi}, ${p.temp} độ, ${p.cond.vi.toLowerCase()}">
          <div class="who"><span class="dots"><span class="dot partner"></span><span class="dot me"></span></span><span class="city" style="font-weight:700">Cả hai cùng ở ${p.city.nameVi}</span></div>
          <div class="now"><span class="temp">${deg(p.temp)}</span>${ic(p.icon)}</div><p class="cond" style="margin-bottom:0">${p.cond.vi}</p></div></div>
        ${k === 'rain' || k === 'hot' || k === 'cold' ? ctaRow(k) : ''}</article>`;
    },
    // C: đã ghép, người ấy chưa có thành phố.
    partnerUnset: (me = W.places.hn) => `<article class="card" aria-labelledby="wx-title">${header(stampFresh())}
        <div class="lanes">${lane('partner', null, { unset: true })}<div class="vr"></div>${lane('me', me)}</div></article>`,
    // D: đã ghép, mình chưa có thành phố (người ấy đã chọn).
    meUnset: (partner = W.places.hcm) => `<article class="card" aria-labelledby="wx-title">${header(stampFresh())}
        <div class="lanes">${lane('partner', partner)}<div class="vr"></div>${lane('me', null, { unset: true })}</div>${ctaRow(partner.cond.kind)}</article>`,
    // E: chưa ai chọn: thẻ thu thành một dòng mời + nút Ẩn.
    none: (waiting = false) => `<article class="card" aria-labelledby="wx-title-inv"><div class="invite">
        <span class="badge">${ic(I.cloudSunny)}</span>
        <a class="txt" href="picker.html" style="text-decoration:none"><h2 id="wx-title-inv" class="t" style="margin:0">${waiting ? 'Xem thời tiết chỗ mình' : 'Xem thời tiết chỗ người ấy'}</h2>
          <p class="s" style="margin:0">${waiting ? 'Chọn thành phố, sáng nào mở app cũng thấy.' : `Chọn chỗ mình và chỗ ${P.name}, sáng nào mở app cũng thấy.`}</p></a>
        <button class="textbtn quiet" type="button" aria-label="Ẩn thẻ thời tiết">Ẩn</button></div></article>`,
    // F: cặp đang chờ người ấy: chỉ làn của mình, không câu chênh lệch, không nút gợi ý.
    waiting: (me = W.places.hn) => `<article class="card tap" data-href="detail.html" aria-labelledby="wx-title">${header(stampFresh())}
        <div class="lanes one">${lane('me', me)}</div></article>`,
    // G: đang tải lần đầu: khung xương đúng cỡ, nhãn hiện ngay.
    loading: () => `<article class="card" aria-busy="true" aria-labelledby="wx-title">${header('<span class="sk" style="width:84px;height:14px"></span>', false)}
        <div class="lanes">${lane('partner', W.places.hcm, { loading: true })}<div class="vr"></div>${lane('me', W.places.hn, { loading: true })}</div></article>`,
    // H: số cũ 6–24 giờ: số chuyển xám, giờ lấy số có icon đồng hồ, ẩn nút gợi ý.
    stale: (partner = W.places.hcm, me = W.places.hn) => `<article class="card tap" data-href="detail.html" aria-labelledby="wx-title">${header(stampStale())}
        <div class="lanes">${lane('partner', partner, { stale: true })}<div class="vr"></div>${lane('me', me, { stale: true })}</div></article>`,
    // I: lỗi / > 24 giờ / chưa từng tải: tên thành phố + câu báo + Thử lại.
    error: (partner = W.places.hcm, me = W.places.hn) => `<article class="card tap" data-retry aria-labelledby="wx-title">${header('', false)}
        <div class="lanes">${lane('partner', partner, { error: true })}<div class="vr"></div>${lane('me', me, { error: true })}</div>
        <div class="shared"><span class="gap muted-line" role="status">${t('Chưa tải được thời tiết', 'Couldn’t load the weather')}</span><button class="textbtn" type="button" data-stop style="margin-left:auto">${ic(I.refresh)}${t('Thử lại', 'Try again')}</button></div></article>`,
  };

  // Chạm cả thẻ → sheet chi tiết (phần tử con có data-stop tự xử lý).
  document.addEventListener('click', (e) => {
    if (e.target.closest('[data-stop], a, button')) return;
    const c = e.target.closest('[data-href]');
    if (c) location.href = c.dataset.href;
  });

  window.UI = { ic, I, card, lane, P, ME, en: (v) => { EN = v; } };
})();
