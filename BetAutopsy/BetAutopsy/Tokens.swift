//
//  Tokens.swift
//  BetAutopsy
//
//  Forensic case-file design system.
//  Reference Tokens.swift for every value. Never hardcode hex.
//

import SwiftUI

// MARK: - Colors

enum BAColor {
    // Brand
    static let midnight = Color(hex: 0x0D1117)        // ground
    static let scalpelTeal = Color(hex: 0x00C9A7)     // signal
    static let bleedRed = Color(hex: 0xE8453C)        // warning / loss

    // Surface ramp (dark only — app is dark-mode locked)
    static let surface0 = Color(hex: 0x0D1117)        // base background
    static let surface1 = Color(hex: 0x161B22)        // cards
    static let surface2 = Color(hex: 0x1F2630)        // elevated cards
    static let surface3 = Color(hex: 0x2A3340)        // highest

    // Text
    static let textPrimary = Color(hex: 0xF0F0F0)
    static let textSecondary = Color(hex: 0xA0A0A0)
    static let textTertiary = Color(hex: 0x606060)

    // Edge highlight (1px top-edge for elevation, never shadows)
    static let edgeHighlight = Color.white.opacity(0.03)
}

// MARK: - Typography

enum BAFont {
    // Numbers, IDs, timestamps — JetBrains Mono
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    // Body, narrative — Inter (using SF for now, swap to Inter on Day 3)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    // Hero number (dollar impact on dashboard)
    static let heroNumber = mono(56, weight: .bold)

    // Section headers
    static let sectionHeader = body(14, weight: .medium)

    // Body
    static let bodyLarge = body(17, weight: .regular)
    static let bodyDefault = body(15, weight: .regular)
    static let bodySmall = body(13, weight: .regular)

    // Forensic chrome (uppercase metadata stamps: "CASE #", "EXHIBIT A")
    static let chrome = body(11, weight: .medium)
}

// MARK: - Spacing

enum BASpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Radii

enum BARadius {
    static let none: CGFloat = 0    // panels
    static let small: CGFloat = 4   // buttons, chips (max)
}

// MARK: - Color hex initializer

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex & 0xFF0000) >> 16) / 255.0
        let g = Double((hex & 0x00FF00) >> 8) / 255.0
        let b = Double(hex & 0x0000FF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
