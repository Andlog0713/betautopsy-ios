//
//  PreBetCheckInCoordinator.swift
//  BetAutopsy
//
//  @Observable state machine for the pre-bet check-in flow. Owned as
//  @State inside PreBetCheckInView (lifetime = sheet lifetime), so
//  each open of the sheet starts fresh in .input.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class PreBetCheckInCoordinator {
    enum Phase: Equatable {
        case input
        case scoring
        case result(PreBetCheckInResponse)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.input, .input), (.scoring, .scoring):
                return true
            case let (.result(a), .result(b)):
                return a.betQualityScore == b.betQualityScore
                    && a.flags.map(\.id) == b.flags.map(\.id)
            default:
                return false
            }
        }
    }

    var phase: Phase = .input
    var sport: Sport = .nfl
    var stake: Decimal = 0
    var odds: Int = -110
    var betType: BetType = .moneyline

    #if DEBUG
    /// DEBUG-only override for time-dependent flag testing. Surfaced
    /// via the hidden 4-tap affordance on the input screen.
    var debugNowOverride: Date? = nil
    #endif

    func submit() async {
        phase = .scoring
        try? await Task.sleep(nanoseconds: 600_000_000)
        let request = PreBetCheckInRequest(
            sport: sport,
            stake: stake,
            odds: odds,
            betType: betType,
            placedAt: Date()
        )
        #if DEBUG
        let response = MockedPreBetScorer.score(request, now: debugNowOverride)
        #else
        let response = MockedPreBetScorer.score(request)
        #endif
        phase = .result(response)
    }

    func reset() {
        phase = .input
        stake = 0
        odds = -110
    }
}
