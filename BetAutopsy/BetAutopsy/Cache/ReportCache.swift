//
//  ReportCache.swift
//  BetAutopsy
//
//  Disk-backed cache for the user's report list. Backs ReportStore so cold
//  launch renders cached reports instantly (microseconds, before first paint)
//  while network refresh runs async in the background. Network failures and
//  hangs become invisible to the user - they always see their cached data.
//
//  Per-user file scoping prevents cross-user data leaks. Atomic writes prevent
//  partial-write corruption. JSON-on-disk chosen over SwiftData for solo-founder
//  pragmatism: ~50 reports per user max, payload ~kilobytes, encode/decode is
//  microseconds. No schema migrations to manage; version field for future-proofing.
//
//  Isolation split (vs the original single-actor spec): this project ships
//  SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor, which makes AutopsyAnalysis's
//  Decodable conformance MainActor-isolated. An actor's nonisolated context
//  therefore cannot decode AutopsyReport. So the responsibilities are split:
//
//    - `ReportCache` (actor): raw-bytes disk I/O only. Sendable Data crosses
//      the boundary; no model decoding happens here. loadData() is nonisolated
//      so ReportStore.init() can read synchronously without an await ceremony
//      (file reads are atomic at the OS level; the brief on-init read window
//      predates any concurrent writers). save()/clear() are actor-isolated and
//      serialized, keeping disk writes off the main thread and ordered.
//
//    - `ReportCacheCodec` (@MainActor enum): owns the versioned payload and
//      all AutopsyReport encode/decode. Legal because it runs on the MainActor
//      where the Decodable conformance is isolated. Microseconds for our size.
//
//  ReportStore composes the two: ReportCacheCodec.decode(cache.loadData()) for
//  the synchronous init/updateUser read, and encode-on-main + Task{ save } for
//  the off-main ordered write.
//

import Foundation

/// Raw-bytes disk layer. Knows nothing about AutopsyReport - it moves Data to
/// and from a per-user JSON file. Decoding lives in ReportCacheCodec.
actor ReportCache {
    /// Immutable after init, so the nonisolated read path can touch it safely.
    nonisolated let fileURL: URL

    /// `directory` defaults to the app's Documents directory. The override exists
    /// purely for test isolation (point it at a temp dir); production never passes it.
    init(userId: String?, directory: URL? = nil) {
        let base = directory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let suffix = ReportCache.sanitize(userId)
        self.fileURL = base.appendingPathComponent("reports-\(suffix).json")
    }

    /// Sanitize the user id into a filename-safe suffix. Keeps alphanumerics,
    /// dash, and underscore. AppleUserID is a base64-style string that can carry
    /// dots; stripping dots avoids any ".json" extension confusion. nil (signed
    /// out) maps to "anonymous".
    nonisolated static func sanitize(_ userId: String?) -> String {
        guard let userId, !userId.isEmpty else { return "anonymous" }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let cleaned = userId.unicodeScalars
            .filter { allowed.contains($0) }
            .reduce(into: "") { $0.unicodeScalars.append($1) }
        return cleaned.isEmpty ? "anonymous" : cleaned
    }

    /// Synchronous raw read for use in ReportStore.init()/updateUser().
    /// Microseconds for our payload size. Returns nil on a missing file or read
    /// error - never throws. Nonisolated and Data is Sendable, so callers read
    /// without awaiting; decoding happens on the MainActor via ReportCacheCodec.
    nonisolated func loadData() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    /// Atomic write: the OS writes to a temp file then renames, so a kill /
    /// power loss mid-write can never leave a half-written file. Actor-isolated
    /// and serialized: concurrent saves apply in submission order. Off the main
    /// thread by construction (actor executor).
    func save(_ data: Data) {
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Delete the cache file. No-op (swallowed) if it doesn't exist.
    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}

/// MainActor-isolated codec. Owns the on-disk payload shape, its version, and
/// all AutopsyReport encode/decode (legal here; would not compile from an actor's
/// nonisolated context under this project's MainActor-default isolation).
@MainActor
enum ReportCacheCodec {
    /// Bump when a breaking change to the persisted shape ships. A cache written
    /// by a newer version is ignored rather than risking a decode crash.
    ///
    /// v2 (P0 full-report rebuild): the AutopsyAnalysis decode paths changed
    /// (AutopsySummary tolerant init + optional overallGrade, dual
    /// executiveDiagnosis). Blobs written by v1 may hold a degraded decode
    /// (zero-fallback summary, nil sessionDetection) that pre-dates the fix and
    /// would otherwise persist across launches - the source of the stale "$0
    /// hero" and the "Pattern analysis lives in the full report" leak in full
    /// mode. Bumping invalidates them so the next launch re-fetches and
    /// re-decodes cleanly.
    ///
    /// v3 (lazy-fetch): AutopsyReport gained `isFullBody`, and the list
    /// endpoint slims the body. v2 blobs may hold slim-card reports cached as
    /// if full (the shell-render bug) and lack the isFullBody field. Bumping
    /// drops them on upgrade so existing users self-heal on first launch: the
    /// empty cache forces a hydrate, and slim reports lazy-fetch their full
    /// body on open instead of rendering as a shell.
    static let currentVersion = 3

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    /// Decode cached reports from raw bytes. Returns [] on nil/missing data,
    /// corrupted JSON, or a version mismatch - never throws, never crashes.
    /// Default key strategies (no snake-case conversion) because we own both
    /// ends of this round-trip: AutopsyReport's own CodingKeys match on encode
    /// and decode. (The network path uses convertFromSnakeCase; the cache does not.)
    static func decode(_ data: Data?) -> [AutopsyReport] {
        guard let data else { return [] }
        guard let payload = try? decoder.decode(ReportCachePayload.self, from: data) else {
            return []
        }
        guard payload.version == currentVersion else { return [] }
        return payload.reports
    }

    /// Encode reports into a versioned payload. Returns nil if encoding fails
    /// (caller then skips the write rather than persisting garbage).
    static func encode(_ reports: [AutopsyReport]) -> Data? {
        let payload = ReportCachePayload(
            version: currentVersion,
            savedAt: Date(),
            reports: reports
        )
        return try? encoder.encode(payload)
    }
}

/// On-disk envelope. `version` gates forward-compat; `savedAt` is retained for
/// future staleness heuristics (unused in v1). Internal so tests can construct it.
struct ReportCachePayload: Codable {
    let version: Int
    let savedAt: Date
    let reports: [AutopsyReport]
}
