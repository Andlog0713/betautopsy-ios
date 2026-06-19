//
//  SectionSports.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2: single-scroll section holding the SPORTS half of
//  ChapterYourSportsView (Ch6): odds buckets (with locked badge), luck
//  rating + wins-vs-expected (D8), sport-specific finding cards, and the
//  snapshot SnapshotCountsModule. The BY HOUR / BY DAY timing content moved
//  to SectionPatternsTiming.
//
//  Strips ScrollView / ChapterNavigator / canvas background / PaywallView
//  sheet. The full-mode "SEE THE ACTION PLAN" chapter-advance CTA is now
//  prose-only.
//
//  Gate preserved: D8 (luck label stays; wins-vs-expected locked behind
//  LockedDollarBar in snapshot).
//

import SwiftUI

struct SectionSports: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            oddsSection
            sportFindingsSection.padding(.top, 32)
            betTypeMixSection

            // Snapshot keeps the volume-anchor counts module. The full-mode
            // exec-diagnosis InsightCallout is removed (Q3 dedup): it
            // duplicated SectionVerdict's insight.
            if report.reportType == "snapshot",
               let counts = report.analysis.snapshotCounts {
                SnapshotCountsModule(counts: counts) {
                    onPaywallTap("section_sports_counts_module_cta")
                }
                .padding(.top, 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    // MARK: - Odds buckets

    private var typedOddsBuckets: [ChartOddsBucket] {
        report.analysis.charts?.oddsBuckets ?? []
    }

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

                // 3B-2: full v3 reports with a qualifying typed array render
                // the OddsBucketsChart; snapshots (LOCKED badges live in the
                // cards) and pre-#74 reports keep the bespoke bucket cards.
                if !isSnapshot, OddsBucketsChart.qualifies(typedOddsBuckets) {
                    OddsBucketsChart(buckets: typedOddsBuckets)
                        .padding(.top, 16)
                } else {
                    VStack(spacing: 12) {
                        ForEach(odds.buckets) { bucket in
                            oddsBucketCard(bucket)
                        }
                    }
                    .padding(.top, 16)
                }

                // D8: the luck rating label stays visible in every mode (it
                // carries the "running hot/cold" direction). The precise
                // wins-vs-expected counts are locked in snapshot.
                Text("Luck rating: \(odds.luckLabel)")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .padding(.top, 16)

                if isSnapshot {
                    LockedDollarBar(width: 140, onTap: { onPaywallTap("section_sports_dollar_locked") })
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
                    Text("ROI \(BAFormat.percent(b.roi, signed: true, headline: true))")
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
                    Text("\(BAFormat.percent(b.actualWinRate, headline: true)) WIN")
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
            .onTapGesture { onPaywallTap("section_sports_dollar_locked") }
        } else {
            Text("DATA SPARSE")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .lineLimit(1)
        }
    }

    // MARK: - Bet type mix (3B-2, new surface)

    /// What you bet, from the typed charts.betTypeMix array. Full v3
    /// reports only; there is no legacy equivalent to fall back to.
    @ViewBuilder
    private var betTypeMixSection: some View {
        let mix = report.analysis.charts?.betTypeMix ?? []
        if !isSnapshot, BetTypeMixChart.qualifies(mix) {
            BetTypeMixChart(mix: mix)
                .padding(.top, 32)
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

            // 3B-2 evidence layer: sub_splits comparison rows (decode since
            // 3A). Collapsed by default; snapshot suppresses the dollar
            // segment. Absent on pre-#74 reports.
            if let splits = f.subSplits, !splits.isEmpty {
                EvidenceBlock(
                    splits: splits,
                    confidence: f.confidence,
                    isSnapshot: isSnapshot
                )
                .padding(.top, 12)
            }

            if f.recommendationVisibility != "hidden",
               !f.recommendation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(f.recommendation)
                    .font(.custom("Georgia-Italic", size: 14))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .lineSpacing(3)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // The locked pill is snapshot-redaction UI only. A full report
            // finding without a real dollar hides the cost row instead of
            // rendering a lock in a paid surface.
            if isSnapshot {
                HStack(spacing: 8) {
                    Text("ESTIMATED COST")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.V3.Severity.red)
                    LockedDollarBar(width: 110, onTap: { onPaywallTap("section_sports_dollar_locked") })
                }
                .padding(.top, 8)
            } else if let cost = f.estimatedCost, cost != 0,
                      f.estimatedCostVisibility != "redacted_dollar" {
                Text("ESTIMATED COST \(BAFormat.currency(cost))")
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

// MARK: - Snapshot counts module (moved verbatim from ChapterYourSportsView)

/// Volume-anchor module rendered at the end of the Sports section in
/// snapshot mode. Reads `_snapshot_counts` and lists the category totals
/// the full report would contain. CTA mirrors the canonical full-report
/// button copy.
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

            // Quiet tappable affordance, not a loud solid-yellow button.
            // The single "Read the full report" primary CTA now lives only
            // on SectionAction's terminal card, so the snapshot no longer
            // stacks three near-identical buy buttons at the end. The whole
            // card taps through to the same paywall source.
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Color.V3.textTertiary)
                Text("See the full breakdown (\(RevenueCatStore.shared.priceString)).")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.Brand.yellow)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
            .padding(.top, 20)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Full report contents: \(counts.sessions) sessions, \(counts.totalBiases) biases, \(counts.patterns) behavioral patterns, \(counts.leaks) leak patterns, \(counts.sportFindings) sport findings. See the full breakdown for nineteen dollars and ninety-nine cents.")
    }
}

#Preview {
    ScrollView {
        SectionSports(report: MockReport.heatedBettor, onPaywallTap: { _ in })
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
