//
//  SectionAction.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2: single-scroll section extracted from
//  ChapterYourNext7DaysView (Ch7, "The Action Plan"). Strips the
//  ScrollView wrapper, the ChapterNavigator chrome, the canvas background,
//  the @Environment(\.dismiss), and the per-chapter PaywallView sheet.
//
//  Preserved: the Phase 1 terminal stack (RepeatedCTABlock(.terminal)
//  ABOVE the snapshotPaywallCard), ranked ActionCards + checkoff store,
//  the warning-signs section + ResponsibleUseLink, and the "SHARE MY
//  FINDINGS" CTA (a share stub, not a chapter advance, so it stays). The
//  push-permission fullScreenCover stays (section-local, not the paywall).
//

import SwiftUI

struct SectionAction: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    @State private var checkoffStore = ActionCheckoffStore.shared

    private struct RankedAction: Identifiable {
        var id: Int { recommendation.id }
        let recommendation: Recommendation
        let parsedDollars: Int
        let isLocked: Bool
    }

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var rankedActions: [RankedAction] {
        report.analysis.recommendations
            .map { rec -> RankedAction in
                let costSavings = rec.costSavings.map { Int($0.rounded()) } ?? 0
                let parsed = parseDollars(rec.expectedImprovement)
                let dollars = max(costSavings, parsed)
                // The locked-pill variant is snapshot-redaction UI and must
                // NEVER render in a paid full report. A full-report action
                // with no honest dollar (unparseable improvement, zero or
                // redaction-tagged costSavings) shows no impact row and
                // falls back to the HIGHEST IMPACT tag where one applies.
                let locked = isSnapshot
                return RankedAction(
                    recommendation: rec,
                    parsedDollars: dollars,
                    isLocked: locked
                )
            }
            .sorted { $0.parsedDollars > $1.parsedDollars }
            .prefix(6)
            .map { $0 }
    }

    // 3B-2: the aggregate card previously SUMMED the per-action
    // projections ("IF YOU DID ALL OF THESE: $2,847") - the additive-
    // counterfactual defect in a third costume. The projections derive
    // from overlapping leak counterfactuals, so a summed total directly
    // contradicted the Verdict's not-every-fix-stacked framing in the
    // same report. The card survives as qualitative framing with NO
    // summed figure; individual per-action projections stay (individual
    // counterfactuals shown individually are fine).
    private var showAggregateNote: Bool {
        !isSnapshot && rankedActions.filter { $0.parsedDollars > 0 }.count >= 2
    }

    var body: some View {
        VStack(spacing: 0) {
            // Snapshot conversion moment: the rich snapshotPaywallCard only.
            // The terminal RepeatedCTABlock that used to sit directly above
            // it was a redundant second full-report CTA (two solid-yellow
            // buttons 24pt apart), part of the snapshot CTA pile-up above the
            // warning-signs checklist. Removed; the paywall card is the
            // canonical end-of-report CTA and keeps the same analytics source.
            if report.reportType == "snapshot" {
                snapshotPaywallCard
                    .padding(.horizontal, 16)
            }

            if !rankedActions.isEmpty {
                Spacer().frame(height: 24)
                if isSnapshot {
                    // Snapshot renders exactly as before: locked ActionCards
                    // with the LockedDollarBar + paywall tap.
                    VStack(spacing: 12) {
                        ForEach(rankedActions) { ranked in
                            checkoffActionCard(for: ranked)
                        }
                    }
                    .padding(.horizontal, 16)
                } else {
                    // 3B-2: full-mode ranked actions recomposed onto
                    // ActionRow inside one container card. Check-off store
                    // wiring (recId scheme, flip semantics) is unchanged.
                    actionRowsCard
                        .padding(.horizontal, 16)

                    if showAggregateNote {
                        Spacer().frame(height: 12)
                        Callout(
                            variant: .info,
                            title: "If you did all of these",
                            text: "These projections overlap, so they do not add up to one big number. Start at the top."
                        )
                        .padding(.horizontal, 16)
                    }
                }
            }

            Spacer().frame(height: 24)

            warningSignsSection
        }
        .frame(maxWidth: .infinity)
        // The push primer used to auto-present here on appear, covering the
        // action plan (the report's key CTA). It moved to TodayView (fires
        // after a report exists, never over a CTA). SectionAction no longer
        // presents it.
        .task(id: report.id) {
            await checkoffStore.load(reportId: report.id)
        }
    }

    // MARK: - Full-mode ActionRow recompose (3B-2)

    private var actionRowsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(rankedActions.enumerated()), id: \.element.id) { index, ranked in
                actionRow(for: ranked)
                if index < rankedActions.count - 1 {
                    V3Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 4)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func actionRow(for ranked: RankedAction) -> some View {
        let recId = "\(report.id):\(ranked.recommendation.priority)"
        let isCompleted = checkoffStore.completed(for: recId)
        ActionRow(
            title: ranked.recommendation.title,
            detail: actionDetailLine(for: ranked),
            isCompleted: isCompleted,
            onToggle: {
                checkoffStore.flip(
                    recommendationId: recId,
                    reportId: report.id,
                    to: !isCompleted
                )
            }
        )
        .padding(.horizontal, 16)
    }

    /// Detail line under the action title: the projected impact (already
    /// BAFormat-shaped by projectedImpactLabel) plus the difficulty tag,
    /// dot-separated. The priority-1 HIGHEST IMPACT fallback survives
    /// from the card variant.
    private func actionDetailLine(for ranked: RankedAction) -> String? {
        var parts: [String] = []
        let impact = projectedImpactLabel(ranked.parsedDollars)
        if !impact.isEmpty {
            parts.append(impact)
        } else if ranked.parsedDollars <= 0, ranked.recommendation.priority == 1 {
            parts.append("HIGHEST IMPACT")
        }
        let difficulty = difficultyCaps(ranked.recommendation.difficulty)
        if !difficulty.isEmpty {
            parts.append(difficulty)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " \u{00B7} ")
    }

    @ViewBuilder
    private func checkoffActionCard(for ranked: RankedAction) -> some View {
        let recId = "\(report.id):\(ranked.recommendation.priority)"
        let isCompleted = checkoffStore.completed(for: recId)
        let projectedImpact: String = ranked.isLocked
            ? ""
            : projectedImpactLabel(ranked.parsedDollars)
        let showsHighestImpactTag = !ranked.isLocked
            && ranked.parsedDollars <= 0
            && ranked.recommendation.priority == 1
        let fallback: String? = showsHighestImpactTag ? "HIGHEST IMPACT" : nil
        let cardAction = ActionCard.Action(
            title: ranked.recommendation.title,
            tiedToFinding: "FROM YOUR DIAGNOSIS",
            projectedImpact: projectedImpact,
            difficulty: difficultyCaps(ranked.recommendation.difficulty),
            isAggregate: false,
            isLockedImpact: ranked.isLocked,
            impactFallback: fallback
        )
        let onCheckoff: () -> Void = {
            checkoffStore.flip(
                recommendationId: recId,
                reportId: report.id,
                to: !isCompleted
            )
        }
        ActionCard(
            action: cardAction,
            isCompleted: isCompleted,
            onCheckoffTap: onCheckoff,
            onLockedTap: handleLockedTap
        )
    }

    private func handleLockedTap() {
        onPaywallTap("section_action_locked_dollar")
    }

    private var warningSignsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            BAChromeLabel("WARNING SIGNS")

            Text("Watch for these patterns in your own behavior:")
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textSecondary)

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                warningSignRow("Chasing losses with bigger stakes")
                warningSignRow("Betting later at night than usual")
                warningSignRow("Hiding bets or losses from family")
                warningSignRow("Borrowing money to bet")
                warningSignRow("Betting to escape stress or sadness")
                warningSignRow("Lying about how much you've lost")
            }

            ResponsibleUseLink()
                .padding(.top, DS.Spacing.md)
        }
        .padding(.vertical, DS.Spacing.xl)
        .padding(.horizontal, DS.Spacing.lg)
    }

    @ViewBuilder
    private func warningSignRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.xs) {
            Text("\u{2022}")
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textSecondary)
            Text(text)
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textPrimary)
        }
    }

    private var snapshotPaywallCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("The autopsy is ready.")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("Dollar costs, recommendations, and the full session timeline. 23 pages.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.V3.textPrimary.opacity(0.85))
                .lineSpacing(3)
                .padding(.top, 6)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { onPaywallTap("section_action_main_cta") }) {
                Text("Read the full report (\(RevenueCatStore.shared.priceString)).")
                    .font(DS.Font.V3.buttonLabel)
                    .foregroundStyle(DS.Color.V3.canvasGradientEnd)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.Brand.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }
            .padding(.top, 16)

            Text("One-time charge. Yours to keep. No subscription.")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .lineSpacing(2)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                DS.Color.V3.surfaceRaised
                DS.Color.Brand.yellow.opacity(0.10)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.Brand.yellow, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Helpers

    // TODO(engine raw-values): expectedImprovement is an LLM pre-formatted
    // prose string; this regex recovers a raw dollar value from it. The
    // numeric costSavings field is preferred wherever the engine ships it
    // (rankedActions takes max(costSavings, parsed)). Once the engine is
    // raw-values-only, delete this parser and read costSavings alone.
    private func parseDollars(_ raw: String) -> Int {
        let pattern = #"\$([0-9][0-9,]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        let range = NSRange(raw.startIndex..., in: raw)
        guard let match = regex.firstMatch(in: raw, range: range),
              let groupRange = Range(match.range(at: 1), in: raw) else { return 0 }
        let digits = raw[groupRange].replacingOccurrences(of: ",", with: "")
        return Int(digits) ?? 0
    }

    private func projectedImpactLabel(_ dollars: Int) -> String {
        // A non-positive projection has no honest dollar figure to show
        // (the deterministic per-bias cost engine lands later). Return an
        // empty label so the impact row hides the "$0 projected next 90
        // days" placeholder and falls back to the HIGHEST IMPACT tag where
        // one applies, rather than printing a fabricated $0.
        guard dollars > 0 else { return "" }
        return "\(BAFormat.currency(dollars)) projected next 90 days"
    }

    private func difficultyCaps(_ raw: String) -> String {
        switch raw.lowercased() {
        case "easy":   return "EASY"
        case "medium": return "MODERATE"
        case "hard":   return "HARD"
        default:       return raw.uppercased()
        }
    }
}

#Preview {
    ScrollView {
        SectionAction(report: MockReport.heatedBettor, onPaywallTap: { _ in })
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
