// Custom branded verification email (feature auth — "Cách B" via Resend).
//
// Builds the bulletproof, email-safe HTML for the "verify your email"
// transactional message that the `sendCustomVerificationEmail` callable sends
// through Resend. Mirrors the design spec in
// project/features/auth/design.md ("Email xác thực — Cách B"):
//   - layout uses <table> + INLINE CSS only (no flexbox/grid/external CSS)
//   - web-safe font stack first (mail clients don't load Fraunces/Plus Jakarta)
//   - max-width 600 white card on #F4F4F7, sunset gradient header (+ bgcolor
//     solid fallback for Outlook), bulletproof table-based button on #FF4D6D
//   - link fallback text + security note + dearembeiu.com footer
//   - vi + en copy keyed by `lang` (fallback 'vi'), matching the CF push pattern
//
// Exports buildVerificationEmail({ name, verifyUrl, lang }) -> { subject, html }.

// Bilingual copy table (every string from design.md E3). Fallback = vi.
const COPY = {
  vi: {
    subject: "Xác thực email cho Dear Embeiu 💞",
    preheader: "Chỉ một bước nữa để bắt đầu lưu giữ kỷ niệm cùng người ấy.",
    greeting: (name) => (name ? `Chào ${name},` : "Chào bạn,"),
    body:
      "Chỉ còn một bước nữa để bắt đầu lưu giữ kỷ niệm cùng người ấy. " +
      "Xác nhận email của bạn để mở khóa không gian riêng của hai người nhé. 💞",
    button: "Xác thực email",
    fallbackIntro: "Nút không bấm được? Sao chép và mở link này trên trình duyệt:",
    securityNote:
      "🔒 Nếu bạn không tạo tài khoản Dear Embeiu, cứ bỏ qua email này.",
    footerLine: "Dear Embeiu · dearembeiu.com",
    footerTagline: "Lưu giữ kỷ niệm & đếm ngày yêu 💞",
    footerCopyright: "© Dear Embeiu",
  },
  en: {
    subject: "Verify your email for Dear Embeiu 💞",
    preheader: "Just one step left to start keeping memories with your love.",
    greeting: (name) => (name ? `Hi ${name},` : "Hi there,"),
    body:
      "You're just one step away from keeping memories with your love. " +
      "Confirm your email to unlock your private space for two. 💞",
    button: "Verify email",
    fallbackIntro: "Button not working? Copy and open this link in your browser:",
    securityNote:
      "🔒 If you didn't create a Dear Embeiu account, you can safely ignore this email.",
    footerLine: "Dear Embeiu · dearembeiu.com",
    footerTagline: "Keep your memories & count the days in love 💞",
    footerCopyright: "© Dear Embeiu",
  },
};

// Web-safe font stack (design.md E2) — native system fonts first so nothing
// ever falls back to Times New Roman when a custom font fails to load.
const FONT_STACK =
  "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";

// HTML-escape untrusted interpolation (displayName can contain <>&"'). Applied
// to `name` before it is dropped into the greeting.
function escapeHtml(value) {
  return `${value || ""}`
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

// Escape a URL for safe use both as an href attribute and as visible text.
// verifyUrl is a Firebase-generated link (already a valid URL), but we still
// escape `&`/quotes/angle-brackets so the markup can't be broken.
function escapeAttr(value) {
  return `${value || ""}`
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * Build the verification email.
 *
 * @param {Object} args
 * @param {string} [args.name] user displayName (raw, will be HTML-escaped;
 *   empty -> "Chào bạn,"/"Hi there,")
 * @param {string} args.verifyUrl Firebase verification link (href + fallback text)
 * @param {string} [args.lang] 'vi' | 'en' (fallback 'vi')
 * @return {{subject: string, html: string}}
 */
function buildVerificationEmail({name, verifyUrl, lang} = {}) {
  const code = `${lang || ""}`.trim().toLowerCase();
  const copy = COPY[code] || COPY.vi;

  const safeName = escapeHtml(`${name || ""}`.trim());
  const safeUrlAttr = escapeAttr(verifyUrl); // for href
  const safeUrlText = escapeAttr(verifyUrl); // same value, shown as fallback text

  const greeting = copy.greeting(safeName);

  // Preheader: hidden preview text, padded with zero-width chars so the inbox
  // preview shows the line and not the raw HTML that follows it.
  const preheaderPad = "&zwnj;&nbsp;".repeat(40);

  const html = `<!DOCTYPE html>
<html lang="${code === "en" ? "en" : "vi"}" xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="color-scheme" content="light">
  <meta name="supported-color-schemes" content="light">
  <title>${escapeHtml(copy.subject)}</title>
  <style>
    /* Mobile tweak — clients that honour <style> shrink the body padding.
       Layout still works (table is fluid) on clients that drop this. */
    @media only screen and (max-width:480px) {
      .db-body { padding: 28px !important; }
      .db-header { padding: 28px 20px !important; }
      .db-footer { padding: 24px 28px !important; }
    }
  </style>
</head>
<body style="margin:0; padding:0; background-color:#F4F4F7; -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%;">
  <div style="display:none; max-height:0; overflow:hidden; opacity:0; mso-hide:all;">
    ${escapeHtml(copy.preheader)}${preheaderPad}
  </div>
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color:#F4F4F7;">
    <tr>
      <td align="center" style="padding:32px 16px;">
        <table role="presentation" width="600" cellpadding="0" cellspacing="0" border="0" style="width:600px; max-width:600px; background-color:#FFFFFF; border-radius:16px; overflow:hidden; box-shadow:0 6px 24px rgba(255,107,157,0.10);">
          <!-- Header: sunset gradient (+ solid bgcolor fallback for Outlook) -->
          <tr>
            <td class="db-header" align="center" bgcolor="#FF6B9D" style="background-color:#FF6B9D; background-image:linear-gradient(135deg,#FF6B9D 0%,#FFB6C1 100%); padding:36px 24px;">
              <div style="font-size:40px; line-height:40px;">💞</div>
              <div style="margin-top:8px; font-family:${FONT_STACK}; font-size:26px; font-weight:700; letter-spacing:0.5px; color:#FFFFFF;">Dear Embeiu</div>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td class="db-body" style="padding:40px;">
              <p style="margin:0 0 18px 0; font-family:${FONT_STACK}; font-size:20px; font-weight:700; color:#1A1A2E;">${greeting}</p>
              <p style="margin:0 0 28px 0; font-family:${FONT_STACK}; font-size:16px; line-height:1.6; color:#3A3A4E;">${escapeHtml(copy.body)}</p>
              <!-- Bulletproof button -->
              <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="margin:0 auto;">
                <tr>
                  <td align="center" bgcolor="#FF4D6D" style="border-radius:28px; background-color:#FF4D6D;">
                    <a href="${safeUrlAttr}" target="_blank" style="display:inline-block; padding:16px 40px; font-family:${FONT_STACK}; font-size:16px; font-weight:700; color:#FFFFFF; text-decoration:none; border-radius:28px;">${escapeHtml(copy.button)}</a>
                  </td>
                </tr>
              </table>
              <!-- Divider -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr><td style="padding:32px 0 0 0;"><div style="height:1px; line-height:1px; font-size:1px; background-color:#EFEFF4;">&nbsp;</div></td></tr>
              </table>
              <!-- Link fallback -->
              <p style="margin:24px 0 6px 0; font-family:${FONT_STACK}; font-size:13px; line-height:1.5; color:#8A8A9A;">${escapeHtml(copy.fallbackIntro)}</p>
              <p style="margin:0 0 24px 0; font-family:${FONT_STACK}; font-size:13px; line-height:1.5; color:#E63956; word-break:break-all;"><a href="${safeUrlAttr}" target="_blank" style="color:#E63956; text-decoration:underline; word-break:break-all;">${safeUrlText}</a></p>
              <!-- Security note -->
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td style="background-color:#FFF5F8; border-radius:12px; padding:14px 18px;">
                    <p style="margin:0; font-family:${FONT_STACK}; font-size:13px; line-height:1.5; color:#8A8A9A;">${escapeHtml(copy.securityNote)}</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td class="db-footer" align="center" style="padding:28px 40px; background-color:#FFFFFF;">
              <div style="border-top:1px solid #EFEFF4; padding-top:20px;">
                <p style="margin:0 0 6px 0; font-family:${FONT_STACK}; font-size:13px; color:#8A8A9A;">${escapeHtml(copy.footerLine)}</p>
                <p style="margin:0 0 6px 0; font-family:${FONT_STACK}; font-size:12px; color:#A0A0B0;">${escapeHtml(copy.footerTagline)}</p>
                <p style="margin:0; font-family:${FONT_STACK}; font-size:12px; color:#A0A0B0;">${escapeHtml(copy.footerCopyright)}</p>
              </div>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

  return {subject: copy.subject, html};
}

module.exports = {buildVerificationEmail};
