//
//  ChapterTheVerdictView.swift
//  BetAutopsy
//
//  Chapter 1: V3 trailer pattern.
//
//  Layout (top-to-bottom):
//      ChapterNavigator  →  HeroRingView  →  archetype name + percentile
//      →  TOP DAMAGES section header + DamagesCard
//      →  InsightCallout  →  bottom spacer.
//
//  Trailer vs autopsy split: Chapter 1 names the top damages by dollar
//  cost (verdict). Chapter 4 explains them with bars, translations,
//  and fixes (autopsy). Same biases, different jobs.
//
//  DamagesCard hides entirely when no bias has estimatedCost > 0.
//

import SwiftUI

struct ChapterTheVerdictView: View {
    let report: AutopsyReport

    /// Programmatic chapter advance used by the "READ THE HEATED FILE"
    /// CTA. Wired from ReportView at TabView construction time. Default
    /// no-op preserves preview / standalone usage.
    var onAdvance: () -> Void = {}

    private var betIQScore: Int {
        report.analysis.betiq?.score ?? 0
    }

    /// Engine global sample floor (c9d9d56): BetIQ detector below floor.
    private var betIQInsufficient: Bool {
        report.analysis.betiq?.insufficientData == true
    }

    /// Engine global sample floor (c9d9d56): archetype detector below
    /// floor (ships name == "Building Sample" + insufficient_data).
    private var archetypeBuildingSample: Bool {
        report.analysis.bettingArchetype?.insufficientData == true
            || report.analysis.bettingArchetype?.name == "Building Sample"
    }

    private var archetypeName: String {
        report.analysis.bettingArchetype?.name ?? ""
    }

    /// Active bias names for the WhatChanged -100% self-contradiction
    /// filter (blocker #4): a -100% impact shift on an entity still
    /// flagged in this report reads as a render bug.
    private var activeBiasNames: Set<String> {
        var names = Set(report.analysis.biasesDetected.map { $0.biasName })
        if let trigger = report.analysis.enhancedTilt?.worstTrigger
            .trimmingCharacters(in: .whitespacesAndNewlines), !trigger.isEmpty {
            names.insert(trigger)
        }
        return names
    }

    /// Baseline-reset guard (blocker #3): when the previous BetIQ value is
    /// 0 but the delta is not stable, the engine reset the baseline on a
    /// schema_version bump rather than measuring a real regression. Hide
    /// the BetIQ delta row in that case. (Engine fix tracked v1.1.)
    private var betIQDeltaIsBaselineReset: Bool {
        guard let delta = report.analysis.whatChanged?.betIQDelta else { return false }
        return delta.from == 0 && delta.direction != .stable
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
        // Building-sample mode: suppress the archetype description prose
        // fallback (it reads as a real verdict on too little data).
        let fallback = archetypeBuildingSample ? "" : (report.analysis.bettingArchetype?.description ?? "")
        let raw = report.analysis.executiveDiagnosis ?? fallback
        return raw.firstSentences(2)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ChapterNavigator(chapterNumber: 1, subtitle: "THE VERDICT")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer().frame(height: 28)

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

                // Building-sample mode skips the longitudinal WhatChanged
                // card (deltas on an insufficient sample are misleading,
                // and this subsumes the "skip TOP IMPACT SHIFTS" rule).
                if let whatChanged = report.analysis.whatChanged, !archetypeBuildingSample {
                    Spacer().frame(height: 24)

                    WhatChangedCard(
                        whatChanged: whatChanged,
                        activeBiasNames: activeBiasNames,
                        suppressBetIQDelta: betIQDeltaIsBaselineReset
                    )
                    .padding(.horizontal, 16)
                }

                if !topDamages.isEmpty, !archetypeBuildingSample {
                    Spacer().frame(height: 24)

                    Text("TOP DAMAGES \u{00B7} \(totalBets) BETS")
                        .font(DS.Font.V3.navigatorSubtitle)
                        .tracking(1.8)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)

                    Spacer().frame(height: 8)

                    DamagesCard(damages: topDamages)
                        .padding(.horizontal, 16)
                }

                Spacer().frame(height: 24)

                InsightCallout(
                    text: insightBody,
                    ctaLabel: "READ THE HEATED FILE",
                    onTap: handleInsightTap
                )
                .padding(.horizontal, 16)

                Spacer().frame(height: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .background(canvasGradient.ignoresSafeArea())
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
        onAdvance()
    }
}

#Preview {
    ChapterTheVerdictView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
