//
//  ChapterTheVerdictView.swift
//  BetAutopsy
//
//  Chapter 1: V3 visual direction pilot.
//
//  Layout (top-to-bottom):
//      ChapterNavigator  →  HeroRingView  →  archetype name
//      →  contributor card (DISCIPLINE + EMOTION)
//      →  InsightCallout  →  bottom spacer.
//
//  Ring color is severity-driven, not archetype-driven (V3 token spec).
//  Archetype subtitle (percentile) deliberately omitted in V1 — data
//  not available on AutopsyAnalysis. Will revisit when subtitle source
//  lands on the model.
//
//  SELECTIVITY + PATTERN contributor rows are deferred until those
//  scores land on AutopsyAnalysis. V1 ships with two rows.
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

    private var disciplineValue: Int {
        report.analysis.disciplineScore?.total ?? 0
    }

    private var emotionValue: Int {
        report.analysis.emotionScore
    }

    private var insightBody: String {
        report.analysis.executiveDiagnosis
            ?? report.analysis.bettingArchetype?.description
            ?? ""
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

                Spacer().frame(height: 24)

                contributorCard
                    .padding(.horizontal, 16)

                Spacer().frame(height: 24)

                InsightCallout(
                    text: insightBody,
                    ctaLabel: "READ THE FULL VERDICT",
                    onTap: handleInsightTap
                )
                .padding(.horizontal, 16)

                Spacer().frame(height: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .background(canvasGradient.ignoresSafeArea())
    }

    private var contributorCard: some View {
        VStack(spacing: 0) {
            ContributorRow(
                iconSystemName: "shield",
                label: "DISCIPLINE",
                value: disciplineValue,
                trendUp: nil
            )
            .padding(.horizontal, 16)

            V3Divider()
                .padding(.horizontal, 16)

            ContributorRow(
                iconSystemName: "flame",
                label: "EMOTION",
                value: emotionValue,
                trendUp: nil
            )
            .padding(.horizontal, 16)
        }
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
