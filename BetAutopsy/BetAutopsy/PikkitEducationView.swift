//
//  PikkitEducationView.swift
//  BetAutopsy
//
//  Step 6: explain Pikkit + deep-link to install. No analytics yet.
//  Migrated to V3 in PR-V12.
//

import SwiftUI

struct PikkitEducationView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(\.openURL) private var openURL

    private let pikkitURL = URL(string: "https://links.pikkit.com/invite/surf40498")!

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: DS.Spacing.md) {
                    Text("ONE MORE STEP")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(11 * 0.18)
                        .foregroundStyle(DS.Color.V3.textTertiary)

                    Text("Connect your bet history.")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(-24 * 0.015)
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("BetAutopsy reads your bet history from Pikkit, which imports from every major sportsbook and DFS platform. Pikkit's 7-day free trial includes CSV export: that's all you need to upload your bets here. We never touch your sportsbook accounts.")
                        .font(DS.Font.V3.bodyRegular)
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, DS.Spacing.md)
                }
                .padding(.horizontal, DS.Spacing.lg)

                pikkitCard
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.xl)

                Text("TAKES 5 MINUTES · ONE UPLOAD PER REPORT")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(10 * 0.18)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .padding(.top, DS.Spacing.md)

                Spacer()

                actions
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.bottom, DS.Spacing.xl)
            }
        }
    }

    private var pikkitCard: some View {
        HStack(spacing: DS.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.tile)
                    .fill(DS.Color.V3.surfaceRaised)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.tile)
                            .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
                    )

                Text("PIKKIT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(11 * 0.18)
                    .foregroundStyle(DS.Color.V3.textPrimary)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Pikkit")
                    .font(DS.Font.V3.buttonLabel)
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Text("Imports from 30+ sportsbooks")
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }

            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private var actions: some View {
        VStack(spacing: DS.Spacing.md) {
            Button(action: {
                openURL(pikkitURL)
                proceedAfterPikkit()
            }) {
                Text("Open Pikkit")
                    .font(DS.Font.V3.buttonLabel)
                    .foregroundStyle(DS.Color.V3.primaryFillText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.V3.primaryFill)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }

            Text("Pikkit is a separate app. BetAutopsy has no affiliation with their billing.")
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.V3.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, DS.Spacing.md)

            Button(action: { proceedAfterPikkit() }) {
                Text("Skip for now")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
        }
    }

    /// Quiz takers see the archetype reveal; skip-path users finish onboarding
    /// here with no archetype persisted.
    private func proceedAfterPikkit() {
        if coordinator.quizResult == nil {
            coordinator.completeOnboardingSkippingReveal()
        } else {
            coordinator.advance()
        }
    }
}

#Preview {
    PikkitEducationView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
