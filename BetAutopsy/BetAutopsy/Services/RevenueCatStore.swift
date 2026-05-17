//
//  RevenueCatStore.swift
//  BetAutopsy
//
//  Process-lifetime singleton that owns all RevenueCat SDK calls. Sits
//  between AuthState / AppleSignInCoordinator / BetAutopsyApp (which
//  drive login + restored-session login) and PaywallView (which drives
//  the purchase + restore flows). Views observe currentOffering,
//  isLoading, and lastPurchaseError; they never call Purchases directly.
//
//  appUserID identity rule: RC appUserID MUST equal Supabase auth.uid()
//  so the /api/webhooks/revenuecat handler can join iap_transactions
//  rows to the right user_id. The Supabase uid lives on
//  SupabaseService.shared.auth.session.user.id (UUID); the local User
//  struct in AuthState carries appleUserID which is NOT the same value.
//
//  Idempotent login: lastLoggedInUserId guards against repeated logIn
//  calls for the same Supabase uid. Cold-start path (BetAutopsyApp
//  .task → loginIfAuthenticated) and fresh-Apple-sign-in path
//  (AppleSignInCoordinator.handleSuccess → loginIfAuthenticated) both
//  reach login(userId:); the second call is a no-op.
//
//  Surface-silent failures on login / logout / fetchOfferings — Sentry
//  capture only, kind=iap. purchase() and restorePurchases() throw
//  because PaywallView needs to react to user-initiated failures.
//

import Foundation
import Observation
import RevenueCat
import Sentry

@Observable
@MainActor
final class RevenueCatStore {
    static let shared = RevenueCatStore()
    private init() {}

    // MARK: - Observable state

    private(set) var currentOffering: Offering?
    private(set) var isLoading: Bool = false
    private(set) var lastPurchaseError: String?

    // MARK: - Internal state

    /// Guards login() against repeated calls for the same Supabase uid.
    /// Cleared on logout(). Not observable; views don't need this.
    private var lastLoggedInUserId: String?

    // MARK: - Login / logout

    /// Idempotent login. No-op if already logged in as the same user.
    /// Fetches the current offering automatically after a successful
    /// fresh login (skipped on the no-op path since the offering will
    /// already be cached).
    func login(userId: String) async {
        guard lastLoggedInUserId != userId else { return }

        do {
            _ = try await Purchases.shared.logIn(userId)
            lastLoggedInUserId = userId

            let crumb = Breadcrumb(level: .info, category: "iap")
            crumb.message = "RC logIn ok"
            SentrySDK.addBreadcrumb(crumb)

            await fetchOfferings()
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "iap", key: "kind")
                scope.setTag(value: "rc_login", key: "failure_source")
            }
        }
    }

    /// Convenience entry point used from BetAutopsyApp .task (cold-start
    /// restored session) and from AppleSignInCoordinator.handleSuccess
    /// (fresh sign-in). Reads the Supabase session for the uid; the
    /// local User struct in AuthState carries appleUserID which would
    /// break the webhook's user_id join.
    func loginIfAuthenticated() async {
        guard AuthState.shared.isAuthenticated else { return }
        guard let uid = await SupabaseService.currentUserId() else {
            let crumb = Breadcrumb(level: .error, category: "iap")
            crumb.message = "AuthState authenticated but supabase uid nil"
            SentrySDK.addBreadcrumb(crumb)
            return
        }
        await login(userId: uid)
    }

    /// Called from AuthState.signOut alongside the other cross-cutting
    /// clears (PushTokenStore.clearPendingToken, ActionCheckoffStore.
    /// clearAll). Prevents cross-user RC state on relaunch.
    func logout() async {
        do {
            _ = try await Purchases.shared.logOut()
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "iap", key: "kind")
                scope.setTag(value: "rc_logout", key: "failure_source")
            }
        }
        lastLoggedInUserId = nil
        currentOffering = nil
    }

    // MARK: - Offerings

    /// Fetches RC offerings and assigns .current to currentOffering.
    /// Called automatically after a fresh login(); also exposed for
    /// PaywallView to call on appear if currentOffering is nil (e.g.,
    /// the user opened PaywallView before the cold-start login fully
    /// resolved). Silent on failure — PaywallView shows a generic
    /// "Couldn't load purchase options" state when currentOffering
    /// stays nil.
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current

            let crumb = Breadcrumb(level: .info, category: "iap")
            crumb.message = "RC offerings fetched"
            crumb.data = ["hasCurrent": currentOffering != nil]
            SentrySDK.addBreadcrumb(crumb)
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "iap", key: "kind")
                scope.setTag(value: "rc_fetch_offerings", key: "failure_source")
            }
        }
    }

    // MARK: - Purchase

    /// Initiates the StoreKit purchase flow via RevenueCat. Sets the
    /// pending_report_unlock_id subscriber attribute BEFORE calling
    /// purchase(package:) so the webhook can read it from
    /// subscriber_attributes when the transaction posts. Without this
    /// the webhook can't link the iap_transactions row to the snapshot
    /// it should upgrade.
    ///
    /// isLoading flips true for the duration of the call. Caller
    /// (PaywallView) observes it to drive the spinner state.
    /// lastPurchaseError is cleared at entry and set on caught errors
    /// before the rethrow.
    func purchase(
        package: Package,
        snapshotReportId: String
    ) async throws -> PurchaseResult {
        isLoading = true
        lastPurchaseError = nil
        defer { isLoading = false }

        Purchases.shared.attribution.setAttributes([
            "pending_report_unlock_id": snapshotReportId
        ])

        let crumb = Breadcrumb(level: .info, category: "iap")
        crumb.message = "RC purchase initiated"
        crumb.data = [
            "snapshotReportId": snapshotReportId,
            "package": package.identifier
        ]
        SentrySDK.addBreadcrumb(crumb)

        do {
            let result = try await Purchases.shared.purchase(package: package)
            return PurchaseResult(
                customerInfo: result.customerInfo,
                transaction: result.transaction,
                userCancelled: result.userCancelled
            )
        } catch {
            lastPurchaseError = "Couldn't complete purchase. Try again."
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "iap", key: "kind")
                scope.setTag(value: "rc_purchase", key: "failure_source")
            }
            throw error
        }
    }

    // MARK: - Restore

    /// Required by the App Store. RevenueCat dashboard handles dedup
    /// via transaction_id, so this is safe to call repeatedly. Returns
    /// the updated CustomerInfo; PaywallView inspects entitlements to
    /// decide whether to show a "Purchases restored" success or a
    /// "No active purchases to restore" message.
    func restorePurchases() async throws -> CustomerInfo {
        isLoading = true
        lastPurchaseError = nil
        defer { isLoading = false }

        do {
            let info = try await Purchases.shared.restorePurchases()

            let crumb = Breadcrumb(level: .info, category: "iap")
            crumb.message = "RC restore ok"
            SentrySDK.addBreadcrumb(crumb)

            return info
        } catch {
            lastPurchaseError = "Couldn't restore purchases. Try again."
            SentrySDK.capture(error: error) { scope in
                scope.setTag(value: "iap", key: "kind")
                scope.setTag(value: "rc_restore", key: "failure_source")
            }
            throw error
        }
    }

}

// MARK: - Result type

/// Thin wrapper around RevenueCat's PurchaseResultData so call sites
/// don't have to import the inner tuple type. Mirrors the field set
/// verbatim.
struct PurchaseResult {
    let customerInfo: CustomerInfo
    let transaction: StoreTransaction?
    let userCancelled: Bool
}
