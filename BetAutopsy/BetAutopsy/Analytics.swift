//
//  Analytics.swift
//  BetAutopsy
//
//  Wrapper around TelemetryDeck SDK.
//  Privacy-first analytics, no PII. Free tier covers ~10K signals/day.
//
//  Usage:
//    Analytics.signal("auth.completed")
//    Analytics.signal("archetype.revealed", parameters: ["archetype": "The Tilter"])
//

import Foundation
import TelemetryDeck

enum Analytics {
    static let appID = "99840A9B-0E36-4F2F-927D-9C5CD4C55B54"

    /// Initialize TelemetryDeck. Call once on app launch.
    static func initialize() {
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
        signal("app.launched")
    }

    /// Send a signal with optional string parameters. No PII.
    static func signal(_ name: String, parameters: [String: String] = [:]) {
        TelemetryDeck.signal(name, parameters: parameters)
    }
}
