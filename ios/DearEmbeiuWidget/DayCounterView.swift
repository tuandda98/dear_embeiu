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

struct DayCounterView: View {
  @Environment(\.widgetFamily) private var family
  let entry: DayEntry

  private var familyName: String { family == .systemMedium ? "medium" : "small" }

  var body: some View {
    content
      .widgetBackground(WidgetBackground())
      .widgetURL(URL(string: "dearembeiu://widget?family=\(familyName)"))
  }

  @ViewBuilder private var content: some View {
    if let snapshot = entry.snapshot, snapshot.isCounter {
      let model = DayModel(snapshot: snapshot, today: entry.date)
      if family == .systemMedium {
        MediumCounter(model: model)
      } else {
        SmallCounter(model: model)
      }
    } else {
      EmptyState(chip: entry.snapshot?["emptyChip"] ?? "DEAR EMBEIU",
                 text: entry.snapshot?["emptyText"] ?? NSLocalizedString("empty_tap", comment: ""))
    }
  }
}

/// Gradient 150° + dark scrim + two aurora glows, like the Home CounterCard.
struct WidgetBackground: View {
  var body: some View {
    ZStack {
      LinearGradient(stops: [
        .init(color: Color(hex: 0xFF5C8F), location: 0),
        .init(color: Color(hex: 0xFF4D6D), location: 0.55),
        .init(color: Color(hex: 0xE63956), location: 1),
      ], startPoint: .topLeading, endPoint: .bottomTrailing)
      LinearGradient(colors: [.black.opacity(0.10), .black.opacity(0.28)],
                     startPoint: .top, endPoint: .bottom)
      Circle().fill(Color.white.opacity(0.26))
        .frame(width: 96, height: 96).blur(radius: 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .offset(x: -28, y: -30)
      Circle().fill(lavender.opacity(0.40))
        .frame(width: 120, height: 120).blur(radius: 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .offset(x: 40, y: 46)
    }
  }
}

/// "TUẤN ♥ THẢO" — white pill, navy ink (small white text on pink fails 4.5:1).
struct NamesChip: View {
  let name1: String
  let name2: String

  var body: some View {
    // .kerning on a container is iOS 16+; on Text it is iOS 13+, so per Text.
    HStack(spacing: 5) {
      if !name1.isEmpty { Text(name1).kerning(1) }
      if !name1.isEmpty && !name2.isEmpty {
        Image(systemName: "heart.fill")
          .font(.system(size: 9, weight: .bold))
          .foregroundColor(loveDeep)
          .accessibilityHidden(true)
      }
      if !name2.isEmpty { Text(name2).kerning(1) }
    }
    .font(.quicksand("Bold", 10))
    .textCase(.uppercase)
    .lineLimit(1)
    .minimumScaleFactor(0.8)
    .foregroundColor(navy)
    .padding(.horizontal, 8)
    .frame(height: 20)
    .background(Capsule().fill(Color.white.opacity(0.84)))
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
  }
}

struct SmallCounter: View {
  let model: DayModel
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      NamesChip(name1: model.name1, name2: model.name2)
      Spacer(minLength: 4)
      DayNumber(text: model.daysText)
      Caption(text: model.daysLabel).padding(.top, 6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .accentable()
  }
}

struct ProgressBar: View {
  let value: Double
  var body: some View {
    GeometryReader { g in
      ZStack(alignment: .leading) {
        Capsule().fill(Color.white.opacity(0.26))
        Capsule().fill(Color.white.opacity(0.96)).frame(width: max(6, g.size.width * value))
      }
    }
    .frame(height: 6)
  }
}

struct MediumCounter: View {
  let model: DayModel
  var body: some View {
    HStack(spacing: 0) {
      SmallCounter(model: model).frame(width: 150)
      Rectangle().fill(Color.white.opacity(0.28)).frame(width: 1)
        .padding(.horizontal, 14).padding(.vertical, 2)
      VStack(alignment: .leading, spacing: 8) {
        Text(model.milestoneText)
          .font(.quicksand("Bold", 12)).foregroundColor(.white).lineLimit(1).inkShadow(0.28)
        ProgressBar(value: model.progress)
        Caption(text: model.daysLeftText)
        Spacer(minLength: 0)
        Text(model.sinceText)
          .font(.quicksand("Medium", 11)).foregroundColor(.white.opacity(0.84)).lineLimit(1).inkShadow(0.28)
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
      HStack(spacing: 5) {
        Image(systemName: "heart.fill")
          .font(.system(size: 9, weight: .bold)).foregroundColor(loveDeep).accessibilityHidden(true)
        Text(chip).kerning(1)
      }
      .font(.quicksand("Bold", 10)).lineLimit(1).foregroundColor(navy)
      .padding(.horizontal, 8).frame(height: 20)
      .background(Capsule().fill(Color.white.opacity(0.84)))
      Spacer(minLength: 4)
      Text(text)
        .font(.quicksand("Bold", 14)).foregroundColor(.white).lineLimit(3).inkShadow()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .accentable()
  }
}
