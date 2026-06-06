// Custom branded password reset email (via Resend).
//
// Same design system as verification_email.js: bulletproof table-based HTML,
// inline CSS, sunset gradient header, web-safe font stack, vi + en copy.
//
// Exports buildPasswordResetEmail({ name, resetUrl, lang }) -> { subject, html }.

const FONT_STACK =
  "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif";

const COPY = {
  vi: {
    subject: "Đặt lại mật khẩu Dear Embeiu 💞",
    preheader: "Bạn vừa yêu cầu đặt lại mật khẩu. Nhấn vào link bên dưới để tiếp tục.",
    greeting: (name) => (name ? `Chào ${name},` : "Chào bạn,"),
    body:
      "Chúng tôi nhận được yêu cầu đặt lại mật khẩu cho tài khoản Dear Embeiu của bạn. " +
      "Nhấn vào nút bên dưới để tạo mật khẩu mới. Link sẽ hết hạn sau 1 giờ.",
    button: "Đặt lại mật khẩu",
    fallbackIntro: "Nút không bấm được? Sao chép và mở link này trên trình duyệt:",
    securityNote:
      "🔒 Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này — tài khoản của bạn vẫn an toàn.",
    footerLine: "Dear Embeiu · dearembeiu.com",
    footerTagline: "Lưu giữ kỷ niệm & đếm ngày yêu 💞",
    footerCopyright: "© Dear Embeiu",
  },
  en: {
    subject: "Reset your Dear Embeiu password 💞",
    preheader: "You requested a password reset. Tap the link below to continue.",
    greeting: (name) => (name ? `Hi ${name},` : "Hi there,"),
    body:
      "We received a request to reset the password for your Dear Embeiu account. " +
      "Click the button below to create a new password. The link will expire in 1 hour.",
    button: "Reset password",
    fallbackIntro: "Button not working? Copy and open this link in your browser:",
    securityNote:
      "🔒 If you didn't request a password reset, you can safely ignore this email — your account is still secure.",
    footerLine: "Dear Embeiu · dearembeiu.com",
    footerTagline: "Keep your memories & count the days in love 💞",
    footerCopyright: "© Dear Embeiu",
  },
};

function escapeHtml(value) {
  return `${value || ""}`
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function escapeAttr(value) {
  return `${value || ""}`
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/**
 * @param {Object} args
 * @param {string} [args.name] user displayName
 * @param {string} args.resetUrl Firebase password reset link
 * @param {string} [args.lang] 'vi' | 'en' (fallback 'vi')
 * @return {{subject: string, html: string}}
 */
function buildPasswordResetEmail({name, resetUrl, lang} = {}) {
  const code = `${lang || ""}`.trim().toLowerCase();
  const copy = COPY[code] || COPY.vi;

  const safeName = escapeHtml(`${name || ""}`.trim());
  const safeUrlAttr = escapeAttr(resetUrl);
  const safeUrlText = escapeAttr(resetUrl);
  const greeting = copy.greeting(safeName);
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
          <tr>
            <td class="db-header" align="center" bgcolor="#FF6B9D" style="background-color:#FF6B9D; background-image:linear-gradient(135deg,#FF6B9D 0%,#FFB6C1 100%); padding:36px 24px;">
              <div style="font-size:40px; line-height:40px;">🔑</div>
              <div style="margin-top:8px; font-family:${FONT_STACK}; font-size:26px; font-weight:700; letter-spacing:0.5px; color:#FFFFFF;">Dear Embeiu</div>
            </td>
          </tr>
          <tr>
            <td class="db-body" style="padding:40px;">
              <p style="margin:0 0 18px 0; font-family:${FONT_STACK}; font-size:20px; font-weight:700; color:#1A1A2E;">${greeting}</p>
              <p style="margin:0 0 28px 0; font-family:${FONT_STACK}; font-size:16px; line-height:1.6; color:#3A3A4E;">${escapeHtml(copy.body)}</p>
              <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center" style="margin:0 auto;">
                <tr>
                  <td align="center" bgcolor="#FF4D6D" style="border-radius:28px; background-color:#FF4D6D;">
                    <a href="${safeUrlAttr}" target="_blank" style="display:inline-block; padding:16px 40px; font-family:${FONT_STACK}; font-size:16px; font-weight:700; color:#FFFFFF; text-decoration:none; border-radius:28px;">${escapeHtml(copy.button)}</a>
                  </td>
                </tr>
              </table>
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr><td style="padding:32px 0 0 0;"><div style="height:1px; line-height:1px; font-size:1px; background-color:#EFEFF4;">&nbsp;</div></td></tr>
              </table>
              <p style="margin:24px 0 6px 0; font-family:${FONT_STACK}; font-size:13px; line-height:1.5; color:#8A8A9A;">${escapeHtml(copy.fallbackIntro)}</p>
              <p style="margin:0 0 24px 0; font-family:${FONT_STACK}; font-size:13px; line-height:1.5; color:#E63956; word-break:break-all;"><a href="${safeUrlAttr}" target="_blank" style="color:#E63956; text-decoration:underline; word-break:break-all;">${safeUrlText}</a></p>
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td style="background-color:#FFF5F8; border-radius:12px; padding:14px 18px;">
                    <p style="margin:0; font-family:${FONT_STACK}; font-size:13px; line-height:1.5; color:#8A8A9A;">${escapeHtml(copy.securityNote)}</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
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

module.exports = {buildPasswordResetEmail};
