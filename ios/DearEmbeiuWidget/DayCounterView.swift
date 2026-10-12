import SwiftUI
import WidgetKit

// Design tokens — project/features/home-widget/design.md (hướng A).
private extension Color {
  init(hex: UInt32, opacity: Double = 1) {
    self.init(.sRGB,
              red: Double((hex >> 16) & 0xFF) / 255,
              green: Double((hex >> 8) & 0xFF) / 255,
              blue: Double(hex & 0xFF) / 255,
              opacity: opacity)
  }
}
private let navy = Color(hex: 0x1A1A2E)
private let loveDeep = Color(hex: 0xE63956)
private let lavender = Color(hex: 0xA78BFA)
private let blush = Color(hex: 0xFF8FA3)

private extension Font {
  /// Quicksand is bundled in the extension (Info.plist UIAppFonts).
  static func quicksand(_ weight: String, _ size: CGFloat) -> Font {
    .custom("Quicksand-\(weight)", size: size)
  }
}

private extension View {
  /// White-on-gradient text rule: a soft DARK shadow, never a halo.
  func inkShadow(_ opacity: Double = 0.30) -> some View {
    shadow(color: .black.opacity(opacity), radius: 4, y: 1)
  }

  /// iOS 17+: system draws the background + content margins. Earlier: we do.
  @ViewBuilder func widgetBackground<B: View>(_ background: B) -> some View {
    if #available(iOS 17.0, *) {
      containerBackground(for: .widget) { background }
    } else {
      ZStack { background; padding(14) }
    }
  }

  /// iOS 18 tinted mode renders accentable views in the user's tint.
  @ViewBuilder func accentable() -> some View {
    if #available(iOS 16.0, *) { widgetAccentable() } else { self }
  }
}

/// Tells its content whether the system is painting the widget in a single
/// tint (iOS 18 "Tinted", iOS 26 "Clear"): every fill becomes the tint, so a
/// solid pill under tinted text has no contrast (smoke Task 5 measured 1.05:1).
/// iOS 15 has no such mode → always false.
struct AccentedReader<Content: View>: View {
  @ViewBuilder let content: (Bool) -> Content
  var body: some View {
    if #available(iOS 16.0, *) {
      RenderingModeReader(content: content)
    } else {
      content(false)
    }
  }
}

@available(iOS 16.0, *)
private struct RenderingModeReader<Content: View>: View {
  @Environment(\.widgetRenderingMode) private var mode
  let content: (Bool) -> Content
  var body: some View { content(mode == .accented) }
}

struct DayCounterView: View {
  @Environment(\.widgetFamily) private var family
  let entry: DayEntry

  private var familyName: String { family == .systemMedium ? "medium" : "small" }

  var body: some View {
    // Photo only with a couple: the empty state never shows a stale file.
    let photo = (entry.snapshot?.isCounter ?? false) ? WidgetSnapshot.loadPhoto() : nil
    content(dark: photo == nil)
      .widgetBackground(WidgetBackground(medium: family == .systemMedium, photo: photo))
      .widgetURL(URL(string: "dearembeiu://widget?family=\(familyName)"))
  }

  /// `dark` = night-sky default (design M2); false = over the couple photo (P3).
  @ViewBuilder private func content(dark: Bool) -> some View {
    if let snapshot = entry.snapshot, snapshot.isCounter {
      let model = DayModel(snapshot: snapshot, today: entry.date)
      if family == .systemMedium {
        MediumCounter(model: model, dark: dark)
      } else {
        SmallCounter(model: model, dark: dark)
      }
    } else {
      EmptyState(chip: entry.snapshot?["emptyChip"] ?? "DEAR EMBEIU",
                 text: entry.snapshot?["emptyText"] ?? NSLocalizedString("empty_tap", comment: ""))
    }
  }
}

/// The couple photo the CounterCard shows (center-crop + the card's
/// mid-strength bottom scrim — design P3), or, with no photo yet, the night
/// sky of the Love Tree with the heart constellation (design M2, user chốt
/// 2026-10-12). The old sunset gradient was darker than anything in the app.
struct WidgetBackground: View {
  let medium: Bool
  var photo: UIImage? = nil
  var body: some View {
    if let photo {
      ZStack {
        GeometryReader { g in
          Image(uiImage: photo).resizable().scaledToFill()
            .frame(width: g.size.width, height: g.size.height).clipped()
        }
        LinearGradient(colors: [.black.opacity(0.18), .black.opacity(0.60)],
                       startPoint: .top, endPoint: .bottom)
      }
    } else {
      NightSky(medium: medium)
    }
  }
}

/// Navy → indigo 160°, a lavender glow top-right, a blush glow bottom-left,
/// five faint stars and the 6-star heart constellation top-right.
struct NightSky: View {
  let medium: Bool
  var body: some View {
    ZStack {
      LinearGradient(stops: [
        .init(color: Color(hex: 0x1A1A2E), location: 0),
        .init(color: Color(hex: 0x241F45), location: 0.55),
        .init(color: Color(hex: 0x352A5E), location: 1),
      ], startPoint: .topLeading, endPoint: .bottomTrailing)
      Circle().fill(lavender.opacity(0.35))
        .frame(width: medium ? 190 : 140, height: medium ? 190 : 140).blur(radius: 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .offset(x: 50, y: -60)
      Circle().fill(Color(hex: 0xFF6B9D).opacity(0.28))
        .frame(width: medium ? 170 : 130, height: medium ? 170 : 130).blur(radius: 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .offset(x: -50, y: 55)
      Canvas { ctx, size in
        let stars: [(CGFloat, CGFloat, CGFloat, Double)] = [
          (0.19, 0.38, 2, 0.7), (0.41, 0.22, 1.5, 0.6), (0.79, 0.47, 1.5, 0.6), (0.13, 0.63, 1.5, 0.6), (0.55, 0.72, 1.5, 0.5),
        ]
        for (x, y, r, a) in stars {
          let rect = CGRect(x: x * size.width - r, y: y * size.height - r, width: r * 2, height: r * 2)
          ctx.fill(Path(ellipseIn: rect), with: .color(.white.opacity(a)))
        }
      }
      Constellation()
        .frame(width: 52, height: 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(.top, 12).padding(.trailing, 14)
    }
  }
}

/// Heart of 6 stars joined by a faint line (Love Tree v3 motif). Decorative.
struct Constellation: View {
  var body: some View {
    Canvas { ctx, _ in
      var line = Path()
      let pts: [CGPoint] = [.init(x: 26, y: 44), .init(x: 8, y: 26), .init(x: 10, y: 10), .init(x: 26, y: 16), .init(x: 42, y: 10), .init(x: 44, y: 26)]
      line.move(to: pts[0]); for p in pts.dropFirst() { line.addLine(to: p) }; line.closeSubpath()
      ctx.stroke(line, with: .color(.white.opacity(0.35)), lineWidth: 1)
      let dots: [(CGPoint, CGFloat, Color)] = [
        (pts[0], 2.6, .white), (pts[1], 2.2, .white), (pts[2], 2.6, lavender), (pts[3], 2, .white), (pts[4], 2.6, blush), (pts[5], 2.2, .white),
      ]
      for (p, r, c) in dots {
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(c))
      }
    }
    .accessibilityHidden(true)
  }
}

/// "TUẤN ♥ THẢO". Night sky: translucent pill, white ink. Over a photo: white
/// pill, navy ink (small white text on a bright photo fails 4.5:1).
/// Tinted/Clear: the pill drops to .22 and the names stay full-tint on top.
struct NamesChip: View {
  let name1: String
  let name2: String
  var dark: Bool = true

  var body: some View {
    AccentedReader { accented in
      // .kerning on a container is iOS 16+; on Text it is iOS 13+, so per Text.
      HStack(spacing: 5) {
        if !name1.isEmpty { Text(name1).kerning(1) }
        if !name1.isEmpty && !name2.isEmpty {
          Image(systemName: "heart.fill")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(dark ? blush : loveDeep)
            .accessibilityHidden(true)
        }
        if !name2.isEmpty { Text(name2).kerning(1) }
      }
      .font(.quicksand("Bold", 10))
      .textCase(.uppercase)
      .lineLimit(1)
      .foregroundColor(dark ? .white : navy)
      .accentable()
      .padding(.horizontal, 8)
      .frame(height: 20)
      .background(ChipPill(dark: dark, accented: accented))
    }
  }
}

struct ChipPill: View {
  let dark: Bool
  let accented: Bool
  var body: some View {
    Capsule().fill(Color.white.opacity(accented ? 0.22 : (dark ? 0.14 : 0.84)))
      .overlay(Capsule().stroke(Color.white.opacity(dark && !accented ? 0.22 : 0), lineWidth: 1))
  }
}

struct DayNumber: View {
  let text: String
  var body: some View {
    Text(text)
      .font(.quicksand("Bold", 40))
      .kerning(-1)
      .foregroundColor(.white)
      .lineLimit(1)
      .minimumScaleFactor(0.6)
      .inkShadow()
      .accentable()
  }
}

struct Caption: View {
  let text: String
  var body: some View {
    Text(text)
      .font(.quicksand("SemiBold", 12))
      .foregroundColor(.white.opacity(0.92))
      .lineLimit(2)
      .inkShadow(0.28)
      .accentable()
  }
}

/// Accentable per element (number, caption, chip text) — never on a container
/// that also holds the chip pill (see NamesChip).
struct SmallCounter: View {
  let model: DayModel
  var dark: Bool = true
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      NamesChip(name1: model.name1, name2: model.name2, dark: dark)
      Spacer(minLength: 4)
      DayNumber(text: model.daysText)
      Caption(text: model.daysLabel).padding(.top, 6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

struct ProgressBar: View {
  let value: Double
  var dark: Bool = true
  var body: some View {
    GeometryReader { g in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.white.opacity(dark ? 0.16 : 0.26))
        Capsule().fill(dark ? lavender : Color.white.opacity(0.96)).frame(width: max(6, g.size.width * value))
      }
    }
    .frame(height: 6)
  }
}

struct MediumCounter: View {
  let model: DayModel
  var dark: Bool = true
  var body: some View {
    HStack(spacing: 0) {
      SmallCounter(model: model, dark: dark).frame(width: 150)
      Rectangle().fill(Color.white.opacity(dark ? 0.14 : 0.28)).frame(width: 1)
        .padding(.horizontal, 14).padding(.vertical, 2)
      VStack(alignment: .leading, spacing: 8) {
        // Night sky: the constellation sits top-right, so the milestone line
        // keeps 48pt clear and may wrap to 2 lines ("Cột mốc / 1.500 ngày").
        Text(model.milestoneText)
          .font(.quicksand("Bold", 12)).foregroundColor(.white).lineLimit(2)
          .minimumScaleFactor(0.85).inkShadow(0.28)
          .padding(.trailing, dark ? 48 : 0)
        ProgressBar(value: model.progress, dark: dark)
        Caption(text: model.daysLeftText)
        Spacer(minLength: 0)
        // "Bắt đầu từ 28 thg 12, 2023" is 133pt — two lines rather than losing the year.
        Text(model.sinceText)
          .font(.quicksand("Medium", 11)).foregroundColor(.white.opacity(0.84)).lineLimit(2).inkShadow(0.28)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .accentable()
    }
  }
}

struct EmptyState: View {
  let chip: String
  let text: String
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      AccentedReader { accented in
        HStack(spacing: 5) {
          Image(systemName: "heart.fill")
            .font(.system(size: 9, weight: .bold)).foregroundColor(blush).accessibilityHidden(true)
          Text(chip).kerning(1)
        }
        .font(.quicksand("Bold", 10)).lineLimit(1).foregroundColor(.white)
        .accentable() // same as NamesChip: faint pill under full-tint text when tinted
        .padding(.horizontal, 8).frame(height: 20)
        .background(ChipPill(dark: true, accented: accented))
      }
      Spacer(minLength: 4)
      Text(text)
        .font(.quicksand("Bold", 14)).foregroundColor(.white).lineLimit(3).inkShadow()
        .accentable()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}
