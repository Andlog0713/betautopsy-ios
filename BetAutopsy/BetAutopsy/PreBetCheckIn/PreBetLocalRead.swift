//
//  PreBetLocalRead.swift
//  BetAutopsy
//
//  Instant, on-device behavioral read for the pre-bet check-in. The
//  whole point of "About to bet" is to intervene AT the moment of
//  impulse - a 10s network spinner loses that moment. This engine reads
//  the user's cached report (their real biases, heated-session rate,
//  emotion score, typical stake, archetype) plus the current input and
//  the local hour, and returns a read in 0ms. The server response then
//  enriches it behind the scenes (see PreBetCheckInCoordinator.Phase).
//
//  Everything here is grounded: every flag traces to a real signal in
//  THEIR report and deep-links to the chapter that proves it. No
//  fabricated numbers - dollar figures are the user's own avgStake and
//  estimatedCost, formatted through BAFormat. When no full-body report
//  is cached (first run, or a slim list card), the read degrades to the
//  signals that are always available: the hour and the stake magnitude.
//
//  Copy here is user-facing and passes the COPY_SYSTEM gate: no em
//  dashes, no exclamations, no "tilt" ("heated" for sessions), sentence
//  case, sourced numbers only.
//

import Foundation

/// Overall tone of a read. Drives the hero color and which CTA leads.
enum ReadTone: String {
    case heated     // multiple strong risk signals stacked
    case elevated   // one strong signal worth a pause
    case normal     // looks ordinary for this bettor
    case calm       // nothing notable, disciplined profile
}

/// A single grounded observation. `sectionId`, when present, deep-links
/// to the report section that proves it (ReportScrollContainer anchors).
struct GroundedFlag: Identifiable {
    let id: String
    let severity: FlagSeverity
    let title: String
    let detail: String
    let sectionId: String?
}

/// The instant read. `headline` + `tone` are the hero; `flags` are the
/// grounded evidence; `leadsWithPause` decides which CTA is primary.
struct LocalBehavioralRead {
    let tone: ReadTone
    let headline: String
    let subtext: String
    let flags: [GroundedFlag]

    /// Heated/elevated reads lead with the cool-off; normal/calm reads
    /// lead with the neutral "Log this bet" record.
    var leadsWithPause: Bool { tone == .heated || tone == .elevated }
}

enum PreBetLocalReadEngine {
    // Report section anchors (ReportScrollContainer.id(...)) used for
    // per-flag deep links.
    private static let sectionFindings = "section_findings"
    private static let sectionHeated   = "section_heated_discipline"

    /// Builds the instant read. `report` is the newest cached report
    /// (may be nil, may be a slim card without biases/sessions).
    static func read(
        report: AutopsyReport?,
        sport: Sport,
        stake: Decimal,
        odds: Int,
        betType: BetType,
        localHour: Int
    ) -> LocalBehavioralRead {
        var flags: [GroundedFlag] = []
        var strongSignals = 0

        // --- Signal 1: late-night window (always available) ----------
        // Midnight to 5am is the documented heated-betting window. This
        // is the user's own wall-clock hour, not a claim about anyone.
        let isLateNight = localHour >= 0 && localHour < 5
        if isLateNight {
            strongSignals += 1
            flags.append(GroundedFlag(
                id: "late_night",
                severity: .medium,
                title: "Late-night bet",
                detail: "It is \(hourLabel(localHour)). Late hours are where heated bets cluster.",
                sectionId: nil
            ))
        }

        // --- Signal 2: stake vs the user's typical (needs full body) --
        let analysis = report?.analysis
        let isFullBody = report?.isFullBody ?? false
        let avgStake = analysis?.summary.avgStake ?? 0
        let avgStakeRedacted = analysis?.summary.avgStakeVisibility == "redacted_dollar"
        let stakeDouble = NSDecimalNumber(decimal: stake).doubleValue

        if isFullBody, avgStake > 0, !avgStakeRedacted {
            let ratio = stakeDouble / avgStake
            if ratio >= 2.5 {
                strongSignals += 1
                flags.append(GroundedFlag(
                    id: "stake_vs_typical",
                    severity: ratio >= 4 ? .high : .medium,
                    title: "Bigger than your usual",
                    detail: "This is \(multipleLabel(ratio)) your typical \(BAFormat.currency(avgStake)) stake.",
                    sectionId: sectionFindings
                ))
            }
        } else if stakeDouble >= 500 {
            // Degraded path: no typical to compare against, fall back to
            // an absolute large-stake note (matches the 500+ bucket).
            strongSignals += 1
            flags.append(GroundedFlag(
                id: "large_stake",
                severity: .medium,
                title: "Large stake",
                detail: "This is a \(BAFormat.currency(stakeDouble)) bet. Worth a beat before you place it.",
                sectionId: nil
            ))
        }

        // --- Signal 3: heated-session history (needs full body) -------
        if isFullBody,
           let session = analysis?.sessionDetection,
           session.insufficientData != true,
           session.heatedSessionPercent >= 25 {
            strongSignals += 1
            flags.append(GroundedFlag(
                id: "heated_history",
                severity: session.heatedSessionPercent >= 40 ? .high : .medium,
                title: "You run heated often",
                detail: "\(BAFormat.percent(session.heatedSessionPercent, headline: true)) of your sessions read as heated. This is the moment that pattern starts.",
                sectionId: sectionHeated
            ))
        }

        // --- Signal 4: top documented bias (needs full body) ----------
        // Surface the single highest-severity bias from THEIR report as a
        // grounded flag, deep-linked to Findings. This is the forensic
        // mirror: their own evidence, thrown back at the decision.
        if isFullBody, let topBias = highestSeverityBias(analysis?.biasesDetected) {
            let sev: FlagSeverity = topBias.severity == .critical || topBias.severity == .high ? .high : .medium
            if topBias.severity == .critical || topBias.severity == .high {
                strongSignals += 1
            }
            flags.append(GroundedFlag(
                id: "bias_\(topBias.biasName)",
                severity: sev,
                title: topBias.biasName,
                detail: biasDetail(topBias),
                sectionId: sectionFindings
            ))
        }

        // --- Signal 5: long-shot bet structure (always available) -----
        if betType == .parlay || betType == .futures {
            flags.append(GroundedFlag(
                id: "longshot_structure",
                severity: .low,
                title: "Long-shot structure",
                detail: "\(betType.displayName) bets carry a wider gap between price and value. Size accordingly.",
                sectionId: nil
            ))
        }

        // --- Resolve tone -------------------------------------------
        let tone: ReadTone
        switch strongSignals {
        case 0:  tone = flags.isEmpty ? .calm : .normal
        case 1:  tone = .elevated
        default: tone = .heated
        }

        return LocalBehavioralRead(
            tone: tone,
            headline: headline(for: tone, sport: sport),
            subtext: subtext(for: tone, flags: flags, sport: sport),
            flags: flags
        )
    }

    // MARK: - Copy

    private static func headline(for tone: ReadTone, sport: Sport) -> String {
        switch tone {
        case .heated:
            return "This looks like a heated-session bet."
        case .elevated:
            return "Worth a second look before you place this."
        case .normal:
            return "This looks like a normal \(sport.displayName) bet for you."
        case .calm:
            return "Nothing here looks off."
        }
    }

    private static func subtext(for tone: ReadTone, flags: [GroundedFlag], sport: Sport) -> String {
        switch tone {
        case .heated:
            return "A few things are stacking up at once. Thirty minutes usually tells you which it was."
        case .elevated:
            return flags.first?.detail ?? "One thing stands out. Take a beat before you place it."
        case .normal:
            return "It fits your usual pattern. No strong signals either way."
        case .calm:
            return "Stake, timing, and structure all look ordinary for you."
        }
    }

    // MARK: - Helpers

    private static func highestSeverityBias(_ biases: [BiasDetected]?) -> BiasDetected? {
        guard let biases, !biases.isEmpty else { return nil }
        func rank(_ s: BiasSeverity) -> Int {
            switch s {
            case .critical: return 4
            case .high:     return 3
            case .medium:   return 2
            case .low:      return 1
            }
        }
        return biases.max { rank($0.severity) < rank($1.severity) }
    }

    private static func biasDetail(_ bias: BiasDetected) -> String {
        // Prefer the report's own evidence sentence; fall back to the
        // description. Both are already report copy.
        let source = bias.evidenceVisibility == "visible" ? bias.evidence : bias.description
        let sentence = source.firstSentence
        return sentence.isEmpty ? "Documented in your last report." : sentence
    }

    private static func multipleLabel(_ ratio: Double) -> String {
        // "2.5x", "3x", "5x" - one decimal only when it adds signal.
        if ratio >= 10 { return "\(Int(ratio.rounded()))x" }
        let rounded = (ratio * 10).rounded() / 10
        return rounded == rounded.rounded() ? "\(Int(rounded))x" : String(format: "%.1fx", rounded)
    }

    private static func hourLabel(_ hour: Int) -> String {
        switch hour {
        case 0:  return "past midnight"
        case 1...4: return "after \(hour) am"
        default: return "late"
        }
    }
}
