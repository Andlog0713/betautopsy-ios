//
//  String+FirstSentence.swift
//  BetAutopsy
//
//  Used by V3 insight callouts to render a single teaser sentence
//  while the full content stays available for the CTA target.
//  Applies to every chapter view in the V-cascade (PR-V1 through V9).
//

import Foundation

extension String {
    /// Returns the first sentence of the string, or the whole string
    /// (trimmed) if no sentence boundary is detected.
    ///
    /// Uses Foundation's built-in sentence detection, which handles
    /// abbreviations (Mr., Dr.), ellipses, decimals, and locale-
    /// specific rules. Robust against the executive_diagnosis
    /// paragraph format produced by the analysis engine.
    var firstSentence: String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        var result: String?
        trimmed.enumerateSubstrings(
            in: trimmed.startIndex..<trimmed.endIndex,
            options: [.bySentences, .localized]
        ) { substring, _, _, stop in
            if let substring = substring, !substring.isEmpty {
                result = substring.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                stop = true
            }
        }
        return result ?? trimmed
    }
}
