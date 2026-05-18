//
//  SettingsView.swift
//  BetAutopsy
//
//  Settings sheet presented from TodayView's gear icon. Houses the
//  Account / Legal / About surfaces required for Apple App Review:
//  account deletion (5.1.1(v)), helpline + ncpgambling.org, league
//  non-affiliation, "not a sportsbook" and non-medical disclaimers,
//  and the privacy/terms links.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showingDeleteConfirm: Bool = false
    @State private var deletionError: String?
    @State private var isDeleting: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.V3.canvasGradient.ignoresSafeArea()

                List {
                    accountSection
                    legalSection
                    aboutSection
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DS.Color.Brand.yellow)
                }
            }
            .alert("Delete account?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task { await performDelete() }
                }
            } message: {
                Text("This cannot be undone. Your reports, sessions, and check-ins will be permanently deleted.")
            }
            .alert("Could not delete",
                   isPresented: Binding(
                       get: { deletionError != nil },
                       set: { if !$0 { deletionError = nil } }
                   )) {
                Button("OK") { deletionError = nil }
            } message: {
                Text(deletionError ?? "")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var accountSection: some View {
        Section("Account") {
            Button("Sign out") {
                Task {
                    await AuthState.shared.signOut()
                    dismiss()
                }
            }
            .foregroundStyle(DS.Color.V3.textPrimary)

            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                if isDeleting {
                    ProgressView()
                } else {
                    Text("Delete account")
                }
            }
        }
    }

    @ViewBuilder
    private var legalSection: some View {
        Section("Legal") {
            Link("Privacy Policy",
                 destination: URL(string: "https://www.betautopsy.com/privacy")!)
                .foregroundStyle(DS.Color.V3.textPrimary)
            Link("Terms of Service",
                 destination: URL(string: "https://www.betautopsy.com/terms")!)
                .foregroundStyle(DS.Color.V3.textPrimary)
            Link("1-800-GAMBLER",
                 destination: URL(string: "tel://18004262537")!)
                .foregroundStyle(DS.Color.V3.textPrimary)
            Link("ncpgambling.org",
                 destination: URL(string: "https://www.ncpgambling.org")!)
                .foregroundStyle(DS.Color.V3.textPrimary)
            // Behavioral Patterns Glossary link added in Phase 5.
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section("About") {
            HStack {
                Text("Version")
                Spacer()
                Text(versionString)
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
            .foregroundStyle(DS.Color.V3.textPrimary)

            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text("BetAutopsy is not affiliated with the NFL, MLB, NBA, NHL, PGA, NCAA, or any sportsbook.")
                Text("BetAutopsy is not a sportsbook. We do not accept wagers.")
                Text("BetAutopsy is not a medical or mental health service. Consult a professional for treatment.")
            }
            .font(.system(size: 12))
            .foregroundStyle(DS.Color.V3.textTertiary)
            .padding(.vertical, DS.Spacing.xs)
        }
    }

    // MARK: - Helpers

    private var versionString: String {
        let v = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "?"
        let b = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "?"
        return "\(v) (\(b))"
    }

    private func performDelete() async {
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await AccountDeletionService.deleteAccount()
            dismiss()
        } catch {
            deletionError = error.localizedDescription
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
