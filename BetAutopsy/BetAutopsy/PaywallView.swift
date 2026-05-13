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

import SwiftUI

// MARK: - Pricing constants

private enum PaywallCopy {
    static let priceLabel = "$19.99"
    static let ctaLabel   = "Read the full report ($19.99)."
    static let microcopy  = "One-time charge. Yours to keep. No subscription."
    /// IAP product ID kept in code as `single` to match the existing
    /// receipt-validation / entitlement path. App Store Connect side
    /// of the rename happens separately.
    static let productID  = "single"
}

// MARK: - Paywall sheet

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showingMockAlert: Bool = false

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
        .alert("Coming soon", isPresented: $showingMockAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("IAP wires in PR-10.")
        }
        .onAppear {
            Analytics.signal("paywall.viewed")
        }
        .onDisappear {
            Analytics.signal("paywall.dismissed")
        }
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
            Button(action: handleBuy) {
                Text(PaywallCopy.ctaLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DS.Color.V3.ctaText)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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

    // MARK: - Mocked IAP handlers

    private func handleBuy() {
        Analytics.signal(
            "paywall.buy_tapped",
            parameters: ["plan_id": PaywallCopy.productID]
        )
        #if DEBUG
        print("[Paywall] Buy tapped for single-report ($19.99).")
        #endif
        showingMockAlert = true
    }

    private func handleRestore() {
        #if DEBUG
        print("[Paywall] Restore Purchases tapped")
        #endif
        showingMockAlert = true
    }
}

#Preview {
    PaywallView()
        .preferredColorScheme(.dark)
}
