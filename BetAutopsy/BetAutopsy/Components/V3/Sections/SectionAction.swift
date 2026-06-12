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

    @State private var showingPushPrompt: Bool = false
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

    private var aggregateAction: ActionCard.Action? {
        guard !rankedActions.isEmpty else { return nil }
        let allLocked = rankedActions.allSatisfy { $0.isLocked }
        guard !allLocked else { return nil }
        let sum = rankedActions
            .filter { !$0.isLocked }
            .reduce(0) { $0 + $1.parsedDollars }
        guard sum > 0 else { return nil }
        return ActionCard.Action(
            title: "IF YOU DID ALL OF THESE",
            tiedToFinding: "",
            projectedImpact: projectedImpactLabel(sum),
            difficulty: "",
            isAggregate: true
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // Snapshot terminal stack (Phase 1): repeated terminal CTA above
            // the rich snapshotPaywallCard (distinct canonical copy).
            if report.reportType == "snapshot" {
                RepeatedCTABlock(variant: .terminal, onTap: { onPaywallTap("section_action_main_cta") })
                    .padding(.horizontal, 16)

                Spacer().frame(height: 24)
                snapshotPaywallCard
                    .padding(.horizontal, 16)
            }

            if !rankedActions.isEmpty {
                Spacer().frame(height: 24)
                VStack(spacing: 12) {
                    ForEach(rankedActions) { ranked in
                        checkoffActionCard(for: ranked)
                    }
                    if let agg = aggregateAction {
                        ActionCard(action: agg)
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer().frame(height: 24)

            warningSignsSection
        }
        .frame(maxWidth: .infinity)
        .fullScreenCover(isPresented: $showingPushPrompt) {
            PushPermissionView()
        }
        .onAppear {
            evaluatePushPrompt()
        }
        .task(id: report.id) {
            await checkoffStore.load(reportId: report.id)
        }
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

    private func evaluatePushPrompt() {
        let asked = UserDefaults.standard.bool(forKey: "betautopsy.push_permission_asked")
        if !asked {
            showingPushPrompt = true
        }
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
