//
//  Callout.swift
//  BetAutopsy
//
//  3B component library: titled note block with semantic variants.
//  Generalizes the one-off callout family (InsightCallout's bordered
//  box, ElevatedRiskNote, BankrollHealthCallout) into one component:
//
//    .info    -> hairline border, neutral icon (notes, disclaimers)
//    .caution -> severity amber border + icon (elevated-tier notes)
//    .severe  -> severity red border + icon (critical warnings)
//
//  Severity amber, NOT brand yellow: callout variants are data/risk
//  semantics; brand yellow stays reserved for CTAs and chrome. The
//  optional CTA arm follows InsightCallout's caps-label + arrow
//  pattern (that one IS chrome, so it uses brand yellow).
//

import SwiftUI

struct Callout: View {
    enum Variant {
        case info, caution, severe

        var tint: Color {
            switch self {
            case .info:    return DS.Color.V3.textSecondary
            case .caution: return DS.Color.V3.Severity.yellow
            case .severe:  return DS.Color.V3.Severity.red
            }
        }

        var borderColor: Color {
            switch self {
            case .info:    return DS.Color.V3.borderSubtle
            case .caution: return DS.Color.V3.Severity.yellow.opacity(0.45)
            case .severe:  return DS.Color.V3.Severity.red.opacity(0.45)
            }
        }

        var borderWidth: CGFloat {
            self == .info ? DS.Stroke.hairline : 1
        }

        var iconSystemName: String {
            switch self {
            case .info:    return "info.circle"
            case .caution: return "exclamationmark.triangle"
            case .severe:  return "exclamationmark.octagon"
            }
        }
    }

    let variant: Variant
    var title: String? = nil
    let text: String
    var ctaLabel: String? = nil
    var onTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: variant.iconSystemName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(variant.tint)

                if let title, !title.isEmpty {
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(variant.tint)
                }
            }

            Text(text)
                .font(DS.Font.V3.insightBody)
                .foregroundStyle(DS.Color.V3.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let ctaLabel, let onTap {
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Text(ctaLabel.uppercased())
                            .font(DS.Font.V3.ctaText)
                            .tracking(1.4)
                            .foregroundStyle(DS.Color.Brand.yellow)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(DS.Color.Brand.yellow)
                    }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .accessibilityLabel(ctaLabel)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(variant.borderColor, lineWidth: variant.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        Callout(
            variant: .info,
            text: "Population benchmarks based on aggregate betting behavior research."
        )
        Callout(
            variant: .caution,
            title: "Heads up",
            text: "Your post-loss stake sizing ran hotter than 8 in 10 bettors this period."
        )
        Callout(
            variant: .severe,
            title: "Pattern alert",
            text: "Three heated sessions this month ended past 2am with escalating stakes.",
            ctaLabel: "Read the heated file",
            onTap: {}
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
