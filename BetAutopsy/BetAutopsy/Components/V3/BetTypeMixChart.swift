//
//  BetTypeMixChart.swift
//  BetAutopsy
//
//  3B-2: what you bet, from the typed charts.betTypeMix array
//  (web PR #74). Horizontal mix bars by pct with the count as the
//  sample annotation - no donut; share-of-volume comparisons read
//  better as aligned bars in this token system. Full v3 reports
//  only; the host renders nothing otherwise (this surface is new,
//  there is no legacy equivalent).
//
//  Mix is descriptive, not semantic: bars use neutral data ink, not
//  the severity scale (nothing here is good or bad by itself).
//

import SwiftUI
import Charts

struct BetTypeMixChart: View {
    let mix: [BetTypeMixEntry]

    /// Host-side floor: at least two classes with volume.
    static func qualifies(_ mix: [BetTypeMixEntry]) -> Bool {
        mix.filter { $0.count > 0 }.count >= 2
    }

    private var active: [BetTypeMixEntry] {
        mix.filter { $0.count > 0 }.sorted { $0.pct > $1.pct }
    }

    private static func displayClass(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var dominant: BetTypeMixEntry? { active.first }

    var body: some View {
        if Self.qualifies(mix) {
            VStack(alignment: .leading, spacing: 0) {
                Text("BET TYPE MIX")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                chart
                    .padding(.top, 4)

                if let dominant {
                    Text("\(Self.displayClass(dominant.betClass)) bets are \(BAFormat.percent(dominant.pct, headline: true)) of your volume.")
                        .font(.system(size: 12, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
        }
    }

    private var chart: some View {
        Chart(active) { entry in
            BarMark(
                x: .value("Share", entry.pct),
                y: .value("Type", Self.displayClass(entry.betClass))
            )
            .foregroundStyle(DS.Color.V3.textTertiary)
            .annotation(position: .trailing, spacing: 6) {
                Text(BAFormat.sampleSize(entry.count))
                    .font(.system(size: 9, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
        }
        .chartXScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisGridLine()
                    .foregroundStyle(DS.Color.V3.borderSubtle)
                AxisValueLabel {
                    if let raw = value.as(Double.self) {
                        Text(BAFormat.percent(raw, headline: true))
                            .font(.system(size: 9, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(DS.Color.V3.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }
        }
        .frame(height: CGFloat(active.count) * 34 + 24)
    }

    private var accessibilitySummary: String {
        let rows = active.map { entry in
            "\(Self.displayClass(entry.betClass)): \(BAFormat.percent(entry.pct, headline: true)) of volume, \(BAFormat.sampleSize(entry.count))"
        }
        return "Bet type mix. " + rows.joined(separator: ". ") + "."
    }
}

#if DEBUG
#Preview {
    BetTypeMixChart(mix: [
        BetTypeMixEntry(betClass: "other", count: 1576, pct: 77.6),
        BetTypeMixEntry(betClass: "parlay", count: 312, pct: 15.4),
        BetTypeMixEntry(betClass: "prop", count: 142, pct: 7.0)
    ])
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
