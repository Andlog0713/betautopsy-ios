//
//  AuthView.swift
//  BetAutopsy
//
//  Sign in with Apple entry point. PR-13 wires the SignInWithAppleButton
//  through AppleSignInCoordinator: nonce attached in onRequest, Supabase
//  exchange in onCompletion via the coordinator. ProgressView replaces
//  the button while the Apple sheet + Supabase round-trip are in flight.
//
//  Migrated to V3 in PR-V12. BAChromeLabel ("CASE FILE ACCESS") is shared
//  with other surfaces and retains V2 chrome styling here — its migration
//  belongs to a follow-up Components.swift PR, not this onboarding pilot.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(OnboardingCoordinator.self) private var onboardingCoordinator
    @State private var coordinator = AppleSignInCoordinator()
    @State private var errorMessage: String? = nil
    @State private var showingError: Bool = false

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    BAChromeLabel("CASE FILE ACCESS")

                    Text("BetAutopsy")
                        .font(.system(size: 40, weight: .bold))
                        .tracking(-40 * 0.015)
                        .foregroundStyle(DS.Color.V3.textPrimary)

                    Text("Behavioral analysis for sports bettors. Upload your history. See what's costing you.")
                        .font(DS.Font.V3.bodyRegular)
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.lg)

                Spacer()

                VStack(spacing: DS.Spacing.md) {
                    signInControl
                        .padding(.horizontal, DS.Spacing.lg)

                    HStack(spacing: DS.Spacing.xs) {
                        Text("Problem gambling?")
                            .font(DS.Font.V3.captionLabel)
                            .foregroundStyle(DS.Color.V3.textTertiary)

                        Text("Call 1-800-GAMBLER")
                            .font(DS.Font.V3.captionLabel)
                            .foregroundStyle(DS.Color.V3.ctaText)
                    }
                    .padding(.top, DS.Spacing.sm)
                }
                .padding(.bottom, DS.Spacing.xxl)
            }
        }
        .onAppear {
            Analytics.signal("auth.viewed")
        }
        .onChange(of: coordinator.state) { _, newState in
            handleStateChange(newState)
        }
        .alert("Sign in", isPresented: $showingError, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { message in
            Text(message)
        }
    }

    @ViewBuilder
    private var signInControl: some View {
        if coordinator.state == .signingIn {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(DS.Color.V3.textPrimary)
                .frame(maxWidth: 375, maxHeight: 52)
        } else {
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                    coordinator.prepareNonce(on: request)
                },
                onCompletion: { result in
                    Task { await coordinator.handleAuthorizationResult(result) }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(maxWidth: 375, maxHeight: 52)
            .cornerRadius(DS.Radius.chip)
        }
    }

    private func handleStateChange(_ newState: AppleSignInCoordinator.State) {
        switch newState {
        case .succeeded:
            onboardingCoordinator.advance()
        case .failed(let kind):
            if let message = kind.userFacingMessage {
                errorMessage = message
                showingError = true
            }
        case .idle, .signingIn:
            break
        }
    }
}

#Preview {
    AuthView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
