//
//  ChapterYourSportsView.swift
//  BetAutopsy
//
//  Chapter 6: when and what you bet. Swift Charts hour bar chart, 7-day
//  tile grid tinted by ROI sign, odds bucket cards with edge per bucket,
//  and sport-specific findings.
//
//  PR-V10 Phase 1: token migration only. Visual structure preserved.
//  ChapterHeader (V2) → ChapterNavigator (V3). Custom JetBrainsMono
//  fonts → system fonts. Closing InsightCallout added in full mode.
//

import SwiftUI
import Charts

struct ChapterYourSportsView: View {
    let report: AutopsyReport

    @State private var showingPaywall: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ChapterNavigator(chapterNumber: 6, subtitle: "WHEN AND WHAT")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                hourChartSection.padding(.top, 32)
                dayTilesSection.padding(.top, 32)
                oddsSection.padding(.top, 32)
                sportFindingsSection.padding(.top, 32)

                // Snapshot mode: closing volume-anchor module at end of
                // Chapter 6, placed AFTER the existing sport findings.
                // Decision (a) per spec: Chapter 7 has substantial own
                // content (header + recommendations + finalCard), so the
                // counts module wraps up Sports and the user swipes to
                // Chapter 7 for the dedicated CTA if not converted here.
                if report.reportType == "snapshot",
                   let counts = report.analysis.snapshotCounts {
                    SnapshotCountsModule(counts: counts) {
                        Analytics.signal(
                            "paywall.triggered",
                            parameters: ["source": "counts_module_cta"]
                        )
                        showingPaywall = true
                    }
                    .padding(.top, 32)
                } else if !insightBody.isEmpty {
                    // Full mode: closing CTA into Chapter 7.
                    InsightCallout(
                        text: insightBody,
                        ctaLabel: "SEE THE ACTION PLAN",
                        onTap: handleInsightTap
                    )
                    .padding(.top, 32)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 60)
        }
        .background(canvasGradient.ignoresSafeArea())
        .sheet(isPresented: $showingPaywall) {
            PaywallView(snapshotReportId: report.id)
        }
    }

    private var insightBody: String {
        (report.analysis.executiveDiagnosis ?? "").firstSentences(2)
    }

    private var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                DS.Color.V3.canvasGradientStart,
                DS.Color.V3.canvasGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func handleInsightTap() {
        #if DEBUG
        print("InsightCallout tapped on Chapter 6 (V1 stub).")
        #endif
    }

    // MARK: - Hour chart

    @ViewBuilder
    private var hourChartSection: some View {
        // D6 (REBUILD-PHASE-1): the BY HOUR bar shape is the moat and stays
        // visible in every mode. The bars encode ROI percent (non-redacted)
        // with hour labels; there is no per-bar tap interaction and no
        // dollar/bet-count tooltip surface to gate, so no dollar value leaks
        // in snapshot. The BEST/WORST captions are window labels only.
        if let timing = report.analysis.timingAnalysis, !timing.byHour.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY HOUR")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Chart(timing.byHour) { bucket in
                    BarMark(
                        x: .value("Hour", bucket.label),
                        y: .value("ROI", bucket.roi)
                    )
                    .foregroundStyle(bucket.roi >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red)
                }
                .chartXAxis {
                    AxisMarks(values: ["0", "4", "8", "12", "16", "20"]) { _ in
                        AxisValueLabel()
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(DS.Color.V3.textTertiary)
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 100)
                .padding(.top, 8)

                HStack {
                    if let best = timing.bestWindow {
                        Text("BEST: \(best.label.uppercased())")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.V3.Severity.green)
                    }
                    Spacer()
                    if let worst = timing.worstWindow {
                        Text("WORST: \(worst.label.uppercased())")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.V3.Severity.red)
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Day tiles

    @ViewBuilder
    private var dayTilesSection: some View {
        if let timing = report.analysis.timingAnalysis, !timing.byDay.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY DAY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                HStack(spacing: 6) {
                    ForEach(timing.byDay) { day in
                        dayTile(day)
                    }
                }
                .padding(.top, 16)

                if let lateNight = timing.lateNightStats {
                    Text("\(lateNight.count.pluralized("bet", "bets")) after 10pm. ROI: \(Int(lateNight.roi.rounded()))%. Cut these and recover most of the bleed.")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineSpacing(3)
                        .padding(.top, 12)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private func dayTile(_ day: TimingBucket) -> some View {
        let tint: Color = day.roi >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red
        let tintOpacity = min(0.25, abs(day.roi) / 100)

        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(DS.Color.V3.surfaceCard)
            RoundedRectangle(cornerRadius: 8)
                .fill(tint.opacity(tintOpacity))

            VStack(spacing: 4) {
                Text(day.label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                if isSnapshot {
                    LockedDollarBar(width: 56, onTap: handleDollarTap)
                } else {
                    Text(formatCurrency(day.profit, signed: true))
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
    }

    private func handleDollarTap() {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": "ch6_locked_dollar"]
        )
        showingPaywall = true
    }

    // MARK: - Odds buckets

    @ViewBuilder
    private var oddsSection: some View {
        if let odds = report.analysis.oddsAnalysis {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY ODDS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Text("Where you find value, and where you don't.")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    ForEach(odds.buckets) { bucket in
                        oddsBucketCard(bucket)
                    }
                }
                .padding(.top, 16)

                // D8 (REBUILD-PHASE-1): the luck rating label stays visible
                // in every mode (it carries the "running hot/cold" direction).
                // The precise wins-vs-expected counts are locked in snapshot
                // behind the standard redaction capsule.
                Text("Luck rating: \(odds.luckLabel)")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .padding(.top, 16)

                if isSnapshot {
                    LockedDollarBar(width: 140, onTap: handleDollarTap)
                        .padding(.top, 4)
                } else {
                    Text("\(odds.actualWins) wins vs \(Int(odds.expectedWins.rounded())) expected")
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .padding(.top, 4)
                }
            }
        }
    }

    private func oddsBucketCard(_ b: OddsBucket) -> some View {
        // Blocker #11: the engine zeroes roi/win_rate/edge in snapshot mode
        // (b775e8e redactOddsForSnapshot) and tags them redacted_percent.
        // Rendering those literally produces a self-contradictory
        // "ROI 0% / 0% WIN / EDGE +0pp" row. In snapshot that is paywall
        // redaction (not sparsity), so we show a locked badge; a genuinely
        // sparse bucket in full mode lands at the same literal zero and
        // reads as "DATA SPARSE". Sample size (bets) stays visible (D12).
        let redactedPercents = isSnapshot
            || (b.bets > 0 && b.actualWinRate == 0 && b.edge == 0)
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(b.label.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.65)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                Spacer()
                if redactedPercents {
                    oddsMetricBadge(locked: isSnapshot)
                } else {
                    Text("ROI \(formatPct(b.roi, signed: false))")
                        .font(.system(size: 12, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(b.roi >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red)
                }
            }

            Text(b.range)
                .font(.system(size: 11, weight: .regular))
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textTertiary)
                .padding(.top, 4)

            if redactedPercents {
                Text(b.bets.pluralizedCaps("BET", "BETS"))
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .padding(.top, 8)
            } else {
                HStack {
                    Text(b.bets.pluralizedCaps("BET", "BETS"))
                        .font(.system(size: 10, weight: .semibold))
                        .monospacedDigit()
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                    Spacer()
                    Text("\(Int(b.actualWinRate.rounded()))% WIN")
                        .font(.system(size: 10, weight: .semibold))
                        .monospacedDigit()
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                    Spacer()
                    Text("EDGE \(b.edge >= 0 ? "+" : "")\(Int(b.edge.rounded()))pp")
                        .font(.system(size: 10, weight: .semibold))
                        .monospacedDigit()
                        .tracking(1.5)
                        .foregroundStyle(b.edge >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red)
                }
                .padding(.top, 8)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Stand-in for the redacted ROI/WIN/EDGE metrics on an odds bucket.
    /// Snapshot: tappable "LOCKED" (paywall redaction). Full-mode sparse:
    /// plain "DATA SPARSE" caps label, no background, no border.
    @ViewBuilder
    private func oddsMetricBadge(locked: Bool) -> some View {
        if locked {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9, weight: .semibold))
                Text("LOCKED")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
            }
            .foregroundStyle(DS.Color.V3.textTertiary)
            .contentShape(Rectangle())
            .onTapGesture { handleDollarTap() }
        } else {
            Text("DATA SPARSE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .lineLimit(1)
        }
    }

    // MARK: - Sport-specific findings

    @ViewBuilder
    private var sportFindingsSection: some View {
        if let findings = report.analysis.sportSpecificFindings, !findings.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("SPORT-SPECIFIC LEAKS")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.65)
                    .foregroundStyle(DS.Color.V3.textTertiary)
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
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.Severity.red)
                Spacer()
                SeverityChip(severity: f.severity)
            }

            Text(f.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .padding(.top, 8)

            // Snapshot ships a first-sentence teaser (b775e8e); full mode
            // ships full prose. Gate display on description_visibility.
            if f.descriptionVisibility != "hidden",
               !f.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(isSnapshot ? f.description.firstSentences(1) : f.description)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .lineSpacing(3)
                    .padding(.top, 4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Rectangle()
                .fill(DS.Color.V3.borderSubtle)
                .frame(height: 0.5)
                .padding(.top, 12)

            Text("EVIDENCE")
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.35)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .padding(.top, 12)

            Text(f.evidence)
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .lineSpacing(3)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            // Recommendation suppressed entirely when hidden or empty
            // (snapshot ships recommendation_visibility="hidden").
            if f.recommendationVisibility != "hidden",
               !f.recommendation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(f.recommendation)
                    .font(.custom("Georgia-Italic", size: 14))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .lineSpacing(3)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Engine V2 ships estimatedCost = 0 + visibility "redacted_dollar"
            // in snapshot mode. Render the locked bar in that case (or
            // when the wire still ships nil); otherwise format the real
            // dollar amount.
            let lockedCost = isSnapshot
                || f.estimatedCostVisibility == "redacted_dollar"
                || f.estimatedCost == nil
                || (f.estimatedCost ?? 0) == 0
            if lockedCost {
                HStack(spacing: 8) {
                    Text("ESTIMATED COST")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.V3.Severity.red)
                    LockedDollarBar(width: 110, onTap: handleDollarTap)
                }
                .padding(.top, 8)
            } else if let cost = f.estimatedCost {
                Text("ESTIMATED COST \(formatCurrency(cost))")
                    .font(.system(size: 10, weight: .semibold))
                    .monospacedDigit()
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.Severity.red)
                    .padding(.top, 8)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Snapshot counts module (PR-7.5 Phase 2)

/// Volume-anchor module rendered at end of Chapter 6 in snapshot mode.
/// Reads `_snapshot_counts` and lists the category totals the full
/// report would contain, leading with sessions (largest number anchors
/// scale). Includes a dedicated CTA that mirrors Chapter 7's existing
/// button copy so the conversion moment is identical regardless of
/// which surface the user taps from.
private struct SnapshotCountsModule: View {
    let counts: SnapshotCounts
    let onTap: () -> Void

    private func pluralize(_ count: Int, _ singular: String, _ plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("IN YOUR FULL REPORT")
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.95)
                .foregroundStyle(DS.Color.V3.textSecondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(pluralize(counts.sessions, "betting session", "betting sessions")) analyzed")
                Text("\(pluralize(counts.totalBiases, "behavioral bias", "behavioral biases")) detected")
                Text("\(pluralize(counts.patterns, "behavioral pattern", "behavioral patterns")) identified")
                Text("\(pluralize(counts.leaks, "leak pattern", "leak patterns")) flagged")
                Text(pluralize(counts.sportFindings, "sport-level finding", "sport-level findings"))
            }
            .font(.system(size: 15))
            .foregroundStyle(DS.Color.V3.textPrimary)
            .lineSpacing(2)
            .padding(.top, 16)

            Button(action: onTap) {
                Text("Read the full report (\(RevenueCatStore.shared.priceString)).")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Brand.canvasDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DS.Color.V3.ctaText)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 24)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Full report contents: \(counts.sessions) sessions, \(counts.totalBiases) biases, \(counts.patterns) behavioral patterns, \(counts.leaks) leak patterns, \(counts.sportFindings) sport findings. Read the full report for nineteen dollars and ninety-nine cents.")
    }
}

#Preview {
    ChapterYourSportsView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
