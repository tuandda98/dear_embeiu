// Icon nét 1.5 vẽ lại theo bộ Iconsax Linear (tên Iconsax ghi cạnh để Dev map).
(function () {
  const s = (d, size = 20) => `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${d}</svg>`;
  const I = {
    home: (z) => s('<path d="M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>', z),          // home_2
    work: (z) => s('<rect x="3" y="7" width="18" height="13" rx="2.5"/><path d="M8.5 7V5.5A1.5 1.5 0 0 1 10 4h4a1.5 1.5 0 0 1 1.5 1.5V7M3 12.5h18"/>', z), // briefcase
    school: (z) => s('<path d="M2.5 9 12 4.5 21.5 9 12 13.5z"/><path d="M6 11v5c0 1.5 2.7 3 6 3s6-1.5 6-3v-5M21.5 9v5"/>', z), // teacher
    batLow: (z) => s('<rect x="2.5" y="7" width="17" height="10" rx="2.5"/><path d="M21.5 10.5v3"/><rect x="5" y="9.5" width="2.2" height="5" rx=".8" fill="currentColor" stroke="none"/>', z), // battery_empty
    bat: (z) => s('<rect x="2.5" y="7" width="17" height="10" rx="2.5"/><path d="M21.5 10.5v3"/><rect x="5" y="9.5" width="9" height="5" rx=".8" fill="currentColor" stroke="none"/>', z), // battery_3full
    loc: (z) => s('<path d="M12 21s-7-5.6-7-11a7 7 0 0 1 14 0c0 5.4-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/>', z), // location
    locOff: (z) => s('<path d="M7.6 4.6A7 7 0 0 1 19 10c0 1.8-.8 3.7-1.9 5.4M14.5 18.6C13.1 20.1 12 21 12 21s-7-5.6-7-11c0-.9.2-1.8.5-2.6M3 3l18 18"/>', z), // location_slash
    care: (z) => s('<path d="M4 5.5A2.5 2.5 0 0 1 6.5 3h11A2.5 2.5 0 0 1 20 5.5v8a2.5 2.5 0 0 1-2.5 2.5H11l-4.5 4v-4h0A2.5 2.5 0 0 1 4 13.5z"/><path d="M12 12.3s-2.8-1.7-2.8-3.5a1.5 1.5 0 0 1 2.8-.8 1.5 1.5 0 0 1 2.8.8c0 1.8-2.8 3.5-2.8 3.5z"/>', z), // message_favorite
    chev: (z = 18) => s('<path d="m9 5 7 7-7 7"/>', z), // arrow_right_3
    back: (z = 24) => s('<path d="M15 5 8 12l7 7"/>', z), // arrow_left_2
    offline: (z) => s('<path d="M7 18h10a4 4 0 0 0 .6-8A6 6 0 0 0 6.2 9.3 4.4 4.4 0 0 0 7 18zM4 4l16 16"/>', z), // cloud_cross
    err: (z) => s('<circle cx="12" cy="12" r="9"/><path d="M12 7.5v5.5M12 16.2v.1"/>', z), // info_circle (đỏ)
    tick: (z) => s('<circle cx="12" cy="12" r="9"/><path d="m8 12.2 2.7 2.7L16 9.5"/>', z), // tick_circle
    info: (z) => s('<circle cx="12" cy="12" r="9"/><path d="M12 11v5.5M12 7.8v.1"/>', z), // info_circle
    trash: (z) => s('<path d="M4 6.5h16M9.5 6.5V4.8c0-.7.6-1.3 1.3-1.3h2.4c.7 0 1.3.6 1.3 1.3v1.7M6.5 6.5l.9 12.6a2 2 0 0 0 2 1.9h5.2a2 2 0 0 0 2-1.9l.9-12.6"/>', z), // trash
    lock: (z) => s('<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/>', z), // lock
    more: (z) => s('<circle cx="5.5" cy="12" r="1" fill="currentColor"/><circle cx="12" cy="12" r="1" fill="currentColor"/><circle cx="18.5" cy="12" r="1" fill="currentColor"/>', z), // more
    setting: (z) => s('<circle cx="12" cy="12" r="3"/><path d="M19 12a7 7 0 0 0-.1-1.2l2-1.5-2-3.4-2.3.9a7 7 0 0 0-2-1.2L14.2 3h-4.4l-.4 2.6a7 7 0 0 0-2 1.2l-2.3-.9-2 3.4 2 1.5a7 7 0 0 0 0 2.4l-2 1.5 2 3.4 2.3-.9a7 7 0 0 0 2 1.2l.4 2.6h4.4l.4-2.6a7 7 0 0 0 2-1.2l2.3.9 2-3.4-2-1.5c.1-.4.1-.8.1-1.2z"/>', z),
    bell: (z) => s('<path d="M6 10a6 6 0 0 1 12 0c0 4.5 2 6 2 6H4s2-1.5 2-6M10 20a2 2 0 0 0 4 0"/>', z), // notification_bing
    heart: (z = 12) => `<svg width="${z}" height="${z}" viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" d="M12 21s-7.5-4.6-10-9.2C.3 8.5 2.2 4.5 6 4.5c2.1 0 3.4 1.1 4.2 2.3h.1c.8-1.2 2-2.3 4.1-2.3 3.8 0 5.7 4 4 7.3C19.5 16.4 12 21 12 21z"/></svg>`,
  };
  const placeIcon = { home: I.home, work: I.work, school: I.school };
  window.UI = { I, placeIcon };
})();
