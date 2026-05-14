//
//  AuthView.swift
//  BetAutopsy
//
//  Sign in with Apple entry point. PR-13 wires the SignInWithAppleButton
//  through AppleSignInCoordinator: nonce attached in onRequest, Supabase
//  exchange in onCompletion via the coordinator. ProgressView replaces
//  the button while the Apple sheet + Supabase round-trip are in flight.
//
//  V2 chrome (custom Inter fonts, DS.Color V2 tokens, DS.Spacing) is
//  intentionally preserved here. AuthView's V2 retirement lives in
//  sprint row 35f5964c-daf2-81fb.
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
            DS.Color.Surface.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    BAChromeLabel("CASE FILE ACCESS")

                    Text("BetAutopsy")
                        .font(.custom("Inter-Bold", size: 40))
                        .foregroundStyle(DS.Color.Text.primary)

                    Text("Behavioral analysis for sports bettors. Upload your history. See what's costing you.")
                        .font(.custom("Inter-Regular", size: 15))
                        .foregroundStyle(DS.Color.Text.secondary)
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
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundStyle(DS.Color.Text.tertiary)

                        Text("Call 1-800-GAMBLER")
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundStyle(DS.Color.Accent.luminolSoft)
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
                .tint(DS.Color.Text.primary)
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
