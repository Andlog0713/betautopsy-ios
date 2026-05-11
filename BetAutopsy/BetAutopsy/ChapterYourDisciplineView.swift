//
//  ChapterYourDisciplineView.swift
//  BetAutopsy
//
//  Chapter 3: discipline + BetIQ. Four-dimension discipline breakdown bars,
//  BetIQ hero with archetype tint, six-row BetIQ component table, and a
//  short prose payoff line.
//

import SwiftUI

struct ChapterYourDisciplineView: View {
    let report: AutopsyReport

    private var archetypeColor: Color {
        report.analysis.bettingArchetype?.color ?? DS.Color.Accent.luminol
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ChapterHeader(
                    chipText: "YOUR DISCIPLINE",
                    alertChip: (text: "BOTTOM 12%", color: DS.Color.Semantic.blood),
                    title: "Your discipline ranks in the bottom 12% of bettors.",
                    pullQuote: "Discipline is sizing, tracking, control, and strategy. Three of the four are working against you."
                )
                .padding(.top, DS.Spacing.md)

                disciplineSection.padding(.top, DS.Spacing.xl)
                betiqSection.padding(.top, DS.Spacing.xl)
                insightProse.padding(.top, DS.Spacing.lg)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Discipline section

    private var disciplineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("DISCIPLINE SCORE \(report.analysis.disciplineScore?.total ?? 0)/100")
                .font(.custom("JetBrainsMono-Regular", size: 12))
                .monospacedDigit()
                .tracking(12 * 0.15)
                .foregroundStyle(DS.Color.Text.primary)

            VStack(spacing: 12) {
                if let d = report.analysis.disciplineScore {
                    disciplineRow("Tracking", value: d.tracking)
                    disciplineRow("Sizing",   value: d.sizing)
                    disciplineRow("Control",  value: d.control)
                    disciplineRow("Strategy", value: d.strategy)
                }
            }
            .padding(.top, DS.Spacing.md)

            Text("PERCENTILE: \(report.analysis.disciplineScore?.percentile ?? 0)")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .monospacedDigit()
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, DS.Spacing.md)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private func disciplineRow(_ label: String, value: Int) -> some View {
        let color = bandColor(for: value)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.Text.primary)
                Spacer()
                Text("\(value)/25")
                    .font(.custom("JetBrainsMono-Regular", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.Surface.raised)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(
                            width: geo.size.width * (Double(value) / 25.0),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
    }

    private func bandColor(for value: Int) -> Color {
        if value <= 7 { return DS.Color.Semantic.blood }
        if value <= 15 { return DS.Color.Accent.luminol }
        return DS.Color.Semantic.win
    }

    // MARK: - BetIQ section

    private var betiqSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("BETIQ SCORE \(report.analysis.betiq?.score ?? 0)/100")
                .font(.custom("JetBrainsMono-Regular", size: 12))
                .monospacedDigit()
                .tracking(12 * 0.15)
                .foregroundStyle(DS.Color.Text.primary)

            Text("Your skill assessment across six dimensions.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.top, 4)

            betiqHeroCard.padding(.top, DS.Spacing.md)
            betiqComponentTable.padding(.top, DS.Spacing.md)
        }
    }

    private var betiqHeroCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(report.analysis.betiq?.score ?? 0)")
                .font(.system(size: 56, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(archetypeColor)

            Text("\(report.analysis.betiq?.percentile ?? 0)TH PERCENTILE")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .monospacedDigit()
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, 4)

            Text(report.analysis.betiq?.interpretation ?? "")
                .font(.custom("Georgia-Italic", size: 15))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(4)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private var betiqComponentTable: some View {
        VStack(spacing: 0) {
            if let c = report.analysis.betiq?.components {
                componentRow("LINE VALUE",     value: c.lineValue,      max: 25, showDivider: true)
                componentRow("CALIBRATION",    value: c.calibration,    max: 20, showDivider: true)
                componentRow("SOPHISTICATION", value: c.sophistication, max: 15, showDivider: true)
                componentRow("SPECIALIZATION", value: c.specialization, max: 15, showDivider: true)
                componentRow("TIMING",         value: c.timing,         max: 10, showDivider: true)
                componentRow("CONFIDENCE",     value: c.confidence,     max: 15, showDivider: false)
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private func componentRow(_ label: String, value: Int, max: Int, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                Spacer()
                Text("\(value)/\(max)")
                    .font(.custom("JetBrainsMono-Regular", size: 15))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Text.primary)
            }
            .padding(.vertical, 12)

            if showDivider {
                Rectangle()
                    .fill(DS.Color.Border.subtle)
                    .frame(height: DS.Stroke.hairline)
            }
        }
    }

    // MARK: - Insight prose

    private var insightProse: some View {
        Text("Tracking is your strongest discipline subscore. Sizing and control are not. Fix sizing first; everything else follows from it.")
            .font(.system(size: 15))
            .foregroundStyle(DS.Color.Text.secondary)
            .lineSpacing(4)
            .padding(.top, DS.Spacing.sm)
    }
}

#Preview {
    ChapterYourDisciplineView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
