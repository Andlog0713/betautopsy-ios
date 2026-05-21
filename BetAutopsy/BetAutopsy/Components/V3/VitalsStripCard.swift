//
//  VitalsStripCard.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2.5 surface #1: top-of-section density anchor for
//  SectionVerdict. Ports web's vitals strip (AutopsyReport.tsx 905-927):
//  RECORD / NET P&L / ROI / AVG STAKE.
//
//  Web lays these out as a 4-col row that does not fit iPhone width
//  (393pt), so iOS uses a 2x2 grid inside one surfaceCard with hairline
//  dividers. The two dollar cells (NET P&L, AVG STAKE) are redacted in
//  snapshot mode (engine zeroes total_profit + avg_stake and tags them
//  "redacted_dollar"); they render a LockedDollarBar. RECORD and ROI stay
//  visible in both modes (counts + ratio, not raw dollars).
//

import SwiftUI

struct VitalsStripCard: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var summary: AutopsySummary { report.analysis.summary }

    private var netPnLLocked: Bool {
        isSnapshot || summary.totalProfitVisibility == "redacted_dollar"
    }

    private var avgStakeLocked: Bool {
        isSnapshot || summary.avgStakeVisibility == "redacted_dollar"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                recordCell
                cellDivider
                netPnLCell
            }
            rowDivider
            HStack(spacing: 0) {
                roiCell
                cellDivider
                avgStakeCell
            }
        }
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Cells

    private var recordCell: some View {
        cell(label: "RECORD") {
            Text(summary.record)
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var netPnLCell: some View {
        cell(label: "NET P&L") {
            if netPnLLocked {
                LockedDollarBar(width: 96, onTap: { onPaywallTap("section_verdict_vitals_dollar_locked") })
            } else {
                Text(signedDollars(summary.totalProfit))
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(summary.totalProfit >= 0
                        ? DS.Color.V3.Severity.green
                        : DS.Color.V3.Severity.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    private var roiCell: some View {
        cell(label: "ROI") {
            Text(signedPercent(summary.roiPercent))
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(summary.roiPercent >= 0
                    ? DS.Color.V3.Severity.green
                    : DS.Color.V3.Severity.red)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var avgStakeCell: some View {
        cell(label: "AVG STAKE") {
            if avgStakeLocked {
                LockedDollarBar(width: 96, onTap: { onPaywallTap("section_verdict_vitals_dollar_locked") })
            } else {
                Text("$\(Int(summary.avgStake.rounded()))")
                    .font(.system(size: 18, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
    }

    @ViewBuilder
    private func cell<Content: View>(
        label: String,
        @ViewBuilder value: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)
            value()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var cellDivider: some View {
        Rectangle()
            .fill(DS.Color.V3.borderSubtle)
            .frame(width: 0.5)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(DS.Color.V3.borderSubtle)
            .frame(height: 0.5)
    }

    // MARK: - Formatting

    private func signedDollars(_ value: Double) -> String {
        let magnitude = Int(abs(value).rounded())
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: magnitude)) ?? "\(magnitude)"
        let sign = value < 0 ? "\u{2212}" : "+"
        return "\(sign)$\(formatted)"
    }

    private func signedPercent(_ value: Double) -> String {
        let sign = value < 0 ? "\u{2212}" : "+"
        return "\(sign)\(String(format: "%.1f", abs(value)))%"
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            VitalsStripCard(report: MockReport.heatedBettor, onPaywallTap: { _ in })
        }
        .padding(16)
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
