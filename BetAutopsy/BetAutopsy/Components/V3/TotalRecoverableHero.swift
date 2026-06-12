//
//  TotalRecoverableHero.swift
//  BetAutopsy
//
//  Chapter 1 hero: the recoverable-money range. NON-ADDITIVE since 3B:
//  the old client-side sum of every bias and leak (web's retired
//  totalRecoverable formula) double-counted overlapping findings and
//  contradicted the engine's recovery object - the exact defect web
//  PR #74 killed. The additive sum never renders again, for any
//  report vintage.
//
//  Sources, in order (same data the Findings DollarImpactCard shows,
//  so the two surfaces can never contradict):
//    1. analysis.recovery rangeLow-rangeHigh (full v3 reports)
//    2. the single LARGEST prioritized leak, rounded through
//       RecoveryRange (web's roundRecoveryRange) - pre-#74 reports
//    3. neither -> hides entirely (snapshots: every dollar input is
//       redacted and recovery is absent)
//
//  Surface conventions match DamagesCard: surfaceCard bg, 0.5pt
//  borderSubtle stroke, 12pt continuous corner radius. Dollar value in
//  JetBrains Mono per the type system (every figure that can change).
//

import SwiftUI

struct TotalRecoverableHero: View {
    let report: AutopsyReport

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var range: (low: Double, high: Double)? {
        if let recovery = report.analysis.recovery {
            return (recovery.rangeLow, recovery.rangeHigh)
        }
        if let leak = TotalRecoverable.ranked(for: report.analysis).first?.costDollars,
           leak > 0 {
            let rounded = RecoveryRange.rounded(from: leak)
            return (rounded.low, rounded.high)
        }
        return nil
    }

    var body: some View {
        // FULL MODE ONLY. Snapshot hides entirely (recovery is absent and
        // every leak dollar input is redacted to 0).
        if !isSnapshot, let range {
            VStack(alignment: .leading, spacing: 4) {
                Text("RECOVERABLE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(10 * 0.18)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Text("~\(BAFormat.currency(range.low))-\(BAFormat.currency(range.high))")
                    .font(.custom("JetBrainsMono-Bold", size: 40))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("What a single change could have kept. Not every fix stacked.")
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
            .accessibilityLabel(
                "Recoverable, roughly \(BAFormat.currency(range.low)) to \(BAFormat.currency(range.high)). What a single change could have kept."
            )
        }
    }
}

/// One entry in the ranked leak/bias fix-sequence. Carries the full
/// payload the LeakPrioritizerCard needs (REBUILD-PHASE-2.5 surface #4),
/// not just the dollar figure the hero sums.
enum PrioritizedItemType: String {
    case bias
    case leak
}

struct PrioritizedItem: Identifiable {
    let rank: Int
    let name: String
    let type: PrioritizedItemType
    let costDollars: Double
    let costVisibility: String?
    let detail: String?
    let fix: String?

    var id: String { "\(type.rawValue)-\(name)" }
}

/// Client-side leak/bias prioritization, factored out so it can be
/// unit-reasoned and reused. Mirrors web's AutopsyReport.tsx ranking,
/// including the bias/leak overlap de-duplication (keep higher cost).
///
/// `ranked(for:)` returns the dedup'd + sorted fix-sequence consumed by
/// LeakPrioritizerCard, and its LARGEST entry feeds the recovery-range
/// fallback on pre-#74 reports. The old `compute(for:)` additive sum was
/// REMOVED in 3B (the defect web PR #74 retired); do not reintroduce a
/// summed total from this list.
enum TotalRecoverable {
    /// Intermediate item carrying cost + the display payload, before
    /// dedup and ranking.
    private struct Candidate {
        let name: String
        let type: PrioritizedItemType
        let cost: Double
        let costVisibility: String?
        let detail: String?
        let fix: String?
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

    /// Dedup'd, cost-descending fix-sequence of every dollar-bearing bias
    /// and leak. Empty in snapshot mode (every dollar input is redacted to
    /// 0, so no candidate survives the cost > 0 filter).
    static func ranked(for analysis: AutopsyAnalysis) -> [PrioritizedItem] {
        let avgStake = analysis.summary.avgStake

        // Bias term.
        var biasItems: [Candidate] = []
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
            if cost > 0 {
                biasItems.append(Candidate(
                    name: bias.biasName,
                    type: .bias,
                    cost: cost,
                    costVisibility: bias.estimatedCostVisibility,
                    detail: bias.description,
                    fix: bias.fix
                ))
            }
        }

        // Leak term. iOS lacks the raw bets array web matches against, so
        // only the roi_impact fallback path is available.
        var leakItems: [Candidate] = []
        for leak in analysis.strategicLeaks where leak.roiImpact < 0 {
            guard leak.sampleSize > 0, avgStake > 0 else { continue }
            let cost = abs(leak.roiImpact / 100 * avgStake * Double(leak.sampleSize))
            if cost > 0 {
                leakItems.append(Candidate(
                    name: leak.category,
                    type: .leak,
                    cost: cost,
                    costVisibility: leak.detailVisibility,
                    detail: leak.detail,
                    fix: leak.suggestion
                ))
            }
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

        let survivors = biasItems.enumerated()
            .filter { !droppedBias.contains($0.offset) }
            .map { $0.element }
            + leakItems.enumerated()
                .filter { !droppedLeak.contains($0.offset) }
                .map { $0.element }

        return survivors
            .sorted { $0.cost > $1.cost }
            .enumerated()
            .map { index, candidate in
                PrioritizedItem(
                    rank: index + 1,
                    name: candidate.name,
                    type: candidate.type,
                    costDollars: candidate.cost,
                    costVisibility: candidate.costVisibility,
                    detail: candidate.detail,
                    fix: candidate.fix
                )
            }
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
