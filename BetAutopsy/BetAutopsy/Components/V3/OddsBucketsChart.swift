//
//  OddsBucketsChart.swift
//  BetAutopsy
//
//  3B-2: ROI by odds band from the typed charts.oddsBuckets array
//  (web PR #74). Horizontal bars by roiPct with the bet count as the
//  per-bar sample annotation (a rate never renders without its
//  sample). Full v3 reports only - the host falls back to the legacy
//  bespoke bucket cards (with their snapshot LOCKED badges) when
//  charts is absent or the floor fails.
//
//  winPct and edgePP feed the accessibility labels and the data-driven
//  caption (strongest edge band) rather than crowding the bars.
//

import SwiftUI
import Charts

struct OddsBucketsChart: View {
    let buckets: [ChartOddsBucket]

    /// Host-side floor check (>= 2 bands with bets) so the section can
    /// fall back to the legacy cards instead of rendering nothing.
    static func qualifies(_ buckets: [ChartOddsBucket]) -> Bool {
        buckets.filter { $0.bets > 0 }.count >= 2
    }

    private var active: [ChartOddsBucket] { buckets.filter { $0.bets > 0 } }

    /// Strongest edge band for the caption, 3-bet floor (relaxed when
    /// nothing qualifies).
    private var bestEdge: ChartOddsBucket? {
        let qualified = active.filter { $0.bets >= 3 }
        return (qualified.isEmpty ? active : qualified).max { $0.edgePP < $1.edgePP }
    }

    /// "+23.8pp" - percentage points. The number shape routes through
    /// BAFormat.percent; only the unit suffix differs.
    private static func edgeLabel(_ value: Double) -> String {
        BAFormat.percent(value, signed: true).replacingOccurrences(of: "%", with: "pp")
    }

    var body: some View {
        if Self.qualifies(buckets) {
            VStack(alignment: .leading, spacing: 0) {
                chart
                    .padding(.top, 4)

                if let best = bestEdge, best.edgePP > 0 {
                    Text("Strongest edge: \(best.bucket), \(Self.edgeLabel(best.edgePP)) over implied odds \u{00B7} \(BAFormat.sampleSize(best.bets)).")
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
        Chart(active) { bucket in
            BarMark(
                x: .value("ROI", bucket.roiPct),
                y: .value("Band", bucket.bucket)
            )
            .foregroundStyle(bucket.roiPct >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red)
            .annotation(position: .trailing, spacing: 6) {
                Text(BAFormat.sampleSize(bucket.bets))
                    .font(.system(size: 9, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                    .foregroundStyle(DS.Color.V3.borderSubtle)
                AxisValueLabel {
                    if let raw = value.as(Double.self) {
                        Text(BAFormat.percent(raw, signed: true, headline: true))
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
        .frame(height: CGFloat(active.count) * 36 + 24)
    }

    private var accessibilitySummary: String {
        let bands = active.map { bucket in
            "\(bucket.bucket): ROI \(BAFormat.percent(bucket.roiPct, signed: true)), \(BAFormat.sampleSize(bucket.bets)), win rate \(BAFormat.percent(bucket.winPct, headline: true)), edge \(Self.edgeLabel(bucket.edgePP))"
        }
        return "Return by odds band. " + bands.joined(separator: ". ") + "."
    }
}

#if DEBUG
#Preview {
    OddsBucketsChart(buckets: [
        ChartOddsBucket(bucket: "Heavy Chalk", roiPct: 31.25, bets: 10, winPct: 100, edgePP: 23.81),
        ChartOddsBucket(bucket: "Chalk", roiPct: -4.2, bets: 184, winPct: 58.2, edgePP: -1.4),
        ChartOddsBucket(bucket: "Near Even", roiPct: -12.8, bets: 412, winPct: 46.1, edgePP: -5.6),
        ChartOddsBucket(bucket: "Underdog", roiPct: 6.3, bets: 88, winPct: 38.6, edgePP: 4.0),
        ChartOddsBucket(bucket: "Longshot", roiPct: -41.0, bets: 36, winPct: 8.3, edgePP: -9.9)
    ])
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
