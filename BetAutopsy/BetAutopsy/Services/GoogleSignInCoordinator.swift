// ────────────────────────────────────────────────────────────
// GoogleSignInCoordinator.swift
// BetAutopsy
//
// Google sign-in via Supabase's signInWithOAuth, which runs an
// ASWebAuthenticationSession internally (no GoogleSignIn SDK). The
// callback scheme is derived from redirectTo's scheme ("betautopsy",
// registered in Info.plist CFBundleURLTypes and in the Supabase
// dashboard's allowed redirect URLs).
//
// Mirrors AppleSignInCoordinator's state machine + error mapping, and
// shares AuthState.handleSignedIn for the post-session tail.
//
// Created PR-AUTH.
// ────────────────────────────────────────────────────────────

import Foundation
import AuthenticationServices
import Supabase
import Sentry

@Observable
@MainActor
final class GoogleSignInCoordinator {
    enum State: Equatable {
        case idle
        case signingIn
        case succeeded
        case failed(ErrorKind)
    }

    enum ErrorKind: String {
        case userCanceled = "user_canceled"
        case network      = "network"
        case supabase     = "supabase"
        case unknown      = "unknown"

        var userFacingMessage: String? {
            switch self {
            case .userCanceled: return nil
            case .network:      return "Couldn't connect. Try again."
            case .supabase:     return "Sign in failed. Try again."
            case .unknown:      return "Something went wrong. Try again."
            }
        }
    }

    private(set) var state: State = .idle

    /// Must match an allowed redirect URL in the Supabase dashboard and the
    /// `betautopsy` scheme registered in Info.plist.
    private static let redirectURL = URL(string: "betautopsy://login-callback")!

    func signIn() async {
        state = .signingIn

        let crumb = Breadcrumb(level: .info, category: "auth")
        crumb.message = "Google Sign-In started"
        SentrySDK.addBreadcrumb(crumb)
        Analytics.signal("auth.google.started")

        do {
            let session = try await SupabaseService.shared.auth.signInWithOAuth(
                provider: .google,
                redirectTo: Self.redirectURL
            )

            // Google puts the display name in user_metadata (full_name / name).
            let meta = session.user.userMetadata
            let name: String? = {
                for key in ["full_name", "name"] {
                    if case let .string(value)? = meta[key], !value.isEmpty { return value }
                }
                return nil
            }()
            let now = Date()

            let user = User(
                provider: .google,
                supabaseUID: session.user.id.uuidString.lowercased(),
                displayName: name,
                email: session.user.email,
                timezone: TimeZone.current.identifier,
                firstSignedInAt: now,
                lastSignedInAt: now
            )
            AuthState.shared.handleSignedIn(user: user)

            Analytics.signal("auth.google.succeeded")
            state = .succeeded
        } catch {
            let kind = classify(error)
            if kind != .userCanceled {
                SentrySDK.capture(error: error) { scope in
                    scope.setTag(value: "google_signin", key: "failure_source")
                    scope.setExtra(value: kind.rawValue, key: "error_kind")
                }
            }
            Analytics.signal("auth.google.failed", parameters: ["error_kind": kind.rawValue])
            state = .failed(kind)
        }
    }

    private func classify(_ error: Error) -> ErrorKind {
        if let asError = error as? ASWebAuthenticationSessionError,
           asError.code == .canceledLogin {
            return .userCanceled
        }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain { return .network }
        let description = String(describing: error)
        if description.localizedCaseInsensitiveContains("auth") ||
           description.localizedCaseInsensitiveContains("supabase") {
            return .supabase
        }
        return .unknown
    }
}
