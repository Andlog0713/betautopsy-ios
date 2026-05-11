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

@Observable
final class ReportStore {
    private(set) var reports: [AutopsyReport] = []

    /// True when no real reports exist yet — ReportListView uses this to
    /// fall back to the Heated Bettor mock as a placeholder card.
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
    }

    func clear() {
        reports = []
    }
}
