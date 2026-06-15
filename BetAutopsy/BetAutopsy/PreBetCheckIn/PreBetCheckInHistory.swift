//
//  PreBetCheckInHistory.swift
//  BetAutopsy
//
//  Local, on-device record of every completed pre-bet check-in. The
//  server outcome post (POST /api/check-in/outcome) is write-only
//  telemetry: nothing reads it back, so the user never sees that their
//  pauses are accumulating. A behavior-change loop only works if the
//  user watches their own good decisions add up. This store is that
//  mirror - LOCAL for v1 (no new backend read endpoint), persisted to
//  UserDefaults, surfaced on TodayView as a calm-decisions counter.
//
//  @MainActor @Observable singleton so SwiftUI surfaces re-render when a
//  new check-in lands. Bounded to the most recent 100 records.
//

import Foundation
import Observation

/// One completed check-in. `outcome` is the in-the-moment decision the
/// user made on the read screen. Stake stored as a Double for a small,
/// stable Codable footprint (display routes through BAFormat).
struct CheckInRecord: Codable, Identifiable {
    let id: String
    let date: Date
    let sportRaw: String
    let stake: Double
    let toneRaw: String
    let outcomeRaw: String

    var outcome: CheckInOutcome? { CheckInOutcome(rawValue: outcomeRaw) }
    var tone: ReadTone? { ReadTone(rawValue: toneRaw) }
}

@MainActor
@Observable
final class PreBetCheckInHistory {
    static let shared = PreBetCheckInHistory()

    private let defaultsKey = "prebet.checkin.history.v1"
    private let cap = 100

    private(set) var records: [CheckInRecord] = []

    private init() {
        load()
    }

    // MARK: - Derived counters (surfaced on TodayView)

    /// Total times the user stopped to check a bet before placing it.
    var totalCheckIns: Int { records.count }

    /// Times the in-the-moment decision was to step back rather than log
    /// the bet. The win we reflect to the user.
    var steppedBackCount: Int {
        records.filter { $0.outcome == .waited }.count
    }

    var hasHistory: Bool { !records.isEmpty }

    // MARK: - Mutation

    /// Records a completed check-in. Called from the coordinator on every
    /// CTA decision, independent of whether the server outcome post
    /// succeeds (the local loop must not depend on the network).
    func record(
        id: String,
        date: Date,
        sport: Sport,
        stake: Decimal,
        tone: ReadTone,
        outcome: CheckInOutcome
    ) {
        let entry = CheckInRecord(
            id: id,
            date: date,
            sportRaw: sport.rawValue,
            stake: NSDecimalNumber(decimal: stake).doubleValue,
            toneRaw: tone.rawValue,
            outcomeRaw: outcome.rawValue
        )
        records.insert(entry, at: 0)
        if records.count > cap {
            records = Array(records.prefix(cap))
        }
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([CheckInRecord].self, from: data) {
            records = decoded
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}
