//
//  ChapterYourMindView.swift
//  BetAutopsy
//
//  Chapter 2: emotion score breakdown. EnhancedTilt signals rendered as a
//  six-axis radar, EmotionBreakdown as four /25 bars, worst trigger callout,
//  and pertinent-negative cards for strengths visible in the data.
//

import SwiftUI

struct ChapterYourMindView: View {
    let report: AutopsyReport

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ChapterHeader(
                    chipText: "YOUR MIND",
                    alertChip: (
                        text: "EMOTIONAL RISK: \(report.analysis.enhancedTilt?.riskLevel.uppercased() ?? "")",
                        color: DS.Color.Semantic.blood
                    ),
                    title: "Your emotional sizing is the leak.",
                    pullQuote: "Your emotion score is in the 92nd percentile. That is the bet itself, not the bets you placed."
                )
                .padding(.top, DS.Spacing.md)

                emotionHero.padding(.top, DS.Spacing.xl)
                emotionBreakdown.padding(.top, DS.Spacing.xl)
                sixSignalsRadar.padding(.top, DS.Spacing.xl)
                worstTriggerCard.padding(.top, DS.Spacing.lg)
                pertinentNegatives.padding(.top, DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Emotion hero

    private var emotionHero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("EMOTION SCORE")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("\(report.analysis.emotionScore)")
                .font(.system(size: 56, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(DS.Color.Semantic.blood)
                .padding(.top, 4)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.Surface.raised)
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.Semantic.blood)
                        .frame(
                            width: geo.size.width
                                   * (Double(report.analysis.emotionScore) / 100.0),
                            height: 8
                        )
                }
            }
            .frame(height: 8)
            .padding(.top, 12)

            Text("\(report.analysis.enhancedTilt?.percentile ?? 0)TH PERCENTILE")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, 8)
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

    // MARK: - Emotion breakdown

    private var emotionBreakdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WHAT DRIVES IT")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            if let bd = report.analysis.emotionBreakdown {
                VStack(spacing: 12) {
                    breakdownRow("Stake volatility", value: bd.stakeVolatility)
                    breakdownRow("Loss chasing",     value: bd.lossChasing)
                    breakdownRow("Streak behavior",  value: bd.streakBehavior)
                    breakdownRow("Session discipline", value: bd.sessionDiscipline)
                }
                .padding(.top, DS.Spacing.md)
            }
        }
    }

    private func breakdownRow(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.Text.primary)
                Spacer()
                Text("\(value)/25")
                    .font(.custom("JetBrainsMono-Regular", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Semantic.blood)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DS.Color.Surface.raised)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DS.Color.Semantic.blood)
                        .frame(
                            width: geo.size.width * (Double(value) / 25.0),
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Six-signal radar

    private var sixSignalsRadar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SIX SIGNALS")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("How the score breaks down across six behavioral dimensions.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.top, 4)

            if let signals = report.analysis.enhancedTilt?.signals {
                radarChart(signals: signals)
                    .frame(width: 280, height: 280)
                    .frame(maxWidth: .infinity)
                    .padding(.top, DS.Spacing.md)
            }
        }
    }

    private func radarChart(signals: TiltSignals) -> some View {
        let values: [Int] = [
            signals.betSizingVolatility, signals.lossReaction,
            signals.streakBehavior, signals.sessionDiscipline,
            signals.sessionAcceleration, signals.oddsDriftAfterLoss
        ]
        let labels = ["SIZING VOL", "LOSS REACTION", "STREAK",
                      "SESSION DISC", "ACCELERATION", "ODDS DRIFT"]

        return GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let maxRadius = size / 2 - 40

            ZStack {
                ForEach(1..<5) { ring in
                    let r = maxRadius * (CGFloat(ring) / 4.0)
                    Circle()
                        .stroke(DS.Color.Border.subtle.opacity(0.3),
                                lineWidth: DS.Stroke.hairline)
                        .frame(width: r * 2, height: r * 2)
                        .position(center)
                }

                ForEach(0..<6) { i in
                    let angle = -Double.pi / 2 + Double(i) * (2 * Double.pi / 6)
                    let endX = center.x + CGFloat(cos(angle)) * maxRadius
                    let endY = center.y + CGFloat(sin(angle)) * maxRadius
                    Path { p in
                        p.move(to: center)
                        p.addLine(to: CGPoint(x: endX, y: endY))
                    }
                    .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
                }

                Path { p in
                    for i in 0..<6 {
                        let angle = -Double.pi / 2 + Double(i) * (2 * Double.pi / 6)
                        let v = CGFloat(values[i]) / 25.0
                        let x = center.x + CGFloat(cos(angle)) * maxRadius * v
                        let y = center.y + CGFloat(sin(angle)) * maxRadius * v
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else      { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    p.closeSubpath()
                }
                .fill(DS.Color.Semantic.blood.opacity(0.22))

                Path { p in
                    for i in 0..<6 {
                        let angle = -Double.pi / 2 + Double(i) * (2 * Double.pi / 6)
                        let v = CGFloat(values[i]) / 25.0
                        let x = center.x + CGFloat(cos(angle)) * maxRadius * v
                        let y = center.y + CGFloat(sin(angle)) * maxRadius * v
                        if i == 0 { p.move(to: CGPoint(x: x, y: y)) }
                        else      { p.addLine(to: CGPoint(x: x, y: y)) }
                    }
                    p.closeSubpath()
                }
                .stroke(DS.Color.Semantic.blood, lineWidth: 1.5)

                ForEach(0..<6) { i in
                    let angle = -Double.pi / 2 + Double(i) * (2 * Double.pi / 6)
                    let labelR = maxRadius + 20
                    let x = center.x + CGFloat(cos(angle)) * labelR
                    let y = center.y + CGFloat(sin(angle)) * labelR
                    Text(labels[i])
                        .font(.custom("JetBrainsMono-Regular", size: 9))
                        .tracking(9 * 0.15)
                        .foregroundStyle(DS.Color.Text.tertiary)
                        .position(x: x, y: y)
                }
            }
        }
    }

    // MARK: - Worst trigger

    private var worstTriggerCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WORST TRIGGER")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
            Text(report.analysis.enhancedTilt?.worstTrigger ?? "")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
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

    // MARK: - Pertinent negatives

    private var pertinentNegatives: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("WHAT YOU DON'T DO")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("Strengths visible in the data that most bettors lack.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.bottom, DS.Spacing.xs)

            ForEach(report.analysis.pertinentNegatives ?? []) { pn in
                VStack(alignment: .leading, spacing: 4) {
                    Text(pn.pattern.uppercased())
                        .font(.custom("JetBrainsMono-Regular", size: 10))
                        .tracking(10 * 0.15)
                        .foregroundStyle(DS.Color.Text.tertiary)

                    Text(pn.finding)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Color.Text.primary)
                        .padding(.top, 4)

                    Text(pn.detail)
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.Text.secondary)
                        .lineSpacing(3)
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
        }
    }
}

#Preview {
    ChapterYourMindView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
