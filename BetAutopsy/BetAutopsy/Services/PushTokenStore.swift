//
//  PushTokenStore.swift
//  BetAutopsy
//
//  Process-lifetime singleton that holds the last APNs device token
//  received from iOS. Sits between the AppDelegate (which gets the
//  token via callback) and DeviceTokenClient (which POSTs it to the
//  backend), because the callback can fire BEFORE the user signs in
//  on cold launch.
//
//  Two flush sites both call into this store:
//    - AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken
//      → register(token:) stores; if already authenticated, fires POST
//    - AppleSignInCoordinator.handleSuccess after setAuthenticated
//      → flushIfPending() fires POST if a token is waiting
//
//  Sign-out clears pendingToken defensively (prevent cross-user re-POST
//  on a relaunch). A proper backend deactivate endpoint is v1.1 work.
//

import Foundation
import Observation
import Sentry

@Observable
final class PushTokenStore {
    static let shared = PushTokenStore()
    private init() {}

    private(set) var pendingToken: String?

    /// Stores the latest hex token from APNs. If the user is already
    /// authenticated when this fires, dispatches the POST immediately.
    /// Otherwise the token waits in pendingToken until
    /// AppleSignInCoordinator calls flushIfPending() after sign-in.
    func register(token: String) {
        pendingToken = token
        if AuthState.shared.isAuthenticated {
            Task { await postToken(token) }
        }
    }

    /// Called from AppleSignInCoordinator after setAuthenticated.
    /// Fires the POST if a token was stashed by a prior APNs callback
    /// that fired before sign-in completed.
    func flushIfPending() {
        guard let token = pendingToken else { return }
        Task { await postToken(token) }
    }

    /// Called from AuthState.signOut to prevent cross-user token
    /// re-POST under a different account on the same device. Does NOT
    /// call any backend deactivate endpoint — that ships as v1.1
    /// security work.
    func clearPendingToken() {
        pendingToken = nil
    }

    /// Fire-and-forget POST. Backend is idempotent (upsert on
    /// user_id + token), so retries on transient failure are safe to
    /// skip in v1 — the next APNs callback or sign-in flush will
    /// re-attempt.
    private func postToken(_ token: String) async {
        do {
            try await DeviceTokenClient.shared.register(token: token)
            let crumb = Breadcrumb(level: .info, category: "push")
            crumb.message = "Device token registered"
            SentrySDK.addBreadcrumb(crumb)
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "push", key: "kind")
                scope.setTag(value: "device_token_register", key: "failure_source")
            }
        }
    }
}
