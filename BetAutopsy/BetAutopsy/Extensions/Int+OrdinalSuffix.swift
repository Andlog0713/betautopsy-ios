//
//  Int+OrdinalSuffix.swift
//  BetAutopsy
//
//  Proper English ordinal suffixes for percentile / rank labels.
//  Used by V3 chapter subtitles (Chapter 1 BetIQ percentile,
//  Chapter 3 Discipline percentile, etc).
//
//  Handles the 11/12/13 exception: 11TH, 12TH, 13TH (not 11ST, 12ND, 13RD).
//

import Foundation

extension Int {
    /// Returns "ST", "ND", "RD", or "TH" for proper English ordinals.
    /// Examples: 1 → ST, 2 → ND, 3 → RD, 4 → TH, 11 → TH, 21 → ST, 22 → ND, 100 → TH.
    var ordinalSuffix: String {
        let mod100 = abs(self) % 100
        if (11...13).contains(mod100) { return "TH" }
        switch abs(self) % 10 {
        case 1: return "ST"
        case 2: return "ND"
        case 3: return "RD"
        default: return "TH"
        }
    }

    /// Convenience: returns the number plus its ordinal suffix.
    /// Examples: 1 → "1ST", 22 → "22ND", 100 → "100TH".
    var ordinalText: String {
        "\(self)\(ordinalSuffix)"
    }
}
