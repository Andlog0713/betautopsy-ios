//
//  PreBetCoolOffScheduler.swift
//  BetAutopsy
//
//  The +30 cooling-off notification. The cooling-off period is the most
//  evidence-based intervention in the whole feature, and before this it
//  was a button that called dismiss() and did nothing. When the user
//  chooses to step back, we schedule one local notification 30 minutes
//  out: the bet is still there if they still want it, and most urges
//  pass in that window.
//
//  Reuses the provisional authorization already requested in
//  PushPermissionView (provisional permits quiet, scheduled local
//  notifications). Honors the CLAUDE.md notification rules: thread-id on
//  every notification, interruption-level active (never time-sensitive
//  in v1), no emoji, no exclamation, no first name. A single pending
//  request (stable identifier) so a re-check replaces rather than stacks.
//
//  Copy passes the COPY_SYSTEM gate: no em dashes, no exclamations, no
//  "tilt", sentence case, the only number is the user's own stake.
//

import Foundation
import UserNotifications
import Sentry

enum PreBetCoolOffScheduler {
    static let requestIdentifier = "prebet_cooloff"
    private static let threadIdentifier = "prebet_cooloff"
    private static let coolOffInterval: TimeInterval = 30 * 60

    /// Schedules (or replaces) the +30 cool-off notification for a bet
    /// the user chose to step back from. Fire-and-forget: failures route
    /// to telemetry only, never to the UI.
    static func schedule(stake: Decimal, sport: Sport, betType: BetType) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Still want that bet?"
        content.body = body(stake: stake, sport: sport)
        content.threadIdentifier = threadIdentifier
        content.interruptionLevel = .active
        content.userInfo = ["betautopsy.kind": "prebet_cooloff"]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: coolOffInterval,
            repeats: false
        )

        // Replace any in-flight cool-off so only the latest bet is pending.
        center.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])

        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                let crumb = Breadcrumb(level: .warning, category: "push")
                crumb.message = "prebet cool-off schedule failed: \(error.localizedDescription)"
                SentrySDK.addBreadcrumb(crumb)
            }
        }
    }

    /// Cancels a pending cool-off (e.g. the user came back and logged the
    /// bet anyway before the 30 minutes elapsed).
    static func cancel() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
    }

    private static func body(stake: Decimal, sport: Sport) -> String {
        let amount = BAFormat.currency(NSDecimalNumber(decimal: stake).doubleValue)
        return "Your \(amount) \(sport.displayName) bet is still there if you still want it. Most urges pass in half an hour."
    }
}
