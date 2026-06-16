//
//  SectionVerdict.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2: single-scroll section extracted verbatim from
//  ChapterTheVerdictView (Ch1). Strips the ScrollView wrapper, the
//  ChapterNavigator chrome, the canvas background, the per-chapter
//  PaywallView sheet, and the "READ THE HEATED FILE" chapter-advance CTA
//  (now prose-only). The legacy WhatChangedCard is removed here; its
//  longitudinal content is owned by VsLastReportCard (Phase 1 + Step 5
//  topImpactDeltas absorption).
//
//  Phase 1 conversion mechanics (TotalRecoverableHero full-mode-only,
//  BankrollHealthCallout conditional, VsLastReportCard conditional) are
//  preserved in the conversionMechanics sub-view.
//

import SwiftUI

struct SectionVerdict: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var betIQScore: Int {
        report.analysis.betiq?.score ?? 0
    }

    private var betIQInsufficient: Bool {
        report.analysis.betiq?.insufficientData == true
    }

    private var archetypeBuildingSample: Bool {
        report.analysis.bettingArchetype?.insufficientData == true
            || report.analysis.bettingArchetype?.name == "Building Sample"
    }

    private var archetypeName: String {
        report.analysis.bettingArchetype?.name ?? ""
    }

    /// Previous report for the VsLastReportCard client-side diff. Picks the
    /// most-recent in-memory FULL report from a DIFFERENT upload window.
    /// Nil when this is the user's first report; the card then hides.
    ///
    /// TESTFLIGHT-MIN first-report fix: candidates must be FULL reports.
    /// The date-range exclusion alone was not enough - the unlock flow
    /// creates a full child with a no-filter FULL-HISTORY date range,
    /// different from its snapshot twin's, so a user's first purchased
    /// report matched their own snapshot as "previous" and diffed against
    /// engine-redacted zeros (every dollar 0 in snapshot mode) - junk
    /// deltas on exactly the report that should show none. Snapshot
    /// analyses are never a valid diff baseline.
    private var previousAnalysis: AutopsyAnalysis? {
        ReportStore.shared.reports.first { other in
            other.id != report.id
                && other.reportType != "snapshot"
                && !(other.dateRangeStart == report.dateRangeStart
                     && other.dateRangeEnd == report.dateRangeEnd)
        }?.analysis
    }

    private var totalBets: Int {
        report.analysis.summary.totalBets
    }

    private var topDamages: [DamagesCard.Damage] {
        report.analysis.biasesDetected
            .compactMap { bias -> DamagesCard.Damage? in
                let cost = Int(bias.estimatedCost.rounded())
                guard cost > 0 else { return nil }
                return DamagesCard.Damage(name: bias.biasName, cost: cost)
            }
            .sorted { $0.cost > $1.cost }
            .prefix(3)
            .map { $0 }
    }

    private var insightBody: String {
        let fallback = archetypeBuildingSample ? "" : (report.analysis.bettingArchetype?.description ?? "")
        // Snapshot routes to insightSnapshot (no dollar figures); full routes
        // to insightFull. Empty insight falls back to the archetype prose so a
        // snapshot without a snapshot variant never leaks the full $ prose.
        let insight = report.analysis.executiveDiagnosisInsight(snapshot: isSnapshot)
        let raw = insight.isEmpty ? fallback : insight
        return raw.firstSentences(2)
    }

    /// Mirrors BetIQComponentBars.shouldRender so the surrounding spacer is
    /// dropped when the bars hide (no betiq, or insufficient sample in full
    /// mode). Snapshot always shows the locked teaser when betiq exists.
    private var showComponentBars: Bool {
        guard let betiq = report.analysis.betiq else { return false }
        if isSnapshot { return true }
        return !betiq.insufficientData
    }

    /// Phase 1 conversion mechanics block. TotalRecoverableHero is
    /// full-mode-only (self-hides in snapshot and when the figure is 0).
    /// BankrollHealthCallout renders only when health != healthy.
    /// VsLastReportCard renders only when a prior report exists and is
    /// skipped in building-sample mode.
    @ViewBuilder
    private var conversionMechanics: some View {
        if !isSnapshot {
            Spacer().frame(height: 24)
            TotalRecoverableHero(report: report)
                .padding(.horizontal, 16)
        }

        // 3B-2: bankroll health recomposed onto Callout (caution/severe
        // variants). Copy is carried over from BankrollHealthCallout
        // verbatim, including the danger-tier helpline line (compliance
        // copy, COPY_SYSTEM). The legacy component file is unconsumed by
        // live code; Prompt 4 retires it.
        if report.analysis.bankrollHealth == .danger {
            Spacer().frame(height: 24)
            Callout(
                variant: .severe,
                title: "Bankroll under strain",
                text: "Your stake sizing relative to your results points to bankroll stress. This is the pattern that precedes the sessions people regret.\n\nIf gambling has stopped being fun, call 1-800-MY-RESET."
            )
            .padding(.horizontal, 16)
        } else if report.analysis.bankrollHealth == .caution {
            Spacer().frame(height: 24)
            Callout(
                variant: .caution,
                title: "Bankroll worth watching",
                text: "Stake sizing is drifting relative to your results. Worth keeping an eye on before it compounds."
            )
            .padding(.horizontal, 16)
        }

        if let previousAnalysis, !archetypeBuildingSample {
            Spacer().frame(height: 24)
            VsLastReportCard(
                current: report.analysis,
                previous: previousAnalysis
            )
            .padding(.horizontal, 16)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Elevated-tier note: dismissible, non-clinical heads-up at the
            // very top. Recovery tier renders nothing here (its card lives in
            // SectionProtocol); snapshots never reach here (controlSystem nil).
            if report.analysis.controlSystem?.effectiveRiskTier == .elevated {
                ElevatedRiskNote(reportId: report.id)
                    .padding(.horizontal, 16)
                Spacer().frame(height: 24)
            }

            // #1 vitals strip: top-of-section density anchor, above the ring.
            VitalsStripCard(report: report, onPaywallTap: onPaywallTap)
                .padding(.horizontal, 16)

            Spacer().frame(height: 24)

            if betIQInsufficient {
                HeroRingInsufficient(metricLabel: "BETIQ")
            } else {
                HeroRingView(score: betIQScore, metricLabel: "BETIQ")
            }

            // #2 BetIQ skill-component bars: between the ring and the
            // archetype prose (opens the composite score into its drivers).
            if showComponentBars {
                Spacer().frame(height: 24)
                BetIQComponentBars(report: report, onPaywallTap: onPaywallTap)
                    .padding(.horizontal, 16)
            }

            Spacer().frame(height: 28)

            Text(archetypeName)
                .font(DS.Font.V3.sectionTitle)
                .foregroundStyle(archetypeBuildingSample
                    ? DS.Color.V3.textTertiary
                    : DS.Color.V3.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // 3A hero chart (report-trust wire): the heated-session stake
            // escalation, full-mode only, gated so snapshots and pre-#74
            // reports render exactly what they rendered before. The chart
            // itself also requires >= 2 timeline points (it returns nothing
            // otherwise, never an empty frame).
            if !isSnapshot,
               let charts = report.analysis.charts,
               let heroSession = charts.heroSession,
               !charts.sessionTimeline.isEmpty {
                Spacer().frame(height: 24)
                SessionTimelineChart(
                    timeline: charts.sessionTimeline,
                    hero: heroSession,
                    revealKey: report.id
                )
                .padding(.horizontal, 16)
            }

            conversionMechanics

            if !topDamages.isEmpty, !archetypeBuildingSample {
                Spacer().frame(height: 24)

                Text("TOP DAMAGES \u{00B7} \(totalBets.pluralizedCaps("BET", "BETS"))")
                    .font(DS.Font.V3.navigatorSubtitle)
                    .tracking(1.8)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 8)

                DamagesCard(damages: topDamages)
                    .padding(.horizontal, 16)
            }

            // #3 What-If simulator: between DamagesCard and the exec-
            // diagnosis insight. Full-mode only (the engine omits
            // what_if_scenarios in snapshot); nil/empty on older reports.
            if !isSnapshot,
               let scenarios = report.analysis.whatIfScenarios,
               !scenarios.isEmpty {
                Spacer().frame(height: 24)
                WhatIfCard(scenarios: scenarios)
                    .padding(.horizontal, 16)
            }

            if !insightBody.isEmpty {
                Spacer().frame(height: 24)

                // Chapter-advance CTA removed (single-scroll IA); prose kept.
                InsightCallout(text: insightBody)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScrollView {
        SectionVerdict(report: MockReport.heatedBettor, onPaywallTap: { _ in })
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
