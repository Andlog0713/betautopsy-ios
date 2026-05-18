//
//  ReviewerBypassSheet.swift
//  BetAutopsy
//
//  Local-only reviewer access gate. Triggered by 5 taps on the AuthView
//  lockup within 3 seconds. Code 729104 unlocks the sample report path
//  without an Apple Sign-In round-trip. No AuthState mutation — this is
//  a fallback for App Review if SiwA fails on the reviewer's device.
//

import SwiftUI

struct ReviewerBypassSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var code: String = ""
    @State private var shake: Bool = false
    @State private var showingError: Bool = false

    let onSuccess: () -> Void

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            VStack(spacing: DS.Spacing.lg) {
                Text("Reviewer Access")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Text("Enter the access code to view a sample report without signing in.")
                    .font(DS.Font.V3.bodyRegular)
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.lg)

                TextField("000000", text: $code)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .padding()
                    .background(DS.Color.V3.surfaceCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, DS.Spacing.lg)
                    .offset(x: shake ? -8 : 0)
                    .animation(.default.repeatCount(3, autoreverses: true), value: shake)

                Button {
                    submit()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Color.Brand.canvasDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(DS.Color.Brand.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
                }
                .padding(.horizontal, DS.Spacing.lg)

                Spacer()
            }
            .padding(.top, DS.Spacing.xxl)
        }
        .alert("Incorrect code", isPresented: $showingError) {
            Button("OK", role: .cancel) { code = "" }
        }
    }

    private func submit() {
        if code == "729104" {
            dismiss()
            // Small delay so dismiss completes before onSuccess presents
            // another sheet (SwiftUI sheet stacking quirk on iOS 17+).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onSuccess()
            }
        } else {
            shake.toggle()
            showingError = true
        }
    }
}

#Preview {
    ReviewerBypassSheet(onSuccess: { print("[Preview] bypass success") })
        .preferredColorScheme(.dark)
}
