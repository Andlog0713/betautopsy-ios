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

    /// Whether the container renders the full body sections, a loading row, or
    /// a retry block. A report opened from the slim list endpoint starts
    /// `.fetching`; ensureFullBody() lazy-fetches the complete body by id and
    /// flips to `.full` (progressive fill - the slim cards in SectionVerdict
    /// render immediately, body sections swap in on success).
    enum BodyState: Equatable { case full, fetching, failed }
    @Published private(set) var bodyState: BodyState

    private var cancellable: AnyCancellable?
    /// In-flight guard so a double .task / re-render can't issue two fetches.
    private var isFetching = false

    init(initial: AutopsyReport) {
        self.report = initial
        self.bodyState = initial.isFullBody ? .full : .fetching
        subscribe()
    }

    // MARK: - Lazy full-body fetch

    /// Called from the container's `.task(id: report.id)`. No-op when the
    /// report already carries the full body (full report, push-opened, or
    /// post-swap). Does NOT auto-refetch after a failure: only retry() or a
    /// new report id (which builds a fresh view model) re-triggers, so a flaky
    /// network can never loop the endpoint on .task re-fire / re-render.
    func ensureFullBody() async {
        if report.isFullBody { bodyState = .full; return }
        if bodyState == .failed { return }
        await performBodyFetch()
    }

    /// Explicit user retry from the failed block.
    func retry() async {
        await performBodyFetch()
    }

    private func performBodyFetch() async {
        guard !isFetching else { return }
        isFetching = true
        bodyState = .fetching
        defer { isFetching = false }
        do {
            let full = try await ReportFetchClient.shared.fetch(id: report.id)
            withAnimation(.easeInOut(duration: 0.3)) {
                report = full
                lastSwapAt = Date()
            }
            bodyState = .full
            // Heal the store + cache so the list row and next launch hold the
            // full body (and hydrate's merge then preserves it).
            ReportStore.shared.upsert(full)
        } catch let urlError as URLError where urlError.code == .cancelled {
            // View dismissed mid-fetch; leave state as-is, no failure flash.
        } catch is CancellationError {
            // Same: cancellation is not a failure.
        } catch {
            bodyState = .failed
        }
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
