// ────────────────────────────────────────────────────────────
// SupabaseService.swift
// BetAutopsy
//
// Lazy singleton wrapping the supabase-swift SupabaseClient.
// URL + anon key load from Info.plist. Session persistence is
// explicit Keychain via KeychainLocalStorage (the SDK default on
// iOS, passed explicitly for clarity).
//
// Created May 14 2026 (PR-13).
// ────────────────────────────────────────────────────────────

import Foundation
import Supabase

enum SupabaseService {
    static let shared: SupabaseClient = {
        SupabaseClient(
            supabaseURL: loadURL(),
            supabaseKey: loadAnonKey(),
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: KeychainLocalStorage(),
                    autoRefreshToken: true
                )
            )
        )
    }()

    private static func loadURL() -> URL {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !value.isEmpty,
              let url = URL(string: value) else {
            #if DEBUG
            print("[SupabaseService] SUPABASE_URL missing or invalid in Info.plist.")
            #endif
            return URL(string: "https://invalid.supabase.co")!
        }
        return url
    }

    private static func loadAnonKey() -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !value.isEmpty,
              value != "PASTE_REAL_KEY_HERE" else {
            #if DEBUG
            print("[SupabaseService] SUPABASE_ANON_KEY not set in Info.plist. Auth calls will fail.")
            #endif
            return ""
        }
        return value
    }
}

// MARK: - Session token accessors (PR-15)

extension SupabaseService {
    /// Returns the current Supabase access token (a JWT) if the user
    /// is authenticated. Returns nil if no session exists or the SDK
    /// couldn't fetch one. supabase-swift with autoRefreshToken: true
    /// refreshes the access token transparently when nearing expiry,
    /// so callers should not need to refresh manually unless they
    /// observe a 401 response (see AnalyzeClient's retry path).
    static func currentAccessToken() async -> String? {
        do {
            let session = try await shared.auth.session
            return session.accessToken
        } catch {
            return nil
        }
    }

    /// Explicit session refresh. Used by AnalyzeClient's 401 retry
    /// path when the access token expired mid-flight or the auto
    /// refresh hasn't fired yet. Throws on offline / invalid refresh
    /// token / etc; callers map to AnalyzeError.unauthenticated.
    static func refreshSession() async throws {
        _ = try await shared.auth.refreshSession()
    }

    /// Returns the Supabase auth.uid() as a lowercase UUID string, or
    /// nil if no session exists. Used by RevenueCatStore to set the
    /// RC appUserID — the webhook joins iap_transactions rows on this
    /// value, so the local User.appleUserID (Apple's identifier) would
    /// not work here.
    static func currentUserId() async -> String? {
        do {
            let session = try await shared.auth.session
            return session.user.id.uuidString.lowercased()
        } catch {
            return nil
        }
    }
}
