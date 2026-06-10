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

    @State private var tapCount: Int = 0
    @State private var lastTapTime: Date = .distantPast
    @State private var showingReviewerSheet: Bool = false
    @State private var showingSampleReport: Bool = false
    @State private var showingGlossary: Bool = false

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("betautopsy-lockup-horizontal-dark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160)
                    .padding(.top, 48)
                    .padding(.bottom, 32)
                    .accessibilityLabel("BetAutopsy")
                    .onTapGesture {
                        registerReviewerTap()
                    }

                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    BAChromeLabel("CASE FILE ACCESS")

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

                    Button("See a Sample Report") {
                        showingSampleReport = true
                    }
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .padding(.top, DS.Spacing.md)

                    HStack(spacing: DS.Spacing.xs) {
                        Text("Problem gambling?")
                            .font(DS.Font.V3.captionLabel)
                            .foregroundStyle(DS.Color.V3.textTertiary)

                        Text("Call 1-800-MY-RESET")
                            .font(DS.Font.V3.captionLabel)
                            .foregroundStyle(DS.Color.V3.ctaText)
                    }
                    .padding(.top, DS.Spacing.sm)

                    HStack(spacing: DS.Spacing.xs) {
                        Text("Read about")
                            .font(DS.Font.V3.captionLabel)
                            .foregroundStyle(DS.Color.V3.textTertiary)

                        Button("Behavioral Patterns") {
                            showingGlossary = true
                        }
                        .font(DS.Font.V3.captionLabel)
                        .foregroundStyle(DS.Color.Brand.yellow)
                    }
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
        .sheet(isPresented: $showingReviewerSheet) {
            ReviewerBypassSheet(onSuccess: {
                showingSampleReport = true
            })
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingSampleReport) {
            SampleReportPreviewView(previewDismiss: {
                showingSampleReport = false
            })
            .environment(onboardingCoordinator)
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingGlossary) {
            NavigationStack {
                GlossaryView()
            }
            .preferredColorScheme(.dark)
        }
    }

    /// 5-taps-in-3-seconds gesture on the lockup. When the threshold is
    /// reached, present ReviewerBypassSheet. Reset window opens whenever
    /// the gap between taps exceeds 3s. Local-only; no analytics emit so
    /// the bypass leaves no fingerprint in TelemetryDeck.
    private func registerReviewerTap() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) > 3.0 {
            tapCount = 1
        } else {
            tapCount += 1
        }
        lastTapTime = now
        if tapCount >= 5 {
            showingReviewerSheet = true
            tapCount = 0
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
