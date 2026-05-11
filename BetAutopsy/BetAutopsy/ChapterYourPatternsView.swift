//
//  ChapterYourPatternsView.swift
//  BetAutopsy
//
//  Chapter 5: behavioral patterns, session grade distribution, notable
//  sessions (worst F's + one A), and bet classification distribution as a
//  stacked bar with legend.
//

import SwiftUI

struct ChapterYourPatternsView: View {
    let report: AutopsyReport

    private var heatedPercentLabel: String {
        let pct = Int((report.analysis.sessionDetection?.heatedSessionPercent ?? 0).rounded())
        return "\(pct)% HEATED SESSIONS"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ChapterHeader(
                    chipText: "YOUR PATTERNS",
                    alertChip: (text: heatedPercentLabel, color: DS.Color.Semantic.blood),
                    title: "Your patterns repeat. The math is in them.",
                    pullQuote: nil
                )
                .padding(.top, DS.Spacing.md)

                patternsSection.padding(.top, DS.Spacing.xl)
                sessionGradesSection.padding(.top, DS.Spacing.xl)
                notableSessionsSection.padding(.top, DS.Spacing.xl)
                classificationSection.padding(.top, DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Behavioral patterns

    private var patternsSection: some View {
        VStack(spacing: 12) {
            ForEach(report.analysis.behavioralPatterns) { p in
                patternCard(p)
            }
        }
    }

    private func patternCard(_ p: BehavioralPattern) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(p.patternName.uppercased())
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.15)
                    .foregroundStyle(DS.Color.Text.primary)
                Spacer()
                impactChip(for: p.impact)
            }

            Text(p.description)
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(DS.Color.Border.subtle)
                .frame(height: DS.Stroke.hairline)
                .padding(.top, 12)

            Text("FREQUENCY: \(p.frequency)")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, 12)

            Text(p.dataPoints)
                .font(.custom("JetBrainsMono-Regular", size: 13))
                .monospacedDigit()
                .foregroundStyle(DS.Color.Text.primary)
                .padding(.top, 4)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    @ViewBuilder
    private func impactChip(for impact: String) -> some View {
        switch impact {
        case "positive": LabelChip(text: "POSITIVE", color: DS.Color.Semantic.win)
        case "negative": LabelChip(text: "NEGATIVE", color: DS.Color.Semantic.blood)
        default:         LabelChip(text: "NEUTRAL",  color: DS.Color.Text.tertiary)
        }
    }

    // MARK: - Session grade distribution

    private var sessionGradesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SESSION GRADES")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("\(report.analysis.sessionDetection?.totalSessions ?? 0) sessions detected. Heated sessions cost an average of $187 each.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                ForEach(report.analysis.sessionDetection?.sessionGradeDistribution ?? []) { g in
                    gradePill(g)
                }
            }
            .padding(.top, DS.Spacing.md)

            if let insight = report.analysis.sessionDetection?.insight {
                Text(insight)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.Text.secondary)
                    .lineSpacing(3)
                    .padding(.top, 12)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func gradePill(_ g: SessionGradeDistribution) -> some View {
        VStack(spacing: 4) {
            Text(g.grade)
                .font(.system(size: 24, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(DS.Color.Text.primary)
            Text("\(g.count)")
                .font(.custom("JetBrainsMono-Regular", size: 12))
                .monospacedDigit()
                .foregroundStyle(DS.Color.Text.secondary)
            Text("\(Int(g.percent.rounded()))%")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .monospacedDigit()
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(DS.Color.Surface.card)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Notable sessions

    private var notableSessionsSection: some View {
        let sessions = report.analysis.sessionDetection?.sessions ?? []
        let worst = Array(sessions.filter { $0.grade == "F" }.prefix(3))
        let best  = Array(sessions.filter { $0.grade == "A" }.prefix(1))
        let notable = worst + best

        return VStack(alignment: .leading, spacing: 12) {
            Text("NOTABLE SESSIONS")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.bottom, 4)

            ForEach(notable) { s in
                sessionCard(s)
            }
        }
    }

    private func sessionCard(_ s: DetectedSession) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("\(s.date.uppercased()) · \(s.dayOfWeek)")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.Surface.raised)
                        .frame(width: 32, height: 32)
                    Text(s.grade)
                        .font(.system(size: 24, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.Text.primary)
                }
            }

            Text("\(s.startTime) to \(s.endTime) · \(s.durationMinutes) min")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.top, 4)

            Rectangle()
                .fill(DS.Color.Border.subtle)
                .frame(height: DS.Stroke.hairline)
                .padding(.top, 12)

            HStack {
                Text("\(s.bets) bets")
                    .font(.custom("JetBrainsMono-Regular", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Text.primary)
                Spacer()
                Text(formatCurrency(s.profit, signed: true))
                    .font(.custom("JetBrainsMono-Medium", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(s.profit >= 0 ? DS.Color.Semantic.win : DS.Color.Semantic.blood)
            }
            .padding(.top, 12)

            if !s.heatSignals.isEmpty {
                Text("Heat signals: \(s.heatSignals.joined(separator: ", "))")
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Bet classification distribution

    private var classificationSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BET CLASSIFICATION")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            if let dist = report.analysis.betAnnotations?.distribution, !dist.isEmpty {
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        ForEach(dist) { stats in
                            Rectangle()
                                .fill(stats.classification.color)
                                .frame(width: geo.size.width * stats.percent / 100, height: 24)
                        }
                    }
                }
                .frame(height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.top, DS.Spacing.md)

                VStack(spacing: 8) {
                    ForEach(dist) { stats in
                        legendRow(stats)
                    }
                }
                .padding(.top, DS.Spacing.md)
            }

            if let insight = report.analysis.betAnnotations?.insight {
                Text(insight)
                    .font(.custom("Georgia-Italic", size: 15))
                    .foregroundStyle(DS.Color.Text.secondary)
                    .lineSpacing(4)
                    .padding(.top, DS.Spacing.md)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func legendRow(_ stats: ClassificationStats) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(stats.classification.color)
                .frame(width: 8, height: 8)
            Text(stats.classification.label)
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
            Spacer()
            Text("\(stats.count) BETS · \(formatPct(stats.percent, decimals: 1))")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .monospacedDigit()
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.primary)
        }
    }
}

#Preview {
    ChapterYourPatternsView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
