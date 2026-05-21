//
//  ReportScrollViewModel.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2 (D14): drives the in-place snapshot->full swap inside
//  ReportScrollContainer. Holds the report currently rendered and listens
//  for the full child row materializing in ReportStore after purchase.
//
//  Observation: ReportStore is @Observable (not ObservableObject), so this
//  subscribes to its Combine surface (reportsChanged PassthroughSubject,
//  added in Phase 2) rather than a @Published projection. When a report
//  whose upgradedFromSnapshotId matches the current snapshot id appears,
//  the viewmodel swaps to it under a short cross-fade and stamps
//  lastSwapAt so the container can restore scroll position.
//

import Combine
import SwiftUI

@MainActor
final class ReportScrollViewModel: ObservableObject {
    @Published private(set) var report: AutopsyReport
    /// nil until the first swap; the container observes changes to anchor
    /// scroll position after section heights grow.
    @Published private(set) var lastSwapAt: Date?

    private var cancellable: AnyCancellable?

    init(initial: AutopsyReport) {
        self.report = initial
        subscribe()
    }

    private func subscribe() {
        cancellable = ReportStore.shared.reportsChanged
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reports in
                // reportsChanged is always sent on the main actor (ReportStore
                // mutations run there) and re-delivered on main via receive(on:),
                // so assuming isolation here is safe and gives the closure the
                // MainActor context it needs to touch report/lastSwapAt.
                MainActor.assumeIsolated {
                    self?.handle(reports)
                }
            }
    }

    private func handle(_ reports: [AutopsyReport]) {
        // Already swapped to (or opened as) a full report: ignore further
        // updates so a later unrelated mutation can't re-trigger.
        guard report.reportType == "snapshot" else { return }
        // Multiple matches edge case: take the first. Engine idempotency
        // guards ensure only one full child per snapshot (Day 13 P0 RCA).
        guard let upgrade = reports.first(where: { $0.upgradedFromSnapshotId == report.id }) else {
            return
        }
        withAnimation(.easeInOut(duration: 0.4)) {
            report = upgrade
            lastSwapAt = Date()
        }
    }
}
