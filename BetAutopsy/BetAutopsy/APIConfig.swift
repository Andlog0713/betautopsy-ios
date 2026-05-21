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

    /// GET /api/reports: the authenticated user's full report list,
    /// RLS-scoped server-side via auth.uid()=user_id. No path, no query
    /// (the ?upgraded_from=X variant lives in reportsListUpgradedFromURL).
    /// Backend returns { reports: [...] } sorted created_at DESC, limit 100.
    nonisolated static var reportsListURL: URL {
        baseURL.appendingPathComponent("api/reports")
    }

    nonisolated static var checkInURL: URL {
        baseURL.appendingPathComponent("api/check-in")
    }

    nonisolated static var outcomeURL: URL {
        baseURL.appendingPathComponent("api/check-in/outcome")
    }

    nonisolated static var deviceTokensURL: URL {
        baseURL.appendingPathComponent("api/device-tokens")
    }

    nonisolated static var actionCheckoffsURL: URL {
        baseURL.appendingPathComponent("api/action-checkoffs")
    }

    /// Per-call URL builder for GET /api/reports/:id. Percent-encodes
    /// the id defensively even though canonical UUIDs are path-safe.
    nonisolated static func reportFetchURL(id: String) -> URL {
        let safe = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
        return baseURL.appendingPathComponent("api/reports/\(safe)")
    }

    /// Per-call URL builder for GET /api/reports?upgraded_from=<id>.
    /// Used by RevenueCatStore.pollForUpgradedReport to detect the
    /// webhook-created full child row after a purchase. Backend
    /// returns { reports: [...] } sorted DESC by created_at; empty
    /// array while the child is still being processed.
    nonisolated static func reportsListUpgradedFromURL(snapshotId: String) -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/reports"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "upgraded_from", value: snapshotId)]
        return components.url!
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
