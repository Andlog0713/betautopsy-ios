//
//  ContradictionCard.swift
//  BetAutopsy
//
//  Renders one engine-shipped Contradiction at the top of Ch 5
//  (The Patterns). Title + insight prose + two-column volume / edge
//  data + optional annual-cost footer. Snapshot mode redacts the
//  annual-cost dollar with a LockedDollarBar.
//
//  Multi-contradiction rendering deferred to v1.1; engine sometimes
//  ships >1 but the chapter currently renders only the first.
//

import SwiftUI

struct ContradictionCard: View {
    let contradiction: Contradiction
    var isLockedCost: Bool = false
    var onLockedTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONTRADICTION")
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text(contradiction.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            Text(contradiction.insight)
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            V3Divider()
                .padding(.vertical, 4)

            // TODO(engine raw-values): volumeData / edgeData are engine
            // pre-formatted strings ("47 bets", "-28.0%") with no raw
            // numeric fields on the Contradiction wire model. When the
            // engine ships raw values, decode them and route through
            // BAFormat here instead of rendering the strings verbatim.
            HStack(alignment: .top, spacing: 16) {
                column(label: contradiction.volumeLabel, value: contradiction.volumeData)
                column(label: contradiction.edgeLabel,   value: contradiction.edgeData)
            }

            if let annualCost = contradiction.annualCost {
                V3Divider()
                    .padding(.top, 4)
                annualCostRow(annualCost: annualCost)
                    .padding(.top, 4)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    @ViewBuilder
    private func column(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(DS.Color.V3.textTertiary)
            Text(value)
                .font(DS.Font.V3.rowValue)
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func annualCostRow(annualCost: Double) -> some View {
        HStack(spacing: 8) {
            Text("ANNUAL COST")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.Severity.red)

            if isLockedCost {
                LockedDollarBar(width: 110, onTap: { onLockedTap?() })
            } else {
                Text("\(BAFormat.currency(-abs(annualCost)))/yr")
                    .font(DS.Font.V3.rowValue)
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.Severity.red)
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        ContradictionCard(contradiction: Contradiction(
            title: "You are sharp until you are not",
            insight: "Your daytime NBA prop ROI is +4%. Your late-night NBA prop ROI is -28%. Same sport, same bet type, same bettor. The window is the only variable.",
            volumeLabel: "Late-night NBA props",
            volumeData: "47 bets",
            edgeLabel: "Late-night ROI",
            edgeData: "-28.0%",
            annualCost: 720
        ))
        ContradictionCard(
            contradiction: Contradiction(
                title: "You are sharp until you are not",
                insight: "Your daytime NBA prop ROI is +4%. Your late-night NBA prop ROI is -28%.",
                volumeLabel: "Late-night NBA props",
                volumeData: "47 bets",
                edgeLabel: "Late-night ROI",
                edgeData: "-28.0%",
                annualCost: 720
            ),
            isLockedCost: true
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
