//
//  BetAutopsyAppDelegate.swift
//  BetAutopsy
//
//  Minimal UIApplicationDelegate to host the APNs + UserNotifications
//  glue. SwiftUI BetAutopsyApp stays @main; this class wires in via
//  UIApplicationDelegateAdaptor.
//
//  Responsibilities:
//    - Set UNUserNotificationCenter.current().delegate = self at launch
//    - Cold-start deep-link parse from launchOptions[.remoteNotification]
//      BEFORE returning, so a force-quit-app tap doesn't lose the
//      report_id while iOS consumes the tap during launch
//    - Convert APNs device token Data → 64-char lowercase hex and hand
//      to PushTokenStore.shared.register(token:)
//    - Foreground presentation options [.banner, .sound, .list]
//    - Parse didReceive userInfo, dispatch to DeepLinkRouter
//    - Sentry breadcrumb on every callback (tagged kind=push)
//

import UIKit
import UserNotifications
import RevenueCat
import Sentry

final class BetAutopsyAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    /// Public SDK key for RevenueCat. Single source — referenced only
    /// from didFinishLaunchingWithOptions below. Phase 1 config locked
    /// in the RevenueCat dashboard (entitlement: full_report_unlock,
    /// offering: default → $rc_lifetime → single_report_v1).
    private static let revenueCatPublicAPIKey = "appl_GQMOhnXmOvJBreyHPyegAidajhf"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Purchases.configure must run before any other RC SDK call.
        // appUserID is intentionally NOT set here; RevenueCatStore
        // calls Purchases.shared.logIn(supabaseUserId) from the
        // sign-in / restored-session hooks (auth restore is async).
        Purchases.configure(withAPIKey: Self.revenueCatPublicAPIKey)
        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        UNUserNotificationCenter.current().delegate = self

        // Cold-start deep link: if the app was launched by a notification
        // tap (force-quit state), iOS consumes the tap during launch and
        // userNotificationCenter(_:didReceive:) may not fire. The userInfo
        // is delivered via launchOptions instead — parse and stash here
        // BEFORE returning so RootTabView's .task picks it up after auth.
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            parseAndStashReportId(userInfo: userInfo)
        }

        return true
    }

    // MARK: - APNs registration callbacks

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()

        let crumb = Breadcrumb(level: .info, category: "push")
        crumb.message = "APNs token received"
        crumb.data = ["length": hex.count]
        SentrySDK.addBreadcrumb(crumb)

        PushTokenStore.shared.register(token: hex)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        let crumb = Breadcrumb(level: .error, category: "push")
        crumb.message = "APNs registration failed: \(error.localizedDescription)"
        SentrySDK.addBreadcrumb(crumb)

        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: "push", key: "kind")
            scope.setTag(value: "apns_register_failed", key: "failure_source")
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Foreground presentation. Returning .list keeps the notification
    /// in Notification Center for later retrieval after the user
    /// dismisses the banner.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    /// User tapped a notification while app is active or backgrounded.
    /// (Cold-start taps land in didFinishLaunchingWithOptions instead.)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        parseAndStashReportId(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }

    // MARK: - userInfo parse + dispatch

    /// Reads betautopsy.kind + betautopsy.report_id from a notification
    /// userInfo dictionary. APNs delivers these as flat top-level keys
    /// with literal dots in the key name (not nested objects). On a
    /// "heated_session" kind with a report_id present, stashes the id
    /// into DeepLinkRouter.shared.pendingReportId for RootTabView to
    /// consume after auth completes.
    private func parseAndStashReportId(userInfo: [AnyHashable: Any]) {
        guard let kind = userInfo["betautopsy.kind"] as? String,
              kind == "heated_session",
              let reportId = userInfo["betautopsy.report_id"] as? String
        else {
            let crumb = Breadcrumb(level: .warning, category: "push")
            crumb.message = "Notification userInfo missing expected betautopsy keys"
            SentrySDK.addBreadcrumb(crumb)
            return
        }

        let crumb = Breadcrumb(level: .info, category: "push")
        crumb.message = "Deep link captured for report \(reportId)"
        SentrySDK.addBreadcrumb(crumb)

        DeepLinkRouter.shared.pendingReportId = reportId
    }
}
