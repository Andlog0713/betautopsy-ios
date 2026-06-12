//
//  StreakInfluenceCard.swift
//  BetAutopsy
//
//  Three-column stake comparison: neutral baseline vs post 3-win streak
//  vs post 3-loss streak. Tinted green/red when the streak-context
//  average diverges from neutral by 10% or more. Used in Ch 3 below
//  the worst/best annotated bet pair.
//
//  Snapshot mode replaces each dollar value with a small LockedDollarBar.
//

import SwiftUI

struct StreakInfluenceCard: View {
    let influence: StreakInfluence
    var isLocked: Bool = false
    var onLockedTap: (() -> Void)? = nil

    private let lockedBarWidth: CGFloat = 64

    private var winTint: Color {
        if isLocked { return DS.Color.V3.textPrimary }
        if influence.avgStakeNeutral <= 0 { return DS.Color.V3.textPrimary }
        let ratio = influence.avgStakeAfterWinStreak3 / influence.avgStakeNeutral
        return ratio >= 1.1 ? DS.Color.V3.Severity.green : DS.Color.V3.textPrimary
    }

    private var lossTint: Color {
        if isLocked { return DS.Color.V3.textPrimary }
        if influence.avgStakeNeutral <= 0 { return DS.Color.V3.textPrimary }
        let ratio = influence.avgStakeAfterLossStreak3 / influence.avgStakeNeutral
        return ratio >= 1.1 ? DS.Color.V3.Severity.red : DS.Color.V3.textPrimary
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STAKE BY STREAK CONTEXT")
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)

            HStack(alignment: .top, spacing: 0) {
                column(
                    caption: "NEUTRAL",
                    value: influence.avgStakeNeutral,
                    tint: DS.Color.V3.textPrimary
                )
                V3Divider()
                    .frame(width: DS.Stroke.hairline, height: 44)
                    .padding(.horizontal, 8)
                column(
                    caption: "AFTER 3 WINS",
                    value: influence.avgStakeAfterWinStreak3,
                    tint: winTint
                )
                V3Divider()
                    .frame(width: DS.Stroke.hairline, height: 44)
                    .padding(.horizontal, 8)
                column(
                    caption: "AFTER 3 LOSSES",
                    value: influence.avgStakeAfterLossStreak3,
                    tint: lossTint
                )
            }
            .frame(maxWidth: .infinity)
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
    private func column(caption: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(DS.Color.V3.textTertiary)

            if isLocked {
                LockedDollarBar(width: lockedBarWidth, onTap: { onLockedTap?() })
            } else {
                Text(BAFormat.currency(value))
                    .font(DS.Font.V3.rowValue)
                    .monospacedDigit()
                    .foregroundStyle(tint)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        StreakInfluenceCard(influence: StreakInfluence(
            avgStakeNeutral: 122,
            avgStakeAfterWinStreak3: 168,
            avgStakeAfterLossStreak3: 244
        ))
        StreakInfluenceCard(
            influence: StreakInfluence(
                avgStakeNeutral: 122,
                avgStakeAfterWinStreak3: 168,
                avgStakeAfterLossStreak3: 244
            ),
            isLocked: true
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
