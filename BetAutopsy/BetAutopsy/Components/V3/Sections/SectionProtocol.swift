//
//  SectionProtocol.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2.5 surface #6: the playbook section, inserted between
//  SectionSports and SectionAction. Holds the "3 Moves" card ported from
//  web's TL;DR (AutopsyReport.tsx 2627-2694): STOP / START / CONTINUE,
//  each derived client-side from the analysis the report already carries.
//
//  Web's PRESCRIBED PROTOCOL (recommendations) is already rendered by
//  SectionAction, and personal_rules is not on the iOS wire, so this
//  section is intro prose + the 3-Moves card only.
//
//  Sourcing (degraded gracefully where iOS lacks a field):
//    STOP     - strategic_leaks by worst ROI, plus a late-night pattern
//    START    - positive behavioral_patterns (web also uses
//               edge_profile.profitable_areas, which is not on the iOS
//               wire, so START is positive-patterns only)
//    CONTINUE - pertinent_negatives mapped to a positive phrasing, plus
//               an emotional-discipline note when emotion is controlled
//
//  Snapshot follows web's full-only gate: the whole card is locked behind
//  a teaser (no partial reveal).
//

import SwiftUI

struct SectionProtocol: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var moves: ThreeMovesCard.Moves {
        ThreeMovesCard.Moves(analysis: report.analysis)
    }

    /// The control system iff this full report is at the recovery tier.
    /// nil on snapshots (controlSystem absent), pre-#71 reports, and the
    /// none/elevated tiers. The recovery card + support resources surface
    /// ONLY here (recovery tier), matching web's message-fatigue gating.
    private var recoveryControlSystem: ReportControlSystem? {
        guard !isSnapshot,
              let cs = report.analysis.controlSystem,
              cs.effectiveRiskTier == .recovery else { return nil }
        return cs
    }

    var body: some View {
        if isSnapshot {
            VStack(alignment: .leading, spacing: 0) {
                header
                lockedTeaser.padding(.top, 16)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        } else if recoveryControlSystem != nil || moves.hasContent {
            VStack(alignment: .leading, spacing: 0) {
                if let recoveryControlSystem {
                    RecoveryRecommendationCard(controlSystem: recoveryControlSystem)
                    if moves.hasContent {
                        Spacer().frame(height: 24)
                    }
                }
                if moves.hasContent {
                    header
                    ThreeMovesCard(moves: moves).padding(.top, 16)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("THE PLAYBOOK")
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text("Three moves, pulled from your own data: what to stop, what to do more of, and what to keep.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lockedTeaser: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                Text("Your three moves: what to stop, start, and keep.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Quiet tappable affordance (the lock icon already sits in the
            // header row above). Replaces the second of three stacked
            // solid-yellow "Read the full report" buttons; the single primary
            // CTA now lives only on SectionAction's terminal card. The whole
            // card taps through to the same paywall source.
            HStack(spacing: 8) {
                Text("See your three moves (\(RevenueCatStore.shared.priceString)).")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.Brand.yellow)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
            .padding(.top, 14)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { onPaywallTap("section_protocol_locked_card_tap") }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("Your three moves: what to stop, start, and keep. See them in the full report for nineteen dollars and ninety-nine cents.")
    }
}

// MARK: - ThreeMovesCard

/// STOP / START / CONTINUE, stacked vertically (web's 3-col grid does not
/// fit iPhone width). Each sub-card is a colored left rail + label + up to
/// three bullets. All copy strings are either chrome labels or verbatim
/// ports of web's canonical move phrasings.
struct ThreeMovesCard: View {
    let moves: Moves

    var body: some View {
        VStack(spacing: 12) {
            if !moves.stop.isEmpty {
                column(label: "STOP", items: moves.stop, tint: DS.Color.V3.Severity.red)
            }
            if !moves.start.isEmpty {
                column(label: "START", items: moves.start, tint: DS.Color.V3.Severity.green)
            }
            if !moves.continueDoing.isEmpty {
                column(label: "CONTINUE", items: moves.continueDoing, tint: DS.Color.V3.Severity.yellow)
            }
        }
    }

    private func column(label: String, items: [String], tint: Color) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Rectangle()
                .fill(tint)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 8) {
                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\u{2022}")
                                .font(.system(size: 13))
                                .foregroundStyle(DS.Color.V3.textTertiary)
                            Text(item)
                                .font(.system(size: 13))
                                .foregroundStyle(DS.Color.V3.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Moves derivation

    /// Client-side STOP/START/CONTINUE derivation, ported from web's TL;DR
    /// block. Each column caps at three items.
    struct Moves {
        let stop: [String]
        let start: [String]
        let continueDoing: [String]

        var hasContent: Bool {
            !stop.isEmpty || !start.isEmpty || !continueDoing.isEmpty
        }

        init(analysis: AutopsyAnalysis) {
            // STOP: worst strategic leaks by ROI, plus a late-night pattern.
            var stopItems: [String] = analysis.strategicLeaks
                .sorted { $0.roiImpact < $1.roiImpact }
                .prefix(2)
                .map { $0.category }
            let lateNight = analysis.behavioralPatterns.first {
                $0.patternName.lowercased().contains("late night") && $0.impact == "negative"
            }
            if lateNight != nil, stopItems.count < 3 {
                stopItems.append("Late-night betting")
            }

            // START: positive behavioral patterns, suffix-cleaned.
            let startItems: [String] = analysis.behavioralPatterns
                .filter { $0.impact == "positive" }
                .prefix(3)
                .map { Moves.cleanPatternName($0.patternName) }

            // CONTINUE: pertinent negatives mapped to a positive phrasing,
            // plus an emotional-discipline note when emotion is controlled.
            var continueItems: [String] = []
            let topNegatives = (analysis.pertinentNegatives ?? []).prefix(2)
            let hasEmotionalNegative = topNegatives.contains {
                $0.pattern.lowercased().contains("emotional")
            }
            for negative in topNegatives {
                continueItems.append(Moves.positivePhrasing(for: negative.pattern))
            }
            if analysis.emotionScore < 40,
               continueItems.count < 3,
               !hasEmotionalNegative {
                continueItems.append("Emotional discipline")
            }

            self.stop = Array(stopItems.prefix(3))
            self.start = Array(startItems.prefix(3))
            self.continueDoing = Array(continueItems.prefix(3))
        }

        /// Verbatim port of web's negativeToPositive map (AutopsyReport.tsx
        /// 2652-2663): a clean finding restated as the discipline to keep.
        private static func positivePhrasing(for pattern: String) -> String {
            switch pattern.lowercased() {
            case "loss chasing":    return "Flat staking after losses"
            case "parlay overuse":  return "Parlay discipline"
            case "late night bias": return "Time discipline"
            case "emotional betting": return "Session control"
            case "favorite bias":   return "Balanced odds selection"
            case "sunk cost":       return "Clean player rotation"
            default:                return "\(pattern) discipline"
            }
        }

        /// Strips trailing descriptor suffixes web removes from pattern
        /// names so START reads as a behavior, not a label.
        private static func cleanPatternName(_ raw: String) -> String {
            let suffixes = ["success", "discipline", "disaster", "pattern", "tendency"]
            var words = raw.split(separator: " ").map(String.init)
            while let last = words.last, suffixes.contains(last.lowercased()) {
                words.removeLast()
            }
            let cleaned = words.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            return cleaned.isEmpty ? raw : cleaned
        }
    }
}

#if DEBUG
#Preview {
    ScrollView {
        SectionProtocol(report: MockReport.heatedBettor, onPaywallTap: { _ in })
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
