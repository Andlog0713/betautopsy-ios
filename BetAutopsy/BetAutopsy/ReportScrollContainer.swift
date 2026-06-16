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
//  PROMPT 4 / STAGE A: formalized as a three-layer shell -
//    1. pinned background  (canvas gradient, ignoresSafeArea)
//    2. scrolling content  (ScrollView + LazyVStack)
//    3. pinned chrome      (StatusBarScrim, ChapterRail, dismiss xmark)
//  all ZStack siblings, so the chrome never scrolls with the body.
//
//  Scroll-position source migrated from the per-section
//  SectionTopPreferenceKey machinery to the native scrollPosition(id:)
//  API (scrollTargetLayout marks the candidate children). currentSectionId
//  feeds the ChapterRail highlight. The D14 swap RE-ANCHOR is unchanged in
//  ACTION: it still fires proxy.scrollTo to the top section on lastSwapAt
//  (now sourced from currentSectionId instead of the preference key), so
//  the load-bearing "stay where you were reading across the snapshot->full
//  height growth" behavior is preserved verbatim - only its input changed.
//

import SwiftUI

struct ReportScrollContainer: View {
    @StateObject private var viewModel: ReportScrollViewModel
    @State private var showingPaywall = false
    /// Top-of-viewport section id from scrollPosition(id:). Drives the
    /// ChapterRail highlight and the lastSwapAt re-anchor.
    @State private var currentSectionId: String?
    @State private var railVisible = true
    /// Monotonic token so a newer scroll cancels an older pending hide
    /// without juggling Task handles.
    @State private var railHideToken = 0
    @Environment(\.dismiss) private var dismiss

    /// When set (e.g. from a pre-bet grounded-flag deep link), the reader
    /// scrolls to this section anchor once the full body is present.
    private let initialSectionId: String?

    /// DEBUG-only: keep the ChapterRail pinned visible so the harness can
    /// screenshot it deterministically (auto-hide would race the capture -
    /// the #40 no-op lesson). Never set in production call sites.
    private let debugKeepRailVisible: Bool

    init(
        report: AutopsyReport,
        initialSectionId: String? = nil,
        debugKeepRailVisible: Bool = false
    ) {
        _viewModel = StateObject(wrappedValue: ReportScrollViewModel(initial: report))
        self.initialSectionId = initialSectionId
        self.debugKeepRailVisible = debugKeepRailVisible
    }

    private var isSnapshot: Bool { viewModel.report.reportType == "snapshot" }

    /// Section ids actually in the scroll content right now, top to
    /// bottom. Just the verdict while the body lazy-fetches; all seven
    /// once full. The ChapterRail only offers dots for these.
    private var presentSectionIds: [String] {
        var ids = ["section_verdict"]
        if viewModel.bodyState == .full {
            ids += [
                "section_findings", "section_heated_discipline",
                "section_patterns_timing", "section_sports",
                "section_protocol", "section_action"
            ]
        }
        return ids
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Layer 1: pinned background.
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            // Layer 2: scrolling content.
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 32) {
                        // Prompt 4 Stage B: the cover is the opening movement
                        // at the very top of the scroll, in both modes. It
                        // carries its own scrollPosition id but is NOT a
                        // ChapterRail dot - the rail's first dot (verdict)
                        // covers it (the cover is the verdict's opening), so
                        // at the top the rail falls back to highlighting
                        // verdict. Slim-safe: uses summary/archetype/betiq,
                        // all present in the slim payload.
                        ReportCoverView(report: viewModel.report)
                            .id("report_cover")

                        SectionVerdict(report: viewModel.report, onPaywallTap: handlePaywallTap)
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
                    .scrollTargetLayout()
                    .padding(.vertical, 32)
                }
                .scrollPosition(id: $currentSectionId, anchor: .top)
                .onScrollPhaseChange { _, phase in
                    if phase == .idle {
                        scheduleRailHide()
                    } else {
                        showRail()
                    }
                }
                .onChange(of: viewModel.lastSwapAt) { _, _ in
                    // After the swap, section heights grow (locked dollars
                    // reveal, hidden cards appear). Re-anchor to whatever
                    // section was topmost-visible so the reader stays put.
                    // Unchanged from the preference-key era except the anchor
                    // source (currentSectionId). scrollPosition(id:) also
                    // maintains the pinned id across content growth, so this
                    // is belt-and-suspenders, not the sole mechanism.
                    guard let anchor = currentSectionId else { return }
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
                    // Best-effort deep-link scroll: once the body is present,
                    // jump to the requested section. A no-op if the anchor is
                    // not rendered (snapshot/slim) - the report still opens.
                    if let target = initialSectionId {
                        try? await Task.sleep(nanoseconds: 350_000_000)
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(target, anchor: .top)
                        }
                    }
                }
                // Layer 3: pinned chrome (inside ScrollViewReader so the rail
                // jump can use the same proxy; positioned by the ZStack, not
                // the scroll content).
                .overlay {
                    ZStack(alignment: .topTrailing) {
                        ChapterRail(
                            sectionIds: presentSectionIds,
                            currentId: currentSectionId,
                            isVisible: railVisible || debugKeepRailVisible,
                            onJump: { id in
                                showRail()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(id, anchor: .top)
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)

                        StatusBarScrim()
                        dismissButton
                    }
                    .allowsHitTesting(true)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(snapshotReportId: viewModel.report.id)
        }
        .onAppear {
            // Rail shows on open, then hides after the idle window unless
            // the user scrolls (which re-arms it).
            scheduleRailHide()
        }
    }

    // MARK: - ChapterRail visibility

    private func showRail() {
        railVisible = true
        railHideToken &+= 1
    }

    private func scheduleRailHide() {
        guard !debugKeepRailVisible else { return }
        railVisible = true
        railHideToken &+= 1
        let token = railHideToken
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            if token == railHideToken { railVisible = false }
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
            .id("section_findings")

        if isSnapshot {
            RepeatedCTABlock(variant: .mid, onTap: { handlePaywallTap("section_findings_repeated_cta") })
                .padding(.horizontal, 16)
                .id("cta_after_findings")
        }

        SectionHeatedDiscipline(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .id("section_heated_discipline")

        SectionPatternsTiming(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .id("section_patterns_timing")

        SectionSports(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .id("section_sports")

        SectionProtocol(report: viewModel.report, onPaywallTap: handlePaywallTap)
            .id("section_protocol")

        SectionAction(report: viewModel.report, onPaywallTap: handlePaywallTap)
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
}

#if DEBUG
#Preview {
    ReportScrollContainer(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
#endif
