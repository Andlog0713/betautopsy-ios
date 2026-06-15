//
//  ChapterRail.swift
//  BetAutopsy
//
//  Prompt 4 / Stage A: auto-hiding right-edge wayfinding for the report
//  reader. One dot per rendered section; the current section is brand
//  yellow and slightly enlarged, the rest are tertiary grey. Tap a dot
//  to jump. The host shows the rail on scroll and hides it after a
//  short idle, so it is wayfinding when you want it and gone when you
//  don't (the Linear/Whoop calm-chrome pattern).
//
//  Placement: vertically centered on the trailing edge. Centering is
//  deliberate so the rail never collides with the top-right dismiss
//  xmark (which lives in the top ~52pt) - they share the right edge but
//  not the same vertical band, and the rail only takes hits when shown.
//
//  Presentational only: the host owns visibility state and the jump
//  action (a scrollTo on the shared ScrollViewReader proxy). Brand
//  yellow here is chrome/active-state accent, which is a sanctioned use.
//

import SwiftUI

struct ChapterRail: View {
    /// Section ids currently present in the scroll content, top to
    /// bottom. The host passes only what is actually rendered (just the
    /// verdict while the body lazy-fetches, all sections once full), so
    /// the rail never offers a dot for a section that isn't on screen.
    let sectionIds: [String]

    /// The scrollPosition id of the section at the top of the viewport.
    /// May be a non-section id (a CTA block, the loading row); when it
    /// is, the rail holds its last known section rather than clearing.
    let currentId: String?

    let isVisible: Bool
    let onJump: (String) -> Void

    @State private var lastKnownSection: String?

    private var activeSection: String? {
        if let currentId, sectionIds.contains(currentId) { return currentId }
        // scrollPosition(id:) reports nil until the first scroll, so at rest
        // at the top fall back to the last known section, then to the first
        // (where the reader actually is on open) - the rail always marks a
        // position rather than going dark.
        return lastKnownSection ?? sectionIds.first
    }

    var body: some View {
        VStack(spacing: 10) {
            ForEach(sectionIds, id: \.self) { id in
                dot(isActive: id == activeSection, id: id)
            }
        }
        .padding(.trailing, 6)
        .frame(maxHeight: .infinity, alignment: .center)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: isVisible)
        .allowsHitTesting(isVisible)
        .onChange(of: currentId) { _, new in
            if let new, sectionIds.contains(new) { lastKnownSection = new }
        }
        // Decorative wayfinding; the sections themselves are the
        // accessibility surface. A labeled VoiceOver rail is a Stage D
        // (a11y pass) concern, not Stage A shell scope.
        .accessibilityHidden(true)
    }

    private func dot(isActive: Bool, id: String) -> some View {
        Button { onJump(id) } label: {
            Circle()
                .fill(isActive ? DS.Color.Brand.yellow : DS.Color.V3.textTertiary)
                .frame(width: isActive ? 8 : 6, height: isActive ? 8 : 6)
                .frame(width: 24, height: 18)
                .contentShape(Rectangle())
                .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    ZStack(alignment: .topTrailing) {
        DS.Color.V3.canvasGradient.ignoresSafeArea()
        ChapterRail(
            sectionIds: [
                "section_verdict", "section_findings", "section_heated_discipline",
                "section_patterns_timing", "section_sports", "section_protocol",
                "section_action"
            ],
            currentId: "section_patterns_timing",
            isVisible: true,
            onJump: { _ in }
        )
    }
    .preferredColorScheme(.dark)
}
#endif
