//
//  ScoreGauge.swift
//  BetAutopsy
//
//  3B component library: compact 0-100 radial gauge for card-level
//  score display (BetIQ, emotion, discipline). HeroRingView remains
//  the full-bleed 86pt hero; this is the small reusable arc.
//
//  Tint via DS.Color.V3.Severity.zoneColor so the gauge reads on the
//  same severity scale as the rest of the report. higherIsWorse flips
//  the scale for risk-direction scores (emotion, tilt).
//

import SwiftUI

struct ScoreGauge: View {
    let score: Int
    let label: String
    var higherIsWorse: Bool = false
    var diameter: CGFloat = 72

    private var clamped: Int { max(0, min(100, score)) }

    private var tint: Color {
        DS.Color.V3.Severity.zoneColor(forScore: clamped, higherIsWorse: higherIsWorse)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(DS.Color.V3.borderRingTrack, lineWidth: 5)

                Circle()
                    .trim(from: 0, to: CGFloat(clamped) / 100)
                    .stroke(tint, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(clamped)")
                    .font(.system(size: diameter * 0.32, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
            }
            .frame(width: diameter, height: diameter)

            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) score \(clamped) out of 100.")
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 24) {
        ScoreGauge(score: 62, label: "BETIQ")
        ScoreGauge(score: 73, label: "EMOTION", higherIsWorse: true)
        ScoreGauge(score: 44, label: "DISCIPLINE", diameter: 88)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
