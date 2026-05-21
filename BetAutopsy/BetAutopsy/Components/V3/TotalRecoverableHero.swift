//
//  TotalRecoverableHero.swift
//  BetAutopsy
//
//  Chapter 1 hero: the single dollar figure that summarizes how much
//  money the detected biases and strategic leaks left on the table.
//
//  FULL MODE ONLY (D1 lock, REBUILD-PHASE-1). The number is a client-side
//  port of web's AutopsyReport.tsx totalRecoverable formula. In snapshot
//  mode every dollar input (avg_stake, estimated_cost, leak costs) is
//  redacted to 0 by the engine, so a real figure is unavailable and the
//  hero hides entirely. There is no engine `total_recoverable` wire field;
//  adding one is deferred (no engine work this phase).
//
//  Compute (full mode):
//    bias term  = |estimatedCost|, else avgStake x severityMultiplier
//                 (critical 8 / high 5 / medium 3 / low 1) when cost is 0
//    leak term  = |roiImpact / 100 x avgStake x sampleSize|  (fallback only;
//                 iOS has no raw bets array for web's matched-bet path)
//    dedup overlapping bias/leak (keep higher cost), sum.
//
//  Surface conventions match DamagesCard: surfaceCard bg, 0.5pt
//  borderSubtle stroke, 12pt continuous corner radius. Dollar value in
//  JetBrains Mono per the type system (every figure that can change).
//

import SwiftUI

struct TotalRecoverableHero: View {
    let report: AutopsyReport

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    /// Client-side port of web's totalRecoverable. Returns 0 when no
    /// dollar-bearing input survives (which is always true in snapshot,
    /// where avg_stake and estimated_cost are redacted to 0).
    private var totalRecoverable: Int {
        Int(TotalRecoverable.compute(for: report.analysis).rounded())
    }

    var body: some View {
        // FULL MODE ONLY. Snapshot hides entirely (D1: inputs are redacted
        // to 0 and there is no engine aggregate to fall back on).
        if !isSnapshot, totalRecoverable > 0 {
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL RECOVERABLE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(10 * 0.18)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Text(dollarString)
                    .font(.custom("JetBrainsMono-Bold", size: 40))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("Money left on the table from your detected leaks and biases. Some overlap.")
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Total recoverable, \(totalRecoverable) dollars left on the table.")
        }
    }

    private var dollarString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: totalRecoverable)) ?? "\(totalRecoverable)"
        return "$\(formatted)"
    }
}

/// Client-side totalRecoverable computation, factored out so it can be
/// unit-reasoned and reused. Mirrors web's AutopsyReport.tsx formula,
/// including the bias/leak overlap de-duplication (keep higher cost).
enum TotalRecoverable {
    private struct Item {
        let name: String
        let cost: Double
    }

    /// Curated bias-keyword <-> leak-keyword overlap pairs, ported verbatim
    /// from web's OVERLAP_KEYWORDS. A bias and leak overlap when the bias
    /// name matches any keyword in the first list and the leak category
    /// matches any in the second.
    private static let overlapKeywords: [([String], [String])] = [
        (["parlay"], ["parlay"]),
        (["post-loss", "post loss", "chase", "chasing", "escalat"],
         ["post-loss", "post loss", "chase", "chasing", "escalat", "tilt"]),
        (["recency"], ["recency", "recent"]),
        (["favorite", "favourite"], ["favorite", "favourite", "chalk"]),
        (["prop"], ["prop"]),
        (["live", "in-game", "in game"], ["live", "in-game", "in game"]),
        (["late night", "late-night"], ["late night", "late-night"]),
        (["underdog"], ["underdog"]),
    ]

    static func compute(for analysis: AutopsyAnalysis) -> Double {
        let avgStake = analysis.summary.avgStake

        // Bias term.
        var biasItems: [Item] = []
        for bias in analysis.biasesDetected {
            let raw = abs(bias.estimatedCost)
            let cost: Double
            if raw != 0 {
                cost = raw
            } else if avgStake > 0 {
                cost = avgStake * severityMultiplier(bias.severity)
            } else {
                cost = 0
            }
            if cost > 0 { biasItems.append(Item(name: bias.biasName, cost: cost)) }
        }

        // Leak term. iOS lacks the raw bets array web matches against, so
        // only the roi_impact fallback path is available.
        var leakItems: [Item] = []
        for leak in analysis.strategicLeaks where leak.roiImpact < 0 {
            guard leak.sampleSize > 0, avgStake > 0 else { continue }
            let cost = abs(leak.roiImpact / 100 * avgStake * Double(leak.sampleSize))
            if cost > 0 { leakItems.append(Item(name: leak.category, cost: cost)) }
        }

        // De-duplicate overlapping bias/leak pairs: keep the higher cost,
        // drop the other so its dollars are not counted twice.
        var droppedBias = Set<Int>()
        var droppedLeak = Set<Int>()
        for (bi, bias) in biasItems.enumerated() {
            let biasLower = bias.name.lowercased()
            for (li, leak) in leakItems.enumerated() {
                let leakLower = leak.name.lowercased()
                let overlaps = overlapKeywords.contains { (biasKws, leakKws) in
                    biasKws.contains { biasLower.contains($0) }
                        && leakKws.contains { leakLower.contains($0) }
                }
                if overlaps {
                    if bias.cost >= leak.cost { droppedLeak.insert(li) }
                    else { droppedBias.insert(bi) }
                }
            }
        }

        let biasSum = biasItems.enumerated()
            .filter { !droppedBias.contains($0.offset) }
            .reduce(0.0) { $0 + $1.element.cost }
        let leakSum = leakItems.enumerated()
            .filter { !droppedLeak.contains($0.offset) }
            .reduce(0.0) { $0 + $1.element.cost }

        return biasSum + leakSum
    }

    private static func severityMultiplier(_ severity: BiasSeverity) -> Double {
        switch severity {
        case .critical: return 8
        case .high:     return 5
        case .medium:   return 3
        case .low:      return 1
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        TotalRecoverableHero(report: MockReport.heatedBettor)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
