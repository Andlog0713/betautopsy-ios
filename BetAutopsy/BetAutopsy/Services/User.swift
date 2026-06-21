// ────────────────────────────────────────────────────────────
// User.swift
// BetAutopsy
//
// Local user model. Persisted via JSON-encoded Data in
// UserDefaults under key "auth.user".
//
// Multi-provider (PR-AUTH): a user can sign in with Apple, Google,
// or email/password. `supabaseUID` (auth.uid()) is the stable,
// cross-provider identity key; `appleUserID` is Apple-only and kept
// for the credential-revocation check. displayName + email come from
// the provider (Apple returns them only at first sign-in).
//
// Created May 14 2026 (PR-13). Multi-provider added PR-AUTH.
// ────────────────────────────────────────────────────────────

import Foundation

enum AuthProvider: String, Codable, Equatable {
    case apple
    case google
    case email
}

struct User: Codable, Equatable {
    var provider: AuthProvider
    /// Apple's stable per-user id (ASAuthorizationAppleIDCredential.user).
    /// Apple-only; nil for Google / email users.
    var appleUserID: String?
    /// Supabase auth.uid() — the cross-provider identity key the webhook
    /// and the AuthState merge logic key on. nil only until the session
    /// uid is fetched.
    var supabaseUID: String?
    var displayName: String?
    var email: String?
    let timezone: String
    let firstSignedInAt: Date
    var lastSignedInAt: Date

    init(
        provider: AuthProvider,
        appleUserID: String? = nil,
        supabaseUID: String? = nil,
        displayName: String? = nil,
        email: String? = nil,
        timezone: String,
        firstSignedInAt: Date,
        lastSignedInAt: Date
    ) {
        self.provider = provider
        self.appleUserID = appleUserID
        self.supabaseUID = supabaseUID
        self.displayName = displayName
        self.email = email
        self.timezone = timezone
        self.firstSignedInAt = firstSignedInAt
        self.lastSignedInAt = lastSignedInAt
    }

    // Back-compat decode: records persisted before multi-provider have no
    // `provider` / `supabaseUID` keys and a (then-required) `appleUserID`.
    // Default the provider to .apple so existing Apple users are NOT logged
    // out on the app update that ships this change.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.provider = try c.decodeIfPresent(AuthProvider.self, forKey: .provider) ?? .apple
        self.appleUserID = try c.decodeIfPresent(String.self, forKey: .appleUserID)
        self.supabaseUID = try c.decodeIfPresent(String.self, forKey: .supabaseUID)
        self.displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
        self.email = try c.decodeIfPresent(String.self, forKey: .email)
        self.timezone = try c.decode(String.self, forKey: .timezone)
        self.firstSignedInAt = try c.decode(Date.self, forKey: .firstSignedInAt)
        self.lastSignedInAt = try c.decode(Date.self, forKey: .lastSignedInAt)
    }

    /// Provider-agnostic identity key for per-user local state (report cache,
    /// hydration trigger). Prefers the Supabase uid; falls back to appleUserID
    /// for pre-multi-provider records whose uid wasn't captured, so existing
    /// Apple users keep their cache key across the update.
    var identityKey: String? { supabaseUID ?? appleUserID }
}
