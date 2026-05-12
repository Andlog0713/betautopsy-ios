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

    private var betIQScore: Int {
        report.analysis.betiq?.score ?? 0
    }

    private var archetypeName: String {
        report.analysis.bettingArchetype?.name ?? ""
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
        let raw = report.analysis.executiveDiagnosis
            ?? report.analysis.bettingArchetype?.description
            ?? ""
        return raw.firstSentences(2)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ChapterNavigator(chapterNumber: 1, subtitle: "THE VERDICT")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer().frame(height: 28)

                HeroRingView(score: betIQScore, metricLabel: "BETIQ")

                Spacer().frame(height: 28)

                Text(archetypeName)
                    .font(DS.Font.V3.sectionTitle)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if !topDamages.isEmpty {
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
                    ctaLabel: "READ THE TILT FILE",
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
        // V1 stub: navigation lands in v1.1 cascade.
        // Use log shape only per repo logging rule.
        #if DEBUG
        print("InsightCallout tapped on Chapter 1 (V1 stub).")
        #endif
    }
}

#Preview {
    ChapterTheVerdictView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
