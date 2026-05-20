//
//  StrategicLeakCard.swift
//  BetAutopsy
//
//  Single-leak card used in Ch 4 (The Bias Sheet) under the new
//  WHERE YOU BLEED section. Category + ROI badge + sample size on top;
//  detail prose; FIX prose below. No dollar field on the model; the
//  engine writes any dollar reference into the detail prose itself
//  (so snapshot mode collapses to first sentence + LockedDollarBar).
//

import SwiftUI

struct StrategicLeakCard: View {
    let leak: StrategicLeak
    var isLockedDetail: Bool = false
    var onLockedTap: (() -> Void)? = nil

    private var roiTint: Color {
        if leak.roiImpact <= -15 { return DS.Color.V3.Severity.red }
        if leak.roiImpact <= -10 { return DS.Color.V3.Severity.orange }
        if leak.roiImpact <= -5  { return DS.Color.V3.Severity.yellow }
        return DS.Color.V3.Severity.gray
    }

    private var showFix: Bool {
        !leak.suggestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && leak.suggestionVisibility != "hidden"
    }

    private var showDetail: Bool {
        leak.detailVisibility != "hidden"
            && !leak.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var roiLabel: String {
        let value = leak.roiImpact
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        let str = formatter.string(from: NSNumber(value: abs(value))) ?? "0.0"
        let sign = value < 0 ? "-" : "+"
        return "\(sign)\(str)%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Text(leak.category.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                roiBadge
            }

            Text("\(leak.sampleSize) bets")
                .font(.system(size: 13, weight: .regular))
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textSecondary)

            V3Divider()

            detailBlock

            // FIX block gated entirely (blocker #9): snapshot ships
            // suggestion="" + suggestion_visibility="hidden", so the label
            // must not render an empty prose body.
            if showFix {
                Text("FIX")
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.4)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .padding(.top, 4)

                Text(leak.suggestion)
                    .font(DS.Font.V3.bodyRegular)
                    .italic()
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var roiBadge: some View {
        Text(roiLabel)
            .font(.system(size: 12, weight: .bold))
            .monospacedDigit()
            .tracking(0.5)
            .foregroundStyle(roiTint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous)
                    .fill(roiTint.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous)
                            .stroke(roiTint, lineWidth: DS.Stroke.hairline)
                    )
            )
    }

    @ViewBuilder
    private var detailBlock: some View {
        if isLockedDetail {
            VStack(alignment: .leading, spacing: 8) {
                if showDetail {
                    Text(leak.detail.firstSentences(1))
                        .font(DS.Font.V3.bodyRegular)
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 8) {
                    Text("DOLLAR DAMAGE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.V3.Severity.red)
                    LockedDollarBar(width: 110, onTap: { onLockedTap?() })
                }
            }
        } else if showDetail {
            Text(leak.detail)
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        StrategicLeakCard(leak: StrategicLeak(
            category: "Slight Favorite (-110 to -199) Bets",
            detail: "You staked $42,180 across 2,293 bets at slight-favorite prices and lost $46,927. That's a -18.7% ROI in the largest category you bet, despite winning the underlying matchup the majority of the time. The juice is the leak, not the picks.",
            roiImpact: -18.7,
            sampleSize: 2293,
            suggestion: "Skip -150 to -199 single-bet juice entirely. Consider 2-leg parlays of independent positive-EV legs instead, or wait for the dog price."
        ))
        StrategicLeakCard(
            leak: StrategicLeak(
                category: "Slight Favorite (-110 to -199) Bets",
                detail: "You staked $42,180 across 2,293 bets at slight-favorite prices and lost $46,927. That's a -18.7% ROI in the largest category you bet, despite winning the underlying matchup the majority of the time. The juice is the leak, not the picks.",
                roiImpact: -18.7,
                sampleSize: 2293,
                suggestion: "Skip -150 to -199 single-bet juice entirely."
            ),
            isLockedDetail: true
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
