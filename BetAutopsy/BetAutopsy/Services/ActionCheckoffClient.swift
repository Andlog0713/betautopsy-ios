//
//  ActionCheckoffClient.swift
//  BetAutopsy
//
//  POST/GET client for /api/action-checkoffs (backend PR #39). User
//  marks Chapter 7 recommendations as completed/reset; backend upserts
//  on (user_id, recommendation_id). 'dismissed' is in the enum for
//  forward compat but iOS v1 never sends it — pass/skip UX deferred
//  to v1.1.
//
//  recommendation_id format is "${report_id}:${priority}" where
//  priority is Recommendation.priority (the existing iOS Identifiable.id).
//  Caller (ActionCheckoffStore) builds this string; this client just
//  passes it through.
//
//  Mirrors DeviceTokenClient on auth/error patterns:
//   - per-request Bearer via APIConfig.bearerToken (no caching)
//   - 401 → SupabaseService.refreshSession() → retry once → on
//     second 401, propagate .unauthorized
//   - Sentry breadcrumb on the refresh-and-retry path
//   - per-property CodingKeys for snake_case wire fields rather than
//     a global .convertToSnakeCase strategy
//   - No LocalizedError — failures are silent per UX spec (UndoToast
//     disappears, store reverts optimistic mutation)
//

import Foundation
import Sentry

final class ActionCheckoffClient {
    static let shared = ActionCheckoffClient()

    private let encoder = JSONEncoder()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - POST

    /// Public entry point. Wraps `attemptPost` with the 401 refresh retry.
    /// Backend upserts on (user_id, recommendation_id) so repeated calls
    /// with the same status are idempotent.
    func post(reportId: String, recommendationId: String, status: ActionCheckoffStatus) async throws {
        do {
            try await attemptPost(reportId: reportId,
                                  recommendationId: recommendationId,
                                  status: status)
        } catch ActionCheckoffError.unauthorized {
            let crumb = Breadcrumb(level: .warning, category: "auth")
            crumb.message = "actioncheckoffs post 401, refreshing session and retrying"
            SentrySDK.addBreadcrumb(crumb)

            do {
                try await SupabaseService.refreshSession()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw ActionCheckoffError.unauthorized
            }
            try await attemptPost(reportId: reportId,
                                  recommendationId: recommendationId,
                                  status: status)
        }
    }

    private func attemptPost(reportId: String, recommendationId: String, status: ActionCheckoffStatus) async throws {
        guard let bearer = await APIConfig.bearerToken else {
            throw ActionCheckoffError.unauthorized
        }

        var urlRequest = URLRequest(url: APIConfig.actionCheckoffsURL, timeoutInterval: 10)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")

        let body = ActionCheckoffPostRequest(
            reportId: reportId,
            recommendationId: recommendationId,
            status: status
        )

        do {
            urlRequest.httpBody = try encoder.encode(body)
        } catch {
            throw ActionCheckoffError.encodingError(error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let urlError as URLError {
            throw ActionCheckoffError.networkError(urlError)
        } catch {
            throw ActionCheckoffError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ActionCheckoffError.unexpectedStatus(-1)
        }

        switch http.statusCode {
        case 200, 201:
            return
        case 401:
            throw ActionCheckoffError.unauthorized
        case 400:
            let message = (try? decoder.decode([String: String].self, from: data))?["error"]
                          ?? "Bad request."
            throw ActionCheckoffError.invalidRequest(message)
        case 500...599:
            throw ActionCheckoffError.serverError(http.statusCode)
        default:
            throw ActionCheckoffError.unexpectedStatus(http.statusCode)
        }
    }

    // MARK: - GET

    /// Lists all checkoffs for a report. RLS auto-filters by user_id at
    /// the backend, so no client-side user scoping needed.
    func list(reportId: String) async throws -> [ActionCheckoff] {
        do {
            return try await attemptList(reportId: reportId)
        } catch ActionCheckoffError.unauthorized {
            let crumb = Breadcrumb(level: .warning, category: "auth")
            crumb.message = "actioncheckoffs list 401, refreshing session and retrying"
            SentrySDK.addBreadcrumb(crumb)

            do {
                try await SupabaseService.refreshSession()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw ActionCheckoffError.unauthorized
            }
            return try await attemptList(reportId: reportId)
        }
    }

    private func attemptList(reportId: String) async throws -> [ActionCheckoff] {
        guard let bearer = await APIConfig.bearerToken else {
            throw ActionCheckoffError.unauthorized
        }

        var components = URLComponents(url: APIConfig.actionCheckoffsURL,
                                       resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "report_id", value: reportId)]
        guard let url = components?.url else {
            throw ActionCheckoffError.unexpectedStatus(-2)
        }

        var urlRequest = URLRequest(url: url, timeoutInterval: 10)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let urlError as URLError {
            throw ActionCheckoffError.networkError(urlError)
        } catch {
            throw ActionCheckoffError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ActionCheckoffError.unexpectedStatus(-1)
        }

        switch http.statusCode {
        case 200:
            do {
                let payload = try decoder.decode(ActionCheckoffListResponse.self, from: data)
                return payload.checkoffs
            } catch {
                throw ActionCheckoffError.decodingError(error)
            }
        case 401:
            throw ActionCheckoffError.unauthorized
        case 500...599:
            throw ActionCheckoffError.serverError(http.statusCode)
        default:
            throw ActionCheckoffError.unexpectedStatus(http.statusCode)
        }
    }
}

// MARK: - Wire model

/// Backend ActionCheckoff row. `completed_at` and `dismissed_at` are
/// both nullable; iOS v1 derives a single Bool from them
/// (completedAt != nil && dismissedAt == nil) in ActionCheckoffStore.
struct ActionCheckoff: Codable, Identifiable {
    let id: String
    let userId: String
    let reportId: String
    let recommendationId: String
    let completedAt: String?
    let dismissedAt: String?
    let createdAt: String
}

/// Backend GET response envelope.
private struct ActionCheckoffListResponse: Decodable {
    let checkoffs: [ActionCheckoff]
}

/// POST body. `report_id` and `recommendation_id` are the only fields
/// requiring snake_case mapping; per-property CodingKeys mirrors
/// DeviceTokenClient's approach.
private struct ActionCheckoffPostRequest: Encodable {
    let reportId: String
    let recommendationId: String
    let status: ActionCheckoffStatus

    enum CodingKeys: String, CodingKey {
        case status
        case reportId = "report_id"
        case recommendationId = "recommendation_id"
    }
}

/// Wire enum. iOS v1 only sends `.completed` and `.reset`. `.dismissed`
/// stays in the type for forward compat with the backend enum; v1.1
/// pass/skip UX will surface it.
enum ActionCheckoffStatus: String, Codable {
    case completed
    case dismissed
    case reset
}

/// No LocalizedError conformance — failures are silent per the locked
/// decision. ActionCheckoffStore captures via Sentry and reverts the
/// optimistic local mutation.
enum ActionCheckoffError: Error {
    case invalidRequest(String)
    case unauthorized
    case serverError(Int)
    case networkError(Error)
    case encodingError(Error)
    case decodingError(Error)
    case unexpectedStatus(Int)
}
