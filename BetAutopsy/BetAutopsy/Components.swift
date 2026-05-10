//
//  Components.swift
//  BetAutopsy
//
//  Reusable UI building blocks. Reference these everywhere.
//  Never hand-roll a new card or button style — extend these.
//

import SwiftUI

// MARK: - BACard
//
// Forensic case-file card. Surface1 background, 1px border, 1px top edge highlight.
// Use for any grouped content: bet rows, report sections, settings groups.
//

struct BACard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            content
                .padding(BASpacing.m)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(BAColor.surface1)
                .overlay(
                    Rectangle()
                        .stroke(BAColor.surface3, lineWidth: 0.5)
                )

            // 1px top-edge highlight (Linear's pattern)
            Rectangle()
                .fill(BAColor.edgeHighlight)
                .frame(height: 1)
        }
    }
}

// MARK: - BAButton
//
// Three variants:
// - .primary: scalpel teal background, dark text. The CTA.
// - .secondary: surface2 background, primary text. Secondary actions.
// - .destructive: bleed red background, white text. Delete, sign out.
//

enum BAButtonStyle {
    case primary, secondary, destructive

    var background: Color {
        switch self {
        case .primary:     return BAColor.scalpelTeal
        case .secondary:   return BAColor.surface2
        case .destructive: return BAColor.bleedRed
        }
    }

    var foreground: Color {
        switch self {
        case .primary:     return BAColor.midnight
        case .secondary:   return BAColor.textPrimary
        case .destructive: return Color.white
        }
    }
}

struct BAButton: View {
    let title: String
    let style: BAButtonStyle
    let action: () -> Void

    init(_ title: String, style: BAButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BAFont.body(15, weight: .semibold))
                .foregroundStyle(style.foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(style.background)
                .clipShape(RoundedRectangle(cornerRadius: BARadius.small))
        }
    }
}

// MARK: - BAChromeLabel
//
// Forensic metadata stamp. Uppercase, tracked, tertiary text.
// Use for "CASE #", "EXHIBIT A", "FILED:", etc.
//

struct BAChromeLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(BAFont.chrome)
            .foregroundStyle(BAColor.textTertiary)
            .tracking(1.2)
    }
}

// MARK: - Previews

#Preview("Components") {
    ZStack {
        BAColor.surface0.ignoresSafeArea()

        ScrollView {
            VStack(spacing: BASpacing.l) {
                BAChromeLabel("Case File Components")

                BACard {
                    VStack(alignment: .leading, spacing: BASpacing.s) {
                        BAChromeLabel("Exhibit A")
                        Text("This is a card.")
                            .font(BAFont.bodyDefault)
                            .foregroundStyle(BAColor.textPrimary)
                        Text("Surface1 background, 1px border, edge highlight.")
                            .font(BAFont.bodySmall)
                            .foregroundStyle(BAColor.textSecondary)
                    }
                }

                BAButton("Primary action", style: .primary) {}
                BAButton("Secondary action", style: .secondary) {}
                BAButton("Destructive action", style: .destructive) {}
            }
            .padding(BASpacing.m)
        }
    }
    .preferredColorScheme(.dark)
}
