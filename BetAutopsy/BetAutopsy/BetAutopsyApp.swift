//
//  BetAutopsyApp.swift
//  BetAutopsy
//

import SwiftUI

@main
struct BetAutopsyApp: App {
    @UIApplicationDelegateAdaptor(BetAutopsyAppDelegate.self) private var appDelegate
    @State private var coordinator = OnboardingCoordinator()
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    // Pre-warm runs at App static init - starts BEFORE any view's .task fires.
    // RootTabView.task(id:) awaits this same Task before calling hydrate(),
    // guaranteeing the JWT refresh is either complete or in-flight (coalesced)
    // by the time hydrate's bearerToken needs auth.session. f4e7e69's inline
    // pre-warm raced hydrate because both fired when their views appeared;
    // this static Task sequences ahead by construction.
    static let sessionPrewarm: Task<Void, Never> = Task {
        let start = Date()
        print("[\(Date())] [perf] sessionPrewarm START")
        _ = await SupabaseService.currentAccessToken()
        let elapsed = Date().timeIntervalSince(start)
        print("[\(Date())] [perf] sessionPrewarm DONE elapsed=\(String(format: "%.2f", elapsed))s")
    }

    init() {
        print("[\(Date())] [perf] BetAutopsyApp.init")
        _ = Self.sessionPrewarm  // Touch to ensure the pre-warm Task fires at App init.
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
                    let taskStart = Date()
                    print("[\(taskStart)] [perf] WindowGroup.task START")

                    // Sync to the shared pre-warm Task instead of awaiting
                    // auth.session directly (f4e7e69 did the latter inline,
                    // which raced RootTabView.task(id:)). If the static Task is
                    // already done, this returns instantly; if still in-flight,
                    // we coalesce on it - no duplicate refresh.
                    await BetAutopsyApp.sessionPrewarm.value
                    print("[\(Date())] [perf] WindowGroup.task pre-warm sync done, elapsed=\(String(format: "%.2f", Date().timeIntervalSince(taskStart)))s")

                    // Silently sign the user out if Apple has revoked
                    // the credential since last launch. No-op if not
                    // authenticated.
                    print("[\(Date())] [perf] checkCredentialState START")
                    await AppleSignInCoordinator.checkCredentialState()
                    print("[\(Date())] [perf] checkCredentialState DONE")

                    // Cold-start RC login for a restored Supabase
                    // session. No-op if not authenticated, idempotent
                    // on repeat launches via lastLoggedInUserId.
                    print("[\(Date())] [perf] loginIfAuthenticated START")
                    await RevenueCatStore.shared.loginIfAuthenticated()
                    print("[\(Date())] [perf] loginIfAuthenticated DONE")
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
