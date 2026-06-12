//
//  StakeByStreakChart.swift
//  BetAutopsy
//
//  3B-2: average stake by streak context from the typed
//  charts.stakeByStreak object (web PR #74). Three bars: neutral /
//  after 3 wins / after 3 losses. Full v3 reports only - the host
//  keeps the legacy StreakInfluenceCard (which has the snapshot
//  locked variant) when charts is absent or this object is null.
//
//  Tint semantics mirror StreakInfluenceCard: a streak bar goes
//  green (wins) / red (losses) when its average diverges >= 10%
//  above neutral; otherwise neutral gray. Caption is data-driven
//  dollars, BAFormat throughout.
//

import SwiftUI
import Charts

struct StakeByStreakChart: View {
    let streak: StakeByStreak?

    private struct Bar: Identifiable {
        let label: String
        let value: Double
        let tint: Color
        var id: String { label }
    }

    /// Host-side check so the section can keep the legacy card when the
    /// typed object is null or degenerate.
    static func qualifies(_ streak: StakeByStreak?) -> Bool {
        guard let streak else { return false }
        return streak.neutralUSD > 0
            && (streak.after3WinsUSD > 0 || streak.after3LossesUSD > 0)
    }

    private var bars: [Bar]? {
        guard let streak, Self.qualifies(streak) else { return nil }
        let winsEscalated = streak.after3WinsUSD / streak.neutralUSD >= 1.1
        let lossesEscalated = streak.after3LossesUSD / streak.neutralUSD >= 1.1
        return [
            Bar(label: "NEUTRAL",
                value: streak.neutralUSD,
                tint: DS.Color.V3.Severity.gray),
            Bar(label: "AFTER 3 WINS",
                value: streak.after3WinsUSD,
                tint: winsEscalated ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.gray),
            Bar(label: "AFTER 3 LOSSES",
                value: streak.after3LossesUSD,
                tint: lossesEscalated ? DS.Color.V3.Severity.red : DS.Color.V3.Severity.gray)
        ]
    }

    private var caption: String? {
        guard let streak, Self.qualifies(streak) else { return nil }
        if streak.after3LossesUSD / streak.neutralUSD >= 1.1 {
            return "After three losses your average stake jumps from \(BAFormat.currency(streak.neutralUSD)) to \(BAFormat.currency(streak.after3LossesUSD))."
        }
        if streak.after3WinsUSD / streak.neutralUSD >= 1.1 {
            return "After three wins your average stake rises from \(BAFormat.currency(streak.neutralUSD)) to \(BAFormat.currency(streak.after3WinsUSD))."
        }
        return "Your stake sizing holds steady across streaks."
    }

    var body: some View {
        if let bars {
            VStack(alignment: .leading, spacing: 0) {
                Text("STAKE BY STREAK CONTEXT")
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Chart(bars) { bar in
                    BarMark(
                        x: .value("Context", bar.label),
                        y: .value("Stake", bar.value),
                        width: .ratio(0.55)
                    )
                    .foregroundStyle(bar.tint)
                    .annotation(position: .top, spacing: 4) {
                        Text(BAFormat.currency(bar.value))
                            .font(.system(size: 10, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(DS.Color.V3.textPrimary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(DS.Color.V3.textTertiary)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 120)
                .padding(.top, 12)

                if let caption {
                    Text(caption)
                        .font(.system(size: 12, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
        }
    }

    private var accessibilitySummary: String {
        guard let streak else { return "" }
        var parts = [
            "Average stake by streak context",
            "Neutral \(BAFormat.currency(streak.neutralUSD))",
            "After three wins \(BAFormat.currency(streak.after3WinsUSD))",
            "After three losses \(BAFormat.currency(streak.after3LossesUSD))"
        ]
        if let caption { parts.append(caption) }
        return parts.joined(separator: ". ") + "."
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        StakeByStreakChart(streak: StakeByStreak(
            after3WinsUSD: 27.05, neutralUSD: 40.69, after3LossesUSD: 90.74
        ))
        StakeByStreakChart(streak: nil) // renders nothing
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
