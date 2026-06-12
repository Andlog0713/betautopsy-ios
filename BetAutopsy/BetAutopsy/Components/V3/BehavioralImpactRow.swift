//
//  BehavioralImpactRow.swift
//  BetAutopsy
//
//  V3 behavioral impact row. Used in Chapter 3 (Discipline Audit) to
//  show pattern-correlated dollar impact with sample size.
//
//  NOT card-wrapped at component level. The CHAPTER VIEW wraps rows
//  in one container card with V3Divider between them and applies the
//  canonical V3 card style at the container level.
//

import SwiftUI

struct BehavioralImpactRow: View {
    struct Impact: Identifiable, Hashable {
        let id: UUID
        let iconSystemName: String   // SF Symbol
        let label: String            // caps display
        let dollarImpact: Int        // signed
        let sampleSize: Int

        init(iconSystemName: String, label: String, dollarImpact: Int, sampleSize: Int) {
            self.id = UUID()
            self.iconSystemName = iconSystemName
            self.label = label
            self.dollarImpact = dollarImpact
            self.sampleSize = sampleSize
        }
    }

    let impact: Impact

    private var dollarLabel: String {
        BAFormat.currency(impact.dollarImpact, signed: true)
    }

    private var dollarColor: Color {
        if impact.dollarImpact == 0 { return DS.Color.V3.textTertiary }
        return impact.dollarImpact < 0 ? DS.Color.V3.Severity.red : DS.Color.V3.textPrimary
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: impact.iconSystemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .frame(width: 16)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(impact.label)
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.1)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("OVER \(impact.sampleSize) INSTANCES")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }

            Spacer()

            Text(dollarLabel)
                .font(DS.Font.V3.rowValue)
                .monospacedDigit()
                .foregroundStyle(dollarColor)
        }
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(impact.label). \(dollarLabel) dollars over \(impact.sampleSize) instances."
        )
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 0) {
        BehavioralImpactRow(impact: BehavioralImpactRow.Impact(
            iconSystemName: "moon.fill",
            label: "LATE-NIGHT SESSIONS (POST-11PM)",
            dollarImpact: -1840,
            sampleSize: 12
        ))
        V3Divider()
        BehavioralImpactRow(impact: BehavioralImpactRow.Impact(
            iconSystemName: "flame.fill",
            label: "HEATED SESSIONS",
            dollarImpact: -2240,
            sampleSize: 12
        ))
    }
    .padding(.vertical, 14)
    .padding(.horizontal, 16)
    .background(DS.Color.V3.surfaceCard)
    .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
