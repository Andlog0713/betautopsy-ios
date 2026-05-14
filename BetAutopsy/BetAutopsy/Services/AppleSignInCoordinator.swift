// ────────────────────────────────────────────────────────────
// AppleSignInCoordinator.swift
// BetAutopsy
//
// Apple Sign-In flow controller. Used together with SwiftUI's
// SignInWithAppleButton: the button hands us its
// ASAuthorizationAppleIDRequest in onRequest (where we attach a
// cryptographic nonce), and hands us the Result in onCompletion
// (where we exchange Apple's identity token for a Supabase
// session via signInWithIdToken).
//
// Nonce handling note: Apple receives the SHA256 hash of the raw
// nonce; Supabase receives the RAW nonce. Mixing these breaks
// verification silently. See prepareNonce + handleSuccess below.
//
// Created May 14 2026 (PR-13).
// ────────────────────────────────────────────────────────────

import Foundation
import AuthenticationServices
import CryptoKit
import Supabase
import Sentry

@Observable
@MainActor
final class AppleSignInCoordinator {
    enum State: Equatable {
        case idle
        case signingIn
        case succeeded
        case failed(ErrorKind)
    }

    enum ErrorKind: String {
        case userCanceled    = "user_canceled"
        case network         = "network"
        case supabase        = "supabase"
        case appleCredential = "apple_credential"
        case unknown         = "unknown"

        /// User-facing alert message. nil for userCanceled (no UI shown).
        var userFacingMessage: String? {
            switch self {
            case .userCanceled:    return nil
            case .network:         return "Couldn't connect. Try again."
            case .supabase:        return "Sign in failed. Try again."
            case .appleCredential: return "Sign in failed. Try again."
            case .unknown:         return "Something went wrong. Try again."
            }
        }
    }

    private(set) var state: State = .idle

    /// Set when prepareNonce attaches the hashed nonce to the request;
    /// consumed when handleSuccess passes the raw nonce to Supabase.
    private var currentRawNonce: String?

    /// Attaches a fresh hashed nonce to the Apple request. Call from
    /// SignInWithAppleButton's onRequest closure.
    func prepareNonce(on request: ASAuthorizationAppleIDRequest) {
        let rawNonce = randomNonceString()
        currentRawNonce = rawNonce
        request.nonce = sha256(rawNonce)

        let crumb = Breadcrumb(level: .info, category: "auth")
        crumb.message = "Apple Sign-In started"
        SentrySDK.addBreadcrumb(crumb)

        Analytics.signal("auth.apple.started")
        state = .signingIn
    }

    /// Handles the SignInWithAppleButton onCompletion result. Performs
    /// the Supabase exchange and updates AuthState on success.
    func handleAuthorizationResult(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                fail(.appleCredential)
                return
            }
            await handleSuccess(credential: credential)

        case .failure(let error):
            let kind: ErrorKind
            if let asError = error as? ASAuthorizationError, asError.code == .canceled {
                kind = .userCanceled
            } else {
                kind = classify(error: error)
                captureToSentry(error: error, kind: kind)
            }
            fail(kind)
        }
    }

    /// Apple Sign-In revoked-credential check. Call from app startup
    /// when AuthState.shared.isAuthenticated is true. Silently signs
    /// the user out if Apple no longer recognizes the credential.
    @MainActor
    static func checkCredentialState() async {
        guard let appleUserID = AuthState.shared.user?.appleUserID else { return }
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let credState = try await provider.credentialState(forUserID: appleUserID)
            if credState == .revoked || credState == .notFound {
                await AuthState.shared.signOut()
            }
        } catch {
            // Best-effort; no signal.
        }
    }

    // MARK: - Private

    private func handleSuccess(credential: ASAuthorizationAppleIDCredential) async {
        guard let identityTokenData = credential.identityToken,
              let identityTokenString = String(data: identityTokenData, encoding: .utf8) else {
            fail(.appleCredential)
            return
        }
        guard let rawNonce = currentRawNonce else {
            fail(.appleCredential)
            return
        }

        do {
            _ = try await SupabaseService.shared.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: identityTokenString,
                    nonce: rawNonce
                )
            )

            let appleUserID = credential.user
            let assembledName: String? = {
                guard let comps = credential.fullName else { return nil }
                let parts = [comps.givenName, comps.familyName]
                    .compactMap { $0 }
                    .filter { !$0.isEmpty }
                return parts.isEmpty ? nil : parts.joined(separator: " ")
            }()
            let email = credential.email
            let now = Date()

            let user = User(
                appleUserID: appleUserID,
                displayName: assembledName,
                email: email,
                timezone: TimeZone.current.identifier,
                firstSignedInAt: now,
                lastSignedInAt: now
            )
            AuthState.shared.setAuthenticated(user: user)

            Analytics.signal("auth.apple.succeeded")
            state = .succeeded
            currentRawNonce = nil
        } catch {
            let kind = classify(error: error)
            captureToSentry(error: error, kind: kind)
            fail(kind)
        }
    }

    /// Sends the error to Sentry with a stable failure_source tag and
    /// the mapped error_kind extra. No PII; error messages may contain
    /// it, but Sentry's beforeSend hook scrubs Authorization headers
    /// from network breadcrumbs, and error types should not include PII
    /// by construction.
    private func captureToSentry(error: Error, kind: ErrorKind) {
        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: "apple_signin", key: "failure_source")
            scope.setExtra(value: kind.rawValue, key: "error_kind")
        }
    }

    private func fail(_ kind: ErrorKind) {
        Analytics.signal("auth.apple.failed", parameters: ["error_kind": kind.rawValue])
        state = .failed(kind)
        currentRawNonce = nil
    }

    private func classify(error: Error) -> ErrorKind {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            return .network
        }
        let description = String(describing: error)
        if description.localizedCaseInsensitiveContains("auth") ||
           description.localizedCaseInsensitiveContains("supabase") {
            return .supabase
        }
        return .unknown
    }

    // MARK: - Nonce helpers

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._"
        )
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("SecRandomCopyBytes failed: \(status)")
            }
            for random in randoms {
                if remaining == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
