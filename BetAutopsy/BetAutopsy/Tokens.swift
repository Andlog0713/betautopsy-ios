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
      static let secondary  = SwiftUI.Color(hex: 0x8E90A6)
      static let tertiary   = SwiftUI.Color(hex: 0x5F6178)
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
      static let heatChaser    = SwiftUI.Color(hex: 0xFF5454)
      static let surgeon       = SwiftUI.Color(hex: 0x6B5BFF)
      static let parlayDreamer = SwiftUI.Color(hex: 0xFF8FB1)
      static let grinder       = SwiftUI.Color(hex: 0xA89472)
      static let gutBettor     = SwiftUI.Color(hex: 0xFFCB47)
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
}
