//
//  PreBetReengageRouter.swift
//  BetAutopsy
//
//  Process-lifetime bridge for a cool-off notification tap. When the +30
//  notification fires and the user taps it, AppDelegate sets
//  `pendingReopen`; TodayView observes it and re-presents the check-in
//  sheet so the user lands back where the decision lives, not on a cold
//  Today screen. Mirrors DeepLinkRouter's shape (single observable flag
//  consumed by the root surface) but carries no report id - the cool-off
//  deep-link is a re-open, not a report fetch.
//

import Foundation
import Observation

@MainActor
@Observable
final class PreBetReengageRouter {
    static let shared = PreBetReengageRouter()
    private init() {}

    /// Set from AppDelegate on a `prebet_cooloff` notification tap.
    /// Consumed (and cleared) by TodayView to re-present the check-in.
    var pendingReopen = false

    func requestReopen() { pendingReopen = true }
    func consume() { pendingReopen = false }
}
