//
//  MockedPreBetScorer.swift
//  BetAutopsy
//
//  PHASE 1 ONLY. Returns hardcoded responses based on a small set of
//  heuristics (time-of-day, stake size, parlay flag). Phase 2 of
//  PR-PREBET-IOS replaces this with a real call to /api/check-in
//  (sprint row 3615964c-daf2-81e7 — ENGINE-PR-CHECKIN-SCORER).
//
//  The flag detail strings explicitly say "Sample insight" + "Real
//  engine analysis lands Phase 2" so any screenshot from Phase 1
//  testing reads as a mock rather than a production response.
//

import Foundation

struct MockedPreBetScorer {
    /// `now` is a DEBUG-only override for time-dependent flag testing.
    /// In production code paths, callers pass nil and the scorer uses
    /// `request.placedAt` as the temporal anchor. The override lets
    /// iPhone verification cover both result paths regardless of the
    /// wall-clock time at which testing happens.
    static func score(_ request: PreBetCheckInRequest, now: Date? = nil) -> PreBetCheckInResponse {
        let effectiveNow = now ?? request.placedAt
        let hour = Calendar.current.component(.hour, from: effectiveNow)
        let isLateNight = hour >= 23 || hour < 4
        let isLargeStake = request.stake >= 100
        let isParlay = request.betType == .parlay

        var flags: [PreBetCheckInFlag] = []
        var score = 75

        if isLateNight {
            flags.append(.init(
                id: UUID(),
                severity: .high,
                title: "Late-night betting",
                detail: "Sample insight. Your historical ROI in this time window has trended negative. Real engine analysis lands Phase 2."
            ))
            score -= 30
        }

        if isLargeStake {
            flags.append(.init(
                id: UUID(),
                severity: .medium,
                title: "Above your usual stake",
                detail: "Sample insight. This stake is larger than your typical pattern. Real engine analysis lands Phase 2."
            ))
            score -= 15
        }

        if isParlay {
            flags.append(.init(
                id: UUID(),
                severity: .medium,
                title: "Parlay session",
                detail: "Sample insight. Your parlay ROI has historically trailed your straight-bet ROI. Real engine analysis lands Phase 2."
            ))
            score -= 12
        }

        score = max(0, min(100, score))

        let recommendation: PreBetRecommendation
        let summary: String
        switch flags.count {
        case 0:
            recommendation = .placeBet
            summary = "No risk flags. Behavioral state looks clean."
        case 1:
            recommendation = .waitThirty
            summary = "One risk flag. Worth a pause."
        default:
            recommendation = .waitThirty
            summary = "\(flags.count) risk flags. Waiting 30 minutes is the smart play."
        }

        return .init(
            betQualityScore: score,
            flags: flags,
            recommendation: recommendation,
            summary: summary
        )
    }
}
