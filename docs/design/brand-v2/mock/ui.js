// Khung chung: icon nét (thay cho Iconsax Linear trong mockup), thanh trên, thanh tab.
(function () {
  const s = (d, extra = '') => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" ${extra}>${d}</svg>`;
  const I = {
    home: s('<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"/>'),
    chat: s('<path d="M4 5h16v11H9l-5 4z"/>'),
    gallery: s('<rect x="3" y="4" width="18" height="16" rx="3"/><circle cx="9" cy="10" r="2"/><path d="m21 16-5-5-9 9"/>'),
    profile: s('<circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/>'),
    bell: s('<path d="M6 16V11a6 6 0 0 1 12 0v5l2 2H4z"/><path d="M10 21h4"/>'),
    gear: s('<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9 7 7M17 17l2.1 2.1M4.9 19.1 7 17M17 7l2.1-2.1"/>'),
    heart: s('<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z" fill="currentColor"/>'),
    chevron: s('<path d="m9 6 6 6-6 6"/>', 'class="chev"'),
    plus: s('<path d="M12 5v14M5 12h14"/>'),
    back: s('<path d="m15 6-6 6 6 6"/>'),
  };
  const mark = `<svg class="mark" viewBox="0 0 24 24" aria-hidden="true"><defs><clipPath id="mk"><circle cx="9" cy="12" r="6.25"/></clipPath></defs><circle cx="15" cy="12" r="6.25" fill="#1b6e66" clip-path="url(#mk)"/><circle cx="9" cy="12" r="6.25" fill="none" stroke="#1f201d" stroke-width="1.5"/><circle cx="15" cy="12" r="6.25" fill="none" stroke="#1f201d" stroke-width="1.5"/></svg>`;

  function topbar({ scope, actions = '' }) {
    return `<div class="status" aria-hidden="true">12:20</div>
      <header class="topbar">${mark}<span class="scope">${scope}</span><span class="spacer"></span>${actions}</header>`;
  }
  function tabbar(current, chatCount = 0) {
    const tabs = [['home', 'Trang chủ', I.home], ['chat', 'Trò chuyện', I.chat], ['gallery', 'Kỷ niệm', I.gallery], ['profile', 'Hồ sơ', I.profile]];
    return `<nav class="tabbar" aria-label="Điều hướng chính">${tabs.map(([id, label, icon]) =>
      `<a class="tab" href="#${id}" ${id === current ? 'aria-current="page"' : ''}>${icon}<span>${label}</span>${id === 'chat' && chatCount ? `<span class="count num" aria-label="${chatCount} tin chưa đọc">${chatCount}</span>` : ''}</a>`).join('')}</nav>`;
  }
  window.UI = { I, mark, topbar, tabbar };
})();
