//
//  ReportStoreCacheTests.swift
//  BetAutopsyTests
//
//  Behavior coverage for ReportStore's cache integration: synchronous cache
//  swap on updateUser, the critical "network failure retains cached reports"
//  invariant, clear wiping both memory and disk, and upsert/add merging into
//  the cache while still firing the reportsChanged D14 subject.
//
//  NOTE: No XCTest target existed when this file was authored (P0 PERSISTENCE
//  CACHE-FIRST); ships as a compile-ready deliverable. See ReportCacheTests for
//  how to wire and run.
//
//  ARCHITECTURE NOTE on what is and isn't covered here:
//  ReportStore.shared is a process-lifetime singleton and ReportListClient is a
//  concrete singleton with no injection seam (preserving both was an approved
//  constraint of this PR). So tests run against the real store and the real
//  network client:
//    - The success path (testRefreshSuccess) needs a live backend + auth session
//      and is therefore an integration test, not a unit test. It is described
//      below but intentionally not asserted here.
//    - The FAILURE path IS unit-testable: with no Supabase session in the test
//      environment, fetchList() throws, which is exactly what the critical
//      retain-on-failure assertion needs. testRefreshFailureRetainsCachedReports
//      relies on that.
//  Each test scopes itself to a unique userId so the singleton's Documents-backed
//  files never collide across tests, and cleans up in tearDown.
//

import XCTest
import Combine
@testable import BetAutopsy

@MainActor
final class ReportStoreCacheTests: XCTestCase {

    private let store = ReportStore.shared
    private var scopedUserIds: [String] = []
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() async throws {
        // Remove every cache file this test scoped, then reset the singleton to
        // a clean anonymous state so the next test starts fresh.
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        for id in scopedUserIds {
            let url = docs.appendingPathComponent("reports-\(ReportCache.sanitize(id)).json")
            try? FileManager.default.removeItem(at: url)
        }
        scopedUserIds = []
        cancellables = []
        store.clear()
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func uniqueUser() -> String {
        let id = "test-\(UUID().uuidString)"
        scopedUserIds.append(id)
        return id
    }

    private func makeReport(id: String, reportType: String = "full",
                            upgradedFrom: String? = nil) -> AutopsyReport {
        let summary = AutopsySummary(
            totalBets: 10, record: "5-5", totalProfit: 0,
            roiPercent: 0, avgStake: 10, dateRange: "", overallGrade: "B"
        )
        let analysis = AutopsyAnalysis(
            schemaVersion: 1, summary: summary,
            biasesDetected: [], strategicLeaks: [],
            behavioralPatterns: [], recommendations: [],
            emotionScore: 0, emotionBreakdown: nil,
            bankrollHealth: .healthy, disciplineScore: nil,
            betiq: nil, enhancedTilt: nil, timingAnalysis: nil,
            oddsAnalysis: nil, sessionDetection: nil, betAnnotations: nil,
            sportSpecificFindings: nil, dfsMode: false, dfsPlatform: nil,
            dfsMetrics: nil, executiveDiagnosis: nil, pertinentNegatives: nil,
            contradictions: nil, bettingArchetype: nil, quizArchetype: nil
        )
        return AutopsyReport(
            id: id, caseNumber: "BA-\(id.prefix(8).uppercased())",
            reportType: reportType, betCountAnalyzed: 10,
            dateRangeStart: nil, dateRangeEnd: nil,
            createdAt: "2026-03-02T00:00:00Z", analysis: analysis,
            upgradedFromSnapshotId: upgradedFrom
        )
    }

    /// Seed a user's on-disk cache directly (awaitable write) so a subsequent
    /// store.updateUser(user) loads a known set synchronously.
    private func seedCache(user: String, reports: [AutopsyReport]) async {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cache = ReportCache(userId: user, directory: docs)
        guard let data = ReportCacheCodec.encode(reports) else {
            return XCTFail("encode failed")
        }
        await cache.save(data)
    }

    /// Read a user's on-disk cache directly to verify persistence.
    private func readCache(user: String) -> [AutopsyReport] {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cache = ReportCache(userId: user, directory: docs)
        return ReportCacheCodec.decode(cache.loadData())
    }

    /// Poll until `condition` is true or the timeout elapses. ReportStore's
    /// persist() is fire-and-forget (Task { await cache.save }), so disk writes
    /// land shortly after the synchronous call returns.
    private func waitUntil(timeout: TimeInterval = 2.0,
                           _ condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
        }
    }

    // MARK: - updateUser swap

    func testUpdateUserSwapsCachedReports() async {
        let user = uniqueUser()
        await seedCache(user: user, reports: [makeReport(id: "u1"), makeReport(id: "u2")])

        store.updateUser(user)   // synchronous load

        XCTAssertEqual(store.reports.map(\.id), ["u1", "u2"],
                       "updateUser must swap in the user's cached reports synchronously.")
        XCTAssertNil(store.hydrationError)
    }

    func testUpdateUserToUnknownUserShowsEmpty() async {
        let knownUser = uniqueUser()
        await seedCache(user: knownUser, reports: [makeReport(id: "k1")])
        store.updateUser(knownUser)
        XCTAssertEqual(store.reports.count, 1)

        // Switching to a user with no cache file must show empty, never the
        // previous user's data.
        let freshUser = uniqueUser()
        store.updateUser(freshUser)
        XCTAssertEqual(store.reports.count, 0, "A different user must never inherit cached reports.")
    }

    // MARK: - CRITICAL: failure retains cache

    func testRefreshFailureRetainsCachedReports() async {
        // The test environment has no Supabase session, so hydrate()'s
        // fetchList() throws. The cached reports must remain untouched.
        let user = uniqueUser()
        await seedCache(user: user, reports: [makeReport(id: "keep-1"), makeReport(id: "keep-2")])
        store.updateUser(user)
        XCTAssertEqual(store.reports.count, 2)

        await store.hydrate()   // expected to fail (no auth session)

        XCTAssertEqual(store.reports.map(\.id), ["keep-1", "keep-2"],
                       "A network failure must NEVER clear cached reports - the entire point of cache-first.")
        XCTAssertNotNil(store.hydrationError, "A failed hydrate should record the error for optional UI display.")
    }

    /// Integration test (not asserted here): with a live backend + valid auth
    /// session, hydrate() replaces reports with the server list AND writes it to
    /// the cache. Verify on device: sign in, upload a report, kill + relaunch,
    /// confirm the report renders from cache before the network returns.
    func testRefreshSuccessUpdatesReportsAndCache() throws {
        throw XCTSkip("Integration-only: needs a live backend + auth session (no ReportListClient injection seam).")
    }

    // MARK: - clear wipes memory + disk

    func testClearWipesReportsAndCache() async {
        let user = uniqueUser()
        await seedCache(user: user, reports: [makeReport(id: "c1")])
        store.updateUser(user)
        XCTAssertEqual(store.reports.count, 1)

        store.clear()

        XCTAssertEqual(store.reports.count, 0, "clear() empties the in-memory list synchronously.")
        // File deletion is async (Task in clear()); poll for it.
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = docs.appendingPathComponent("reports-\(ReportCache.sanitize(user)).json")
        await waitUntil { !FileManager.default.fileExists(atPath: url.path) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path),
                       "clear() must delete the user's cache file.")
    }

    // MARK: - upsert / add merge into cache (IAP path)

    func testUpsertMergesAndPersists() async {
        let user = uniqueUser()
        store.updateUser(user)            // start empty
        XCTAssertEqual(store.reports.count, 0)

        let report = makeReport(id: "new-full")
        store.upsert(report)              // PaywallView's post-purchase call shape

        XCTAssertEqual(store.reports.map(\.id), ["new-full"])
        await waitUntil { self.readCache(user: user).contains { $0.id == "new-full" } }
        XCTAssertTrue(readCache(user: user).contains { $0.id == "new-full" },
                      "upsert must persist to cache so the IAP-converted report survives cold launch.")
    }

    func testUpsertReplacesById() async {
        let user = uniqueUser()
        store.updateUser(user)
        store.upsert(makeReport(id: "dup", reportType: "snapshot"))
        store.upsert(makeReport(id: "dup", reportType: "full"))

        XCTAssertEqual(store.reports.count, 1, "Same id must replace, not duplicate.")
        XCTAssertEqual(store.reports.first?.reportType, "full")
    }

    func testAddPrependsAndPersists() async {
        let user = uniqueUser()
        store.updateUser(user)
        store.add(makeReport(id: "older"))
        store.add(makeReport(id: "newer"))

        XCTAssertEqual(store.reports.map(\.id), ["newer", "older"], "add inserts at the front.")
        await waitUntil { self.readCache(user: user).count == 2 }
        XCTAssertEqual(readCache(user: user).count, 2, "add must persist to cache.")
    }

    // MARK: - reportsChanged (D14) preservation

    func testUpsertFiresReportsChanged() async {
        let user = uniqueUser()
        store.updateUser(user)

        let exp = expectation(description: "reportsChanged fires on upsert")
        store.reportsChanged
            .sink { reports in
                if reports.contains(where: { $0.id == "d14" }) { exp.fulfill() }
            }
            .store(in: &cancellables)

        store.upsert(makeReport(id: "d14", reportType: "full", upgradedFrom: "snap-1"))
        await fulfillment(of: [exp], timeout: 1.0)
    }
}
