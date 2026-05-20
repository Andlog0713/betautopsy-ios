//
//  HeroRingInsufficient.swift
//  BetAutopsy
//
//  Building-sample variant of HeroRingView, rendered when the engine
//  global sample floor (c9d9d56) flags a metric insufficient_data. Same
//  230x230 footprint as HeroRingView but track ring only (no progress
//  arc), and the 86pt number is replaced by a stacked "BUILDING /
//  SAMPLE" stand-in. Used by Ch 1 (BETIQ), Ch 2 (EMOTION), Ch 3
//  (DISCIPLINE) when their detector did not clear the floor.
//

import SwiftUI

struct HeroRingInsufficient: View {
    let metricLabel: String  // e.g. "BETIQ"

    private let diameter: CGFloat = 230
    private let lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            // Track ring only, no progress arc, since there is no score.
            Circle()
                .stroke(DS.Color.V3.borderRingTrack, lineWidth: lineWidth)

            VStack(spacing: 6) {
                Text("BETAUTOPSY")
                    .font(DS.Font.V3.heroBrandWordmark)
                    .tracking(2.4)
                    .foregroundStyle(DS.Color.V3.textWatermark)

                VStack(spacing: 2) {
                    Text("BUILDING")
                        .font(DS.Font.V3.heroMetricLabel)
                        .tracking(2.0)
                        .foregroundStyle(DS.Color.V3.textSecondary)
                    Text("SAMPLE")
                        .font(DS.Font.V3.heroMetricLabel)
                        .tracking(2.0)
                        .foregroundStyle(DS.Color.V3.textSecondary)
                }

                Text(metricLabel.uppercased())
                    .font(DS.Font.V3.heroMetricLabel)
                    .tracking(2.0)
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(metricLabel) score: building sample. More bet history needed.")
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 32) {
        HeroRingInsufficient(metricLabel: "BETIQ")
        HeroRingInsufficient(metricLabel: "EMOTION")
        HeroRingInsufficient(metricLabel: "DISCIPLINE")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
