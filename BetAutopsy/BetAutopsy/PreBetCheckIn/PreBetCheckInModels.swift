//
//  PreBetCheckInModels.swift
//  BetAutopsy
//
//  Data shapes for the pre-bet check-in feature. Phase 1 of
//  PR-PREBET-IOS (sprint row 3615964c-daf2-81cf). Phase 2 wires
//  these to the real /api/check-in endpoint; until then the
//  MockedPreBetScorer returns hardcoded responses.
//

import Foundation

enum BetType: String, CaseIterable, Codable {
    case moneyline
    case spread
    case total
    case parlay
    case prop
    case futures

    var displayName: String {
        switch self {
        case .moneyline: return "Moneyline"
        case .spread:    return "Spread"
        case .total:     return "Total"
        case .parlay:    return "Parlay"
        case .prop:      return "Prop"
        case .futures:   return "Futures"
        }
    }
}

enum Sport: String, CaseIterable, Codable {
    case nfl
    case nba
    case mlb
    case nhl
    case ncaaf
    case ncaab
    case soccer
    case mma
    case tennis
    case golf
    case other

    var displayName: String {
        switch self {
        case .nfl:    return "NFL"
        case .nba:    return "NBA"
        case .mlb:    return "MLB"
        case .nhl:    return "NHL"
        case .ncaaf:  return "NCAAF"
        case .ncaab:  return "NCAAB"
        case .soccer: return "Soccer"
        case .mma:    return "MMA"
        case .tennis: return "Tennis"
        case .golf:   return "Golf"
        case .other:  return "Other"
        }
    }
}

struct PreBetCheckInRequest: Codable {
    let sport: Sport
    let stake: Decimal
    let odds: Int
    let betType: BetType
    let placedAt: Date
    let localHour: Int
}

extension PreBetCheckInRequest {
    /// 5-param convenience init: derives `localHour` from `placedAt`
    /// via `Calendar.current.component(.hour, ...)`. Production code
    /// uses this. The 6-param synthesized memberwise init stays
    /// available (declaring this init in an extension does not
    /// suppress synthesis) so DEBUG paths can pass an explicit
    /// `localHour` without disturbing `placedAt` — important because
    /// `placedAt` is what backend uses for recency calculations,
    /// while `localHour` is only the user's wall-clock hour for the
    /// late-night flag heuristic.
    init(sport: Sport, stake: Decimal, odds: Int, betType: BetType, placedAt: Date) {
        self.init(
            sport: sport,
            stake: stake,
            odds: odds,
            betType: betType,
            placedAt: placedAt,
            localHour: Calendar.current.component(.hour, from: placedAt)
        )
    }
}

enum FlagSeverity: String, Codable {
    case high
    case medium
    case low
    case info
}

struct PreBetCheckInFlag: Codable, Identifiable {
    /// Opaque server-assigned id. Was `UUID` in Phase 1 when the
    /// mocked scorer produced one per call; backend may emit any
    /// stable string form (canonical UUID, nanoid, base36, etc.), so
    /// the iOS client treats it as opaque and only uses it for
    /// SwiftUI `Identifiable` conformance.
    let id: String
    let severity: FlagSeverity
    let title: String
    let detail: String
}

enum PreBetRecommendation: String, Codable {
    case placeAnyway  = "place_anyway"
    case waitThirty   = "wait_thirty"
    case placeBet     = "place_bet"
}

struct PreBetCheckInResponse: Codable {
    /// Server-assigned id for this check-in. Required for outcome
    /// posting via POST /api/check-in/outcome. Always present on
    /// 200 responses from backend Phase 3 (merged 495b2936).
    let checkInId: String
    let betQualityScore: Int
    let flags: [PreBetCheckInFlag]
    let recommendation: PreBetRecommendation
    let summary: String
}

enum CheckInOutcome: String, Codable {
    case placedAnyway = "placed_anyway"
    case waited       = "waited"
    case placedBet    = "placed_bet"
}

struct CheckInOutcomeRequest: Codable {
    let checkInId: String
    let outcome: CheckInOutcome
}
