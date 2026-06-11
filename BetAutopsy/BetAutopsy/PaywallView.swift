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

    /// True once the in-sheet poll window elapses without materialization.
    /// Swaps the compiling spinner for the calm "in your Reports tab" copy.
    /// Not an error state.
    @State private var showStillCompiling: Bool = false

    /// Rotating compile-stage copy index, advanced by the compilingBlock task.
    @State private var stageIndex: Int = 0

    private let compileStages = [
        "Analyzing your bets.",
        "Itemizing the costs.",
        "Writing your verdict."
    ]

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
        Text("If gambling has stopped being fun, call 1-800-MY-RESET. We can wait.")
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

            if showStillCompiling {
                stillCompilingBlock
            } else if RevenueCatStore.shared.isPollingForUpgrade {
                compilingBlock
            } else {
                buyButton

                Text(PaywallCopy.microcopy)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(DS.Color.V3.canvasGradientEnd)
    }

    @ViewBuilder
    private var inlineErrorLabel: some View {
        // Red inline error is reserved for genuine purchase / restore
        // failures (and the terminal auth-expired poll case, which routes
        // into lastPurchaseError). A report that is simply still generating
        // is never an error and never red - it uses the calm compiling /
        // still-compiling blocks below.
        if let error = RevenueCatStore.shared.lastPurchaseError {
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

    /// Post-purchase compiling state: confirms payment up front (decoupled
    /// from generation), shows staged progress with a realistic ETA, and is
    /// dismissable - closing leaves the persisted pending unlock for the
    /// resume path to finish out of sheet.
    private var compilingBlock: some View {
        VStack(spacing: 10) {
            Text("Payment received. Your full autopsy is compiling.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ProgressView()
                    .tint(DS.Color.V3.textSecondary)
                Text(compileStages[stageIndex])
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }

            Text("This usually takes under two minutes.")
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.V3.textTertiary)
                .multilineTextAlignment(.center)

            Button("Close") { dismiss() }
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.V3.textTertiary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .task {
            // Rotate the stage copy so a long wait reads as motion, not a
            // hang. Cancels automatically when the block leaves the tree.
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6))
                stageIndex = (stageIndex + 1) % compileStages.count
            }
        }
    }

    /// In-sheet poll window elapsed. Calm, not red: the report keeps
    /// generating server-side and the resume path will surface it. Copy
    /// leads on the Reports-tab guarantee (resume-backed), not a push
    /// promise, until the report_ready push is live on the backend.
    private var stillCompilingBlock: some View {
        VStack(spacing: 12) {
            Text("Still compiling. Your full report will be in your Reports tab when it's ready.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            Button("Close") { dismiss() }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Color.V3.ctaText)
        }
        .frame(maxWidth: .infinity)
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

                // Payment is confirmed here, independent of generation.
                // Persist the pending unlock immediately so the resume path
                // owns reliability even if the sheet is closed or the
                // in-sheet poll window elapses.
                Analytics.signal("purchase.confirmed")
                PendingUnlockStore.shared.begin(snapshotId: snapshotReportId)
                Analytics.signal("compile.started")

                let outcome = await RevenueCatStore.shared
                    .pollForUpgradedReport(snapshotReportId: snapshotReportId)

                switch outcome {
                case .materialized(let report):
                    RevenueCatStore.shared.materialize(report, source: "in_sheet")
                    dismiss()
                case .stillCompiling:
                    // Calm hand-off to the resume path. Sheet stays open on
                    // the still-compiling copy; the user closes when ready.
                    showStillCompiling = true
                case .authExpired:
                    // lastPurchaseError set by the poll; red inline surface.
                    break
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
