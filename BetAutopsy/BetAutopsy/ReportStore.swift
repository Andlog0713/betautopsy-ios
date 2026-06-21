//
//  ReportStore.swift
//  BetAutopsy
//
//  @Observable store for AutopsyReport instances, now backed by an on-disk
//  cache (P0 PERSISTENCE CACHE-FIRST). Cold launch reads the cache synchronously
//  in init() (microseconds, before first paint) so the UI renders cached reports
//  instantly; network refresh runs async in the background via hydrate(). A
//  network hang or failure is invisible: the cached reports stay on screen and
//  are never cleared on error.
//
//  Cache responsibilities are split to satisfy this project's MainActor-default
//  isolation (AutopsyAnalysis's Decodable conformance is MainActor-isolated):
//  the `ReportCache` actor moves raw Data on/off disk (off-main, ordered writes;
//  nonisolated synchronous read), while the `@MainActor ReportCacheCodec` does
//  the AutopsyReport encode/decode. See ReportCache.swift.
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
    /// post-purchase polling via PaywallView, future v1.1 paths) use the
    /// .shared accessor directly.
    static let shared = ReportStore()

    private(set) var reports: [AutopsyReport] = []

    /// True while hydrate() has an in-flight GET /api/reports. Drives the
    /// loading state on cold launch and the empty-state spinner.
    var isHydrating: Bool = false

    /// Last hydrate() failure, retained so ReportListView can surface an
    /// error + retry. Cleared at the start of each hydrate attempt. Never
    /// clears the cached reports - the whole point of cache-first.
    var hydrationError: Error?

    /// Combine surface for non-SwiftUI observers (REBUILD-PHASE-2 D14).
    /// @Observable drives SwiftUI views; ReportScrollViewModel needs a
    /// Combine publisher to react to the post-purchase upsert without the
    /// store conforming to ObservableObject. Fired on every mutation that
    /// replaces the in-memory list with the current reports snapshot. Not
    /// @Observable-tracked (it's a let).
    let reportsChanged = PassthroughSubject<[AutopsyReport], Never>()

    /// Disk-backed cache, scoped to the current user's file. Reassigned by
    /// updateUser()/clear() when the auth user changes. var (not let) so the
    /// file follows the signed-in user; persist() captures it by value at
    /// call time so a write always lands in the cache live when it was issued.
    private var cache: ReportCache

    /// Single-flight guard. A second hydrate() call while one is in flight
    /// awaits the same task instead of starting a duplicate fetch.
    private var refreshTask: Task<Void, Never>?

    init() {
        // Scope the initial cache to the already-signed-in user (if any) and
        // load synchronously, before the first view paints. AuthState.shared is
        // populated from UserDefaults in its own init, which runs ahead of this
        // store's first reference (RootTabView @State / cross-cutting writers).
        let userId = AuthState.shared.user?.identityKey
        let cache = ReportCache(userId: userId)
        self.cache = cache

        #if DEBUG
        let start = Date()
        let loaded = ReportCacheCodec.decode(cache.loadData())
        self.reports = loaded
        let ms = Date().timeIntervalSince(start) * 1000
        print("[cache] loaded \(loaded.count) reports from cache in \(String(format: "%.1f", ms))ms")
        #else
        self.reports = ReportCacheCodec.decode(cache.loadData())
        #endif
    }

    /// The reports to render. No longer substitutes a mock when empty
    /// (P0 persistence): callers own their own empty state. ReportListView
    /// shows an upload prompt; SessionsTabView falls through to its own
    /// emptyState. Retained as a named accessor for both call sites.
    var displayedReports: [AutopsyReport] {
        reports
    }

    /// Called from RootTabView.task(id:) when the auth user changes (cold
    /// launch, sign-in, sign-out). Re-scopes the cache to the new user's file
    /// and swaps in their cached reports synchronously - instant, before any
    /// await fires - so the UI re-renders with the right user's data before the
    /// caller kicks off hydrate(). Per-user file scoping is what prevents
    /// serving user A's cache to user B.
    func updateUser(_ userId: String?) {
        let newCache = ReportCache(userId: userId)
        self.cache = newCache
        self.reports = ReportCacheCodec.decode(newCache.loadData())
        self.hydrationError = nil
        reportsChanged.send(reports)
    }

    /// Hydrate from Supabase via GET /api/reports (web 5cc8356). Called once
    /// per userId transition by RootTabView (after updateUser) and by
    /// ReportListView's pull-to-refresh. Single-flight: concurrent callers
    /// coalesce on the in-flight task. On success: replaces reports and writes
    /// the cache. On failure: KEEPS the cached reports (offline / hang
    /// resilience) and only records hydrationError.
    @MainActor
    func hydrate() async {
        if let existing = refreshTask {
            await existing.value
            return
        }
        let task = Task { await self.performHydrate() }
        refreshTask = task
        await task.value
        refreshTask = nil
    }

    @MainActor
    private func performHydrate() async {
        isHydrating = true
        hydrationError = nil
        do {
            let fetched = try await ReportListClient.shared.fetchList()
            // CRITICAL: the list endpoint returns SLIM card rows (body omitted).
            // Merge them over any full bodies we already hold so a refresh can
            // never clobber a report whose full body was fetched-on-open or
            // materialized by the IAP unlock (PR #34) back down to a shell.
            let merged = Self.mergePreservingFullBodies(fetched: fetched, existing: self.reports)
            self.reports = merged
            persist(merged)
        } catch {
            self.hydrationError = error
            // CRITICAL: do NOT touch self.reports on error - keep the cached
            // list visible. This is the entire point of cache-first.
        }
        isHydrating = false
    }

    /// Merge the slim list (server owns membership + ordering) with any full
    /// bodies already held: for an id we already hold at full body, keep the
    /// held full report; otherwise take the slim card row. The full body is a
    /// strict superset of the slim card, so this loses nothing. Reports dropped
    /// server-side fall out naturally (the result maps over `fetched`). Static
    /// + pure for testability.
    static func mergePreservingFullBodies(
        fetched: [AutopsyReport],
        existing: [AutopsyReport]
    ) -> [AutopsyReport] {
        let existingById = Dictionary(existing.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return fetched.map { slim in
            if let held = existingById[slim.id], held.isFullBody { return held }
            return slim
        }
    }

    func add(_ report: AutopsyReport) {
        reports.insert(report, at: 0)
        persist(reports)
        reportsChanged.send(reports)
    }

    /// Inserts or replaces a report by id. Used by PaywallView's post-purchase
    /// path (ReportStore.shared.upsert) when the child full row materializes:
    /// the new full is inserted as the newest and the UI (via reportsChanged)
    /// swaps the open snapshot for it in place (D14). Persists to cache so the
    /// IAP-converted report survives a cold launch.
    func upsert(_ report: AutopsyReport) {
        if let idx = reports.firstIndex(where: { $0.id == report.id }) {
            reports[idx] = report
        } else {
            reports.insert(report, at: 0)
        }
        persist(reports)
        reportsChanged.send(reports)
    }

    /// Sign-out path. Empties the in-memory list, wipes the current user's
    /// cache file, and re-scopes the cache to anonymous so the next sign-in
    /// (potentially a different user) starts clean. Called both directly from
    /// AuthState.signOut (immediate, for security) and from RootTabView's
    /// task(id:) when the user id goes nil (belt + suspenders).
    func clear() {
        refreshTask?.cancel()
        refreshTask = nil
        reports = []
        hydrationError = nil
        let old = cache
        Task { await old.clear() }
        cache = ReportCache(userId: nil)
        reportsChanged.send(reports)
    }

    /// Encode on the MainActor (where AutopsyReport's Codable conformance is
    /// isolated), then hand the bytes to the cache actor for an ordered,
    /// off-main atomic write. Captures the live cache by value so a write issued
    /// before an updateUser()/clear() still targets the cache it was meant for.
    private func persist(_ reports: [AutopsyReport]) {
        guard let data = ReportCacheCodec.encode(reports) else { return }
        let cache = self.cache
        Task { await cache.save(data) }
    }
}
