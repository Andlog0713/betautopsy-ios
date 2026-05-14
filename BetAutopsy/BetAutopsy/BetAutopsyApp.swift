//
//  BetAutopsyApp.swift
//  BetAutopsy
//

import SwiftUI

@main
struct BetAutopsyApp: App {
    @State private var coordinator = OnboardingCoordinator()
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    init() {
        Self.runArchetypeV2toV3MigrationIfNeeded()
        // Sentry first so subsequent SDK init errors get captured.
        SentryService.start()
        Analytics.initialize()
    }

    /// One-shot migration: any UserDefaults `userArchetype` value still
    /// holding a V2 archetype string gets remapped to its V3 equivalent.
    /// Guarded by a flag so it cannot run twice on the same device.
    /// V2-era users land on the right V3 archetype on first launch
    /// after the update; V3-era users hit a no-op and the flag is set.
    private static func runArchetypeV2toV3MigrationIfNeeded() {
        let flagKey = "betautopsy.archetypeV2toV3MigrationCompleted"
        guard !UserDefaults.standard.bool(forKey: flagKey) else { return }

        let migrationMap: [String: String] = [
            "Heated Bettor":  "The Tilter",
            "Parlay Dreamer": "The Lottery Bettor",
            "Volume Warrior": "The Grinder",
            "The Natural":    "The Sharp",
            "Sniper":         "The Sharp",
            "Degen King":     "The Action Junkie",
            "Sharp Sleeper":  "The Methodical",
            "Chalk Grinder":  "The Methodical",
            "The Grinder":    "The Methodical"
        ]

        let currentValue = UserDefaults.standard.string(forKey: "userArchetype") ?? ""
        if let migrated = migrationMap[currentValue] {
            UserDefaults.standard.set(migrated, forKey: "userArchetype")
        }
        UserDefaults.standard.set(true, forKey: flagKey)
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
                .environment(coordinator)
                .task {
                    // Silently sign the user out if Apple has revoked
                    // the credential since last launch. No-op if not
                    // authenticated.
                    await AppleSignInCoordinator.checkCredentialState()
                }
                .fullScreenCover(isPresented: onboardingPresented) {
                    OnboardingHost()
                        .environment(coordinator)
                        .preferredColorScheme(.dark)
                }
        }
    }

    private var onboardingPresented: Binding<Bool> {
        Binding(
            get: { !onboardingComplete },
            set: { newValue in
                if !newValue { onboardingComplete = true }
            }
        )
    }
}

private struct OnboardingHost: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    var body: some View {
        NavigationStack {
            currentStep
                .navigationBarHidden(true)
        }
    }

    @ViewBuilder
    private var currentStep: some View {
        switch coordinator.step {
        case .ageGate:             AgeGateView()
        case .sampleReportPreview: SampleReportPreviewView()
        case .betDNAQuiz:          BetDNAQuizView()
        case .archetypeReveal:     ArchetypeRevealView()
        case .signIn:              AuthView()
        case .pikkitEducation:     PikkitEducationView()
        case .complete:            Color.clear
        }
    }
}
