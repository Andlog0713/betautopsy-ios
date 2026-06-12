//
//  ContributorBars.swift
//  BetAutopsy
//
//  3B component library: a sub-component score breakdown as labeled
//  horizontal bars (BetIQ components, emotion_breakdown). Generalizes
//  the bar language of BetIQComponentBars / TiltSignalBreakdownCard:
//  caps label, severity-zoned fill on the value/max ratio, mono
//  "value/max" readout via BAFormat.score.
//
//  Value-driven: callers map their model (BetIQComponents,
//  EmotionBreakdown) into [Contributor]. higherIsWorse flips the
//  severity scale for risk-direction breakdowns.
//

import SwiftUI

struct ContributorBars: View {
    struct Contributor: Identifiable {
        let label: String
        let value: Int
        let max: Int
        var id: String { label }

        var ratio: Double {
            max > 0 ? Swift.max(0, Swift.min(1, Double(value) / Double(max))) : 0
        }
    }

    let contributors: [Contributor]
    var higherIsWorse: Bool = false

    var body: some View {
        if !contributors.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(contributors) { contributor in
                    barRow(contributor)
                }
            }
        }
    }

    @ViewBuilder
    private func barRow(_ contributor: Contributor) -> some View {
        let tint = DS.Color.V3.Severity.zoneColor(
            forScore: Int((contributor.ratio * 100).rounded()),
            higherIsWorse: higherIsWorse
        )
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(contributor.label.uppercased())
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.1)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                Text(BAFormat.score(contributor.value, outOf: contributor.max))
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(tint)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DS.Color.V3.borderSubtle)
                    Capsule()
                        .fill(tint)
                        .frame(width: Swift.max(0, geo.size.width * contributor.ratio))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(contributor.label), \(contributor.value) out of \(contributor.max)."
        )
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 24) {
        // BetIQ components shape.
        ContributorBars(contributors: [
            .init(label: "Line value", value: 14, max: 25),
            .init(label: "Calibration", value: 11, max: 20),
            .init(label: "Sophistication", value: 9, max: 15),
            .init(label: "Specialization", value: 12, max: 15)
        ])
        // Emotion breakdown shape (risk direction).
        ContributorBars(contributors: [
            .init(label: "Stake volatility", value: 78, max: 100),
            .init(label: "Loss chasing", value: 84, max: 100),
            .init(label: "Streak behavior", value: 41, max: 100),
            .init(label: "Session discipline", value: 72, max: 100)
        ], higherIsWorse: true)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
