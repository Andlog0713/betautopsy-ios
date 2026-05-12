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
    /// Returns the first sentence of the string, trimmed, or the whole
    /// (trimmed) string if no sentence boundary is detected.
    var firstSentence: String {
        firstSentences(1)
    }

    /// Returns the first `count` sentences of the string, joined with
    /// a single space. Trimmed. Falls back to the whole trimmed string
    /// if Foundation can't detect any sentence boundary.
    ///
    /// Uses Foundation's [.bySentences, .localized] enumeration, which
    /// handles abbreviations (Mr., Dr.), decimals (3.14), ellipses,
    /// and locale-specific rules.
    func firstSentences(_ count: Int) -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, count > 0 else { return "" }

        var collected: [String] = []
        trimmed.enumerateSubstrings(
            in: trimmed.startIndex..<trimmed.endIndex,
            options: [.bySentences, .localized]
        ) { substring, _, _, stop in
            guard let substring = substring else { return }
            let cleaned = substring.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !cleaned.isEmpty else { return }
            collected.append(cleaned)
            if collected.count >= count {
                stop = true
            }
        }

        return collected.isEmpty
            ? trimmed
            : collected.joined(separator: " ")
    }
}
