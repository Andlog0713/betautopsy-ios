// ────────────────────────────────────────────────────────────
// EmailAuthCoordinator.swift
// BetAutopsy
//
// Email/password auth via Supabase. One coordinator, two modes:
// sign in (existing) and create account (new). Instant access —
// Supabase email confirmation is disabled, so signUp returns a
// session immediately. Forgot-password sends a reset email whose
// link deep-links back via the betautopsy:// scheme.
//
// Shares AuthState.handleSignedIn for the post-session tail.
//
// Created PR-AUTH.
// ────────────────────────────────────────────────────────────

import Foundation
import Supabase
import Sentry

@Observable
@MainActor
final class EmailAuthCoordinator {
    enum Mode: Equatable {
        case signIn
        case createAccount
    }

    enum State: Equatable {
        case idle
        case working
        case succeeded
        case resetSent
        case failed(String)
    }

    var mode: Mode = .signIn
    var email: String = ""
    var password: String = ""
    private(set) var state: State = .idle

    /// Minimum client-side password length. Supabase's default minimum is 6;
    /// 8 is stricter and always satisfies the server.
    private static let minPasswordLength = 8

    var canSubmit: Bool {
        Self.isValidEmail(email) && password.count >= Self.minPasswordLength
    }

    func clearTransientState() {
        if case .failed = state { state = .idle }
        if state == .resetSent { state = .idle }
    }

    func submit() async {
        guard canSubmit else {
            state = .failed("Enter a valid email and a password of at least 8 characters.")
            return
        }
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        state = .working
        do {
            switch mode {
            case .signIn:
                _ = try await SupabaseService.shared.auth.signIn(email: cleanEmail, password: password)
            case .createAccount:
                _ = try await SupabaseService.shared.auth.signUp(email: cleanEmail, password: password)
            }

            let uid = await SupabaseService.currentUserId()
            let now = Date()
            let user = User(
                provider: .email,
                supabaseUID: uid,
                displayName: nil,
                email: cleanEmail,
                timezone: TimeZone.current.identifier,
                firstSignedInAt: now,
                lastSignedInAt: now
            )
            AuthState.shared.handleSignedIn(user: user)
            Analytics.signal(mode == .signIn ? "auth.email.signed_in" : "auth.email.created")
            state = .succeeded
        } catch {
            let message = Self.message(for: error, mode: mode)
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "email_signin", key: "failure_source")
            }
            Analytics.signal("auth.email.failed", parameters: ["mode": mode == .signIn ? "sign_in" : "create"])
            state = .failed(message)
        }
    }

    func sendReset() async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidEmail(cleanEmail) else {
            state = .failed("Enter your email first, then tap reset.")
            return
        }
        do {
            try await SupabaseService.shared.auth.resetPasswordForEmail(
                cleanEmail,
                redirectTo: URL(string: "betautopsy://password-reset")
            )
            Analytics.signal("auth.email.reset_sent")
            state = .resetSent
        } catch {
            state = .failed("Couldn't send the reset email. Try again.")
        }
    }

    // MARK: - Helpers

    private static func isValidEmail(_ raw: String) -> Bool {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard s.count >= 5, !s.hasPrefix("@"), !s.hasSuffix("@") else { return false }
        guard let at = s.firstIndex(of: "@") else { return false }
        let domain = s[s.index(after: at)...]
        return domain.contains(".") && !domain.hasSuffix(".")
    }

    private static func message(for error: Error, mode: Mode) -> String {
        let d = String(describing: error).lowercased()
        if d.contains("already registered") || d.contains("already been registered") || d.contains("user already") {
            return "That email is already in use. Sign in instead."
        }
        if d.contains("invalid login") || d.contains("invalid credentials") {
            return "Email or password is incorrect."
        }
        if (error as NSError).domain == NSURLErrorDomain {
            return "Couldn't connect. Try again."
        }
        return mode == .signIn ? "Sign in failed. Try again." : "Couldn't create your account. Try again."
    }
}
