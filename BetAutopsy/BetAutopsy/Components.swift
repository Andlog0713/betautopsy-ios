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
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - BAButton

enum BAButtonStyle {
    case primary, secondary, destructive

    var background: Color {
        switch self {
        case .primary:     return DS.Color.V3.primaryFill
        case .secondary:   return DS.Color.V3.surfaceRaised
        case .destructive: return DS.Color.V3.Severity.red
        }
    }

    var foreground: Color {
        switch self {
        case .primary:     return DS.Color.V3.primaryFillText
        case .secondary:   return DS.Color.V3.textPrimary
        case .destructive: return DS.Color.V3.textPrimary
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
                .font(.system(size: 15, weight: .semibold))
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
            .font(.system(size: 11, weight: .medium).monospacedDigit())
            .foregroundStyle(DS.Color.V3.textTertiary)
            .tracking(11 * 0.15)
    }
}

// MARK: - Previews

#Preview("Components") {
    ZStack {
        DS.Color.V3.canvasGradient.ignoresSafeArea()

        ScrollView {
            VStack(spacing: DS.Spacing.lg) {
                BAChromeLabel("Case File Components")

                BACard {
                    VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                        BAChromeLabel("Exhibit A")
                        Text("This is a card.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(DS.Color.V3.textPrimary)
                        Text("Card surface, hairline border.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(DS.Color.V3.textSecondary)
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
