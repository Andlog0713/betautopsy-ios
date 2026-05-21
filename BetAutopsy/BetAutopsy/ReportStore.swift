//
//  ReportStore.swift
//  BetAutopsy
//
//  @Observable in-memory store for AutopsyReport instances. PR-4 keeps
//  reports in memory only (lost on app restart); on-disk persistence
//  ships as a v1.1 polish item.
//

import Foundation
import Observation
import Combine

@Observable
final class ReportStore {
    /// Process-lifetime singleton. RootTabView seeds its @State from
    /// this same instance and forwards it through the environment, so
    /// existing @Environment(ReportStore.self) consumers still resolve
    /// to the canonical store. Cross-cutting writers (RevenueCatStore's
    /// post-purchase polling, future v1.1 paths) use the .shared
    /// accessor directly.
    static let shared = ReportStore()

    private(set) var reports: [AutopsyReport] = []

    /// True while hydrate() has an in-flight GET /api/reports. Drives the
    /// loading state on cold launch and the empty-state spinner.
    var isHydrating: Bool = false

    /// Last hydrate() failure, retained so ReportListView can surface an
    /// error + retry. Cleared at the start of each hydrate attempt.
    var hydrationError: Error?

    /// Combine surface for non-SwiftUI observers (REBUILD-PHASE-2 D14).
    /// @Observable drives SwiftUI views; ReportScrollViewModel needs a
    /// Combine publisher to react to the post-purchase upsert without the
    /// store conforming to ObservableObject. Fired on every mutation with
    /// the current reports snapshot. Not @Observable-tracked (it's a let).
    let reportsChanged = PassthroughSubject<[AutopsyReport], Never>()

    /// The reports to render. No longer substitutes a mock when empty
    /// (P0 persistence): callers own their own empty state. ReportListView
    /// shows an upload prompt; SessionsTabView falls through to its own
    /// emptyState. Retained as a named accessor for both call sites.
    var displayedReports: [AutopsyReport] {
        reports
    }

    /// Hydrate from Supabase via GET /api/reports (web 5cc8356). Called
    /// once per userId transition by RootTabView (cold launch + sign-in)
    /// and by ReportListView's pull-to-refresh. On error, keeps the
    /// last-known reports for offline resilience.
    @MainActor
    func hydrate() async {
        isHydrating = true
        hydrationError = nil
        do {
            let fetched = try await ReportListClient.shared.fetchList()
            self.reports = fetched
        } catch {
            self.hydrationError = error
            // Do NOT touch self.reports on error - keep last-known state.
        }
        isHydrating = false
    }

    func add(_ report: AutopsyReport) {
        reports.insert(report, at: 0)
        reportsChanged.send(reports)
    }

    /// Inserts or replaces a report by id. Used by RevenueCatStore's
    /// post-purchase polling when the child full row materializes:
    /// replacing the snapshot in-place would orphan the snapshot row;
    /// we insert the new full as the newest and let the UI choose
    /// which to surface.
    func upsert(_ report: AutopsyReport) {
        if let idx = reports.firstIndex(where: { $0.id == report.id }) {
            reports[idx] = report
        } else {
            reports.insert(report, at: 0)
        }
        reportsChanged.send(reports)
    }

    func clear() {
        reports = []
        reportsChanged.send(reports)
    }
}
