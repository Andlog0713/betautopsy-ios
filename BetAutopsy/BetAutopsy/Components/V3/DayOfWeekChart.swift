//
//  DayOfWeekChart.swift
//  BetAutopsy
//
//  3B-2: BY DAY net P&L from the typed charts.dayOfWeekPnl array
//  (web PR #74; day 0 = Sunday). Full v3 reports only - the host
//  falls back to the legacy day tiles (with their snapshot locks)
//  when charts is absent or the sample floor fails.
//
//  Construction matches SessionTimelineChart: sign-keyed severity
//  colors, BAFormat axes, data-driven BEST/WORST callouts with a
//  3-bet floor, hides entirely below the sample floor.
//

import SwiftUI
import Charts

struct DayOfWeekChart: View {
    let points: [DayPnlPoint]

    private static let dayLabels = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    /// Host-side floor check so the section can fall back to the legacy
    /// tiles instead of rendering nothing.
    static func qualifies(_ points: [DayPnlPoint]) -> Bool {
        points.filter { $0.bets > 0 && (0...6).contains($0.day) }.count >= 2
    }

    private var validPoints: [DayPnlPoint] {
        points.filter { (0...6).contains($0.day) }.sorted { $0.day < $1.day }
    }

    private var activePoints: [DayPnlPoint] { validPoints.filter { $0.bets > 0 } }

    private var calloutPool: [DayPnlPoint] {
        let qualified = activePoints.filter { $0.bets >= 3 }
        return qualified.isEmpty ? activePoints : qualified
    }

    private var bestPoint: DayPnlPoint? { calloutPool.max { $0.netUSD < $1.netUSD } }
    private var worstPoint: DayPnlPoint? { calloutPool.min { $0.netUSD < $1.netUSD } }

    private static func label(_ day: Int) -> String {
        (0...6).contains(day) ? dayLabels[day] : "\(day)"
    }

    var body: some View {
        if Self.qualifies(points) {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY DAY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                chart
                    .padding(.top, 8)

                if let best = bestPoint, let worst = worstPoint, best.day != worst.day {
                    HStack {
                        Text("BEST: \(Self.label(best.day))")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.V3.Severity.green)
                        Spacer()
                        Text("WORST: \(Self.label(worst.day))")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.V3.Severity.red)
                    }
                    .padding(.top, 4)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
        }
    }

    private var chart: some View {
        Chart(validPoints) { point in
            BarMark(
                x: .value("Day", point.day),
                y: .value("Net", point.netUSD),
                width: .ratio(0.6)
            )
            .foregroundStyle(point.netUSD >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red)
        }
        .chartXScale(domain: -0.5...6.5)
        .chartXAxis {
            AxisMarks(values: Array(0...6)) { value in
                AxisValueLabel {
                    if let day = value.as(Int.self) {
                        Text(Self.label(day))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(DS.Color.V3.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                    .foregroundStyle(DS.Color.V3.borderSubtle)
                AxisValueLabel {
                    if let raw = value.as(Double.self) {
                        Text(BAFormat.currency(raw, signed: true))
                            .font(.system(size: 9, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(DS.Color.V3.textTertiary)
                    }
                }
            }
        }
        .frame(height: 100)
    }

    private var accessibilitySummary: String {
        var parts: [String] = ["Net profit and loss by day of week"]
        if let best = bestPoint {
            parts.append("Best day \(Self.label(best.day)), \(BAFormat.currency(best.netUSD, signed: true))")
        }
        if let worst = worstPoint {
            parts.append("Worst day \(Self.label(worst.day)), \(BAFormat.currency(worst.netUSD, signed: true))")
        }
        return parts.joined(separator: ". ") + "."
    }
}

#if DEBUG
#Preview {
    DayOfWeekChart(points: [
        DayPnlPoint(day: 0, netUSD: -1244.4, bets: 392),
        DayPnlPoint(day: 1, netUSD: 512.5, bets: 235),
        DayPnlPoint(day: 2, netUSD: -310, bets: 188),
        DayPnlPoint(day: 3, netUSD: 122, bets: 154),
        DayPnlPoint(day: 4, netUSD: -88, bets: 201),
        DayPnlPoint(day: 5, netUSD: -640, bets: 266),
        DayPnlPoint(day: 6, netUSD: 940, bets: 410)
    ])
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
