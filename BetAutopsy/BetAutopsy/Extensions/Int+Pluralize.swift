//
//  Int+Pluralize.swift
//  BetAutopsy
//
//  Single source of truth for count-based pluralization of user-facing
//  copy. Replaces the scattered "\(n) bets" interpolations that rendered
//  "1 bets" when a count legitimately equals 1.
//

import Foundation

extension Int {
    /// Returns "\(self) \(self == 1 ? singular : plural)".
    /// Example: 1.pluralized("bet", "bets") -> "1 bet";
    ///          5.pluralized("bet", "bets") -> "5 bets".
    func pluralized(_ singular: String, _ plural: String) -> String {
        "\(self) \(self == 1 ? singular : plural)"
    }

    /// Caps variant matching the project's "5 BETS" caps chip style used
    /// in Ch 5/6. Example: 1.pluralizedCaps("bet", "bets") -> "1 BET".
    func pluralizedCaps(_ singular: String, _ plural: String) -> String {
        "\(self) \(self == 1 ? singular.uppercased() : plural.uppercased())"
    }
}
