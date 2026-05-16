//
//  DeepLinkRouter.swift
//  BetAutopsy
//
//  Process-lifetime singleton that bridges a notification tap's
//  report_id (captured by AppDelegate) into a SwiftUI cover at the
//  RootTabView level. Two state fields:
//
//    pendingReportId — set by AppDelegate from either cold-start
//      launchOptions[.remoteNotification] or didReceive userInfo
//    presentingReport — set by consume() after a successful fetch;
//      bound to a .fullScreenCover(item:) on RootTabView
//
//  consume() is idempotent (isConsuming flag guards re-entry) so the
//  RootTabView .task + onChange(isAuthenticated) both safely call it
//  on the same launch without firing two fetches.
//
//  Failures clear pendingReportId so the router doesn't loop forever
//  on a stale/invalid id. Sentry captures with kind=push.
//

import Foundation
import Observation
import Sentry

@Observable
final class DeepLinkRouter {
    static let shared = DeepLinkRouter()
    private init() {}

    /// Set by AppDelegate when a notification tap is observed.
    /// Cleared by consume() after a successful or failed fetch.
    var pendingReportId: String?

    /// Set by consume() after a successful ReportFetchClient.fetch.
    /// Bound to RootTabView's .fullScreenCover(item:).
    var presentingReport: AutopsyReport?

    private var isConsuming = false

    /// Idempotent. Called from RootTabView's .task on first appear
    /// and from .onChange(AuthState.isAuthenticated) when sign-in
    /// completes after a cold-start launch. No-op unless both a
    /// pendingReportId is set AND the user is authenticated.
    func consume() async {
        guard !isConsuming else { return }
        guard let id = pendingReportId else { return }
        guard AuthState.shared.isAuthenticated else { return }

        isConsuming = true
        defer { isConsuming = false }

        do {
            let report = try await ReportFetchClient.shared.fetch(id: id)
            pendingReportId = nil
            presentingReport = report

            let crumb = Breadcrumb(level: .info, category: "push")
            crumb.message = "Deep link consumed for report \(id)"
            SentrySDK.addBreadcrumb(crumb)
        } catch {
            // Clear pendingReportId so a stale/invalid id doesn't
            // re-fetch forever on every onChange.
            pendingReportId = nil
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "push", key: "kind")
                scope.setTag(value: "deep_link_fetch", key: "failure_source")
            }
        }
    }

    /// Called when the fullScreenCover dismisses (user closed the
    /// report). Resets so the next deep link can present.
    func dismissed() {
        presentingReport = nil
    }
}
