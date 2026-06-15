//
//  DecimalStakeParsing.swift
//  BetAutopsy
//
//  Locale-aware parse of a free-typed stake string. The pre-bet stake
//  field uses a `.decimalPad`, whose separator key is the user's LOCALE
//  decimal separator (a comma across much of Europe/LatAm). The original
//  `Decimal(string:)` parse is US-only: it reads "12,50" as nil and
//  silently zeroes the stake, which then fails the `stake > 0` submit
//  gate with no feedback. This helper normalizes the locale separator to
//  a dot before parsing with a fixed POSIX locale.
//

import Foundation

extension Decimal {
    /// Parses a user-typed stake honoring the current locale's decimal
    /// separator. Tolerates a trailing separator mid-typing ("12." or
    /// "12,") and a stray comma in dot-locales. Returns nil on empty or
    /// non-numeric input so the caller can leave the bound stake untouched.
    static func parsingStake(_ raw: String, locale: Locale = .current) -> Decimal? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let decimalSeparator = locale.decimalSeparator ?? "."
        var normalized = trimmed

        // Map the locale separator (e.g. ",") to a canonical dot.
        if decimalSeparator != "." {
            normalized = normalized.replacingOccurrences(of: decimalSeparator, with: ".")
        }

        // Defensive: a comma that survived in a dot-locale (user habit,
        // pasted value). Only treat it as the decimal mark when no dot is
        // already present, so "1,250.50" style grouping is not corrupted.
        if !normalized.contains(".") {
            normalized = normalized.replacingOccurrences(of: ",", with: ".")
        }

        // A lone trailing separator is valid mid-typing; pad it so Decimal
        // parses "12." as 12 rather than failing.
        if normalized.hasSuffix(".") {
            normalized += "0"
        }

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}
