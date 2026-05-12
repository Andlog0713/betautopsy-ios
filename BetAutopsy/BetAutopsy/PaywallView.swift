//
//  PaywallView.swift
//  BetAutopsy
//
//  PR-7 Phase 1 / PR-7.5 Phase 1. Grammarly-style paywall presented
//  as a sheet from Chapter 7. Two plan cards as iOS-native radio
//  buttons (Bundle featured + default-selected, Annual prominent)
//  plus a small text-link fallback for Single below the card stack.
//  Single bottom CTA tracks the selected plan's label, price, and
//  microcopy across all three plans.
//
//  Bundle is the visually featured plan (Luminol border + math chip)
//  AND the default selection in the two-plan layout. The Single
//  enum case is preserved (raw value, CTA copy, microcopy) so the
//  link selector lights it up correctly.
//
//  Mocked IAP for v1: Buy and Restore Purchases both log to console
//  and present the same "Coming soon" alert. Real StoreKit wires in
//  PR-10 once DUNS is unblocked.
//
//  TelemetryDeck signals: paywall.viewed on appear, paywall.dismissed
//  on disappear, paywall.plan_selected (with plan_id parameter) on
//  any plan tap including the Single link, paywall.buy_tapped on Buy.
//

import SwiftUI

// MARK: - Plan model

enum PaywallPlan: String, CaseIterable, Identifiable {
    case single
    case bundle3
    case annual

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single:  return "Single Report"
        case .bundle3: return "3-Report Bundle"
        case .annual:  return "Pro Annual"
        }
    }

    /// Headline price shown on the card.
    var priceLabel: String {
        switch self {
        case .single:  return "$9.99"
        case .bundle3: return "$19.99"
        case .annual:  return "$99.99/year"
        }
    }

    /// Body description, verbatim from COPY_SYSTEM.md §3D.
    var description: String {
        switch self {
        case .single:
            return "One autopsy, one-time. The report stays in your library."
        case .bundle3:
            return "Three autopsies. Use them across one season. The unit price is $6.66."
        case .annual:
            return "Unlimited autopsies for a year. Built for users who run more than 10 reports a season."
        }
    }

    /// Bottom CTA label, verbatim from the PR-7 Notion spec.
    var ctaLabel: String {
        switch self {
        case .single:  return "Read the full report ($9.99)."
        case .bundle3: return "Read three full reports ($19.99)."
        case .annual:  return "Read every report you generate ($99.99/year)."
        }
    }

    /// Trust copy under the CTA. Single + Bundle are Consumables; Annual
    /// is an Auto-Renewable subscription, hence different microcopy.
    var microcopy: String {
        switch self {
        case .single, .bundle3:
            return "One-time charge. Yours to keep. No subscription."
        case .annual:
            return "Renews yearly until cancelled. Cancel anytime."
        }
    }

    /// Bundle is the visually featured plan — Luminol border + math chip
    /// per §3D's "arithmetic, not adjective" rule. No text badge.
    var isFeatured: Bool { self == .bundle3 }

    /// Math chip on the featured card. Backed by $19.99 / 3 = $6.66.
    var mathChip: String? {
        isFeatured ? "$6.66 PER REPORT" : nil
    }
}

// MARK: - Paywall sheet

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: PaywallPlan = .bundle3
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

                        planCards
                            .padding(.top, DS.Spacing.xl)

                        singleLink
                            .padding(.top, 16)

                        restoreButton
                            .padding(.top, DS.Spacing.lg)

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

    // MARK: - Plan cards

    private var planCards: some View {
        VStack(spacing: DS.Spacing.md) {
            ForEach([PaywallPlan.bundle3, .annual]) { plan in
                planCard(plan)
            }
        }
    }

    private func planCard(_ plan: PaywallPlan) -> some View {
        let isSelected = selectedPlan == plan
        let cardBg: Color = plan.isFeatured
            ? DS.Color.Accent.luminol.opacity(0.08)
            : DS.Color.Surface.card

        return Button {
            selectedPlan = plan
            Analytics.signal("paywall.plan_selected",
                             parameters: ["plan_id": plan.rawValue])
        } label: {
            HStack(alignment: .top, spacing: DS.Spacing.md) {
                radio(selected: isSelected, holeColor: cardBg)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(plan.displayName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DS.Color.Text.primary)

                        Spacer()

                        Text(plan.priceLabel)
                            .font(.custom("JetBrainsMono-Medium", size: 15))
                            .monospacedDigit()
                            .foregroundStyle(DS.Color.Text.primary)
                    }

                    if let chip = plan.mathChip {
                        Text(chip)
                            .font(.custom("JetBrainsMono-Regular", size: 10))
                            .tracking(10 * 0.15)
                            .foregroundStyle(DS.Color.Accent.luminolSoft)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DS.Color.Accent.luminol.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tile))
                            .padding(.top, 6)
                    }

                    Text(plan.description)
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.Text.secondary)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 8)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBg)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(
                        borderColor(for: plan, selected: isSelected),
                        lineWidth: borderWidth(for: plan, selected: isSelected)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
        .buttonStyle(.plain)
    }

    private func borderColor(for plan: PaywallPlan, selected: Bool) -> Color {
        if selected { return DS.Color.Accent.luminol }
        if plan.isFeatured { return DS.Color.Accent.luminol }
        return DS.Color.Border.subtle
    }

    private func borderWidth(for plan: PaywallPlan, selected: Bool) -> CGFloat {
        if selected { return 2 }
        if plan.isFeatured { return 1 }
        return DS.Stroke.hairline
    }

    private func radio(selected: Bool, holeColor: Color) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? DS.Color.Accent.luminol : DS.Color.Border.subtle,
                        lineWidth: 1)
                .frame(width: 20, height: 20)

            if selected {
                Circle()
                    .fill(DS.Color.Accent.luminol)
                    .frame(width: 20, height: 20)

                Circle()
                    .fill(holeColor)
                    .frame(width: 14, height: 14)

                Circle()
                    .fill(DS.Color.Accent.luminol)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 20, height: 20)
        .padding(.top, 2)
    }

    // MARK: - Single-plan text link

    /// Third plan selector for Single, sitting below the Bundle + Annual
    /// card stack. Tapping it selects .single — the bottom CTA + microcopy
    /// then track Single just like a card tap would. Dot-on-left visual
    /// indicator when Single is the active plan; no underline/border/shadow.
    /// 44pt minimum tap target per iOS HIG (8pt vertical padding either side
    /// of the 14pt text + 6pt dot bumps the hit area).
    private var singleLink: some View {
        Button {
            selectedPlan = .single
            Analytics.signal("paywall.plan_selected",
                             parameters: ["plan_id": PaywallPlan.single.rawValue])
        } label: {
            HStack(spacing: 8) {
                if selectedPlan == .single {
                    Circle()
                        .fill(DS.Color.Accent.luminol)
                        .frame(width: 6, height: 6)
                }
                Text("or just this report ($9.99)")
                    .font(.system(size: 14))
                    .foregroundStyle(selectedPlan == .single
                                     ? DS.Color.Text.primary
                                     : DS.Color.Text.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                Text(selectedPlan.ctaLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Text.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(DS.Color.Accent.luminol)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }

            Text(selectedPlan.microcopy)
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
        Analytics.signal("paywall.buy_tapped",
                         parameters: ["plan_id": selectedPlan.rawValue])
        #if DEBUG
        print("[Paywall] Buy tapped for plan: \(selectedPlan.rawValue)")
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
