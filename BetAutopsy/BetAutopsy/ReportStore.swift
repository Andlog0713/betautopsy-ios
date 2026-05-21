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

    /// Combine surface for non-SwiftUI observers (REBUILD-PHASE-2 D14).
    /// @Observable drives SwiftUI views; ReportScrollViewModel needs a
    /// Combine publisher to react to the post-purchase upsert without the
    /// store conforming to ObservableObject. Fired on every mutation with
    /// the current reports snapshot. Not @Observable-tracked (it's a let).
    let reportsChanged = PassthroughSubject<[AutopsyReport], Never>()

    /// True when no real reports exist yet; ReportListView uses this to
    /// fall back to the Tilter mock as a placeholder card.
    var showMockPlaceholder: Bool { reports.isEmpty }

    /// Mock placeholder when empty, otherwise the real reports list.
    var displayedReports: [AutopsyReport] {
        if reports.isEmpty {
            return [MockReport.heatedBettor]
        }
        return reports
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
