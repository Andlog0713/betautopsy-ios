//
//  PikkitEducationView.swift
//  BetAutopsy
//
//  Step 4: explain Pikkit + deep-link to install. No analytics yet.
//

import SwiftUI

struct PikkitEducationView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(\.openURL) private var openURL

    private let pikkitURL = URL(string: "https://links.pikkit.com/invite/surf40498")!

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: DS.Spacing.md) {
                    Text("ONE MORE STEP")
                        .font(.custom("JetBrainsMono-Regular", size: 11))
                        .tracking(11 * 0.15)
                        .foregroundStyle(DS.Color.Text.tertiary)

                    Text("Connect your bet history.")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(DS.Color.Text.primary)
                        .multilineTextAlignment(.center)

                    Text("BetAutopsy reads your bet history from Pikkit, which imports from every major sportsbook and DFS platform. Pikkit's 7-day free trial includes CSV export: that's all you need to upload your bets here. We never touch your sportsbook accounts.")
                        .font(.system(size: 15))
                        .foregroundStyle(DS.Color.Text.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.horizontal, DS.Spacing.md)
                }
                .padding(.horizontal, DS.Spacing.lg)

                pikkitCard
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.top, DS.Spacing.xl)

                Text("TAKES 5 MINUTES · ONE UPLOAD PER REPORT")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
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
                    .fill(DS.Color.Surface.raised)
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.tile)
                            .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
                    )

                Text("PIKKIT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(DS.Color.Text.primary)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                Text("Pikkit")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Text.primary)

                Text("Imports from 30+ sportsbooks")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.Text.secondary)
            }

            Spacer()
        }
        .padding(DS.Spacing.md)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Text.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.Accent.luminol)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }

            Text("Pikkit is a separate app. BetAutopsy has no affiliation with their billing.")
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.Text.tertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, DS.Spacing.md)

            Button(action: { proceedAfterPikkit() }) {
                Text("Skip for now")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Color.Text.tertiary)
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
