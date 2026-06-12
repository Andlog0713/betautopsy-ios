//
//  BAFormat.swift
//  BetAutopsy
//
//  The single number-formatting utility. Every number the report
//  renderer draws (currency, percent, sample size, score, odds, date)
//  routes through here. No view defines its own NumberFormatter or
//  sign-gluing string math.
//
//  RULE: the renderer formats all numbers. Never render an LLM- or
//  engine-provided pre-formatted number string; format the raw value
//  through BAFormat instead. The engine is moving to raw-values-only.
//  Where a surface today has ONLY the formatted string (no raw value
//  on the wire), the call site carries a TODO naming the raw field it
//  needs; do not add new pre-formatted consumers.
//
//  Canonical output shapes:
//    currency        -$7,862   +$3,174   $1,840   $7.50   $0
//                    (sign BEFORE the symbol, never "$-4087";
//                     thousands separators always; decimals only on
//                     non-whole magnitudes under $10; zero unsigned)
//    percent         -25.8%    +16%      4.2%     0%
//                    (one decimal max; headline style drops the
//                     decimal at magnitude >= 10; zero unsigned)
//    sample size     781 bets   1 bet
//    rate + sample   ROI -16.0% · 781 bets  (a rate never ships alone)
//    score           44/100    7/25
//    odds            -110      +250      (American, always signed)
//    date            Apr 1     Apr 1, 2026   (never ISO in UI)
//

import Foundation

enum BAFormat {

    // MARK: - Currency

    /// Formats dollars. `signed: false` prefixes "-" only on negatives;
    /// `signed: true` prefixes "+" on positives too (P&L deltas). The
    /// sign always precedes the dollar symbol. Magnitudes that round to
    /// zero render "$0" with no sign. Whole dollars carry no decimals;
    /// non-whole magnitudes under $10 carry two.
    static func currency(_ value: Double, signed: Bool = false) -> String {
        let magnitude = abs(value)
        let showCents = magnitude < 10 && magnitude.truncatingRemainder(dividingBy: 1) != 0
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = showCents ? 2 : 0
        formatter.maximumFractionDigits = showCents ? 2 : 0
        let body = formatter.string(from: NSNumber(value: magnitude)) ?? "0"
        if !showCents && Int(magnitude.rounded()) == 0 { return "$0" }
        if value < 0 { return "-$\(body)" }
        return signed ? "+$\(body)" : "$\(body)"
    }

    static func currency(_ value: Int, signed: Bool = false) -> String {
        currency(Double(value), signed: signed)
    }

    // MARK: - Percent

    /// Display cap for ROI percentages. Tiny-stake outliers produce
    /// four-digit ROIs ("+1,411.1%") that read as broken; at or above
    /// this magnitude, render the dollar figure and win rate instead
    /// (callers own that fallback since the fields differ per surface).
    static let roiDisplayCap: Double = 200

    /// Formats a percentage. One decimal by default (evidence rows);
    /// `headline: true` drops the decimal once magnitude reaches 10
    /// ("+16%" not "+16.2%"). `signed: true` prefixes "+" on positives
    /// (use for any delta or ROI). Zero renders "0%" unsigned.
    static func percent(_ value: Double, signed: Bool = false, headline: Bool = false) -> String {
        let magnitude = abs(value)
        let decimals = (headline && magnitude >= 10) ? 0 : 1
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        let body = formatter.string(from: NSNumber(value: magnitude)) ?? "0"
        if body == "0" || body == "0.0" { return "0%" }
        if value < 0 { return "-\(body)%" }
        return signed ? "+\(body)%" : "\(body)%"
    }

    // MARK: - Sample size

    /// "781 bets" / "1 bet". A rate (ROI, win rate) never renders
    /// without its sample size somewhere on the same surface.
    static func sampleSize(_ bets: Int) -> String {
        bets.pluralized("bet", "bets")
    }

    /// The canonical rate-plus-sample pairing: "ROI -16.0% · 781 bets".
    static func roiWithSample(_ roi: Double, bets: Int) -> String {
        "ROI \(percent(roi, signed: true)) \u{00B7} \(sampleSize(bets))"
    }

    // MARK: - Score

    /// "44/100", "7/25".
    static func score(_ value: Int, outOf total: Int) -> String {
        "\(value)/\(total)"
    }

    // MARK: - Odds

    /// American odds, always signed: "-110", "+250".
    static func odds(_ american: Int) -> String {
        american < 0 ? "\(american)" : "+\(american)"
    }

    // MARK: - Dates

    /// "Apr 1" / "Apr 1, 2026". Never ISO in UI.
    static func date(_ date: Date, includeYear: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = includeYear ? "MMM d, yyyy" : "MMM d"
        return formatter.string(from: date)
    }

    /// Parses the date string shapes the engine ships ("Apr 1, 2026",
    /// "April 1, 2026", "2026-04-01"). Nil when none match.
    static func parseEngineDate(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        for format in ["MMM d, yyyy", "MMMM d, yyyy", "yyyy-MM-dd"] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }

    /// Parse-and-reformat in one step. Falls back to the trimmed raw
    /// string when the engine shape is unrecognized (never blanks a
    /// date the user should still see).
    static func date(parsing raw: String, includeYear: Bool = false) -> String {
        guard let parsed = parseEngineDate(raw) else {
            return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return date(parsed, includeYear: includeYear)
    }

    /// Hour-of-day label for timing charts: 0 -> "12AM", 13 -> "1PM".
    static func hourLabel(_ hour: Int) -> String {
        let clamped = ((hour % 24) + 24) % 24
        switch clamped {
        case 0:      return "12AM"
        case 1...11: return "\(clamped)AM"
        case 12:     return "12PM"
        default:     return "\(clamped - 12)PM"
        }
    }
}
