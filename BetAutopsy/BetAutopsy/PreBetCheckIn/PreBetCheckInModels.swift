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
}

enum FlagSeverity: String, Codable {
    case high
    case medium
    case low
    case info
}

struct PreBetCheckInFlag: Codable, Identifiable {
    let id: UUID
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
    let betQualityScore: Int
    let flags: [PreBetCheckInFlag]
    let recommendation: PreBetRecommendation
    let summary: String
}
