//
//  ChapterYourMindView.swift
//  BetAutopsy
//
//  Chapter 2: V3 visual direction cascade.
//
//  Layout (top-to-bottom):
//      ChapterNavigator  →  HeroRingView (Emotion, higherIsWorse: true)
//      →  contributor card (4 emotion sub-dimensions)
//      →  InsightCallout (worst trigger or fallback)
//
//  Inverted color logic: high emotion = high tilt = red zone.
//  Sub-dimensions individually directional (three higherIsWorse,
//  one higherIsWorse: false for SESSION DISCIPLINE).
//
//  Emotion breakdown components are 0-25 in the engine; we × 4 at
//  the call site to render on ContributorRow's 0-100 scale.
//
//  Radar chart, worst-trigger card, and pertinent-negative cards
//  from the V2 version are removed. WHOOP-style restraint: ring +
//  contributors + insight, nothing more.
//

import SwiftUI

struct ChapterYourMindView: View {
    let report: AutopsyReport

    private var emotionScore: Int {
        report.analysis.emotionScore
    }

    private var stakeVolatility: Int {
        (report.analysis.emotionBreakdown?.stakeVolatility ?? 0) * 4
    }

    private var lossChasing: Int {
        (report.analysis.emotionBreakdown?.lossChasing ?? 0) * 4
    }

    private var streakBehavior: Int {
        (report.analysis.emotionBreakdown?.streakBehavior ?? 0) * 4
    }

    private var sessionDiscipline: Int {
        (report.analysis.emotionBreakdown?.sessionDiscipline ?? 0) * 4
    }

    private var insightBody: String {
        if let trigger = report.analysis.enhancedTilt?.worstTrigger
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !trigger.isEmpty {
            return trigger
        }
        let exec = report.analysis.executiveDiagnosis ?? ""
        return exec.firstSentences(2)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ChapterNavigator(chapterNumber: 2, subtitle: "YOUR MIND")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer().frame(height: 28)

                HeroRingView(
                    score: emotionScore,
                    metricLabel: "EMOTION",
                    higherIsWorse: true
                )

                Spacer().frame(height: 28)

                contributorCard
                    .padding(.horizontal, 16)

                if !insightBody.isEmpty {
                    Spacer().frame(height: 24)

                    InsightCallout(
                        text: insightBody,
                        ctaLabel: "BREAK DOWN MY MIND",
                        onTap: handleInsightTap
                    )
                    .padding(.horizontal, 16)
                }

                Spacer().frame(height: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .background(canvasGradient.ignoresSafeArea())
    }

    private var contributorCard: some View {
        VStack(spacing: 0) {
            ContributorRow(
                iconSystemName: "scribble.variable",
                label: "STAKE VOLATILITY",
                value: stakeVolatility,
                trendUp: nil,
                higherIsWorse: true
            )
            .padding(.horizontal, 16)

            V3Divider()
                .padding(.horizontal, 16)

            ContributorRow(
                iconSystemName: "arrow.uturn.right",
                label: "LOSS CHASING",
                value: lossChasing,
                trendUp: nil,
                higherIsWorse: true
            )
            .padding(.horizontal, 16)

            V3Divider()
                .padding(.horizontal, 16)

            ContributorRow(
                iconSystemName: "arrow.triangle.2.circlepath",
                label: "STREAK BEHAVIOR",
                value: streakBehavior,
                trendUp: nil,
                higherIsWorse: true
            )
            .padding(.horizontal, 16)

            V3Divider()
                .padding(.horizontal, 16)

            ContributorRow(
                iconSystemName: "timer",
                label: "SESSION DISCIPLINE",
                value: sessionDiscipline,
                trendUp: nil,
                higherIsWorse: false
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
        #if DEBUG
        print("InsightCallout tapped on Chapter 2 (V1 stub).")
        #endif
    }
}

#Preview {
    ChapterYourMindView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
