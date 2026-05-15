//
//  PreBetCheckInCoordinator.swift
//  BetAutopsy
//
//  @Observable state machine for the pre-bet check-in flow. Owned as
//  @State inside PreBetCheckInView (lifetime = sheet lifetime), so
//  each open of the sheet starts fresh in .input.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class PreBetCheckInCoordinator {
    enum Phase: Equatable {
        case input
        case scoring
        case result(PreBetCheckInResponse)

        static func == (lhs: Phase, rhs: Phase) -> Bool {
            switch (lhs, rhs) {
            case (.input, .input), (.scoring, .scoring):
                return true
            case let (.result(a), .result(b)):
                return a.betQualityScore == b.betQualityScore
                    && a.flags.map(\.id) == b.flags.map(\.id)
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

    /// Set on a failed `score` call, displayed as a banner above the
    /// input form. Cleared at the start of every `submit`.
    var lastError: String?

    #if DEBUG
    /// DEBUG-only override for time-dependent flag testing. Surfaced
    /// via the hidden 4-tap affordance on the input screen.
    var debugNowOverride: Date? = nil
    #endif

    func submit() async {
        lastError = nil
        phase = .scoring

        let placedAt = Date()
        let request: PreBetCheckInRequest = {
            #if DEBUG
            if let override = debugNowOverride {
                // 6-param memberwise init: real placedAt on the wire
                // (so backend recency calculations stay honest) plus
                // an explicit localHour from the override (so the
                // late-night flag fires for testing regardless of
                // wall-clock time).
                return PreBetCheckInRequest(
                    sport: sport,
                    stake: stake,
                    odds: odds,
                    betType: betType,
                    placedAt: placedAt,
                    localHour: Calendar.current.component(.hour, from: override)
                )
            }
            #endif
            // Production path: 5-param convenience init derives
            // localHour from placedAt.
            return PreBetCheckInRequest(
                sport: sport,
                stake: stake,
                odds: odds,
                betType: betType,
                placedAt: placedAt
            )
        }()

        do {
            let response = try await PreBetCheckInClient.shared.score(request)
            self.phase = .result(response)
        } catch is CancellationError {
            // User dismissed the modal mid-request. Silent return.
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            // URLSession's cancellation flavor; same silent path.
            return
        } catch let error as PreBetCheckInError {
            self.lastError = error.errorDescription
                             ?? "Something went wrong. Try again."
            self.phase = .input
            Analytics.signal(
                "prebet.api_failed",
                parameters: ["error_kind": String(describing: error)]
            )
        } catch {
            self.lastError = "Something went wrong. Try again."
            self.phase = .input
            Analytics.signal(
                "prebet.api_failed",
                parameters: ["error_kind": "unknown"]
            )
        }
    }

    func reset() {
        phase = .input
        stake = 0
        odds = -110
        lastError = nil
    }

    /// Fires the user's CTA decision against /api/check-in/outcome.
    /// Synchronous from the call site (no await), the network round-
    /// trip happens inside a detached Task. Failures are silent at
    /// the UI level and surface only via telemetry — outcome posting
    /// is a behavioral-data capture, not a UX-critical request.
    ///
    /// Captures `checkInId` locally before the Task closure because
    /// dismiss() runs synchronously after this method on the CTA
    /// path; the sheet starts tearing down and the coordinator's
    /// `phase` is no longer guaranteed reachable from inside the
    /// Task. Local capture pins the value.
    func submitOutcome(_ outcome: CheckInOutcome) {
        guard case .result(let response) = phase else { return }
        let checkInId = response.checkInId

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
}
