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
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success:
                                print("AuthView: SiwA stub success (real wiring blocked on DUNS)")
                                Analytics.signal("auth.stub_completed")
                            case .failure(let error):
                                print("AuthView: SiwA stub failure - \(error.localizedDescription)")
                                Analytics.signal("auth.stub_failed")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(maxWidth: 375, maxHeight: 52)
                    .cornerRadius(DS.Radius.chip)
                    .padding(.horizontal, DS.Spacing.lg)

                    VStack(spacing: DS.Spacing.xs) {
                        Text("By continuing you confirm you are 21 or older.")
                            .font(.custom("Inter-Regular", size: 13))
                            .foregroundStyle(DS.Color.Text.tertiary)

                        HStack(spacing: DS.Spacing.xs) {
                            Text("Problem gambling?")
                                .font(.custom("Inter-Regular", size: 13))
                                .foregroundStyle(DS.Color.Text.tertiary)

                            Text("Call 1-800-GAMBLER")
                                .font(.custom("Inter-Regular", size: 13))
                                .foregroundStyle(DS.Color.Accent.luminolSoft)
                        }
                    }
                    .padding(.top, DS.Spacing.sm)
                }
                .padding(.bottom, DS.Spacing.xxl)
            }
        }
        .onAppear {
            Analytics.signal("auth.viewed")
        }
    }
}

#Preview {
    AuthView()
        .preferredColorScheme(.dark)
}
