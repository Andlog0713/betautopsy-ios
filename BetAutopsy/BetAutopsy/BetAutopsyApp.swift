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
        Analytics.initialize()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
                .environment(coordinator)
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
        case .pikkitEducation:     PikkitEducationView()
        case .archetypeReveal:     ArchetypeRevealView()
        case .complete:            Color.clear
        }
    }
}
