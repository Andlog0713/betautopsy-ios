//
//  ChapterYourDisciplineView.swift
//  BetAutopsy
//
//  Chapter 3: Discipline Audit.
//
//  Layout (top-to-bottom):
//      ChapterNavigator  ->  HeroRingView (Discipline, higherIsWorse: false)
//
//      Annotations path (engine V2+ ships bet_annotations):
//          ->  EMOTIONAL COST hero card (red/orange/yellow by ratio)
//          ->  AnnotationDistributionBar (5-segment)
//          ->  AnnotatedBetCard (worst) + AnnotatedBetCard (best)
//          ->  StreakInfluenceCard (when streakInfluence present)
//
//      Legacy path (betAnnotations == nil):
//          ->  BEHAVIORAL IMPACT card (session-derived BehavioralImpactRow)
//
//      Always:
//          ->  COMPONENT BREAKDOWN section (4 sub-component lines)
//          ->  InsightCallout (executive diagnosis)
//
//  Snapshot mode: hero number replaced with LockedDollarBar; streak
//  influence values replaced with locked bars. Distribution bar and
//  annotated bet cards have no dollar values and render unchanged.
//

import SwiftUI

struct ChapterYourDisciplineView: View {
    let report: AutopsyReport

    @State private var showingPaywall: Bool = false

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var disciplineTotal: Int {
        report.analysis.disciplineScore?.total ?? 0
    }

    private var sessions: [DetectedSession] {
        report.analysis.sessionDetection?.sessions ?? []
    }

    private var annotations: AnnotationSummary? {
        report.analysis.betAnnotations
    }

    private var totalStaked: Double {
        annotations?.distribution.reduce(0) { $0 + $1.totalStaked } ?? 0
    }

    private var emotionalCostRatio: Double {
        guard totalStaked > 0, let cost = annotations?.emotionalCost else { return 0 }
        return cost / totalStaked
    }

    private var emotionalCostTint: Color {
        if isSnapshot { return DS.Color.V3.Severity.red }
        let r = emotionalCostRatio
        if r >= 0.20 { return DS.Color.V3.Severity.red }
        if r >= 0.10 { return DS.Color.V3.Severity.orange }
        return DS.Color.V3.Severity.yellow
    }

    private var legacyImpacts: [BehavioralImpactRow.Impact] {
        var result: [BehavioralImpactRow.Impact] = []

        let lateNight = sessions.filter { $0.lateNight }
        if lateNight.count >= 2 {
            let net = Int(lateNight.reduce(0) { $0 + $1.profit }.rounded())
            if net <= -50 {
                result.append(BehavioralImpactRow.Impact(
                    iconSystemName: "moon.fill",
                    label: "LATE-NIGHT SESSIONS (POST-11PM)",
                    dollarImpact: net,
                    sampleSize: lateNight.count
                ))
            }
        }

        let heated = sessions.filter { $0.isHeated }
        if heated.count >= 2 {
            let net = Int(heated.reduce(0) { $0 + $1.profit }.rounded())
            if net <= -50 {
                result.append(BehavioralImpactRow.Impact(
                    iconSystemName: "flame.fill",
                    label: "HEATED SESSIONS",
                    dollarImpact: net,
                    sampleSize: heated.count
                ))
            }
        }

        let escalated = sessions.filter { $0.stakeEscalation > 1.5 }
        if escalated.count >= 2 {
            let net = Int(escalated.reduce(0) { $0 + $1.profit }.rounded())
            if net <= -50 {
                result.append(BehavioralImpactRow.Impact(
                    iconSystemName: "arrow.up.right.square.fill",
                    label: "STAKE ESCALATION (>1.5x)",
                    dollarImpact: net,
                    sampleSize: escalated.count
                ))
            }
        }

        let rapid = sessions.filter { $0.betsPerHour > 3 }
        if rapid.count >= 2 {
            let net = Int(rapid.reduce(0) { $0 + $1.profit }.rounded())
            if net <= -50 {
                result.append(BehavioralImpactRow.Impact(
                    iconSystemName: "bolt.fill",
                    label: "RAPID-FIRE (>3 BETS/HOUR)",
                    dollarImpact: net,
                    sampleSize: rapid.count
                ))
            }
        }

        return result
            .sorted { abs($0.dollarImpact) > abs($1.dollarImpact) }
            .prefix(5)
            .map { $0 }
    }

    private var insightBody: String {
        (report.analysis.executiveDiagnosis ?? "").firstSentences(2)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ChapterNavigator(chapterNumber: 3, subtitle: "DISCIPLINE AUDIT")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer().frame(height: 28)

                HeroRingView(
                    score: disciplineTotal,
                    metricLabel: "DISCIPLINE",
                    higherIsWorse: false
                )

                if let annotations {
                    annotationsSection(annotations)
                } else {
                    legacySection
                }

                Spacer().frame(height: 28)

                Text("COMPONENT BREAKDOWN")
                    .font(DS.Font.V3.navigatorSubtitle)
                    .tracking(1.8)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 8)

                componentBreakdown
                    .padding(.horizontal, 16)

                if !insightBody.isEmpty {
                    Spacer().frame(height: 24)

                    InsightCallout(
                        text: insightBody,
                        ctaLabel: "READ THE BIAS SHEET",
                        onTap: handleInsightTap
                    )
                    .padding(.horizontal, 16)
                }

                Spacer().frame(height: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .background(canvasGradient.ignoresSafeArea())
        .sheet(isPresented: $showingPaywall) {
            PaywallView(snapshotReportId: report.id)
        }
    }

    @ViewBuilder
    private func annotationsSection(_ annotations: AnnotationSummary) -> some View {
        Spacer().frame(height: 28)
        emotionalCostHero(annotations: annotations)
            .padding(.horizontal, 16)

        Spacer().frame(height: 20)
        AnnotationDistributionBar(
            distribution: annotations.distribution,
            insightText: annotations.insight
        )
        .padding(.horizontal, 16)

        if let worst = annotations.worstAnnotatedBet,
           let best  = annotations.bestAnnotatedBet {
            Spacer().frame(height: 20)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    AnnotatedBetCard(role: .worst, annotation: worst)
                        .frame(width: 320)
                    AnnotatedBetCard(role: .best, annotation: best)
                        .frame(width: 320)
                }
                .padding(.horizontal, 16)
            }
        } else if let worst = annotations.worstAnnotatedBet {
            Spacer().frame(height: 20)
            AnnotatedBetCard(role: .worst, annotation: worst)
                .padding(.horizontal, 16)
        } else if let best = annotations.bestAnnotatedBet {
            Spacer().frame(height: 20)
            AnnotatedBetCard(role: .best, annotation: best)
                .padding(.horizontal, 16)
        }

        if let streak = annotations.streakInfluence,
           streak.avgStakeNeutral > 0 {
            Spacer().frame(height: 20)
            StreakInfluenceCard(
                influence: streak,
                isLocked: isSnapshot,
                onLockedTap: { showPaywall(source: "ch3_streak_locked") }
            )
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private func emotionalCostHero(annotations: AnnotationSummary) -> some View {
        let count = annotations.annotations.count
        VStack(alignment: .leading, spacing: 8) {
            Text("EMOTIONAL COST")
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)

            if isSnapshot {
                LockedDollarBar(
                    width: 200,
                    onTap: { showPaywall(source: "ch3_emotional_cost_locked") }
                )
            } else {
                Text("-$\(Int(annotations.emotionalCost.rounded()))")
                    .font(.system(size: 52, weight: .bold).monospacedDigit())
                    .foregroundStyle(emotionalCostTint)
            }

            if count > 0 {
                Text("across \(count) classified bets")
                    .font(DS.Font.V3.bodyRegular)
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
    }

    @ViewBuilder
    private var legacySection: some View {
        if !legacyImpacts.isEmpty {
            Spacer().frame(height: 28)

            Text("BEHAVIORAL IMPACT")
                .font(DS.Font.V3.navigatorSubtitle)
                .tracking(1.8)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            Spacer().frame(height: 8)

            impactCard
                .padding(.horizontal, 16)
        }
    }

    private var impactCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(legacyImpacts.enumerated()), id: \.element.id) { index, impact in
                BehavioralImpactRow(impact: impact)
                    .padding(.horizontal, 16)
                if index < legacyImpacts.count - 1 {
                    V3Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 2)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var componentBreakdown: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let d = report.analysis.disciplineScore {
                Text("TRACKING \(d.tracking)/25")
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textSecondary)
                Text("SIZING \(d.sizing)/25")
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textSecondary)
                Text("CONTROL \(d.control)/25")
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textSecondary)
                Text("STRATEGY \(d.strategy)/25")
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func showPaywall(source: String) {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": source]
        )
        showingPaywall = true
    }

    private func handleInsightTap() {
        if isSnapshot {
            showPaywall(source: "ch3_insight_cta")
        } else {
            #if DEBUG
            print("InsightCallout tapped on Chapter 3 (V1 stub).")
            #endif
        }
    }
}

#Preview {
    ChapterYourDisciplineView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
