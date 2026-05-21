//
//  ReportCacheTests.swift
//  BetAutopsyTests
//
//  Coverage for the disk layer: ReportCache (raw-bytes actor, per-user file
//  scoping, atomic write, clear) and ReportCacheCodec (versioned payload
//  encode/decode, corruption tolerance, version-mismatch rejection).
//
//  NOTE: No XCTest target existed when this file was authored (P0 PERSISTENCE
//  CACHE-FIRST). These tests ship as a compile-ready deliverable. To run them:
//  create a unit-test target in Xcode, add this file to it, then `xcodebuild
//  test`. The cache layer is fully isolated (directory override on init), so
//  every test below runs without touching the app's real Documents directory.
//

import XCTest
@testable import BetAutopsy

final class ReportCacheTests: XCTestCase {

    private var tempDir: URL!

    override func setUp() async throws {
        try await super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("ReportCacheTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        if let tempDir { try? FileManager.default.removeItem(at: tempDir) }
        tempDir = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    /// Minimal AutopsyReport for round-trip assertions. Only the fields the
    /// cache cares about (identity + a non-trivial nested analysis) matter.
    private func makeReport(id: String) -> AutopsyReport {
        let summary = AutopsySummary(
            totalBets: 42, record: "20-22", totalProfit: -150.0,
            roiPercent: -3.5, avgStake: 25.0, dateRange: "Jan-Mar",
            overallGrade: "C"
        )
        let analysis = AutopsyAnalysis(
            schemaVersion: 1, summary: summary,
            biasesDetected: [], strategicLeaks: [],
            behavioralPatterns: [], recommendations: [],
            emotionScore: 50, emotionBreakdown: nil,
            bankrollHealth: .caution, disciplineScore: nil,
            betiq: nil, enhancedTilt: nil,
            timingAnalysis: nil, oddsAnalysis: nil,
            sessionDetection: nil, betAnnotations: nil,
            sportSpecificFindings: nil, dfsMode: false,
            dfsPlatform: nil, dfsMetrics: nil,
            executiveDiagnosis: nil, pertinentNegatives: nil,
            contradictions: nil, bettingArchetype: nil,
            quizArchetype: nil
        )
        return AutopsyReport(
            id: id, caseNumber: "BA-\(id.prefix(8).uppercased())",
            reportType: "full", betCountAnalyzed: 42,
            dateRangeStart: "2026-01-01", dateRangeEnd: "2026-03-01",
            createdAt: "2026-03-02T00:00:00Z", analysis: analysis
        )
    }

    // MARK: - Codec: load behavior

    func testMissingFileReturnsEmpty() async {
        let cache = ReportCache(userId: "missing-user", directory: tempDir)
        let data = cache.loadData()       // nonisolated, synchronous
        XCTAssertNil(data)
        let reports = await ReportCacheCodec.decode(data)
        XCTAssertEqual(reports.count, 0)
    }

    func testCorruptedJSONReturnsEmpty() async throws {
        let cache = ReportCache(userId: "corrupt-user", directory: tempDir)
        try Data("{ this is not valid json ]".utf8).write(to: cache.fileURL)

        let reports = await ReportCacheCodec.decode(cache.loadData())
        XCTAssertEqual(reports.count, 0, "Corrupted JSON must decode to empty, never crash.")
    }

    func testVersionMismatchReturnsEmpty() async throws {
        // Hand-build a payload with a version newer than currentVersion.
        let cache = ReportCache(userId: "future-version", directory: tempDir)
        let future = ReportCachePayload(
            version: await ReportCacheCodec.currentVersion + 1,
            savedAt: Date(),
            reports: [makeReport(id: "r1")]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(future).write(to: cache.fileURL)

        let reports = await ReportCacheCodec.decode(cache.loadData())
        XCTAssertEqual(reports.count, 0, "A future cache version must be ignored, not decoded.")
    }

    // MARK: - Save round-trip

    func testSaveProducesReadableFile() async {
        let cache = ReportCache(userId: "roundtrip", directory: tempDir)
        let originals = [makeReport(id: "alpha"), makeReport(id: "beta")]

        let data = await ReportCacheCodec.encode(originals)
        XCTAssertNotNil(data)
        await cache.save(data!)

        let loaded = await ReportCacheCodec.decode(cache.loadData())
        XCTAssertEqual(loaded.map(\.id), ["alpha", "beta"])
        XCTAssertEqual(loaded.first?.analysis.summary.totalBets, 42)
        XCTAssertEqual(loaded.first?.analysis.bankrollHealth, .caution)
    }

    // MARK: - Per-user scoping

    func testCacheScopedByUserId() async {
        let cacheA = ReportCache(userId: "user-A", directory: tempDir)
        let cacheB = ReportCache(userId: "user-B", directory: tempDir)
        XCTAssertNotEqual(cacheA.fileURL, cacheB.fileURL, "Different users must map to different files.")

        await cacheA.save((await ReportCacheCodec.encode([makeReport(id: "a-only")]))!)

        // B must NOT see A's data.
        let bReports = await ReportCacheCodec.decode(cacheB.loadData())
        XCTAssertEqual(bReports.count, 0, "User B must never read user A's cache.")

        let aReports = await ReportCacheCodec.decode(cacheA.loadData())
        XCTAssertEqual(aReports.map(\.id), ["a-only"])
    }

    func testSanitizeStripsUnsafeCharacters() {
        // Apple user ids carry dots and can carry other punctuation; the suffix
        // must keep only [A-Za-z0-9-_].
        XCTAssertEqual(ReportCache.sanitize("abc.123_def-XYZ"), "abc123_def-XYZ")
        XCTAssertEqual(ReportCache.sanitize(nil), "anonymous")
        XCTAssertEqual(ReportCache.sanitize(""), "anonymous")
        XCTAssertEqual(ReportCache.sanitize("///...!!!"), "anonymous",
                       "An id with no safe characters must fall back to anonymous, not an empty filename.")
    }

    func testDistinctIdsThatSanitizeSameShareFile() {
        // Documented limitation: sanitize is lossy, so two ids differing only in
        // stripped characters collide. AppleUserID values are long opaque strings;
        // a real-world collision is implausible. This test pins the behavior so a
        // future change to sanitize is a conscious decision.
        XCTAssertEqual(ReportCache.sanitize("user.1"), ReportCache.sanitize("user1"))
    }

    // MARK: - Clear

    func testClearDeletesFile() async {
        let cache = ReportCache(userId: "to-clear", directory: tempDir)
        await cache.save((await ReportCacheCodec.encode([makeReport(id: "x")]))!)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cache.fileURL.path))

        await cache.clear()
        XCTAssertFalse(FileManager.default.fileExists(atPath: cache.fileURL.path))

        // Clearing again is a no-op, never throws.
        await cache.clear()
        let reports = await ReportCacheCodec.decode(cache.loadData())
        XCTAssertEqual(reports.count, 0)
    }

    // MARK: - Atomic write

    func testAtomicWriteLeavesAValidFile() async {
        // Two successive saves; the file must always be a complete, decodable
        // payload (atomic write means no half-written intermediate is ever read).
        let cache = ReportCache(userId: "atomic", directory: tempDir)

        await cache.save((await ReportCacheCodec.encode([makeReport(id: "first")]))!)
        await cache.save((await ReportCacheCodec.encode([makeReport(id: "second"), makeReport(id: "third")]))!)

        let loaded = await ReportCacheCodec.decode(cache.loadData())
        XCTAssertEqual(loaded.map(\.id), ["second", "third"], "Last write wins; file is always whole.")
    }
}
