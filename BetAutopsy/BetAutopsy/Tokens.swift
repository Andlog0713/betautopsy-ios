// ─────────────────────────────────────────────────────────────────
// BetAutopsy design system tokens.
//
// V2 = Luminol (legacy, retirement deferred).
// V3 = current visual direction (WHOOP-style).
//
// V3 spec: Notion 35e5964c-daf2-819e-9484-de25a4e3af56
//
// PR-V1 through PR-V9 migrated the report chapters (Ch 1-7) to V3.
// PR-V10 closes out by migrating Ch 6, TodayView, and PaywallView.
// The V2 namespace remains intact in this file because ~15 other
// consumers (BetDNAQuizView, ReportListView, SessionsTabView, the
// auth and age-gate flow, ArchetypeRevealView, UploadProgressView,
// ReportModels severity encoders, Components.swift primitives, etc.)
// are still on V2. V2 namespace retirement is scoped as a follow-up
// bundle.
//
// Rules:
//   - V2 namespace remains; additive-only changes here.
//   - New views consume V3.
//   - Existing V2 views stay on V2 until their follow-up migration.
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
      // V3 archetype color tokens (PR-V11). Hex values preserved from
      // the V2 keys they replaced — only the key names changed. The
      // backend-only V3 archetypes (Reformed Degen, Bonus Hunter,
      // Steamer) will get their own colors when those branches land.
      static let chaser        = SwiftUI.Color(hex: 0xFF5C45)  // NEW. PLACEHOLDER — refine in PR-V9 design pass.
      static let tilter        = SwiftUI.Color(hex: 0xFF5454)  // was heatedBettor
      static let sharp         = SwiftUI.Color(hex: 0x5BFFA8)  // was natural
      static let lotteryBettor = SwiftUI.Color(hex: 0x8B7DFF)  // was parlayDreamer
      static let grinder       = SwiftUI.Color(hex: 0xA78BFA)  // was volumeWarrior — V3 sense (high-volume archetype)
      static let actionJunkie  = SwiftUI.Color(hex: 0xFF5454)  // was degenKing
      static let methodical    = SwiftUI.Color(hex: 0xA8AABF)  // was the V2 fallback (also keyed .grinder) — renamed to avoid V3 Grinder collision
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
        // Three-tier elevation: canvas (gradient) → surfaceCard → surfaceRaised.
        // Mirrors V2's canvas/card/raised pattern.
        static let canvasGradientStart = SwiftUI.Color(hex: "#131A20")
        static let canvasGradientEnd   = SwiftUI.Color(hex: "#0A0E12")
        static let surfaceCard         = SwiftUI.Color.white.opacity(0.04)
        static let surfaceRaised       = SwiftUI.Color.white.opacity(0.07)

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

        // Insight callout (PR-9 brand swap).
        // These names are retained as aliases for backwards compatibility
        // with ~25 V3 consumers (PR-V-CASCADE-DAY-12). New code should
        // reference DS.Color.Brand.* directly — see Brand namespace below.
        static let insightBorder = DS.Color.Brand.yellowBorder
        static let ctaText       = DS.Color.Brand.yellow

        // Severity-driven score colors (V3 rings are severity-colored,
        // NOT archetype-colored — archetype identity moves to typography).
        enum Severity {
            static let red    = SwiftUI.Color(hex: "#FF4D4D")
            static let orange = SwiftUI.Color(hex: "#FF7847")
            // PR-9: #FFCD2C → #FFC66D (Darcula amber). Disambiguates
            // severity caution from brand yellow #FACC15.
            static let yellow = SwiftUI.Color(hex: "#FFC66D")
            static let green  = SwiftUI.Color(hex: "#00DC82")
            static let gray   = SwiftUI.Color(hex: "#7A7E8B")

            /// Returns the severity color for a 0-100 score.
            /// - When `higherIsWorse` is false (default), higher scores trend
            ///   toward green (optimal). Used for BetIQ, Discipline, Selectivity.
            /// - When `higherIsWorse` is true, higher scores trend toward red
            ///   (critical). Used for Emotion, Tilt, Loss Chasing, etc.
            static func zoneColor(
                forScore score: Int,
                higherIsWorse: Bool = false
            ) -> SwiftUI.Color {
                let clamped = max(0, min(100, score))
                let lowZone:  SwiftUI.Color = higherIsWorse ? green : red
                let highZone: SwiftUI.Color = higherIsWorse ? red   : green
                switch clamped {
                case ..<34:    return lowZone
                case 34..<67:  return yellow
                default:       return highZone
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

// ─────────────────────────────────────────────────────────────────
// V3 additions for the onboarding cascade pilot (PR-V12).
// Additive only — V2 namespace untouched.
// ─────────────────────────────────────────────────────────────────

extension DS.Color.V3 {
    static let canvasGradient = LinearGradient(
        colors: [canvasGradientStart, canvasGradientEnd],
        startPoint: .top,
        endPoint: .bottom
    )
    static let primaryFill     = SwiftUI.Color(hex: "#FFFFFF")
    static let primaryFillText = SwiftUI.Color(hex: "#131A20")
}

extension DS.Font.V3 {
    static let bodyLarge    = SwiftUI.Font.system(size: 17, weight: .regular)
    static let bodyRegular  = SwiftUI.Font.system(size: 15, weight: .regular)
    static let buttonLabel  = SwiftUI.Font.system(size: 16, weight: .semibold)
    static let captionLabel = SwiftUI.Font.system(size: 13, weight: .regular)
}

// ─────────────────────────────────────────────────────────────
// Brand identity tokens — permanent, not versioned (PR-9).
// See Notion 🎨 Brand System v3 — LOCKED
// (3645964c-daf2-8110-bd66-dae2fc6ccad6).
//
// Yellow #FACC15 ladder + transparency steps + interaction states
// per brand deck §05B (interaction system).
// ─────────────────────────────────────────────────────────────

extension DS.Color {
    enum Brand {
        // Primary brand yellow (solid CTA, wordmark, key text, icons).
        static let yellow         = SwiftUI.Color(hex: "#FACC15")

        // Interaction states.
        static let yellowPressed  = SwiftUI.Color(hex: "#E5BA0E")
        static let yellowDim      = SwiftUI.Color(hex: "#FACC15").opacity(0.35)

        // Transparency ladder for borders, washes, backgrounds.
        static let yellowBorder   = SwiftUI.Color(hex: "#FACC15").opacity(0.25)
        static let yellowWash     = SwiftUI.Color(hex: "#FACC15").opacity(0.08)

        // Canvas dark for on-yellow foreground (text + icons against
        // brand-yellow backgrounds — yellow + white fails contrast).
        static let canvasDark     = SwiftUI.Color(hex: "#0A0E12")
    }
}

extension DS {
    enum Gradient {
        /// Ambient canvas — primary app background.
        static let ambientCanvas = LinearGradient(
            colors: [
                SwiftUI.Color(hex: "#131A20"),
                SwiftUI.Color(hex: "#0A0E12")
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Yellow accent wash — archetype reveal, key callouts, premium moments.
        static let yellowWash = LinearGradient(
            colors: [
                SwiftUI.Color(hex: "#FACC15").opacity(0.08),
                SwiftUI.Color(hex: "#131A20")
            ],
            startPoint: .top,
            endPoint: .bottom
        )

        /// Spotlight glow — hero element background.
        static let spotlightGlow = RadialGradient(
            colors: [
                SwiftUI.Color(hex: "#FACC15").opacity(0.15),
                SwiftUI.Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 240
        )
    }
}
