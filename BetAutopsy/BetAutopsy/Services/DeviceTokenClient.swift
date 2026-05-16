//
//  DeviceTokenClient.swift
//  BetAutopsy
//
//  POST /api/device-tokens client. Backend (PR #36) upserts on (user_id,
//  token) so repeat calls with the same token are idempotent.
//
//  Mirrors PreBetCheckInClient on the auth pattern:
//   - per-request Bearer via APIConfig.bearerToken (no caching)
//   - 401 → SupabaseService.refreshSession() → retry once → on
//     second 401, propagate .unauthorized
//   - Sentry breadcrumb on the refresh-and-retry path
//
//  bundle_id is the only wire field that requires snake_case; the rest
//  are single words. Per-property CodingKeys keeps the strategy local
//  rather than imposing a global .convertToSnakeCase on the encoder.
//
//  No user-visible UI on failure per locked decision. Sentry captures
//  with kind=push tag.
//

import Foundation
import Sentry

final class DeviceTokenClient {
    static let shared = DeviceTokenClient()

    /// v1 hardcoded constants. DEBUG + TestFlight both ride APNs
    /// Sandbox. App Store ship will introduce a Production APNs key
    /// and flip this via build config.
    private static let environment = "sandbox"
    private static let bundleID    = "com.diagnosticsports.betautopsy.app"
    private static let platform    = "ios"

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    private let decoder = JSONDecoder()

    /// Public entry point. Wraps `attemptRegister` with the 401 refresh
    /// retry. Idempotent at the backend (upsert).
    func register(token: String) async throws {
        do {
            try await attemptRegister(token: token)
        } catch DeviceTokenError.unauthorized {
            let crumb = Breadcrumb(level: .warning, category: "auth")
            crumb.message = "devicetokens 401, refreshing session and retrying"
            SentrySDK.addBreadcrumb(crumb)

            do {
                try await SupabaseService.refreshSession()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw DeviceTokenError.unauthorized
            }
            try await attemptRegister(token: token)
        }
    }

    private func attemptRegister(token: String) async throws {
        guard let bearer = await APIConfig.bearerToken else {
            throw DeviceTokenError.unauthorized
        }

        var urlRequest = URLRequest(url: APIConfig.deviceTokensURL, timeoutInterval: 10)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")

        let body = DeviceTokenRequest(
            token: token,
            environment: Self.environment,
            bundleId: Self.bundleID,
            platform: Self.platform
        )

        do {
            urlRequest.httpBody = try encoder.encode(body)
        } catch {
            throw DeviceTokenError.encodingError(error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let urlError as URLError {
            throw DeviceTokenError.networkError(urlError)
        } catch {
            throw DeviceTokenError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw DeviceTokenError.unexpectedStatus(-1)
        }

        switch http.statusCode {
        case 200, 201:
            return
        case 401:
            throw DeviceTokenError.unauthorized
        case 400:
            let message = (try? decoder.decode([String: String].self, from: data))?["error"]
                          ?? "Bad request."
            throw DeviceTokenError.invalidRequest(message)
        case 500...599:
            throw DeviceTokenError.serverError(http.statusCode)
        default:
            throw DeviceTokenError.unexpectedStatus(http.statusCode)
        }
    }
}

/// Request body matching backend PR #36 contract. `bundle_id` is the
/// only field that needs snake_case mapping; the rest are single
/// words and pass through unchanged.
private struct DeviceTokenRequest: Encodable {
    let token: String
    let environment: String
    let bundleId: String
    let platform: String

    enum CodingKeys: String, CodingKey {
        case token, environment, platform
        case bundleId = "bundle_id"
    }
}

/// No LocalizedError conformance — failures are silent per the
/// locked decision (Sentry captures, no user UI).
enum DeviceTokenError: Error {
    case invalidRequest(String)
    case unauthorized
    case serverError(Int)
    case networkError(Error)
    case encodingError(Error)
    case unexpectedStatus(Int)
}
