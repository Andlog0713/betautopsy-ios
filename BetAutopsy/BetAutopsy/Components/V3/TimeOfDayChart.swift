//
//  TimeOfDayChart.swift
//  BetAutopsy
//
//  3B-2: the BY HOUR chart on the typed wire arrays. Prefers
//  charts.timeOfDayPnl (web PR #74; y = net DOLLARS) and falls back to
//  the legacy timing_analysis byHour buckets (y = ROI percent, label
//  parsing) so pre-#74 reports and snapshots keep their chart. The
//  fallback absorbs the PR #36 interim implementation verbatim: hour
//  label parsing, 0-23 numeric axis, 3-bet BEST/WORST sample floor.
//
//  KNOWN CAVEAT (do not fix here): hours inherit the engine's UTC
//  bucketing exactly as before. Local-time bucketing is WS-TEMPORAL.
//
//  Construction matches SessionTimelineChart: Swift Charts, token
//  colors (sign-keyed severity green/red), BAFormat on every axis and
//  callout, hides entirely below the sample floor (>= 2 hours with
//  bets), never an empty frame.
//

import SwiftUI
import Charts

struct TimeOfDayChart: View {
    private struct HourPoint: Identifiable {
        let hour: Int
        let value: Double
        let bets: Int
        var id: Int { hour }
    }

    private enum ValueKind {
        case dollars     // typed charts.timeOfDayPnl
        case roiPercent  // legacy timing_analysis fallback
    }

    private let points: [HourPoint]
    private let kind: ValueKind

    /// `typed` wins whenever it carries any bets (full v3 reports);
    /// otherwise the legacy buckets render (pre-#74 reports, snapshots -
    /// charts is absent there, so this is also the snapshot path and
    /// keeps the D6 "bar shape stays visible in every mode" behavior).
    init(typed: [HourPnlPoint], legacy: [TimingBucket]) {
        let typedPoints = typed
            .filter { (0...23).contains($0.hour) }
            .map { HourPoint(hour: $0.hour, value: $0.netUSD, bets: $0.bets) }
            .sorted { $0.hour < $1.hour }

        if typedPoints.contains(where: { $0.bets > 0 }) {
            self.points = typedPoints
            self.kind = .dollars
        } else {
            self.points = legacy
                .compactMap { bucket -> HourPoint? in
                    guard let hour = Self.parseHour(bucket.label) else { return nil }
                    return HourPoint(hour: hour, value: bucket.roi, bets: bucket.bets)
                }
                .sorted { $0.hour < $1.hour }
            self.kind = .roiPercent
        }
    }

    private var activePoints: [HourPoint] { points.filter { $0.bets > 0 } }

    /// Best/worst hours from the underlying data, never engine label
    /// strings. 3-bet floor so a 1-bet fluke can't own the callout; the
    /// floor relaxes when nothing qualifies.
    private var calloutPool: [HourPoint] {
        let qualified = activePoints.filter { $0.bets >= 3 }
        return qualified.isEmpty ? activePoints : qualified
    }

    private var bestPoint: HourPoint? { calloutPool.max { $0.value < $1.value } }
    private var worstPoint: HourPoint? { calloutPool.min { $0.value < $1.value } }

    var body: some View {
        // Sample floor: a chart needs at least two hours with bets.
        if activePoints.count >= 2 {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY HOUR")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                chart
                    .padding(.top, 8)

                if let best = bestPoint, let worst = worstPoint, best.hour != worst.hour {
                    HStack {
                        Text("BEST: \(BAFormat.hourLabel(best.hour))")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.V3.Severity.green)
                        Spacer()
                        Text("WORST: \(BAFormat.hourLabel(worst.hour))")
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
        Chart(points) { point in
            BarMark(
                x: .value("Hour", point.hour),
                y: .value(kind == .dollars ? "Net" : "ROI", point.value),
                width: .ratio(0.7)
            )
            .foregroundStyle(point.value >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red)
        }
        .chartXScale(domain: -0.5...23.5)
        .chartXAxis {
            AxisMarks(values: [0, 4, 8, 12, 16, 20]) { value in
                AxisValueLabel {
                    if let hour = value.as(Int.self) {
                        Text(BAFormat.hourLabel(hour))
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
                        Text(kind == .dollars
                             ? BAFormat.currency(raw, signed: true)
                             : BAFormat.percent(raw, signed: true, headline: true))
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
        var parts: [String] = ["Profit and loss by hour of day"]
        if let best = bestPoint {
            parts.append("Best hour \(BAFormat.hourLabel(best.hour))")
        }
        if let worst = worstPoint {
            parts.append("Worst hour \(BAFormat.hourLabel(worst.hour))")
        }
        return parts.joined(separator: ". ") + "."
    }

    /// Parses a legacy byHour label into an hour of day. Accepts "0"-"23"
    /// and "12am"/"9pm" shapes (case-insensitive, optional space). Moved
    /// from SectionPatternsTiming (PR #36) with the chart.
    static func parseHour(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let plain = Int(trimmed) {
            return (0...23).contains(plain) ? plain : nil
        }
        let isPM = trimmed.hasSuffix("pm")
        let isAM = trimmed.hasSuffix("am")
        guard isPM || isAM else { return nil }
        let digits = trimmed.dropLast(2).trimmingCharacters(in: .whitespaces)
        guard let hour12 = Int(digits), (1...12).contains(hour12) else { return nil }
        if isAM { return hour12 == 12 ? 0 : hour12 }
        return hour12 == 12 ? 12 : hour12 + 12
    }
}

#if DEBUG
#Preview("Typed dollars (v3)") {
    TimeOfDayChart(
        typed: (0..<24).map { hour in
            HourPnlPoint(hour: hour, netUSD: Double((hour - 14) * -90), bets: hour % 5 == 0 ? 2 : 12)
        },
        legacy: []
    )
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}

#Preview("Legacy ROI fallback (pre-#74 / snapshot)") {
    TimeOfDayChart(
        typed: [],
        legacy: [
            TimingBucket(label: "9am", bets: 7, wins: 4, losses: 3, staked: 700, profit: 80, roi: 11.4, winRate: 57),
            TimingBucket(label: "1pm", bets: 14, wins: 6, losses: 8, staked: 1400, profit: -120, roi: -8.6, winRate: 43),
            TimingBucket(label: "9pm", bets: 22, wins: 8, losses: 14, staked: 2300, profit: -510, roi: -22.2, winRate: 36),
            TimingBucket(label: "11pm", bets: 9, wins: 3, losses: 6, staked: 900, profit: -260, roi: -28.9, winRate: 33)
        ]
    )
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
