//
//  SessionsTabView.swift
//  BetAutopsy
//
//  PR-6. Reads analysis.sessionDetection?.sessions across every report in
//  ReportStore and renders them as a chronological feed of read-only
//  cards. Visual register mirrors the notable-session card in
//  ChapterYourPatternsView so the chapter and the tab feel like one
//  product surface.
//
//  v1 scope per Notion (35d5964c-daf2-815e-8d55-fbe720103b16):
//  - Read-only feed; tap does nothing
//  - No filters, no pull-to-refresh, no per-card swipe gestures
//  - Detailed session view with constituent bets parked for v1.1
//

import SwiftUI

struct SessionsTabView: View {
    @Environment(ReportStore.self) private var store

    /// Aggregate every detected session across every visible report (real
    /// or mock-placeholder), dedupe by id, newest-first. Reports without
    /// sessionDetection (older reports / engine miss) contribute nothing.
    private var sessions: [DetectedSession] {
        let all = store.displayedReports.flatMap {
            $0.analysis.sessionDetection?.sessions ?? []
        }
        var seen = Set<String>()
        let deduped = all.filter { seen.insert($0.id).inserted }
        return deduped.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                feed
            }
        }
        // Bar-less full-bleed scroll surface: scrim keeps scrolled content
        // from colliding with the clock (TESTFLIGHT-MIN safe-area audit).
        .statusBarScrim()
    }

    // MARK: - Feed

    private var feed: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.top, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.md)

                LazyVStack(spacing: 12) {
                    ForEach(sessions) { session in
                        sessionCard(session)
                    }
                }

                Spacer(minLength: DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.xl)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            HStack(spacing: DS.Spacing.sm) {
                BABrandMark()
                Text("SESSIONS")
                    .font(.system(size: 10, weight: .regular).monospacedDigit())
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }

            Text("Recent sessions.")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
        }
    }

    // MARK: - Session card (mirrors ChapterYourPatternsView)

    private func sessionCard(_ s: DetectedSession) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("\(s.date.uppercased()) · \(s.dayOfWeek)")
                    .font(.system(size: 10, weight: .regular).monospacedDigit())
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.V3.surfaceRaised)
                        .frame(width: 32, height: 32)
                    Text(s.grade)
                        .font(.system(size: 24, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textPrimary)
                }
            }

            Text("\(s.startTime) to \(s.endTime) · \(s.durationMinutes) min")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .padding(.top, 4)

            Rectangle()
                .fill(DS.Color.V3.borderSubtle)
                .frame(height: DS.Stroke.hairline)
                .padding(.top, 12)

            HStack {
                Text(s.bets.pluralized("bet", "bets"))
                    .font(.system(size: 13, weight: .regular).monospacedDigit())
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
                Spacer()
                Text(BAFormat.currency(s.profit, signed: true))
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .monospacedDigit()
                    .foregroundStyle(s.profit >= 0
                                     ? DS.Color.V3.Severity.green
                                     : DS.Color.V3.Severity.red)
            }
            .padding(.top, 12)

            if !s.heatSignals.isEmpty {
                Text("Heat signals: \(s.heatSignals.joined(separator: ", "))")
                    .font(.system(size: 13, weight: .regular).italic())
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.md) {
            BABrandMark()
            Text("SESSIONS")
                .font(.system(size: 10, weight: .regular).monospacedDigit())
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text("No sessions on file. Sync from Pikkit or import a CSV to begin.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, DS.Spacing.xl)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SessionsTabView()
        .environment(ReportStore())
        .preferredColorScheme(.dark)
}
