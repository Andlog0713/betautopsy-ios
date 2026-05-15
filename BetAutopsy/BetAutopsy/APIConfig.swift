//
//  APIConfig.swift
//  BetAutopsy
//
//  Base URL + bearer token accessor. The bearer is now sourced from
//  the active Supabase session (PR-15), not from a manually-pasted
//  Info.plist value. Auto-refresh is handled by supabase-swift.
//

import Foundation
import Sentry

enum APIConfig {
    // api subdomain: canonical API host (architecture Stage 1). Apex
    // (betautopsy.com) 308-redirects to www, and URLSession strips the
    // Authorization header on cross-host redirects (apex -> www counts
    // as cross-host). Targeting api.betautopsy.com directly avoids the
    // redirect chain and preserves the Bearer token.
    nonisolated static let baseURL = URL(string: "https://api.betautopsy.com")!

    nonisolated static var analyzeURL: URL {
        baseURL.appendingPathComponent("api/analyze")
    }

    nonisolated static var checkInURL: URL {
        baseURL.appendingPathComponent("api/check-in")
    }

    /// Returns a fresh Supabase access token (JWT) for the
    /// authenticated user. Returns nil if the user is not
    /// authenticated. If the user IS authenticated but no session is
    /// available (bug-shape, e.g. Keychain race after sign-in), logs
    /// a Sentry breadcrumb and returns nil.
    static var bearerToken: String? {
        get async {
            guard AuthState.shared.isAuthenticated else {
                return nil
            }
            let token = await SupabaseService.currentAccessToken()
            if token == nil {
                let crumb = Breadcrumb(level: .error, category: "auth")
                crumb.message = "Bearer fetch returned nil for authenticated user"
                SentrySDK.addBreadcrumb(crumb)
            }
            return token
        }
    }
}
