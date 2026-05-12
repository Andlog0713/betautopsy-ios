//
//  ContributorRow.swift
//  BetAutopsy
//
//  V3 contributor row: icon, caps label, 70pt severity-colored segment bar
//  with a positional dot, and a monospaced-digit value.
//
//  trendUp is future-proofed (nil = hidden in V1; v1.1 cascade adds the
//  arrow glyph once trend data lands on AutopsyAnalysis).
//

import SwiftUI

struct ContributorRow: View {
    let iconSystemName: String   // SF Symbol
    let label: String            // caps display
    let value: Int               // 0...100
    let trendUp: Bool?           // nil in V1

    private var clampedValue: Int { max(0, min(100, value)) }
    private var progress: CGFloat { CGFloat(clampedValue) / 100.0 }

    private var segmentColor: Color {
        DS.Color.V3.Severity.zoneColor(forScore: clampedValue)
    }

    private let barWidth: CGFloat = 70
    private let barHeight: CGFloat = 4
    private let dotDiameter: CGFloat = 8

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconSystemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.Color.V3.iconStroke)
                .frame(width: 18, alignment: .center)

            Text(label.uppercased())
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.4)
                .foregroundStyle(DS.Color.V3.textSecondary)

            Spacer(minLength: 12)

            // Segment bar with positional dot
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DS.Color.V3.borderSubtleStrong)
                    .frame(width: barWidth, height: barHeight)

                Capsule()
                    .fill(segmentColor)
                    .frame(width: barWidth * progress, height: barHeight)

                Circle()
                    .fill(segmentColor)
                    .frame(width: dotDiameter, height: dotDiameter)
                    .offset(x: max(0, (barWidth * progress) - (dotDiameter / 2)))
            }
            .frame(width: barWidth, height: dotDiameter)

            Text("\(clampedValue)")
                .font(DS.Font.V3.rowValue)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .frame(minWidth: 32, alignment: .trailing)

            if let trendUp {
                Image(systemName: trendUp ? "arrow.up" : "arrow.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        trendUp
                            ? DS.Color.V3.Severity.green
                            : DS.Color.V3.Severity.red
                    )
            }
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(clampedValue) out of 100")
    }
}

#Preview {
    VStack(spacing: 0) {
        ContributorRow(
            iconSystemName: "shield",
            label: "DISCIPLINE",
            value: 17,
            trendUp: nil
        )
        V3Divider()
        ContributorRow(
            iconSystemName: "flame",
            label: "EMOTION",
            value: 88,
            trendUp: nil
        )
    }
    .padding(.horizontal, 16)
    .background(DS.Color.V3.surfaceCard)
    .preferredColorScheme(.dark)
}
