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
//    - Convert APNs device token Data → 64-char lowercase hex and hand
//      to PushTokenStore.shared.register(token:)
//    - Foreground presentation options [.banner, .sound, .list]
//    - Sentry breadcrumb on every callback (tagged kind=push) so prod
//      auth races are debuggable without an attached console
//
//  Cold-start deep-link parse of launchOptions[.remoteNotification] and
//  the actual didReceive userInfo parse land in Commit 5 once
//  DeepLinkRouter exists. This commit ships AppDelegate scaffolding only.
//

import UIKit
import UserNotifications
import Sentry

final class BetAutopsyAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self

        // Cold-start deep-link parse of launchOptions[.remoteNotification]
        // is wired in Commit 5 once DeepLinkRouter exists.

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

    /// User tapped a notification. Full parse + DeepLinkRouter dispatch
    /// land in Commit 5. For now: Sentry breadcrumb and complete.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let crumb = Breadcrumb(level: .info, category: "push")
        crumb.message = "Notification tap received"
        SentrySDK.addBreadcrumb(crumb)

        completionHandler()
    }
}
