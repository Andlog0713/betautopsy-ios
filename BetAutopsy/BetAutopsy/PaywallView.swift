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

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header
                            .padding(.top, DS.Spacing.sm)

                        restoreButton
                            .padding(.top, DS.Spacing.xl)

                        complianceLine
                            .padding(.top, DS.Spacing.lg)

                        ageStatement
                            .padding(.top, DS.Spacing.md)

                        footerLinks
                            .padding(.top, DS.Spacing.sm)

                        Spacer(minLength: DS.Spacing.lg)
                    }
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.md)
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
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, DS.Spacing.xs)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            Text("The autopsy is ready.")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Text("Dollar costs, recommendations, and the full session timeline. 23 pages.")
                .font(.custom("Georgia-Italic", size: 17))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Restore

    private var restoreButton: some View {
        Button(action: handleRestore) {
            Text("Restore purchases")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.tertiary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    // MARK: - Compliance + footer

    private var complianceLine: some View {
        Text("If gambling has stopped being fun, call 1-800-GAMBLER. We can wait.")
            .font(.system(size: 13))
            .foregroundStyle(DS.Color.Accent.luminolSoft)
            .multilineTextAlignment(.leading)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var ageStatement: some View {
        Text("By continuing you confirm you are 18 or older.")
            .font(.system(size: 12))
            .foregroundStyle(DS.Color.Text.tertiary)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var footerLinks: some View {
        HStack(spacing: DS.Spacing.md) {
            Link("Privacy", destination: privacyURL)
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.Text.tertiary)

            Link("Terms", destination: termsURL)
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.Text.tertiary)
        }
    }

    // MARK: - Bottom CTA

    private var bottomCTA: some View {
        VStack(spacing: DS.Spacing.sm) {
            Button(action: handleBuy) {
                Text(PaywallCopy.ctaLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Text.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DS.Color.Accent.luminol)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }

            Text(PaywallCopy.microcopy)
                .font(.system(size: 13))
                .foregroundStyle(DS.Color.Text.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.md)
        .padding(.bottom, DS.Spacing.lg)
        .background(DS.Color.Surface.canvas)
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
