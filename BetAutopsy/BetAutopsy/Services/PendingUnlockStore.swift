//
//  PendingUnlockStore.swift
//  BetAutopsy
//
//  Persists the one in-flight report unlock across app launches so the
//  snapshot->full materialization can complete OUT of the paywall sheet.
//  The full report is generated server-side (RevenueCat webhook -> engine
//  re-run, 30-120s), longer than any reasonable in-sheet wait, so the user
//  must be able to leave and have the report appear on its own. This record
//  is the source of truth for the resume path and the genuine-failure path.
//
//  Lifecycle:
//    begin(snapshotId:)  on a confirmed purchase
//    clear()             once the full report materializes (any path)
//
//  The createdAt timestamp drives the failure ceiling: if the report has
//  not materialized within `failureCeiling`, a dropped webhook (or engine
//  error) is assumed and the resume path surfaces a recoverable failure
//  instead of waiting forever in calm "still compiling."
//

import Foundation
import Observation

@Observable
final class PendingUnlockStore {
    static let shared = PendingUnlockStore()

    /// Hard ceiling after which a non-materialized unlock is treated as a
    /// genuine failure. Generously above the 30-120s normal generation
    /// window so a slow-but-fine report never trips it.
    static let failureCeiling: TimeInterval = 12 * 60

    private let idKey = "pendingUnlock.snapshotId"
    private let atKey = "pendingUnlock.createdAt"

    private(set) var snapshotId: String?
    private(set) var createdAt: Date?

    init() {
        let defaults = UserDefaults.standard
        self.snapshotId = defaults.string(forKey: idKey)
        let stamp = defaults.double(forKey: atKey)
        self.createdAt = stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
    }

    var isActive: Bool { snapshotId != nil }

    var isPastFailureCeiling: Bool {
        guard let createdAt else { return false }
        return Date().timeIntervalSince(createdAt) > Self.failureCeiling
    }

    func begin(snapshotId: String) {
        let now = Date()
        self.snapshotId = snapshotId
        self.createdAt = now
        let defaults = UserDefaults.standard
        defaults.set(snapshotId, forKey: idKey)
        defaults.set(now.timeIntervalSince1970, forKey: atKey)
    }

    func clear() {
        snapshotId = nil
        createdAt = nil
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: idKey)
        defaults.removeObject(forKey: atKey)
    }
}
