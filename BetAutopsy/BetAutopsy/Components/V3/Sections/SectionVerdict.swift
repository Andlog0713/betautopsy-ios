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
    /// most-recent in-memory report from a DIFFERENT upload window (skips
    /// the snapshot/full twin of the current upload, which shares the same
    /// date range). Nil when this is the first report or in previews where
    /// the store is empty; the card then hides.
    private var previousAnalysis: AutopsyAnalysis? {
        ReportStore.shared.reports.first { other in
            other.id != report.id
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
        let raw = report.analysis.executiveDiagnosis ?? fallback
        return raw.firstSentences(2)
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

        if report.analysis.bankrollHealth != .healthy {
            Spacer().frame(height: 24)
            BankrollHealthCallout(health: report.analysis.bankrollHealth)
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
            if betIQInsufficient {
                HeroRingInsufficient(metricLabel: "BETIQ")
            } else {
                HeroRingView(score: betIQScore, metricLabel: "BETIQ")
            }

            Spacer().frame(height: 28)

            Text(archetypeName)
                .font(DS.Font.V3.sectionTitle)
                .foregroundStyle(archetypeBuildingSample
                    ? DS.Color.V3.textTertiary
                    : DS.Color.V3.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

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
