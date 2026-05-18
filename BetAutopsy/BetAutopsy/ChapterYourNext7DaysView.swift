//
//  ChapterYourNext7DaysView.swift
//  BetAutopsy
//
//  Chapter 7: The Action Plan.
//
//  Layout (top-to-bottom):
//      ChapterNavigator (no hero ring)
//      ->  Top 4-6 ActionCards sorted by parsed dollar amount desc
//      ->  Aggregate ActionCard ("IF YOU DID ALL OF THESE") summing
//          the displayed actions
//      ->  Full mode: InsightCallout with CTA "SHARE MY FINDINGS"
//          (inert; debug print only)
//      ->  Snapshot mode: paywall trigger card preserved from PR-7.5
//          (replaces the InsightCallout; fires paywall.triggered with
//          source "chapter_7_button")
//
//  expectedImprovement is a String on the engine model; the chapter
//  parses the first dollar amount for sort/sum/display. Falls back to
//  0 if no parseable amount exists.
//

import SwiftUI

struct ChapterYourNext7DaysView: View {
    let report: AutopsyReport

    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall: Bool = false
    @State private var showingPushPrompt: Bool = false
    @State private var checkoffStore = ActionCheckoffStore.shared

    private struct RankedAction: Identifiable {
        var id: Int { recommendation.id }
        let recommendation: Recommendation
        let parsedDollars: Int
    }

    private var rankedActions: [RankedAction] {
        report.analysis.recommendations
            .map { RankedAction(recommendation: $0, parsedDollars: parseDollars($0.expectedImprovement)) }
            .sorted { $0.parsedDollars > $1.parsedDollars }
            .prefix(6)
            .map { $0 }
    }

    private var aggregateAction: ActionCard.Action? {
        guard !rankedActions.isEmpty else { return nil }
        let sum = rankedActions.reduce(0) { $0 + $1.parsedDollars }
        guard sum > 0 else { return nil }
        return ActionCard.Action(
            title: "IF YOU DID ALL OF THESE",
            tiedToFinding: "",
            projectedImpact: projectedImpactLabel(sum),
            difficulty: "",
            isAggregate: true
        )
    }

    private var insightBody: String {
        (report.analysis.executiveDiagnosis ?? "").firstSentences(2)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ChapterNavigator(chapterNumber: 7, subtitle: "THE ACTION PLAN")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

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

                if report.reportType == "snapshot" {
                    snapshotPaywallCard
                        .padding(.horizontal, 16)
                } else if !insightBody.isEmpty {
                    InsightCallout(
                        text: insightBody,
                        ctaLabel: "SHARE MY FINDINGS",
                        onTap: handleShareTap
                    )
                    .padding(.horizontal, 16)
                }

                Spacer().frame(height: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .background(canvasGradient.ignoresSafeArea())
        .sheet(isPresented: $showingPaywall) {
            PaywallView(snapshotReportId: report.id)
        }
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

    /// Renders a ranked recommendation as an ActionCard wired to the
    /// ActionCheckoffStore. The recommendation_id format matches
    /// the backend contract: "${report_id}:${priority}".
    @ViewBuilder
    private func checkoffActionCard(for ranked: RankedAction) -> some View {
        let recId = "\(report.id):\(ranked.recommendation.priority)"
        let isCompleted = checkoffStore.completed(for: recId)
        ActionCard(
            action: ActionCard.Action(
                title: ranked.recommendation.title,
                tiedToFinding: "FROM YOUR DIAGNOSIS",
                projectedImpact: projectedImpactLabel(ranked.parsedDollars),
                difficulty: difficultyCaps(ranked.recommendation.difficulty),
                isAggregate: false
            ),
            isCompleted: isCompleted,
            onCheckoffTap: {
                checkoffStore.flip(
                    recommendationId: recId,
                    reportId: report.id,
                    to: !isCompleted
                )
            }
        )
    }

    /// One-shot push permission gate. The "asked" flag is set by
    /// PushPermissionView on either Allow or Maybe Later, so this
    /// branch fires at most once per device install.
    private func evaluatePushPrompt() {
        let asked = UserDefaults.standard.bool(forKey: "betautopsy.push_permission_asked")
        if !asked {
            showingPushPrompt = true
        }
    }

    /// Warning Signs section (PR-9 Apple compliance Phase 2). Mounted
    /// before snapshotPaywallCard/InsightCallout so it appears in both
    /// full-report and snapshot modes. Backs the pre-emptive reviewer
    /// response in APPLE_REVIEW_COMPLIANCE.md §12.
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

    /// Snapshot-mode paywall trigger card (PR-7.5, preserved).
    /// Replaces the InsightCallout when reportType == "snapshot".
    /// Fires paywall.triggered with source "chapter_7_button" verbatim.
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

            Button(action: handleUnlock) {
                Text("Read the full report ($19.99).")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Color.V3.textPrimary, lineWidth: 1)
                    )
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
        .background(DS.Color.V3.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.Brand.yellowBorder, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Helpers

    /// Parses the first dollar amount from an `expectedImprovement` string
    /// (e.g., "Recovers an estimated $1,840 over 12 weeks" -> 1840).
    /// Returns 0 when no parseable amount is present.
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: dollars)) ?? "\(dollars)"
        return "$\(formatted) projected next 90 days"
    }

    private func difficultyCaps(_ raw: String) -> String {
        switch raw.lowercased() {
        case "easy":   return "EASY"
        case "medium": return "MODERATE"
        case "hard":   return "HARD"
        default:       return raw.uppercased()
        }
    }

    private var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                DS.Color.V3.canvasGradientStart,
                DS.Color.V3.canvasGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func handleShareTap() {
        #if DEBUG
        print("InsightCallout tapped on Chapter 7 (V1 stub).")
        #endif
    }

    private func handleUnlock() {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": "chapter_7_button"]
        )
        showingPaywall = true
    }
}

#Preview {
    ChapterYourNext7DaysView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
