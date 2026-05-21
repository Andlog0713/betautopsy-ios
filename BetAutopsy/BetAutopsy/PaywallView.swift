//
//  PaywallView.swift
//  BetAutopsy
//
//  Single-SKU paywall (PR-V9-pricing). Grammarly-style sheet presented
//  from any chapter that triggers paywall.triggered analytics. One
//  product: single-report autopsy at $19.99, one-time consumable.
//
//  Bundle and Annual SKUs are retired from v1. The PR-7 / PR-7.5 era
//  three-plan radio UI is gone with them. Real StoreKit wires in PR-10.
//
//  TelemetryDeck signals preserved: paywall.viewed on appear,
//  paywall.dismissed on disappear, paywall.buy_tapped on Buy.
//  paywall.plan_selected was tied to multi-plan selection UI and is
//  retired along with that UI.
//
//  PR-V10 Phase 3: token migration only. All user-visible strings,
//  TelemetryDeck signals, and mock IAP alert behavior preserved
//  verbatim.
//
//  PR-REVENUECAT-IOS commit 4: surgical IAP wire-in. Mock alert
//  replaced with real Purchases.purchase + restorePurchases through
//  RevenueCatStore. snapshotReportId is now a required init param so
//  the pending_report_unlock_id subscriber attribute can link the
//  transaction to the right snapshot row in the webhook. All locked
//  V3 copy, tokens, compliance, age gate, restore link, and footer
//  links preserved verbatim. Zero visual diff intended on the
//  happy-path render.
//

import SwiftUI
import RevenueCat

// MARK: - Pricing constants

private enum PaywallCopy {
    /// CTA label is now built dynamically from RevenueCatStore.priceString
    /// (REBUILD-PHASE-1 Step 4); see PaywallView.ctaLabel. The "$19.99"
    /// fallback lives only in RevenueCatStore.priceString.
    static let microcopy  = "One-time charge. Yours to keep. No subscription."
    /// IAP product ID kept in code as `single` to match the existing
    /// receipt-validation / entitlement path. App Store Connect side
    /// of the rename happens separately.
    static let productID  = "single"
    /// RC package identifier (Phase 1 dashboard config: offering
    /// "default" → package "$rc_lifetime" → product "single_report_v1").
    static let packageIdentifier = "$rc_lifetime"
    /// RC entitlement identifier (Phase 1 dashboard config). Checked
    /// against CustomerInfo.entitlements.active after a restore call.
    static let entitlementIdentifier = "full_report_unlock"
    /// Restore alert copy. Two messages: one when the SDK reports the
    /// full_report_unlock entitlement is active after restore (rare
    /// for a consumable, but possible via family sharing or sandbox
    /// state), one when no active entitlement was found.
    static let restoreActiveMessage = "Purchases restored."
    static let restoreEmptyMessage  = "No active purchases to restore."
    /// Used when currentOffering is nil at buy time (offerings fetch
    /// failed silently, or sheet opened before RC could load).
    static let noOfferingError = "Couldn't load purchase options. Try again."
}

// MARK: - Paywall sheet

struct PaywallView: View {
    let snapshotReportId: String

    @Environment(\.dismiss) private var dismiss

    @State private var showingRestoreAlert: Bool = false
    @State private var restoreAlertMessage: String = ""

    private let privacyURL = URL(string: "https://betautopsy.com/privacy")!
    private let termsURL   = URL(string: "https://betautopsy.com/terms")!

    private var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                DS.Color.V3.canvasGradientStart,
                DS.Color.V3.canvasGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            canvasGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                brandHeader

                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.top, 8)

                        restoreButton
                            .padding(.top, 32)

                        complianceLine
                            .padding(.top, 24)

                        ageStatement
                            .padding(.top, 16)

                        footerLinks
                            .padding(.top, 8)

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }

                bottomCTA
            }
        }
        .alert(restoreAlertMessage, isPresented: $showingRestoreAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            Analytics.signal("paywall.viewed")
        }
        .onDisappear {
            Analytics.signal("paywall.dismissed")
        }
        .task {
            // Clear any leftover error from a previous sheet
            // presentation so the user opens on a clean state.
            RevenueCatStore.shared.clearError()

            // Fetch offerings if RC hadn't loaded them yet (e.g., the
            // sheet was triggered before the cold-start login resolved).
            // Subsequent opens skip this; currentOffering stays cached.
            if RevenueCatStore.shared.currentOffering == nil {
                await RevenueCatStore.shared.fetchOfferings()
            }
        }
    }

    // MARK: - Brand header

    private var brandHeader: some View {
        HStack {
            Image("y-mark-yellow")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.sm)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("The autopsy is ready.")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text("Dollar costs, recommendations, and the full session timeline. 23 pages.")
                .font(.custom("Georgia-Italic", size: 17))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button(action: handleRestore) {
            Text("Restore purchases")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Compliance + footer

    private var complianceLine: some View {
        Text("If gambling has stopped being fun, call 1-800-GAMBLER. We can wait.")
            .font(.system(size: 13))
            .foregroundStyle(DS.Color.V3.ctaText)
            .multilineTextAlignment(.leading)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var ageStatement: some View {
        Text("By continuing you confirm you are 18 or older.")
            .font(.system(size: 12))
            .foregroundStyle(DS.Color.V3.textTertiary)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var footerLinks: some View {
        HStack(spacing: 16) {
            Link("Privacy", destination: privacyURL)
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.V3.textTertiary)

            Link("Terms", destination: termsURL)
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.V3.textTertiary)
        }
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: 8) {
            inlineErrorLabel

            if RevenueCatStore.shared.isPollingForUpgrade {
                pollingIndicator
            } else {
                buyButton
            }

            Text(PaywallCopy.microcopy)
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.V3.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(DS.Color.V3.canvasGradientEnd)
    }

    @ViewBuilder
    private var inlineErrorLabel: some View {
        // lastPurchaseError covers RC purchase / restore failures.
        // lastPollError covers post-purchase polling failures
        // (timeout or terminal auth). Either may be set; show whichever
        // is non-nil. Purchase error takes precedence if both somehow
        // populated in the same session.
        if let error = RevenueCatStore.shared.lastPurchaseError
            ?? RevenueCatStore.shared.lastPollError {
            Text(error)
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.V3.Severity.red)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)
        }
    }

    /// Buy CTA label, built from the live localized price (Step 4).
    /// Falls back to "$19.99" via RevenueCatStore.priceString.
    private var ctaLabel: String {
        "Read the full report (\(RevenueCatStore.shared.priceString))."
    }

    private var buyButton: some View {
        Button(action: handleBuy) {
            ZStack {
                Text(ctaLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Brand.canvasDark)
                    .opacity(RevenueCatStore.shared.isLoading ? 0 : 1)

                if RevenueCatStore.shared.isLoading {
                    ProgressView()
                        .tint(DS.Color.Brand.canvasDark)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(DS.Color.V3.ctaText)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(RevenueCatStore.shared.isLoading)
    }

    private var pollingIndicator: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(DS.Color.V3.textPrimary)
            Text("Preparing your full report...")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
    }

    // MARK: - IAP handlers

    private func handleBuy() {
        Analytics.signal(
            "paywall.buy_tapped",
            parameters: ["plan_id": PaywallCopy.productID]
        )

        Task {
            guard let package = RevenueCatStore.shared
                .currentOffering?
                .availablePackages
                .first(where: { $0.identifier == PaywallCopy.packageIdentifier })
            else {
                RevenueCatStore.shared.setError(PaywallCopy.noOfferingError)
                return
            }

            do {
                let result = try await RevenueCatStore.shared.purchase(
                    package: package,
                    snapshotReportId: snapshotReportId
                )
                if result.userCancelled {
                    // Sheet stays open so the user can retry or xmark.
                    return
                }

                // Poll the backend for the webhook-created full report.
                // Up to 90s; returns nil on timeout.
                let newReport = await RevenueCatStore.shared
                    .pollForUpgradedReport(snapshotReportId: snapshotReportId)

                if let newReport {
                    ReportStore.shared.upsert(newReport)
                    dismiss()
                } else {
                    // Timeout. lastPollError is now set with the
                    // "Pull to refresh on the dashboard..." message
                    // and renders inline via bottomCTA. Hold visible
                    // for a beat so the user can read it, then close
                    // the sheet; the dashboard reactive observation
                    // will pick up the child row on the user's pull
                    // to refresh.
                    try? await Task.sleep(for: .seconds(2.5))
                    dismiss()
                }
            } catch {
                // lastPurchaseError was already set by the store's
                // catch. View re-render picks it up via the
                // bottomCTA error label.
            }
        }
    }

    private func handleRestore() {
        Task {
            do {
                let info = try await RevenueCatStore.shared.restorePurchases()
                if info.entitlements.active[PaywallCopy.entitlementIdentifier] != nil {
                    restoreAlertMessage = PaywallCopy.restoreActiveMessage
                } else {
                    restoreAlertMessage = PaywallCopy.restoreEmptyMessage
                }
                showingRestoreAlert = true
            } catch {
                // lastPurchaseError surfaced inline by the store.
            }
        }
    }
}

#Preview {
    PaywallView(snapshotReportId: "preview-snapshot-id")
        .preferredColorScheme(.dark)
}
