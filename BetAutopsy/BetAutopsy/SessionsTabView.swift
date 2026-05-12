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
            DS.Color.Surface.canvas.ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                feed
            }
        }
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
            Text("SESSIONS")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("Recent sessions.")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
        }
    }

    // MARK: - Session card (mirrors ChapterYourPatternsView)

    private func sessionCard(_ s: DetectedSession) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text("\(s.date.uppercased()) · \(s.dayOfWeek)")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.Surface.raised)
                        .frame(width: 32, height: 32)
                    Text(s.grade)
                        .font(.system(size: 24, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.Text.primary)
                }
            }

            Text("\(s.startTime) to \(s.endTime) · \(s.durationMinutes) min")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.top, 4)

            Rectangle()
                .fill(DS.Color.Border.subtle)
                .frame(height: DS.Stroke.hairline)
                .padding(.top, 12)

            HStack {
                Text("\(s.bets) bets")
                    .font(.custom("JetBrainsMono-Regular", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Text.primary)
                Spacer()
                Text(formatCurrency(s.profit, signed: true))
                    .font(.custom("JetBrainsMono-Medium", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(s.profit >= 0
                                     ? DS.Color.Semantic.win
                                     : DS.Color.Semantic.blood)
            }
            .padding(.top, 12)

            if !s.heatSignals.isEmpty {
                Text("Heat signals: \(s.heatSignals.joined(separator: ", "))")
                    .font(.custom("Georgia-Italic", size: 13))
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .padding(.top, 8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("SESSIONS")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("No sessions on file. Sync from Pikkit or import a CSV to begin.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.Text.secondary)
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
