//
//  SectionHeatedDiscipline.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2: single-scroll section merging ChapterYourMindView
//  (Ch2, "The Heated File") FIRST, then ChapterYourDisciplineView (Ch3,
//  "Discipline Audit"). Mind is the emotional entry; Discipline is the
//  deeper follow-on analysis. Per the locked merge decision the Discipline
//  sub-section is marked with an inline "DISCIPLINE AUDIT" sub-heading;
//  no per-section header chrome is added above the Mind content (the
//  section opens on the emotion ring, matching SectionVerdict's ring open).
//
//  Strips ScrollView / ChapterNavigator / canvas background / PaywallView
//  sheet. The Mind closing InsightCallout keeps its snapshot paywall CTA
//  ("SEE THE DOLLAR DAMAGE") and is prose-only in full mode (its old full
//  CTA "READ THE DISCIPLINE AUDIT" now points to content directly below).
//  The Discipline closing InsightCallout is DROPPED: its prose duplicated
//  the executive diagnosis already shown in SectionVerdict and its CTA
//  ("READ THE BIAS SHEET") pointed backward to SectionFindings.
//
//  Gates preserved: D5 (TiltSignalBreakdownCard hidden in snapshot),
//  D7 (discipline component sub-breakdown hidden in snapshot).
//

import SwiftUI

struct SectionHeatedDiscipline: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    // MARK: - Shared

    private var sessions: [DetectedSession] {
        report.analysis.sessionDetection?.sessions ?? []
    }

    // MARK: - Mind (emotion / heated)

    private var emotionScore: Int { report.analysis.emotionScore }

    private var emotionInsufficient: Bool {
        report.analysis.emotionScoreInsufficientData == true
            || (report.analysis.emotionScore == 0 && report.analysis.emotionPercentile == nil)
    }

    private var sessionsInsufficient: Bool {
        report.analysis.sessionDetection?.insufficientData == true
    }

    private var heatedSessions: [DetectedSession] {
        (report.analysis.sessionDetection?.sessions ?? []).filter { $0.isHeated }
    }

    private var totalHeatedCount: Int {
        report.analysis.sessionDetection?.heatedSessionCount ?? heatedSessions.count
    }

    private var totalSessionCount: Int {
        report.analysis.sessionDetection?.totalSessions
            ?? (report.analysis.sessionDetection?.sessions.count ?? heatedSessions.count)
    }

    private var topHeatedSessions: [TiltSessionCard.Session] {
        heatedSessions
            .sorted { abs($0.profit) > abs($1.profit) }
            .prefix(3)
            .map { session in
                let trigger = session.heatSignals.first
                let secondarySignal: String?
                if session.heatSignals.count > 1 {
                    secondarySignal = session.heatSignals[1]
                } else {
                    secondarySignal = session.gradeReasons.first
                }
                return TiltSessionCard.Session(
                    dateLabel: shortDateLabel(session.date),
                    timeRangeLabel: usableTimeRange(start: session.startTime, end: session.endTime),
                    pnl: Int(session.profit.rounded()),
                    betCount: session.bets,
                    triggerLabel: trigger,
                    behavioralSignal: secondarySignal,
                    triggerEvent: session.triggerEvent
                )
            }
    }

    private var previewSession: HeatedSessionPreviewCard.Session? {
        let withSignals = heatedSessions.first { !$0.heatSignals.isEmpty }
        let source = withSignals ?? heatedSessions.first
        guard let s = source else { return nil }
        return HeatedSessionPreviewCard.Session(
            grade: s.grade,
            dateLabel: previewDateLabel(date: s.date, dayOfWeek: s.dayOfWeek, startTime: s.startTime),
            betCount: s.bets,
            heatSignals: Array(s.heatSignals.prefix(3)),
            triggerEvent: s.triggerEvent
        )
    }

    private func hasAnySignal(_ signals: TiltSignals) -> Bool {
        signals.betSizingVolatility > 0
            || signals.lossReaction > 0
            || signals.streakBehavior > 0
            || signals.sessionDiscipline > 0
            || signals.sessionAcceleration > 0
            || signals.oddsDriftAfterLoss > 0
    }

    private var mindInsightBody: String {
        if let trigger = report.analysis.enhancedTilt?.worstTrigger
            .trimmingCharacters(in: .whitespacesAndNewlines), !trigger.isEmpty {
            return trigger
        }
        return report.analysis.executiveDiagnosisInsight(snapshot: isSnapshot).firstSentences(2)
    }

    /// True when the full-mode TiltSignalBreakdownCard renders and carries
    /// the worst-trigger line inside it. The InsightCallout below must then
    /// be skipped: mindInsightBody is that same trigger string, and it was
    /// rendering twice (italic inside the card, then again in a bordered
    /// callout immediately below).
    private var triggerShownInBreakdownCard: Bool {
        guard !isSnapshot,
              let tilt = report.analysis.enhancedTilt,
              hasAnySignal(tilt.signals) else { return false }
        return !tilt.worstTrigger
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    // MARK: - Discipline

    private var disciplineTotal: Int { report.analysis.disciplineScore?.total ?? 0 }

    private var disciplineInsufficient: Bool {
        report.analysis.disciplineScore?.insufficientData == true
    }

    private var annotations: AnnotationSummary? { report.analysis.betAnnotations }

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
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            mindContent
            disciplineContent
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var mindContent: some View {
        if emotionInsufficient {
            HeroRingInsufficient(metricLabel: "EMOTION")
        } else {
            HeroRingView(score: emotionScore, metricLabel: "EMOTION", higherIsWorse: true)
        }

        if sessionsInsufficient {
            heatedInsufficientCard
        } else if isSnapshot {
            snapshotHeatedSection
        } else {
            fullHeatedSection
        }

        // D5: signal breakdown is paid-tier depth; hidden in snapshot.
        if !isSnapshot,
           let signals = report.analysis.enhancedTilt?.signals,
           hasAnySignal(signals) {
            Spacer().frame(height: 24)
            TiltSignalBreakdownCard(
                signals: signals,
                worstTrigger: report.analysis.enhancedTilt?.worstTrigger
            )
            .padding(.horizontal, 16)
        }

        // Dedup: when the breakdown card above already shows the worst
        // trigger, the full-mode callout would repeat the same sentence
        // verbatim. The insight renders once.
        if !mindInsightBody.isEmpty, !triggerShownInBreakdownCard {
            Spacer().frame(height: 24)
            if isSnapshot {
                InsightCallout(
                    text: mindInsightBody,
                    ctaLabel: "SEE THE DOLLAR DAMAGE",
                    onTap: { onPaywallTap("section_heated_discipline_mind_insight") }
                )
                .padding(.horizontal, 16)
            } else {
                InsightCallout(text: mindInsightBody)
                    .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private var disciplineContent: some View {
        Spacer().frame(height: 36)

        Text("DISCIPLINE AUDIT")
            .font(DS.Font.V3.navigatorSubtitle)
            .tracking(1.8)
            .foregroundStyle(DS.Color.V3.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)

        Spacer().frame(height: 20)

        if disciplineInsufficient {
            HeroRingInsufficient(metricLabel: "DISCIPLINE")
        } else {
            HeroRingView(score: disciplineTotal, metricLabel: "DISCIPLINE", higherIsWorse: false)
        }

        if disciplineInsufficient {
            disciplineInsufficientCard
        } else {
            if let annotations {
                annotationsSection(annotations)
            } else {
                legacySection
            }

            // D7: TRACKING / SIZING / CONTROL / STRATEGY sub-scores are
            // paid-tier depth; hidden in snapshot. Overall ring stays.
            if !isSnapshot {
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
            }
        }
    }

    // MARK: - Mind sub-views

    // 3B-2: insufficient-data cards recomposed onto Callout(.info).
    private var heatedInsufficientCard: some View {
        Callout(
            variant: .info,
            title: "Heated sessions",
            text: "Heated session detection needs more bet history."
        )
        .padding(.horizontal, 16)
        .padding(.top, 28)
    }

    @ViewBuilder
    private var snapshotHeatedSection: some View {
        if let preview = previewSession {
            Spacer().frame(height: 28)

            Text("\(totalHeatedCount) of \(totalSessionCount) sessions flagged as heated.")
                .font(DS.Font.V3.navigatorSubtitle)
                .tracking(1.8)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            Spacer().frame(height: 8)

            HeatedSessionPreviewCard(
                session: preview,
                onLockedTap: { onPaywallTap("section_heated_discipline_heated_session") }
            )
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var fullHeatedSection: some View {
        if !topHeatedSessions.isEmpty {
            Spacer().frame(height: 28)

            Text("TOP HEATED SESSIONS \u{00B7} \(totalHeatedCount) TOTAL")
                .font(DS.Font.V3.navigatorSubtitle)
                .tracking(1.8)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            Spacer().frame(height: 8)

            VStack(spacing: 8) {
                ForEach(topHeatedSessions) { session in
                    TiltSessionCard(session: session)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private func usableTimeRange(start: String, end: String) -> String {
        let s = start.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = end.trimmingCharacters(in: .whitespacesAndNewlines)
        if s == "12:00 AM" && e == "12:00 AM" {
            return ""
        }
        return "\(start) - \(end)"
    }

    private func shortDateLabel(_ raw: String) -> String {
        BAFormat.date(parsing: raw).uppercased()
    }

    private func previewDateLabel(date: String, dayOfWeek: String, startTime: String) -> String {
        let dow = dayOfWeek.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let dateShort = shortDateLabel(date)
        let time = startTime.trimmingCharacters(in: .whitespacesAndNewlines)
        let leftSide: String
        if dow.isEmpty {
            leftSide = dateShort
        } else if dateShort.isEmpty {
            leftSide = dow
        } else {
            leftSide = "\(dow) \(dateShort)"
        }
        if time.isEmpty || time == "12:00 AM" {
            return leftSide
        }
        return "\(leftSide) \u{00B7} \(time)"
    }

    // MARK: - Discipline sub-views

    private var disciplineInsufficientCard: some View {
        Callout(
            variant: .info,
            title: "Discipline audit",
            text: "Discipline scoring needs more bet history."
        )
        .padding(.horizontal, 16)
        .padding(.top, 28)
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
                .padding(.leading, 16)
                .padding(.trailing, 32)
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

        // 3B-2: full v3 reports with a qualifying typed object render the
        // StakeByStreakChart; snapshots (the locked variant lives in the
        // card) and pre-#74 reports keep StreakInfluenceCard.
        if !isSnapshot, StakeByStreakChart.qualifies(report.analysis.charts?.stakeByStreak) {
            Spacer().frame(height: 20)
            StakeByStreakChart(streak: report.analysis.charts?.stakeByStreak)
                .padding(.horizontal, 16)
        } else if let streak = annotations.streakInfluence,
                  streak.avgStakeNeutral > 0,
                  (streak.avgStakeAfterWinStreak3 > 0 || streak.avgStakeAfterLossStreak3 > 0) {
            Spacer().frame(height: 20)
            StreakInfluenceCard(
                influence: streak,
                isLocked: isSnapshot,
                onLockedTap: { onPaywallTap("section_heated_discipline_streak_locked") }
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
                    onTap: { onPaywallTap("section_heated_discipline_emotional_cost_locked") }
                )
            } else {
                // emotionalCost ships negative (a P&L delta, e.g. -8839.78).
                // Formatting the forced-negative magnitude renders a single
                // "-$8,840" (comma, one minus) matching the other loss
                // cards; the old hardcoded "-$\(value)" prepended a second
                // minus onto the already-negative value ("-$-8,840").
                Text(BAFormat.currency(-abs(annotations.emotionalCost)))
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

    // 3B-2: the four plain score lines recomposed onto ContributorBars
    // (zone-tinted ratio bars + BAFormat.score readouts). D7 gate is
    // unchanged: full mode only, the caller hides this in snapshot.
    @ViewBuilder
    private var componentBreakdown: some View {
        if let d = report.analysis.disciplineScore {
            ContributorBars(contributors: [
                ContributorBars.Contributor(label: "Tracking", value: d.tracking, max: 25),
                ContributorBars.Contributor(label: "Sizing", value: d.sizing, max: 25),
                ContributorBars.Contributor(label: "Control", value: d.control, max: 25),
                ContributorBars.Contributor(label: "Strategy", value: d.strategy, max: 25)
            ])
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    ScrollView {
        SectionHeatedDiscipline(report: MockReport.heatedBettor, onPaywallTap: { _ in })
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
