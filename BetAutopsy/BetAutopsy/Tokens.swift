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
