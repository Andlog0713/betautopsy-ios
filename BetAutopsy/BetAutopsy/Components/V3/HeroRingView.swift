//
//  HeroRingView.swift
//  BetAutopsy
//
//  V3 hero ring. 230x230 circle, 14pt stroke. Severity-colored .trim arc
//  starting at 12-o'clock and sweeping clockwise.
//
//  Center stack: BETAUTOPSY watermark + 86pt monospaced-digit score
//  + metric caps label.
//
//  Ring color is driven by score severity, NOT archetype color.
//

import SwiftUI

struct HeroRingView: View {
    let score: Int           // 0...100
    let metricLabel: String  // e.g. "BETIQ"
    var higherIsWorse: Bool = false

    private let diameter: CGFloat = 230
    private let lineWidth: CGFloat = 14

    private var clampedScore: Int {
        max(0, min(100, score))
    }

    private var progress: CGFloat {
        CGFloat(clampedScore) / 100.0
    }

    private var ringColor: Color {
        DS.Color.V3.Severity.zoneColor(
            forScore: clampedScore,
            higherIsWorse: higherIsWorse
        )
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(DS.Color.V3.borderRingTrack, lineWidth: lineWidth)

            // Progress arc: rotate -90° so .trim(from: 0) starts at 12 o'clock
            // and sweeps clockwise.
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 6) {
                Text("BETAUTOPSY")
                    .font(DS.Font.V3.heroBrandWordmark)
                    .tracking(2.4)
                    .foregroundStyle(DS.Color.V3.textWatermark)

                Text("\(clampedScore)")
                    .font(DS.Font.V3.heroNumber)
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Text(metricLabel.uppercased())
                    .font(DS.Font.V3.heroMetricLabel)
                    .tracking(2.0)
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
        }
        .frame(width: diameter, height: diameter)
        // Cap (Stage D): the ring is a fixed-geometry circle. The wordmark
        // and metric label scale, but only up to xLarge so they never
        // overflow the 230pt circle; the 86pt hero number is fixed-size
        // already. Body sections elsewhere scale fully to AX5.
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(metricLabel) score \(clampedScore) out of 100")
    }
}

#Preview {
    VStack(spacing: 32) {
        HeroRingView(score: 23, metricLabel: "BETIQ")
        HeroRingView(score: 55, metricLabel: "BETIQ")
        HeroRingView(score: 82, metricLabel: "BETIQ")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
