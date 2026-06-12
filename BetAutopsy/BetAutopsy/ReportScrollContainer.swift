//
//  ReportScrollContainer.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2: single-scroll report reader. Replaces the paged
//  7-chapter TabView (ReportView, now deprecated) with one LazyVStack of
//  6 sections. Owns the single PaywallView sheet (sections call
//  onPaywallTap with an analytics source string), the xmark dismiss, and
//  the D14 in-place snapshot->full swap via ReportScrollViewModel.
//
//  Scroll position preservation (the D14 risk surface): each section
//  reports its top offset in the scroll coordinate space; the container
//  tracks the topmost-visible section and, after a swap grows section
//  heights, re-anchors to it so the user stays where they were reading.
//

import SwiftUI

struct ReportScrollContainer: View {
    @StateObject private var viewModel: ReportScrollViewModel
    @State private var showingPaywall = false
    @State private var topVisibleSectionId: String?
    @Environment(\.dismiss) private var dismiss

    init(report: AutopsyReport) {
        _viewModel = StateObject(wrappedValue: ReportScrollViewModel(initial: report))
    }

    private var isSnapshot: Bool { viewModel.report.reportType == "snapshot" }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 32) {
                        SectionVerdict(report: viewModel.report, onPaywallTap: handlePaywallTap)
                            .trackSectionTop("section_verdict")
                            .id("section_verdict")

                        if isSnapshot {
                            RepeatedCTABlock(variant: .mid, onTap: { handlePaywallTap("section_verdict_repeated_cta") })
                                .padding(.horizontal, 16)
                                .id("cta_after_verdict")
                        }

                        // Body sections render only when the full body is
                        // present. While it lazy-fetches (slim list payload) we
                        // show a loading row; on failure a retry block. We do
                        // NOT let the sections fall to their snapshot/fallback
                        // copy on a slim payload - that masquerade ("Pattern
                        // analysis lives in the full report" / WARNING SIGNS) is
                        // exactly the shell bug. SectionVerdict above is
                        // slim-safe and always renders for progressive fill.
                        switch viewModel.bodyState {
                        case .full:
                            fullBodySections
                        case .fetching:
                            bodyLoadingRow
                                .id("body_loading")
                        case .failed:
                            bodyRetryBlock
                                .id("body_retry")
                        }
                    }
                    .padding(.vertical, 32)
                }
                .coordinateSpace(name: Self.scrollSpace)
                .onPreferenceChange(SectionTopPreferenceKey.self) { tops in
                    topVisibleSectionId = Self.topmostVisible(tops)
                }
                .onChange(of: viewModel.lastSwapAt) { _, _ in
                    // After the swap, section heights grow (locked dollars
                    // reveal, hidden cards appear). Re-anchor to whatever
                    // section was topmost-visible so the reader stays put.
                    guard let anchor = topVisibleSectionId else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(anchor, anchor: .top)
                        }
                    }
                }
                // Lazy-fetch the full body when opened from the slim list.
                // Keyed on report.id: fires once per report, does not re-fire on
                // the slim->full swap (same id), and re-fires on a D14
                // snapshot->full swap (new id, already full -> no-op).
                .task(id: viewModel.report.id) {
                    await viewModel.ensureFullBody()
                }
            }

            // Scrim under the floating xmark: scrolled report content fades
            // out beneath the status bar instead of colliding with the clock
            // (TESTFLIGHT-MIN safe-area audit). Sits below dismissButton in
            // the ZStack so the button stays fully legible.
            StatusBarScrim()

            dismissButton
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(snapshotReportId: viewModel.report.id)
        }
    }

    private func handlePaywallTap(_ source: String) {
        Analytics.signal("paywall.triggered", parameters: ["source": source])
        showingPaywall = true
    }

    @ViewBuilder
    private var dismissButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .frame(width: 44, height: 44)
                .background(DS.Color.V3.surfaceRaised.opacity(0.6), in: Circle())
        }
        .padding(.top, 8)
        .padding(.trailing, 16)
    }

    // MARK: - Body sections (rendered only when the full body is present)

    @ViewBuilder
    private var fullBodySections: some View {
        SectionFindings(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .trackSectionTop("section_findings")
            .id("section_findings")

        if isSnapshot {
            RepeatedCTABlock(variant: .mid, onTap: { handlePaywallTap("section_findings_repeated_cta") })
                .padding(.horizontal, 16)
                .id("cta_after_findings")
        }

        SectionHeatedDiscipline(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .trackSectionTop("section_heated_discipline")
            .id("section_heated_discipline")

        SectionPatternsTiming(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .trackSectionTop("section_patterns_timing")
            .id("section_patterns_timing")

        SectionSports(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .trackSectionTop("section_sports")
            .id("section_sports")

        SectionProtocol(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .trackSectionTop("section_protocol")
            .id("section_protocol")

        SectionAction(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .trackSectionTop("section_action")
            .id("section_action")
        // Terminal RepeatedCTABlock lives INSIDE SectionAction (Phase 1).
    }

    /// Progressive-fill loading state: the slim cards (SectionVerdict) are
    /// already on screen; this sits where the body will appear.
    private var bodyLoadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(DS.Color.V3.textSecondary)
            Text("Loading the rest of your report.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.V3.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    /// Body fetch failed (offline / server). Explicit, recoverable, and NOT
    /// the masquerade fallback: the degraded body sections never render.
    private var bodyRetryBlock: some View {
        VStack(spacing: 12) {
            Text("Couldn't load the full report.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.center)

            Button(action: { Task { await viewModel.retry() } }) {
                Text("Retry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Brand.canvasDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.Brand.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Scroll position tracking

    static let scrollSpace = "reportScroll"

    /// The section whose top sits at or just above the viewport top, i.e.
    /// the one currently filling the top of the screen. Falls back to the
    /// topmost section when scrolled to the very start (all tops > 0).
    private static func topmostVisible(_ tops: [String: CGFloat]) -> String? {
        guard !tops.isEmpty else { return nil }
        // Tops are minY in the scroll coordinate space: <= 0 means scrolled
        // past that section's top. Pick the greatest minY among those <=
        // a small threshold (closest to the top line from above).
        let threshold: CGFloat = 1
        let aboveLine = tops.filter { $0.value <= threshold }
        if let anchor = aboveLine.max(by: { $0.value < $1.value }) {
            return anchor.key
        }
        // Nothing scrolled past yet: anchor to the topmost (smallest minY).
        return tops.min(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Section top tracking plumbing

private struct SectionTopPreferenceKey: PreferenceKey {
    static let defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct SectionTopTracker: ViewModifier {
    let id: String
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: SectionTopPreferenceKey.self,
                    value: [id: geo.frame(in: .named(ReportScrollContainer.scrollSpace)).minY]
                )
            }
        )
    }
}

private extension View {
    func trackSectionTop(_ id: String) -> some View {
        modifier(SectionTopTracker(id: id))
    }
}

#if DEBUG
#Preview {
    ReportScrollContainer(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
#endif
