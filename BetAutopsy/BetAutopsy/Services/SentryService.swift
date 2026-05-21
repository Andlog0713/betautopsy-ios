// ────────────────────────────────────────────────────────────
// SentryService.swift
// BetAutopsy
//
// Sentry crash reporting wrapper. Single entry point start()
// called once from BetAutopsyApp.init(). Reads SENTRY_DSN from
// Info.plist, configures privacy-preserving options, installs a
// beforeSend hook that scrubs Authorization-style headers from
// outgoing breadcrumb data, and assigns an anonymous session ID
// (NOT the appleUserID) for grouping.
//
// Init policy: enabled in both Debug and Release. Debug builds
// set options.debug = true and environment = "debug". CLAUDE.md
// has no explicit Sentry policy as of May 13 2026.
//
// Created May 14 2026 (PR-14).
// ────────────────────────────────────────────────────────────

import Foundation
import Sentry

enum SentryService {
    nonisolated(unsafe) private static var started = false

    /// Initializes Sentry once. Safe to call from app init() AND
    /// Xcode previews; subsequent calls are no-ops.
    nonisolated static func start() {
        guard !started else { return }
        started = true

        guard let dsn = loadDSN() else {
            #if DEBUG
            print("[SentryService] SENTRY_DSN missing or placeholder. Sentry disabled.")
            #endif
            return
        }

        SentrySDK.start { options in
            options.dsn = dsn

            #if DEBUG
            options.debug = true
            options.environment = "debug"
            #else
            options.debug = false
            options.environment = "production"
            #endif

            options.releaseName = buildReleaseName()
            options.tracesSampleRate = 1.0
            options.enableAutoSessionTracking = true
            options.enableUserInteractionTracing = false

            // P0 fix May 2026: Sentry's URLSession swizzling was causing
            // /api/reports requests to time out after 15s on cold launch (server
            // responded fast per Vercel logs; iOS never received the body).
            // Disabling network tracking eliminated the hang. Crash reporting and
            // custom breadcrumbs remain enabled.
            options.enableNetworkTracking = false
            options.enableNetworkBreadcrumbs = false
            options.enableCaptureFailedRequests = false

            options.attachStacktrace = true
            options.attachScreenshot = false
            options.attachViewHierarchy = false
            options.enableSwizzling = true
            options.sendDefaultPii = false

            options.beforeSend = { event in
                Self.scrub(event: event)
                return event
            }
        }

        SentrySDK.configureScope { scope in
            let user = Sentry.User()
            user.userId = AnonymousID.current
            scope.setUser(user)
        }
    }

    /// Scrubs Authorization-style headers from any breadcrumb data
    /// attached to outgoing events. Mutates the event in place. Called
    /// from Sentry's beforeSend hook on a non-MainActor thread.
    nonisolated private static func scrub(event: Event) {
        guard let breadcrumbs = event.breadcrumbs else { return }
        for crumb in breadcrumbs {
            guard var data = crumb.data else { continue }
            if var headers = data["headers"] as? [String: Any] {
                if headers["Authorization"] != nil {
                    headers["Authorization"] = "***scrubbed***"
                }
                if headers["X-Supabase-Auth"] != nil {
                    headers["X-Supabase-Auth"] = "***scrubbed***"
                }
                if headers["apikey"] != nil {
                    headers["apikey"] = "***scrubbed***"
                }
                data["headers"] = headers
                crumb.data = data
            }
        }
    }

    nonisolated private static func loadDSN() -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN") as? String,
              !value.isEmpty,
              value != "PASTE_REAL_DSN_HERE" else {
            return nil
        }
        return value
    }

    /// Sentry release-name format: bundle@version+build. Lets release
    /// tracking match across builds with the same version string.
    nonisolated private static func buildReleaseName() -> String {
        let bundleID = Bundle.main.bundleIdentifier ?? "unknown"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(bundleID)@\(version)+\(build)"
    }
}
