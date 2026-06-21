//
//  AuthView.swift
//  BetAutopsy
//
//  Multi-provider sign-in (PR-AUTH): Continue with Apple, Continue with
//  Google, and an email/password form with a Sign in | Create account
//  toggle + Forgot password. All three land in the same Supabase session
//  and call onboardingCoordinator.advance() on success.
//
//  Apple stays prominent (App Store guideline 4.8). Google uses Supabase
//  OAuth (ASWebAuthenticationSession, no SDK); email/password uses Supabase
//  email auth with instant access (confirmation disabled server-side).
//
//  The reviewer-bypass 5-tap gesture on the lockup is preserved.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(OnboardingCoordinator.self) private var onboardingCoordinator

    @State private var apple = AppleSignInCoordinator()
    @State private var google = GoogleSignInCoordinator()
    @State private var email = EmailAuthCoordinator()

    @State private var errorMessage: String? = nil
    @State private var showingError: Bool = false

    @State private var tapCount: Int = 0
    @State private var lastTapTime: Date = .distantPast
    @State private var showingReviewerSheet: Bool = false
    @State private var showingSampleReport: Bool = false
    @State private var showingGlossary: Bool = false

    @FocusState private var focusedField: Field?
    private enum Field { case email, password }

    private var anyProviderBusy: Bool {
        apple.state == .signingIn || google.state == .signingIn || email.state == .working
    }

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    header
                    providerButtons
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.top, DS.Spacing.lg)
                    orDivider
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.lg)
                    emailForm
                        .padding(.horizontal, DS.Spacing.lg)
                    footerLinks
                        .padding(.top, DS.Spacing.xl)
                        .padding(.bottom, DS.Spacing.xxl)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear { Analytics.signal("auth.viewed") }
        .onChange(of: apple.state) { _, s in handleApple(s) }
        .onChange(of: google.state) { _, s in handleGoogle(s) }
        .onChange(of: email.state) { _, s in if s == .succeeded { onboardingCoordinator.advance() } }
        .alert("Sign in", isPresented: $showingError, presenting: errorMessage) { _ in
            Button("OK", role: .cancel) { }
        } message: { Text($0) }
        .sheet(isPresented: $showingReviewerSheet) {
            ReviewerBypassSheet(onSuccess: { showingSampleReport = true })
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingSampleReport) {
            SampleReportPreviewView(previewDismiss: { showingSampleReport = false })
                .environment(onboardingCoordinator)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingGlossary) {
            NavigationStack { GlossaryView() }
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            Image("betautopsy-lockup-horizontal-dark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 230)
                .padding(.top, DS.Spacing.xxl)
                .padding(.bottom, DS.Spacing.lg)
                .accessibilityLabel("BetAutopsy")
                .onTapGesture { registerReviewerTap() }

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
        }
    }

    // MARK: - Provider buttons

    private var providerButtons: some View {
        VStack(spacing: DS.Spacing.sm) {
            if apple.state == .signingIn {
                providerSpinner
            } else {
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                        apple.prepareNonce(on: request)
                    },
                    onCompletion: { result in
                        Task { await apple.handleAuthorizationResult(result) }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(maxWidth: 375, maxHeight: 52)
                .cornerRadius(DS.Radius.chip)
            }

            googleButton
        }
        .disabled(anyProviderBusy)
    }

    private var googleButton: some View {
        Button {
            Task { await google.signIn() }
        } label: {
            HStack(spacing: 8) {
                if google.state == .signingIn {
                    ProgressView().tint(DS.Color.Brand.canvasDark)
                } else {
                    Text("Continue with Google")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(DS.Color.Brand.canvasDark)
                }
            }
            .frame(maxWidth: 375)
            .frame(height: 52)
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
        }
        .frame(maxWidth: 375)
    }

    private var providerSpinner: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .tint(DS.Color.V3.textPrimary)
            .frame(maxWidth: 375, maxHeight: 52)
    }

    private var orDivider: some View {
        HStack(spacing: DS.Spacing.md) {
            Rectangle().fill(DS.Color.V3.borderSubtle).frame(height: 0.5)
            Text("or")
                .font(DS.Font.V3.captionLabel)
                .foregroundStyle(DS.Color.V3.textTertiary)
            Rectangle().fill(DS.Color.V3.borderSubtle).frame(height: 0.5)
        }
    }

    // MARK: - Email/password form

    @ViewBuilder
    private var emailForm: some View {
        @Bindable var email = email
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            modeToggle

            authField(label: "Email", text: $email.email, isSecure: false, field: .email)
            authField(label: "Password", text: $email.password, isSecure: true, field: .password)

            if case .failed(let message) = email.state {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.V3.Severity.red)
                    .fixedSize(horizontal: false, vertical: true)
            } else if email.state == .resetSent {
                Text("Check your email for a reset link.")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }

            continueButton

            if email.mode == .signIn {
                Button("Forgot password?") {
                    focusedField = nil
                    Task { await email.sendReset() }
                }
                .font(DS.Font.V3.captionLabel)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    private var modeToggle: some View {
        @Bindable var email = email
        return HStack(spacing: DS.Spacing.lg) {
            modeTab("Sign in", mode: .signIn)
            modeTab("Create account", mode: .createAccount)
            Spacer()
        }
    }

    private func modeTab(_ title: String, mode: EmailAuthCoordinator.Mode) -> some View {
        let selected = email.mode == mode
        return Button {
            email.mode = mode
            email.clearTransientState()
        } label: {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? DS.Color.V3.textPrimary : DS.Color.V3.textTertiary)
                Rectangle()
                    .fill(selected ? DS.Color.Brand.yellow : Color.clear)
                    .frame(height: 2)
            }
        }
    }

    private func authField(label: String, text: Binding<String>, isSecure: Bool, field: Field) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(DS.Color.V3.textTertiary)
            Group {
                if isSecure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .focused($focusedField, equals: field)
            .font(.system(size: 16))
            .foregroundStyle(DS.Color.V3.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(DS.Color.V3.surfaceCard)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var continueButton: some View {
        Button {
            focusedField = nil
            Task { await email.submit() }
        } label: {
            ZStack {
                Text("Continue")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Brand.canvasDark)
                    .opacity(email.state == .working ? 0 : 1)
                if email.state == .working {
                    ProgressView().tint(DS.Color.Brand.canvasDark)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(email.canSubmit ? DS.Color.Brand.yellow : DS.Color.V3.surfaceRaised)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!email.canSubmit || anyProviderBusy)
    }

    // MARK: - Footer

    private var footerLinks: some View {
        VStack(spacing: DS.Spacing.md) {
            Button("See a Sample Report") { showingSampleReport = true }
                .font(DS.Font.V3.captionLabel)
                .foregroundStyle(DS.Color.V3.textTertiary)

            HStack(spacing: DS.Spacing.xs) {
                Text("Problem gambling?")
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                Text("Call 1-800-MY-RESET")
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.V3.ctaText)
            }

            HStack(spacing: DS.Spacing.xs) {
                Text("Read about")
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                Button("Behavioral Patterns") { showingGlossary = true }
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.Brand.yellow)
            }
        }
    }

    // MARK: - Helpers

    private func handleApple(_ s: AppleSignInCoordinator.State) {
        switch s {
        case .succeeded: onboardingCoordinator.advance()
        case .failed(let kind): showAlert(kind.userFacingMessage)
        case .idle, .signingIn: break
        }
    }

    private func handleGoogle(_ s: GoogleSignInCoordinator.State) {
        switch s {
        case .succeeded: onboardingCoordinator.advance()
        case .failed(let kind): showAlert(kind.userFacingMessage)
        case .idle, .signingIn: break
        }
    }

    private func showAlert(_ message: String?) {
        guard let message else { return }
        errorMessage = message
        showingError = true
    }

    /// 5-taps-in-3-seconds on the lockup presents ReviewerBypassSheet.
    /// Local-only; no analytics so the bypass leaves no fingerprint.
    private func registerReviewerTap() {
        let now = Date()
        if now.timeIntervalSince(lastTapTime) > 3.0 { tapCount = 1 } else { tapCount += 1 }
        lastTapTime = now
        if tapCount >= 5 {
            showingReviewerSheet = true
            tapCount = 0
        }
    }
}

#Preview {
    AuthView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
