//
//  AgeGateView.swift
//  BetAutopsy
//
//  Step 1 of onboarding: confirm 21+. Underage = soft block, no path forward.
//

import SwiftUI

struct AgeGateView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var underageBlocked = false

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            if underageBlocked {
                blockedState
            } else {
                gateContent
            }
        }
    }

    // MARK: - Gate

    private var gateContent: some View {
        VStack(spacing: 0) {
            Spacer()

            Text("BETAUTOPSY")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("You must be 18 or older to use BetAutopsy.")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .multilineTextAlignment(.center)
                .padding(.top, DS.Spacing.lg)
                .padding(.horizontal, DS.Spacing.lg)

            Text("BetAutopsy is for adults who legally use sportsbooks, daily fantasy apps, or prediction markets. We analyze your bet history to identify behavioral patterns.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, DS.Spacing.md)
                .padding(.horizontal, DS.Spacing.lg)

            Spacer()

            VStack(spacing: DS.Spacing.sm) {
                Button(action: { coordinator.advance() }) {
                    Text("I'm 18 or older")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Color.Text.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(DS.Color.Accent.luminol)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                }

                Button(action: { underageBlocked = true }) {
                    Text("I'm under 18")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DS.Color.Text.tertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.card)
                                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
                        )
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.bottom, DS.Spacing.xl)
        }
    }

    // MARK: - Soft block

    private var blockedState: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("BETAUTOPSY")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("Come back when you're 18.")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .multilineTextAlignment(.center)
                .padding(.top, DS.Spacing.lg)

            Text("BetAutopsy stays for when you're ready.")
                .font(.custom("Georgia-Italic", size: 17))
                .foregroundStyle(DS.Color.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DS.Spacing.lg)
    }
}

#Preview {
    AgeGateView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
