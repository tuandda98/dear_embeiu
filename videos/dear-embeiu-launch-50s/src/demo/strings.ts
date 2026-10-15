// Every on-screen string of the 45 s product demo (composition "Demo"). Product strings are verbatim from the app
// (lib/l10n/app_vi.arb — key in the comment) or BRIEF §1; "demo" marks the demo's own copy (short titles, every
// claim checked against BRIEF §1). Voice: "chúng mình" / "người ấy", never "hai đứa".
import { T } from "../copy/strings.ts";

export const D = {
  hook: { wordmark: T.a7.wordmark, sub: "Không gian riêng của hai người" }, // demo
  titles: {
    counter: "Đếm ngày yêu", // guestCounterTitle
    question: "Câu hỏi mỗi ngày", // demo (BRIEF §6 glyph label)
    mood: "Tâm trạng hôm nay", // moodCardTitle
    sleep: "Giấc ngủ", // sleepBadge, sentence case
    photos: "Ảnh chung", // demo (BRIEF §6 glyph label)
    chat: "Trò chuyện riêng", // demo (BRIEF §1 Chat: private, two people)
    care: "Lời quan tâm", // careTimelineBadge, sentence case
    tree: "Cây tình yêu", // loveTreeBadge, sentence case
  },
  callouts: {
    counter: "1250 ngày, đếm tới từng giây", // demo (BRIEF §1: the live clock's seconds tick)
    question: "Trả lời xong mới thấy câu của người ấy", // demo (dailyAnswerToReveal, said plainly)
    mood: "Chúng mình cùng một tâm trạng 💞", // moodMatched
    sleep: "Trăng càng tròn, ngủ càng tròn giấc", // sleepMoonTagline
    tree: "Mỗi cột mốc nở một bông hoa", // demo (the film's line, BRIEF §1: each flower is a milestone crossed)
  },
  end: {
    wordmark: T.a7.wordmark,
    l1: T.a7.l1,
    l2: T.a7.l2,
    offer: T.a7.offer,
    url: T.a7.url,
    legal: T.a7.legal,
  },
  /**
   * The iPhone simulator draws the app's inline emoji as "[?]" boxes (the Android captures show them right). The demo
   * paints each one back over its box, with the app's own string: streakChipRestart 🌱 · dailyPartnerAnsweredTeaser 👀
   * · dailyQuestionSent 💞 · moodMatched 💞 · the seeded chat 😚 💕 · careQuick1…6Title · careMessageSendCta 💌 ·
   * the Oẳn tù tì tile ✌️✊✋ (rps_invite_card.dart).
   */
  emoji: { sprout: "🌱", eyes: "👀", hearts: "💞", kiss: "😚", twoHearts: "💕", drop: "💧", rice: "🍚", moon: "🌙", heart: "❤️", muscle: "💪", letter: "💌", rps: "✌️✊✋" },
} as const;
