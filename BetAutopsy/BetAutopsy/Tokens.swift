// ─────────────────────────────────────────────────────────────────
// BetAutopsy design system tokens.
//
// V2 = Luminol (legacy, being migrated).
// V3 = current visual direction (WHOOP-style).
//
// V3 spec: Notion 35e5964c-daf2-819e-9484-de25a4e3af56
//
// PR-V1 through PR-V9 cascade migrates every consumer from V2 to V3.
// Both namespaces coexist during the cascade. The V2 namespace will
// be deleted in a final cleanup commit after PR-V9 lands.
//
// Rules during cascade:
//   - Additive only: do not modify or remove V2 tokens.
//   - New views consume V3.
//   - Existing views stay on V2 until their dedicated cascade PR.
// ─────────────────────────────────────────────────────────────────

import SwiftUI

enum DS {
  enum Color {
    enum Surface {
      static let canvas = SwiftUI.Color(hex: 0x14151D)
      static let card   = SwiftUI.Color(hex: 0x1B1D27)
      static let raised = SwiftUI.Color(hex: 0x232636)
    }
    enum Border {
      static let subtle = SwiftUI.Color(hex: 0x292B38)
    }
    enum Text {
      static let primary    = SwiftUI.Color(hex: 0xECEDF1)
      static let secondary  = SwiftUI.Color(hex: 0xA8AABF)
      static let tertiary   = SwiftUI.Color(hex: 0x74768C)
      static let quaternary = SwiftUI.Color(hex: 0x3D3F50)
    }
    enum Accent {
      static let luminol     = SwiftUI.Color(hex: 0x6B5BFF)
      static let luminolSoft = SwiftUI.Color(hex: 0x8B7DFF)
    }
    enum Semantic {
      static let blood = SwiftUI.Color(hex: 0xFF5454)
      static let win   = SwiftUI.Color(hex: 0x5BFFA8)
    }
    enum Archetype {
      static let natural        = SwiftUI.Color(hex: 0x5BFFA8)
      static let sharpSleeper   = SwiftUI.Color(hex: 0x6B5BFF)
      static let heatedBettor   = SwiftUI.Color(hex: 0xFF5454)
      static let chalkGrinder   = SwiftUI.Color(hex: 0xB8944A)
      static let parlayDreamer  = SwiftUI.Color(hex: 0x8B7DFF)
      static let sniper         = SwiftUI.Color(hex: 0x60A5FA)
      static let volumeWarrior  = SwiftUI.Color(hex: 0xA78BFA)
      static let degenKing      = SwiftUI.Color(hex: 0xFF5454)
      static let grinder        = SwiftUI.Color(hex: 0xA8AABF)
    }
  }
  enum Spacing {
    static let xxs: CGFloat = 2
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
  }
  enum Radius {
    static let chip:  CGFloat = 4
    static let tile:  CGFloat = 6
    static let card:  CGFloat = 10
    static let sheet: CGFloat = 16
  }
  enum Stroke {
    static let hairline: CGFloat = 0.5
  }
}

extension Color {
  init(hex: UInt32) {
    let r = Double((hex >> 16) & 0xFF) / 255
    let g = Double((hex >> 8) & 0xFF) / 255
    let b = Double(hex & 0xFF) / 255
    self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
  }

  init(hex: String) {
    var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.hasPrefix("#") { trimmed.removeFirst() }
    guard trimmed.count == 6, let value = UInt32(trimmed, radix: 16) else {
      self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
      return
    }
    self.init(hex: value)
  }
}

// ─────────────────────────────────────────────────────────────────
// V3 tokens (WHOOP-style visual direction).
// Additive: do not modify V2 above. See PR-V1 cascade plan.
// ─────────────────────────────────────────────────────────────────

extension DS.Color {
    enum V3 {
        // Canvas + surfaces
        static let canvasGradientStart = SwiftUI.Color(hex: "#131A20")
        static let canvasGradientEnd   = SwiftUI.Color(hex: "#0A0E12")
        static let surfaceCard         = SwiftUI.Color.white.opacity(0.04)

        // Borders
        static let borderSubtle       = SwiftUI.Color.white.opacity(0.06)
        static let borderRingTrack    = SwiftUI.Color.white.opacity(0.07)
        static let borderSubtleStrong = SwiftUI.Color.white.opacity(0.08)

        // Text (V3 uses white-with-opacity ladder, NOT V2's off-white)
        static let textPrimary   = SwiftUI.Color.white
        static let textSecondary = SwiftUI.Color.white.opacity(0.7)
        static let textTertiary  = SwiftUI.Color.white.opacity(0.5)
        static let textWatermark = SwiftUI.Color.white.opacity(0.32)

        // Icon stroke (chevrons, info glyph)
        static let iconStroke = SwiftUI.Color(hex: "#C0C5CE")

        // Insight callout
        static let insightBorder = SwiftUI.Color(hex: "#7F7ADC").opacity(0.5)
        static let ctaText       = SwiftUI.Color(hex: "#8B86E8")

        // Severity-driven score colors (V3 rings are severity-colored,
        // NOT archetype-colored — archetype identity moves to typography).
        enum Severity {
            static let red    = SwiftUI.Color(hex: "#FF4D4D")
            static let orange = SwiftUI.Color(hex: "#FF7847")
            static let yellow = SwiftUI.Color(hex: "#FFCD2C")
            static let green  = SwiftUI.Color(hex: "#00DC82")
            static let gray   = SwiftUI.Color(hex: "#7A7E8B")

            static func zoneColor(forScore score: Int) -> SwiftUI.Color {
                switch score {
                case ..<34:    return red
                case 34..<67:  return yellow
                default:       return green
                }
            }
        }
    }
}

extension DS {
    enum Font {
        enum V3 {
            // Hero
            static let heroNumber        = SwiftUI.Font.system(size: 86, weight: .bold).monospacedDigit()
            static let heroMetricLabel   = SwiftUI.Font.system(size: 12, weight: .bold)
            static let heroBrandWordmark = SwiftUI.Font.system(size: 13, weight: .bold)

            // Chapter navigator
            static let navigatorLabel    = SwiftUI.Font.system(size: 13, weight: .bold)
            static let navigatorSubtitle = SwiftUI.Font.system(size: 10, weight: .semibold)

            // Section header
            static let sectionTitle    = SwiftUI.Font.system(size: 22, weight: .bold)
            static let sectionSubtitle = SwiftUI.Font.system(size: 11, weight: .regular)

            // Contributor row
            static let rowCapsLabel = SwiftUI.Font.system(size: 11, weight: .bold)
            static let rowValue     = SwiftUI.Font.system(size: 17, weight: .bold).monospacedDigit()

            // Insight callout
            static let insightBody = SwiftUI.Font.system(size: 12.5, weight: .regular)
            static let ctaText     = SwiftUI.Font.system(size: 11, weight: .bold)
        }
    }
}
