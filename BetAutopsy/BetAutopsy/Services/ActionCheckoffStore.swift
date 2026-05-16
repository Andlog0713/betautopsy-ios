//
//  ActionCheckoffStore.swift
//  BetAutopsy
//
//  Process-lifetime @Observable singleton holding per-recommendation
//  completion state. Surfaces Chapter 7 checkboxes and the dashboard
//  progress ring.
//
//  Wire shape lives in ActionCheckoff (timestamps); this store derives
//  a single Bool per recommendation_id. v1 iOS doesn't surface
//  dismissed-state, so the rule is:
//      completed = (completedAt != nil && dismissedAt == nil)
//
//  Multi-report state. The dict spans every loaded report's checkoffs;
//  scope is encoded in the recommendation_id key prefix
//  "${report_id}:${priority}". This keeps Path D (user generates a new
//  report mid-session — old report's checkoffs must still be visible)
//  working without per-report dict swaps.
//
//  UserDefaults per-report cache "betautopsy.checkoffs.<report_id>"
//  for offline first-render. Cache rehydrates on load() before the
//  network reconciliation fires.
//
//  flip() is optimistic: local mutation is instant, POST happens in
//  the background, failure path reverts. lastFlip is published so
//  UndoToast (Commit 3) can observe and present a banner. Revert
//  mutations do NOT update lastFlip (they're not user-initiated
//  flips) — UndoToast won't double-fire.
//

import Foundation
import Observation
import Sentry

@Observable
final class ActionCheckoffStore {
    static let shared = ActionCheckoffStore()
    private init() {}

    /// recommendation_id ("${report_id}:${priority}") → CheckoffState.
    /// Single dict spans multiple reports; report scope lives in the
    /// key prefix.
    private(set) var states: [String: CheckoffState] = [:]

    /// Last user-initiated flip event. UndoToast observes this and
    /// shows itself when the value changes AND previousCompleted is
    /// false (so undos of a completion show a toast, but undos of an
    /// undo do not).
    private(set) var lastFlip: FlipEvent?

    struct CheckoffState: Codable, Equatable {
        var completed: Bool
    }

    /// Unique per flip via UUID so SwiftUI .onChange observers
    /// can detect a new event even if previousCompleted repeats.
    struct FlipEvent: Equatable, Identifiable {
        let id: UUID
        let recommendationId: String
        let reportId: String
        let previousCompleted: Bool
        let newCompleted: Bool
    }

    // MARK: - Read

    /// True if the given recommendation is marked completed.
    func completed(for recommendationId: String) -> Bool {
        states[recommendationId]?.completed ?? false
    }

    /// Number of completed checkoffs whose recommendation_id begins
    /// with "<reportId>:". Used by the dashboard progress ring.
    func completedCount(forReportId reportId: String) -> Int {
        let prefix = "\(reportId):"
        return states.lazy
            .filter { $0.key.hasPrefix(prefix) && $0.value.completed }
            .count
    }

    // MARK: - Load (hydrate from cache then reconcile via GET)

    /// Hydrate from UserDefaults cache first (instant offline render),
    /// then fire GET to reconcile with backend. Silent failure: cache
    /// stays as the visible state, Sentry captures the network error.
    func load(reportId: String) async {
        hydrateFromCache(reportId: reportId)
        do {
            let rows = try await ActionCheckoffClient.shared.list(reportId: reportId)
            mergeServer(rows: rows, reportId: reportId)
            persistToCache(reportId: reportId)
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "checkoff", key: "kind")
                scope.setTag(value: "store_load", key: "failure_source")
            }
        }
    }

    // MARK: - Flip (optimistic + POST + revert on failure)

    /// Optimistic mutation. Updates local state instantly, persists
    /// the cache, publishes a FlipEvent for UndoToast, fires POST in
    /// the background. On POST failure, reverts local state directly
    /// (bypassing flip()) so UndoToast doesn't double-fire.
    func flip(recommendationId: String, reportId: String, to completed: Bool) {
        let previous = states[recommendationId]?.completed ?? false
        states[recommendationId] = CheckoffState(completed: completed)
        persistToCache(reportId: reportId)

        lastFlip = FlipEvent(
            id: UUID(),
            recommendationId: recommendationId,
            reportId: reportId,
            previousCompleted: previous,
            newCompleted: completed
        )

        Task { [weak self] in
            guard let self else { return }
            do {
                let status: ActionCheckoffStatus = completed ? .completed : .reset
                try await ActionCheckoffClient.shared.post(
                    reportId: reportId,
                    recommendationId: recommendationId,
                    status: status
                )
            } catch {
                // Revert local state directly (not through flip()) so
                // UndoToast doesn't observe a synthetic event.
                self.states[recommendationId] = CheckoffState(completed: previous)
                self.persistToCache(reportId: reportId)
                SentrySDK.capture(error: error) { scope in
                    scope.setTag(value: "checkoff", key: "kind")
                    scope.setTag(value: "store_flip", key: "failure_source")
                }
            }
        }
    }

    /// Called from AuthState.signOut. Wipes the in-memory dict and any
    /// per-report UserDefaults cache entries so a different user signing
    /// in on the same device starts clean. Mirrors PushTokenStore's
    /// clearPendingToken defensive sign-out pattern.
    func clearAll() {
        states = [:]
        lastFlip = nil
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys
        where key.hasPrefix("betautopsy.checkoffs.") {
            defaults.removeObject(forKey: key)
        }
    }

    // MARK: - Cache (per-report UserDefaults blob)

    private static func cacheKey(reportId: String) -> String {
        "betautopsy.checkoffs.\(reportId)"
    }

    private func hydrateFromCache(reportId: String) {
        guard let data = UserDefaults.standard.data(forKey: Self.cacheKey(reportId: reportId)),
              let cached = try? JSONDecoder().decode([String: CheckoffState].self, from: data)
        else {
            return
        }
        for (key, value) in cached {
            states[key] = value
        }
    }

    /// Server is authoritative for this report's keys: stale entries
    /// with the report prefix are dropped before the merge so a
    /// reset-on-server clears a previously-cached completed locally.
    private func mergeServer(rows: [ActionCheckoff], reportId: String) {
        let prefix = "\(reportId):"
        for key in states.keys where key.hasPrefix(prefix) {
            states.removeValue(forKey: key)
        }
        for row in rows {
            let isCompleted = row.completedAt != nil && row.dismissedAt == nil
            states[row.recommendationId] = CheckoffState(completed: isCompleted)
        }
    }

    private func persistToCache(reportId: String) {
        let prefix = "\(reportId):"
        let scoped = states.filter { $0.key.hasPrefix(prefix) }
        guard let data = try? JSONEncoder().encode(scoped) else { return }
        UserDefaults.standard.set(data, forKey: Self.cacheKey(reportId: reportId))
    }
}
