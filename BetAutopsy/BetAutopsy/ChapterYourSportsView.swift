//
//  ChapterYourSportsView.swift
//  BetAutopsy
//
//  Chapter 6: when and what you bet. Swift Charts hour bar chart, 7-day
//  tile grid tinted by ROI sign, odds bucket cards with edge per bucket,
//  and sport-specific findings.
//

import SwiftUI
import Charts

struct ChapterYourSportsView: View {
    let report: AutopsyReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ChapterHeader(
                    chipText: "YOUR SPORTS",
                    alertChip: (text: "TIMING IS THE LEAK", color: DS.Color.Semantic.blood),
                    title: "When you bet matters more than what you bet.",
                    pullQuote: nil
                )
                .padding(.top, DS.Spacing.md)

                hourChartSection.padding(.top, DS.Spacing.xl)
                dayTilesSection.padding(.top, DS.Spacing.xl)
                oddsSection.padding(.top, DS.Spacing.xl)
                sportFindingsSection.padding(.top, DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Hour chart

    @ViewBuilder
    private var hourChartSection: some View {
        if let timing = report.analysis.timingAnalysis, !timing.byHour.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY HOUR")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)

                Chart(timing.byHour) { bucket in
                    BarMark(
                        x: .value("Hour", bucket.label),
                        y: .value("ROI", bucket.roi)
                    )
                    .foregroundStyle(bucket.roi >= 0 ? DS.Color.Semantic.win : DS.Color.Semantic.blood)
                }
                .chartXAxis {
                    AxisMarks(values: ["0", "4", "8", "12", "16", "20"]) { _ in
                        AxisValueLabel()
                            .font(.custom("JetBrainsMono-Regular", size: 8))
                            .foregroundStyle(DS.Color.Text.tertiary)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 100)
                .padding(.top, DS.Spacing.sm)

                HStack {
                    if let best = timing.bestWindow {
                        Text("BEST: \(best.label.uppercased())")
                            .font(.custom("JetBrainsMono-Regular", size: 10))
                            .tracking(10 * 0.15)
                            .foregroundStyle(DS.Color.Semantic.win)
                    }
                    Spacer()
                    if let worst = timing.worstWindow {
                        Text("WORST: \(worst.label.uppercased())")
                            .font(.custom("JetBrainsMono-Regular", size: 10))
                            .tracking(10 * 0.15)
                            .foregroundStyle(DS.Color.Semantic.blood)
                    }
                }
                .padding(.top, DS.Spacing.xs)
            }
        }
    }

    // MARK: - Day tiles

    @ViewBuilder
    private var dayTilesSection: some View {
        if let timing = report.analysis.timingAnalysis, !timing.byDay.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY DAY")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)

                HStack(spacing: 6) {
                    ForEach(timing.byDay) { day in
                        dayTile(day)
                    }
                }
                .padding(.top, DS.Spacing.md)

                if let lateNight = timing.lateNightStats {
                    Text("\(lateNight.count) bets after 10pm. ROI: \(Int(lateNight.roi.rounded()))%. Cut these and recover most of the bleed.")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.Text.secondary)
                        .lineSpacing(3)
                        .padding(.top, 12)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func dayTile(_ day: TimingBucket) -> some View {
        let tint: Color = day.roi >= 0 ? DS.Color.Semantic.win : DS.Color.Semantic.blood
        let tintOpacity = min(0.25, abs(day.roi) / 100)

        return ZStack {
            RoundedRectangle(cornerRadius: DS.Radius.tile)
                .fill(DS.Color.Surface.card)
            RoundedRectangle(cornerRadius: DS.Radius.tile)
                .fill(tint.opacity(tintOpacity))

            VStack(spacing: 4) {
                Text(day.label)
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.primary)
                Text(formatCurrency(day.profit, signed: true))
                    .font(.custom("JetBrainsMono-Regular", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Text.primary)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
    }

    // MARK: - Odds buckets

    @ViewBuilder
    private var oddsSection: some View {
        if let odds = report.analysis.oddsAnalysis {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY ODDS")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)

                Text("Where you find value, and where you don't.")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.Text.secondary)
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    ForEach(odds.buckets) { bucket in
                        oddsBucketCard(bucket)
                    }
                }
                .padding(.top, DS.Spacing.md)

                Text("Luck rating: \(odds.luckLabel)")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .padding(.top, DS.Spacing.md)

                Text("\(odds.actualWins) wins vs \(Int(odds.expectedWins.rounded())) expected")
                    .font(.custom("JetBrainsMono-Regular", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Text.primary)
                    .padding(.top, 4)
            }
        }
    }

    private func oddsBucketCard(_ b: OddsBucket) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(b.label.uppercased())
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.15)
                    .foregroundStyle(DS.Color.Text.primary)
                Spacer()
                Text("ROI \(formatPct(b.roi, signed: false))")
                    .font(.custom("JetBrainsMono-Regular", size: 12))
                    .monospacedDigit()
                    .foregroundStyle(b.roi >= 0 ? DS.Color.Semantic.win : DS.Color.Semantic.blood)
            }

            Text(b.range)
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .monospacedDigit()
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, 4)

            HStack {
                Text("\(b.bets) BETS")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .monospacedDigit()
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                Spacer()
                Text("\(Int((b.actualWinRate * 100).rounded()))% WIN")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .monospacedDigit()
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                Spacer()
                Text("EDGE \(b.edge >= 0 ? "+" : "")\(Int((b.edge * 100).rounded()))pp")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .monospacedDigit()
                    .tracking(10 * 0.15)
                    .foregroundStyle(b.edge >= 0 ? DS.Color.Semantic.win : DS.Color.Semantic.blood)
            }
            .padding(.top, 8)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Sport-specific findings

    @ViewBuilder
    private var sportFindingsSection: some View {
        if let findings = report.analysis.sportSpecificFindings, !findings.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("SPORT-SPECIFIC LEAKS")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .padding(.bottom, 4)

                ForEach(findings) { finding in
                    sportFindingCard(finding)
                }
            }

            if report.analysis.dfsMode {
                // DFS metrics block intentionally left for a future PR;
                // mock data has dfsMode == false so nothing renders today.
                EmptyView()
            }
        }
    }

    private func sportFindingCard(_ f: SportSpecificFinding) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(f.sport.uppercased())
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Semantic.blood)
                Spacer()
                SeverityChip(severity: f.severity)
            }

            Text(f.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .padding(.top, 8)

            Text(f.description)
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(DS.Color.Border.subtle)
                .frame(height: DS.Stroke.hairline)
                .padding(.top, 12)

            Text("EVIDENCE")
                .font(.custom("JetBrainsMono-Regular", size: 9))
                .tracking(9 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, 12)

            Text(f.evidence)
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            Text(f.recommendation)
                .font(.custom("Georgia-Italic", size: 14))
                .foregroundStyle(DS.Color.Text.primary)
                .lineSpacing(3)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)

            if let cost = f.estimatedCost {
                Text("ESTIMATED COST \(formatCurrency(cost))")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .monospacedDigit()
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Semantic.blood)
                    .padding(.top, 8)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

#Preview {
    ChapterYourSportsView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
