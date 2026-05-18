//
//  AgeGateView.swift
//  BetAutopsy
//
//  Step 1 of onboarding: confirm 18+. Underage = soft block, no path forward.
//  Migrated to V3 in PR-V12. Gradient canvas, SF Pro system fonts, white-fill
//  primary CTA, no serif on the soft-block message.
//

import SwiftUI

struct AgeGateView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var underageBlocked = false

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

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
            HStack {
                Image("y-mark-yellow")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .accessibilityHidden(true)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()

            Text("BETAUTOPSY")
                .font(.system(size: 11, weight: .bold))
                .tracking(11 * 0.18)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text("You must be 18 or older to use BetAutopsy.")
                .font(DS.Font.V3.sectionTitle)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, DS.Spacing.lg)
                .padding(.horizontal, DS.Spacing.lg)

            Text("BetAutopsy is for adults who legally use sportsbooks, daily fantasy apps, or prediction markets. We analyze your bet history to identify behavioral patterns.")
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, DS.Spacing.md)
                .padding(.horizontal, DS.Spacing.lg)

            Spacer()

            VStack(spacing: DS.Spacing.sm) {
                Button(action: { coordinator.advance() }) {
                    Text("I'm 18 or older")
                        .font(DS.Font.V3.buttonLabel)
                        .foregroundStyle(DS.Color.V3.primaryFillText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(DS.Color.V3.primaryFill)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                }

                Button(action: { underageBlocked = true }) {
                    Text("I'm under 18")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.card)
                                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
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
                .font(.system(size: 11, weight: .bold))
                .tracking(11 * 0.18)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text("Come back when you're 18.")
                .font(DS.Font.V3.sectionTitle)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, DS.Spacing.lg)

            Text("BetAutopsy stays for when you're ready.")
                .font(DS.Font.V3.bodyLarge)
                .foregroundStyle(DS.Color.V3.textSecondary)
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
