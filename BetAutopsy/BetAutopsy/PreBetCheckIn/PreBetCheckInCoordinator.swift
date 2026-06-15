//
//  PreBetCheckInCoordinator.swift
//  BetAutopsy
//
//  @Observable state machine for the pre-bet check-in flow. Owned as
//  @State inside PreBetCheckInView (lifetime = sheet lifetime), so each
//  open of the sheet starts fresh in .input.
//
//  In-the-moment rework: submit() no longer awaits the network behind a
//  spinner. It computes an instant on-device read from the cached report
//  (PreBetLocalReadEngine) and shows it in 0ms, then enriches with the
//  server response behind the read. A server failure is silent - the
//  local read is the product, the server is an enhancement. Every CTA
//  decision writes a LOCAL history record (PreBetCheckInHistory)
//  regardless of the network, and the step-back decision schedules the
//  +30 cool-off notification.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class PreBetCheckInCoordinator {
    enum Phase: Equatable {
        case input
        /// Instant local read is the hero. `enriched` is nil until the
        /// server responds (and stays nil if it fails); when present it
        /// adds the server's prose summary behind the read.
        case read(LocalBehavioralRead, enriched: PreBetCheckInResponse?)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.input, .input):
                return true
            case let (.read(a, ea), .read(b, eb)):
                return a.tone == b.tone
                    && a.headline == b.headline
                    && ea?.checkInId == eb?.checkInId
            default:
                return false
            }
        }
    }

    var phase: Phase = .input
    var sport: Sport = .nfl
    var stake: Decimal = 0
    var odds: Int = -110
    var betType: BetType = .moneyline

    #if DEBUG
    /// DEBUG-only override for time-dependent read testing. Surfaced via
    /// the hidden 4-tap affordance on the input screen.
    var debugNowOverride: Date? = nil
    #endif

    // MARK: - Submit (instant read, enrich behind)

    /// Synchronous from the call site. Computes the instant read and swaps
    /// the phase immediately, then fires the server enrichment in a Task.
    func submit() {
        let placedAt = Date()
        let localHour = resolvedLocalHour(placedAt: placedAt)

        let read = PreBetLocalReadEngine.read(
            report: ReportStore.shared.reports.first,
            sport: sport,
            stake: stake,
            odds: odds,
            betType: betType,
            localHour: localHour
        )
        phase = .read(read, enriched: nil)

        let request = PreBetCheckInRequest(
            sport: sport,
            stake: stake,
            odds: odds,
            betType: betType,
            placedAt: placedAt,
            localHour: localHour
        )

        Task { await enrich(request) }
    }

    private func enrich(_ request: PreBetCheckInRequest) async {
        do {
            let response = try await PreBetCheckInClient.shared.score(request)
            // Only fold the enrichment in if the user is still on the read
            // (they may have decided and dismissed). Keep the same read.
            if case .read(let read, _) = phase {
                phase = .read(read, enriched: response)
            }
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch let error as PreBetCheckInError {
            // Silent at the UI level: the local read stands on its own.
            Analytics.signal(
                "prebet.api_failed",
                parameters: ["error_kind": String(describing: error)]
            )
        } catch {
            Analytics.signal(
                "prebet.api_failed",
                parameters: ["error_kind": "unknown"]
            )
        }
    }

    // MARK: - Decision (CTA)

    /// Records the user's in-the-moment decision. Writes the LOCAL history
    /// mirror unconditionally (the loop must not depend on the network),
    /// schedules or cancels the +30 cool-off, and posts the outcome to the
    /// server only when enrichment supplied a checkInId.
    func decide(_ outcome: CheckInOutcome) {
        guard case .read(let read, let enriched) = phase else { return }

        let now = Date()
        PreBetCheckInHistory.shared.record(
            id: UUID().uuidString,
            date: now,
            sport: sport,
            stake: stake,
            tone: read.tone,
            outcome: outcome
        )

        if outcome == .waited {
            PreBetCoolOffScheduler.schedule(stake: stake, sport: sport, betType: betType)
        } else {
            // Logged the bet (or came back via the cool-off and logged it):
            // clear any pending cool-off so it does not fire afterward.
            PreBetCoolOffScheduler.cancel()
        }

        guard let checkInId = enriched?.checkInId else { return }
        postOutcome(checkInId: checkInId, outcome: outcome)
    }

    /// Fires the server outcome post against an existing check-in. Failures
    /// are silent at the UI level and surface only via telemetry - outcome
    /// posting is behavioral-data capture, not a UX-critical request.
    /// `checkInId` is captured locally because dismiss() runs synchronously
    /// after this on the CTA path and the coordinator's `phase` is no longer
    /// guaranteed reachable from inside the Task.
    private func postOutcome(checkInId: String, outcome: CheckInOutcome) {
        Task {
            do {
                try await PreBetCheckInClient.shared.submitOutcome(
                    checkInId: checkInId,
                    outcome: outcome
                )
                Analytics.signal(
                    "prebet.outcome_posted",
                    parameters: ["outcome": outcome.rawValue]
                )
            } catch is CancellationError {
                return
            } catch let urlError as URLError where urlError.code == .cancelled {
                return
            } catch let error as PreBetCheckInError {
                Analytics.signal(
                    "prebet.outcome_failed",
                    parameters: [
                        "outcome":    outcome.rawValue,
                        "error_kind": String(describing: error)
                    ]
                )
            } catch {
                Analytics.signal(
                    "prebet.outcome_failed",
                    parameters: [
                        "outcome":    outcome.rawValue,
                        "error_kind": "unknown"
                    ]
                )
            }
        }
    }

    func reset() {
        phase = .input
        stake = 0
        odds = -110
    }

    // MARK: - Helpers

    private func resolvedLocalHour(placedAt: Date) -> Int {
        #if DEBUG
        if let override = debugNowOverride {
            return Calendar.current.component(.hour, from: override)
        }
        #endif
        return Calendar.current.component(.hour, from: placedAt)
    }
}
