//
//  BankrollHealthCallout.swift
//  BetAutopsy
//
//  Surfaces the engine's bankrollHealth signal, which ships on the wire
//  but had no iOS render surface before REBUILD-PHASE-1.
//
//  Renders ONLY when health is not .healthy:
//    .danger  -> red left border + inline 1-800-MY-RESET responsible-use line
//    .caution -> yellow left border, no helpline line
//    .healthy -> EmptyView (nothing to flag)
//
//  Left-border accent + surfaceCard body matches the era's callout idiom
//  (StrategicLeakCard, ContradictionCard). 0.5pt hairline elsewhere.
//

import SwiftUI

struct BankrollHealthCallout: View {
    let health: BankrollHealth

    private var accent: Color { health.color }

    private var headline: String {
        switch health {
        case .danger:  return "Bankroll under strain."
        case .caution: return "Bankroll worth watching."
        case .healthy: return ""
        }
    }

    private var body_: String {
        switch health {
        case .danger:
            return "Your stake sizing relative to your results points to bankroll stress. This is the pattern that precedes the sessions people regret."
        case .caution:
            return "Stake sizing is drifting relative to your results. Worth keeping an eye on before it compounds."
        case .healthy:
            return ""
        }
    }

    var body: some View {
        if health != .healthy {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(accent)
                    .frame(width: 3)

                VStack(alignment: .leading, spacing: 6) {
                    Text(health.label)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(10 * 0.18)
                        .foregroundStyle(accent)

                    Text(headline)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(body_)
                        .font(DS.Font.V3.bodyRegular)
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if health == .danger {
                        helplineLine
                            .padding(.top, 2)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .combine)
        }
    }

    private var helplineLine: some View {
        (
            Text("If gambling has stopped being fun, call ")
                .foregroundStyle(DS.Color.V3.textSecondary)
            + Text("1-800-MY-RESET")
                .foregroundStyle(DS.Color.V3.textPrimary)
        )
        .font(DS.Font.V3.captionLabel)
        .lineSpacing(2)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        BankrollHealthCallout(health: .danger)
        BankrollHealthCallout(health: .caution)
        BankrollHealthCallout(health: .healthy) // renders nothing
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
