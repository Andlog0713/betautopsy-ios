//
//  Components.swift
//  BetAutopsy
//
//  Reusable UI building blocks. Reference these everywhere.
//  Never hand-roll a new card or button style — extend these.
//

import SwiftUI

// MARK: - BACard

struct BACard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.Surface.card)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - BAButton

enum BAButtonStyle {
    case primary, secondary, destructive

    var background: Color {
        switch self {
        case .primary:     return DS.Color.Accent.luminol
        case .secondary:   return DS.Color.Surface.raised
        case .destructive: return DS.Color.Semantic.blood
        }
    }

    var foreground: Color {
        switch self {
        case .primary:     return DS.Color.Text.primary
        case .secondary:   return DS.Color.Text.primary
        case .destructive: return DS.Color.Text.primary
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
                .font(.custom("Inter-SemiBold", size: 15))
                .foregroundStyle(style.foreground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(style.background)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
        }
    }
}

// MARK: - BAChromeLabel

struct BAChromeLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.custom("JetBrainsMono-Medium", size: 11))
            .foregroundStyle(DS.Color.Text.tertiary)
            .tracking(11 * 0.15)
    }
}

// MARK: - Previews

#Preview("Components") {
    ZStack {
        DS.Color.Surface.canvas.ignoresSafeArea()

        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                BAChromeLabel("Case File Components")

                BACard {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        BAChromeLabel("Exhibit A")
                        Text("This is a card.")
                            .font(.custom("Inter-Regular", size: 15))
                            .foregroundStyle(DS.Color.Text.primary)
                        Text("Card surface, hairline border.")
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundStyle(DS.Color.Text.secondary)
                    }
                }

                BAButton("Primary action", style: .primary) {}
                BAButton("Secondary action", style: .secondary) {}
                BAButton("Destructive action", style: .destructive) {}
            }
            .padding(DS.Spacing.md)
        }
    }
    .preferredColorScheme(.dark)
}
