//
//  PreBetCheckInClient.swift
//  BetAutopsy
//
//  POST /api/check-in client. Phase 2 of PR-PREBET-IOS replaces the
//  MockedPreBetScorer with real backend calls.
//
//  Mirrors AnalyzeClient on three patterns:
//   - per-request Bearer token via APIConfig.bearerToken (no caching)
//   - 401 -> SupabaseService.refreshSession() -> retry once -> on
//     second 401, propagate .unauthorized
//   - Sentry breadcrumb on the refresh-and-retry path so production
//     auth races are debuggable without an attached console
//
//  URLSession.shared with a 10s timeoutInterval on the URLRequest
//  keeps the shared session intact. Default JSONDecoder (no
//  convertFromSnakeCase) matches the backend's camelCase response
//  per the wire contract.
//
//  URLError(.cancelled) is re-thrown unwrapped so the coordinator
//  can silence dismiss-mid-request (no error banner, no telemetry).
//

import Foundation
import Sentry

final class PreBetCheckInClient {
    static let shared = PreBetCheckInClient()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private let decoder = JSONDecoder()

    /// Public entry point. Wraps `attemptScore` with the 401 refresh
    /// retry. CancellationError from the refresh path is propagated
    /// as-is so the coordinator's silent-dismiss path catches it,
    /// without firing a spurious `prebet.api_failed` telemetry.
    func score(_ request: PreBetCheckInRequest) async throws -> PreBetCheckInResponse {
        do {
            return try await attemptScore(request)
        } catch PreBetCheckInError.unauthorized {
            let crumb = Breadcrumb(level: .warning, category: "auth")
            crumb.message = "prebet 401, refreshing session and retrying"
            SentrySDK.addBreadcrumb(crumb)

            do {
                try await SupabaseService.refreshSession()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw PreBetCheckInError.unauthorized
            }
            return try await attemptScore(request)
        }
    }

    /// Posts the user's decision (placed_anyway / waited / placed_bet)
    /// against an existing check-in. Fire-and-forget at the call site
    /// (the coordinator wraps this in a Task and only routes failures
    /// to telemetry, never to the UI). No 401-refresh-retry: if the
    /// Bearer expired in the seconds between score and outcome, that's
    /// a rare loss captured in telemetry.
    ///
    /// 404 is mapped to `.invalidRequest("Check-in not found")` rather
    /// than a dedicated case — keeps the shared error type lean and the
    /// telemetry error_kind grouping stable across endpoints.
    func submitOutcome(checkInId: String, outcome: CheckInOutcome) async throws {
        guard let token = await APIConfig.bearerToken else {
            throw PreBetCheckInError.unauthorized
        }

        var urlRequest = URLRequest(url: APIConfig.outcomeURL, timeoutInterval: 10)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = CheckInOutcomeRequest(checkInId: checkInId, outcome: outcome)
        do {
            urlRequest.httpBody = try encoder.encode(body)
        } catch {
            throw PreBetCheckInError.encodingError(error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let urlError as URLError {
            throw PreBetCheckInError.networkError(urlError)
        } catch {
            throw PreBetCheckInError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw PreBetCheckInError.unexpectedStatus(-1)
        }

        switch http.statusCode {
        case 200:
            return
        case 400:
            let message = (try? decoder.decode([String: String].self, from: data))?["error"]
                          ?? "Bad request."
            throw PreBetCheckInError.invalidRequest(message)
        case 401:
            throw PreBetCheckInError.unauthorized
        case 404:
            throw PreBetCheckInError.invalidRequest("Check-in not found")
        case 500...599:
            throw PreBetCheckInError.serverError(http.statusCode)
        default:
            throw PreBetCheckInError.unexpectedStatus(http.statusCode)
        }
    }

    private func attemptScore(_ request: PreBetCheckInRequest) async throws -> PreBetCheckInResponse {
        guard let token = await APIConfig.bearerToken else {
            throw PreBetCheckInError.unauthorized
        }

        var urlRequest = URLRequest(url: APIConfig.checkInURL, timeoutInterval: 10)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            urlRequest.httpBody = try encoder.encode(request)
        } catch {
            throw PreBetCheckInError.encodingError(error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let urlError as URLError {
            throw PreBetCheckInError.networkError(urlError)
        } catch {
            throw PreBetCheckInError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw PreBetCheckInError.unexpectedStatus(-1)
        }

        switch http.statusCode {
        case 200:
            do {
                return try decoder.decode(PreBetCheckInResponse.self, from: data)
            } catch {
                throw PreBetCheckInError.decodingError(error)
            }
        case 400:
            let message = (try? decoder.decode([String: String].self, from: data))?["error"]
                          ?? "Bad request."
            throw PreBetCheckInError.invalidRequest(message)
        case 401:
            throw PreBetCheckInError.unauthorized
        case 500...599:
            throw PreBetCheckInError.serverError(http.statusCode)
        default:
            throw PreBetCheckInError.unexpectedStatus(http.statusCode)
        }
    }
}

enum PreBetCheckInError: Error, LocalizedError {
    case invalidRequest(String)
    case unauthorized
    case serverError(Int)
    case networkError(Error)
    case encodingError(Error)
    case decodingError(Error)
    case unexpectedStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidRequest(let m): return m
        case .unauthorized:          return "Session expired. Please sign in again."
        case .serverError:           return "Something went wrong on our end. Try again in a moment."
        case .networkError:          return "Connection failed. Check your internet and try again."
        case .encodingError:         return "Couldn't send the request. Try again."
        case .decodingError:         return "Couldn't read response from server. Try again."
        case .unexpectedStatus:      return "Something went wrong. Try again."
        }
    }
}
