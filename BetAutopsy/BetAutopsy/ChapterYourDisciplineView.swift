//
//  ChapterYourDisciplineView.swift
//  BetAutopsy
//
//  Chapter 3: Discipline Audit.
//
//  Layout (top-to-bottom):
//      ChapterNavigator  ->  HeroRingView (Discipline, higherIsWorse: false)
//      ->  BEHAVIORAL IMPACT card (multiple session-derived impacts)
//      ->  COMPONENT BREAKDOWN section (4 sub-component lines)
//      ->  InsightCallout (executive diagnosis)
//
//  Engine doesn't ship a per-bet timeline; impacts are computed from
//  sessionDetection.sessions instead. The framing ("OVER N INSTANCES")
//  surfaces session counts, not bet counts. This is the v1 honest form.
//

import SwiftUI

struct ChapterYourDisciplineView: View {
    let report: AutopsyReport

    private var disciplineTotal: Int {
        report.analysis.disciplineScore?.total ?? 0
    }

    private var sessions: [DetectedSession] {
        report.analysis.sessionDetection?.sessions ?? []
    }

    private var impacts: [BehavioralImpactRow.Impact] {
        var result: [BehavioralImpactRow.Impact] = []

        // LATE-NIGHT SESSIONS
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

        // HEATED SESSIONS
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

        // STAKE ESCALATION
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

        // RAPID-FIRE
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

                if !impacts.isEmpty {
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
    }

    private var impactCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(impacts.enumerated()), id: \.element.id) { index, impact in
                BehavioralImpactRow(impact: impact)
                    .padding(.horizontal, 16)
                if index < impacts.count - 1 {
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

    private func handleInsightTap() {
        #if DEBUG
        print("InsightCallout tapped on Chapter 3 (V1 stub).")
        #endif
    }
}

#Preview {
    ChapterYourDisciplineView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
