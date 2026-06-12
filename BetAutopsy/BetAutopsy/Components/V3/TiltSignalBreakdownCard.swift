//
//  TiltSignalBreakdownCard.swift
//  BetAutopsy
//
//  Six-row breakdown card surfacing the engine's enhanced_tilt signals
//  on Ch 2 (The Heated File). Each row pairs a labeled SF Symbol with a
//  severity-coded bar + numeric score. Engine ships these scores; iOS
//  was ignoring them before Mega-PR B.
//
//  Rendered after the heated session list (full mode) or the single
//  HeatedSessionPreviewCard (snapshot mode), before the InsightCallout.
//  Concrete evidence reads before the abstract aggregate.
//

import SwiftUI

struct TiltSignalBreakdownCard: View {
    let signals: TiltSignals
    let worstTrigger: String?

    private struct Row {
        let icon: String
        let label: String
        let score: Int
    }

    private var rows: [Row] {
        [
            Row(icon: "dollarsign.arrow.circlepath",      label: "BET SIZING VOLATILITY", score: signals.betSizingVolatility),
            Row(icon: "arrow.down.heart.fill",            label: "LOSS REACTION",         score: signals.lossReaction),
            Row(icon: "chart.line.uptrend.xyaxis",        label: "STREAK BEHAVIOR",       score: signals.streakBehavior),
            Row(icon: "timer",                            label: "SESSION DISCIPLINE",    score: signals.sessionDiscipline),
            Row(icon: "gauge.with.dots.needle.67percent", label: "SESSION ACCELERATION",  score: signals.sessionAcceleration),
            Row(icon: "scope",                            label: "ODDS DRIFT AFTER LOSS", score: signals.oddsDriftAfterLoss)
        ]
    }

    private var trimmedTrigger: String? {
        guard let t = worstTrigger?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !t.isEmpty else { return nil }
        return t
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SIGNAL BREAKDOWN")
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .padding(.bottom, 12)

            ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                signalRow(row)
                if index < rows.count - 1 {
                    V3Divider()
                }
            }

            if let trigger = trimmedTrigger {
                Text(trigger)
                    .font(DS.Font.V3.bodyRegular)
                    .italic()
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
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
    private func signalRow(_ row: Row) -> some View {
        let tint = DS.Color.V3.Severity.zoneColor(forScore: row.score, higherIsWorse: true)
        HStack(spacing: 12) {
            Image(systemName: row.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .frame(width: 16)

            Text(row.label)
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.1)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 8)

            severityBar(score: row.score, tint: tint)
                .frame(maxWidth: 80)

            Text(BAFormat.score(row.score, outOf: 100))
                .font(DS.Font.V3.rowValue)
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.label) score \(row.score) out of 100")
    }

    @ViewBuilder
    private func severityBar(score: Int, tint: Color) -> some View {
        let clamped = max(0, min(100, score))
        let ratio = CGFloat(clamped) / 100
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(DS.Color.V3.borderSubtle)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, geo.size.width * ratio))
            }
        }
        .frame(height: 8)
    }
}

#if DEBUG
#Preview {
    TiltSignalBreakdownCard(
        signals: TiltSignals(
            betSizingVolatility: 78,
            lossReaction: 84,
            streakBehavior: 41,
            sessionDiscipline: 72,
            sessionAcceleration: 66,
            oddsDriftAfterLoss: 58
        ),
        worstTrigger: "Sunday-night NFL losses drove your largest stake escalations."
    )
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
