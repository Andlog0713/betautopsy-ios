//
//  DollarImpactCard.swift
//  BetAutopsy
//
//  3B component library: the iOS twin of the web recovery display
//  (web PR #74). Shows the engine's NON-ADDITIVE recoverable range,
//  the single most effective method, and the verified net.
//
//  THE NEVER-ADDITIVE INVARIANT LIVES HERE: this component renders the
//  engine's single-best-method range (or a rounded range from the
//  single largest leak as fallback). It never sums leaks or biases,
//  and no additive total may be reintroduced upstream of it. The
//  client-side additive sum (the old TotalRecoverableHero formula) is
//  the exact defect web PR #74 retired.
//
//  Sources, in order:
//    1. analysis.recovery (full reports, schema_version >= 3)
//    2. fallbackLargestLeakUSD (pre-#74 reports: the single largest
//       prioritized leak, rounded through the same range math web
//       uses - roundRecoveryRange, lib/engine/recovery.ts)
//    3. neither -> renders nothing (snapshots, empty reports)
//

import SwiftUI

/// Swift mirror of web's roundRecoveryRange (lib/engine/recovery.ts:38).
/// Same step thresholds and 0.8x / 1.2x bounds so a pre-#74 report shows
/// the same range iOS-side as the web engine would compute.
enum RecoveryRange {
    static func rounded(from value: Double) -> (low: Double, high: Double) {
        let step: Double = value >= 10_000 ? 1_000 : (value >= 2_000 ? 500 : 100)
        let low = max(0, (value * 0.8 / step).rounded(.down) * step)
        let high = max(step, (value * 1.2 / step).rounded(.up) * step)
        return (low, high)
    }
}

struct DollarImpactCard: View {
    let recovery: ReportRecovery?
    var fallbackLargestLeakUSD: Double? = nil

    private struct Display {
        let rangeLow: Double
        let rangeHigh: Double
        let methodLine: String
        let netUSD: Double?
    }

    private var display: Display? {
        if let recovery {
            return Display(
                rangeLow: recovery.rangeLow,
                rangeHigh: recovery.rangeHigh,
                methodLine: Self.methodLabel(recovery.method),
                netUSD: recovery.netUSD
            )
        }
        if let leak = fallbackLargestLeakUSD, leak > 0 {
            let range = RecoveryRange.rounded(from: leak)
            return Display(
                rangeLow: range.low,
                rangeHigh: range.high,
                methodLine: "from your single largest leak",
                netUSD: nil
            )
        }
        return nil
    }

    /// Human labels for the four method enums. Unknown future methods
    /// fall back to generic copy rather than leaking a raw enum string.
    private static func methodLabel(_ method: String) -> String {
        switch method {
        case "flat_staking":               return "flat staking at your median bet"
        case "no_long_parlays":            return "cutting 4+ leg parlays"
        case "profitable_categories_only": return "sticking to profitable categories"
        case "exit_worst_category":        return "exiting your worst category"
        default:                           return "the single change in this report"
        }
    }

    var body: some View {
        if let display {
            VStack(alignment: .leading, spacing: 8) {
                Text("RECOVERABLE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Text("~\(BAFormat.currency(display.rangeLow))-\(BAFormat.currency(display.rangeHigh))")
                    .font(.custom("JetBrainsMono-Bold", size: 28))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("One change, not a stack: \(display.methodLine).")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let net = display.netUSD {
                    Text("Verified against your \(BAFormat.currency(net, signed: true)) net over the analyzed period.")
                        .font(.system(size: 12))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "Recoverable, roughly \(BAFormat.currency(display.rangeLow)) to \(BAFormat.currency(display.rangeHigh)), \(display.methodLine)."
            )
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        // Full v3 report: engine recovery object.
        DollarImpactCard(recovery: ReportRecovery(
            biggestSingleLeakUSD: 17971,
            method: "profitable_categories_only",
            overlapsExist: true,
            rangeLow: 14000,
            rangeHigh: 22000,
            netUSD: -7862
        ))
        // Pre-#74 report: rounded range from the largest leak.
        DollarImpactCard(recovery: nil, fallbackLargestLeakUSD: 4087)
        // Neither: renders nothing (snapshot).
        DollarImpactCard(recovery: nil)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
