//
//  InsightCallout.swift
//  BetAutopsy
//
//  V3 insight callout: brand-yellow-bordered box, body paragraph,
//  caps CTA with trailing arrow.
//
//  V1 (PR-V1): CTA is inert. The closure is stubbed to a debug print so
//  the tap target is real but does nothing. Wiring lands in v1.1 cascade.
//

import SwiftUI

struct InsightCallout: View {
    let text: String
    let ctaLabel: String   // caps display
    let onTap: () -> Void

    private let cornerRadius: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(DS.Font.V3.insightBody)
                .foregroundStyle(DS.Color.V3.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: onTap) {
                HStack(spacing: 6) {
                    Text(ctaLabel.uppercased())
                        .font(DS.Font.V3.ctaText)
                        .tracking(1.4)
                        .foregroundStyle(DS.Color.Brand.yellow)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DS.Color.Brand.yellow)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(ctaLabel)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(DS.Color.Brand.yellowBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    InsightCallout(
        text: "Stake volatility spiked across the last six sessions. Smaller, " +
              "more uniform stakes pull this number down inside two weeks.",
        ctaLabel: "READ THE HEATED FILE",
        onTap: { print("InsightCallout tapped (V1 stub).") }
    )
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
