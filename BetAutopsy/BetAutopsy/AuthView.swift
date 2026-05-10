//
//  AuthView.swift
//  BetAutopsy
//
//  Sign in with Apple entry point. Static UI scaffold.
//  Real Sign in with Apple wiring blocked on DUNS / Apple Dev Program activation.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    var body: some View {
        ZStack {
            BAColor.surface0.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero
                VStack(alignment: .leading, spacing: BASpacing.m) {
                    BAChromeLabel("CASE FILE ACCESS")

                    Text("BetAutopsy")
                        .font(BAFont.body(40, weight: .bold))
                        .foregroundStyle(BAColor.textPrimary)

                    Text("Behavioral analysis for sports bettors. Upload your history. See what's costing you.")
                        .font(BAFont.bodyDefault)
                        .foregroundStyle(BAColor.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BASpacing.l)

                Spacer()

                // Sign in
                VStack(spacing: BASpacing.m) {
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            // Real handling wired post-DUNS. For now, just log.
                            switch result {
                            case .success:
                                print("AuthView: SiwA stub success (real wiring blocked on DUNS)")
                            case .failure(let error):
                                print("AuthView: SiwA stub failure - \(error.localizedDescription)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .cornerRadius(BARadius.small)
                    .padding(.horizontal, BASpacing.l)

                    // Compliance footer
                    VStack(spacing: BASpacing.xs) {
                        Text("By continuing you confirm you are 21 or older.")
                            .font(BAFont.bodySmall)
                            .foregroundStyle(BAColor.textTertiary)

                        HStack(spacing: BASpacing.xs) {
                            Text("Problem gambling?")
                                .font(BAFont.bodySmall)
                                .foregroundStyle(BAColor.textTertiary)

                            Text("Call 1-800-GAMBLER")
                                .font(BAFont.bodySmall)
                                .foregroundStyle(BAColor.scalpelTeal)
                        }
                    }
                    .padding(.top, BASpacing.s)
                }
                .padding(.bottom, BASpacing.xxl)
            }
        }
    }
}

#Preview {
    AuthView()
        .preferredColorScheme(.dark)
}
