//
//  SetNewPasswordView.swift
//  BetAutopsy
//
//  Presented when a betautopsy://password-reset recovery link is opened.
//  BetAutopsyApp has already exchanged the link for a recovery session via
//  auth.session(from:); this screen sets the new password (auth.update) and
//  marks the user signed in through the shared AuthState tail.
//
//  Created PR-AUTH.
//

import SwiftUI
import Supabase

struct SetNewPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var password = ""
    @State private var working = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private var canSubmit: Bool { password.count >= 8 }

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                Text("Set a new password.")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Text("Enter a new password of at least 8 characters.")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 6) {
                    Text("NEW PASSWORD")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                    SecureField("", text: $password)
                        .focused($focused)
                        .font(.system(size: 16))
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(DS.Color.V3.surfaceCard)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Color.V3.Severity.red)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    focused = false
                    Task { await submit() }
                } label: {
                    ZStack {
                        Text("Save password")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.Color.Brand.canvasDark)
                            .opacity(working ? 0 : 1)
                        if working { ProgressView().tint(DS.Color.Brand.canvasDark) }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(canSubmit ? DS.Color.Brand.yellow : DS.Color.V3.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!canSubmit || working)

                Spacer()
            }
            .padding(DS.Spacing.lg)
            .padding(.top, DS.Spacing.xl)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { focused = true }
        }
    }

    private func submit() async {
        working = true
        defer { working = false }
        do {
            _ = try await SupabaseService.shared.auth.update(user: UserAttributes(password: password))
            let uid = await SupabaseService.currentUserId()
            let email = (try? await SupabaseService.shared.auth.session)?.user.email
            let now = Date()
            let user = User(
                provider: .email,
                supabaseUID: uid,
                displayName: nil,
                email: email,
                timezone: TimeZone.current.identifier,
                firstSignedInAt: now,
                lastSignedInAt: now
            )
            AuthState.shared.handleSignedIn(user: user)
            dismiss()
        } catch {
            errorMessage = "Couldn't update your password. Try again."
        }
    }
}
