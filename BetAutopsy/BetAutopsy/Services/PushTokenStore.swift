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
//  This commit ships state-only. POST wiring lands in Commit 3 when
//  DeviceTokenClient arrives.
//

import Foundation
import Observation

@Observable
final class PushTokenStore {
    static let shared = PushTokenStore()
    private init() {}

    private(set) var pendingToken: String?

    /// Stores the latest hex token from APNs. POST wiring added in
    /// Commit 3 alongside DeviceTokenClient.
    func register(token: String) {
        pendingToken = token
    }

    /// Called from AppleSignInCoordinator after setAuthenticated.
    /// POST wiring added in Commit 3.
    func flushIfPending() {
        // No-op in Commit 2. Becomes a network POST in Commit 3.
    }

    /// Called from AuthState.signOut to prevent cross-user token
    /// re-POST under a different account on the same device.
    func clearPendingToken() {
        pendingToken = nil
    }
}
