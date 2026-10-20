// Sheet chọn thành phố. Thứ sống của mockup: gõ không dấu, gõ tên tỉnh cũ vẫn ra.
(function () {
  const { ic, I } = UI, W = WX;
  const qs = new URLSearchParams(location.search);
  let forPartner = (window.PICK_FOR || qs.get('for')) === 'partner';
  // chain=1: lần đầu (chưa ai chọn) chọn xong chỗ mình thì sheet hỏi luôn chỗ người ấy, có "Để sau".
  const chain = qs.get('chain') === '1' || window.PICK_CHAIN;
  const name = W.people.partner.name;
  let selected = forPartner || chain ? null : 'vn-ha-noi'; // bạn đang ở Hà Nội; Thảo chưa chọn
  const title = () => (forPartner ? (chain ? `Còn ${name} đang ở đâu?` : `${name} đang ở đâu?`) : 'Bạn đang ở đâu?');
  const sub = () => (forPartner ? `${name} vẫn tự đổi được sau.` : 'Chỉ cần tên thành phố, app không xin vị trí.');
  const row = ({ city: c, via }) => `<li><button type="button" class="crow${c.id === selected ? ' on' : ''}" data-id="${c.id}" aria-pressed="${c.id === selected}">
      <span class="ctext"><span class="cname">${c.nameVi}</span>${c.regionVi ? `<span class="creg"> · ${c.regionVi}</span>` : ''}
      ${via ? `<span class="cvia">Tỉnh cũ: ${via}</span>` : ''}</span>
      ${c.id === selected ? `<span class="tick">${ic(I.tickB, true)}</span>` : ''}</button></li>`;
  function list(q) {
    const hits = W.search(q);
    if (!hits.length) return `<p class="empty" role="status">Chưa có thành phố này. Chọn nơi gần nhất nhé.</p>`;
    const cur = !q && selected ? hits.filter((h) => h.city.id === selected) : [];
    // Việt Nam: 6 thành phố trực thuộc TW lên đầu (region rỗng), còn lại A→Z theo tên bỏ dấu. Nước ngoài giữ thứ tự Phụ lục A (theo nước).
    const notCur = (h) => !(cur.length && h.city.id === selected); // đã nằm ở nhóm Đang chọn thì không lặp lại
    const vn = hits.filter((h) => h.city.group === 'vn' && notCur(h)).sort((a, b) => (!!a.city.regionVi - !!b.city.regionVi) || (a.city.regionVi ? W.fold(a.city.nameVi).localeCompare(W.fold(b.city.nameVi)) : 0));
    const intl = hits.filter((h) => h.city.group === 'intl' && notCur(h));
    const grp = (id, label, items) => (items.length ? `<section aria-labelledby="${id}"><h2 class="grp" id="${id}">${label}</h2><ul>${items.map(row).join('')}</ul></section>` : '');
    return grp('g-cur', 'Đang chọn', cur) + grp('g-vn', 'Việt Nam', vn) + grp('g-intl', 'Nước ngoài', intl);
  }
  const app = document.getElementById('app');
  const render = () => { app.innerHTML = `<div class="handle"></div><div class="ptop"><h1 id="p-title">${title()}</h1>${forPartner && chain ? '<a class="textbtn quiet" href="states.html">Để sau</a>' : ''}</div><p class="sub">${sub()}</p>
    <label class="field">${ic(I.search)}<span class="sr">Tìm thành phố</span><input id="q" type="search" autocomplete="off" placeholder="Tìm thành phố hoặc tỉnh">
      <button type="button" class="clear" aria-label="Xoá chữ đã gõ" hidden>${ic(I.close)}</button></label>
    <div id="list"></div>
    <p class="source">Dữ liệu thời tiết: <a href="https://api.met.no/doc/License">MET Norway</a></p>`;
  const q = app.querySelector('#q'), clear = app.querySelector('.clear'), out = app.querySelector('#list');
  const draw = () => { out.innerHTML = list(q.value); clear.hidden = !q.value; };
  q.value = window.PICK_QUERY || '';
  q.addEventListener('input', draw);
  clear.addEventListener('click', () => { q.value = ''; draw(); q.focus(); });
  out.addEventListener('click', (e) => {
    const b = e.target.closest('.crow'); if (!b) return; selected = b.dataset.id;
    if (chain && !forPartner) { forPartner = true; selected = null; window.PICK_QUERY = ''; render(); return; } // bước 2
    draw();
  });
  draw(); };
  render();
})();
