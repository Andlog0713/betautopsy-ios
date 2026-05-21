//
//  RootTabView.swift
//  BetAutopsy
//
//  3-tab root: Today, Sessions, Reports.
//  Today tab is wrapped in NavigationStack to host a DEBUG-only reset button.
//

import SwiftUI
import UIKit

struct RootTabView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var uploadCoordinator = UploadFlowCoordinator()
    @State private var reportStore = ReportStore.shared
    @State private var deepLinkRouter = DeepLinkRouter.shared

    init() {
        configureTabBarAppearance()
    }

    var body: some View {
        TabView {
            todayTab
                .tabItem {
                    Label("Today", systemImage: "circle.dotted")
                }

            SessionsTabView()
                .environment(reportStore)
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet.rectangle")
                }

            ReportListView()
                .environment(uploadCoordinator)
                .environment(reportStore)
                .tabItem {
                    Label("Reports", systemImage: "doc.text")
                }
        }
        .tint(DS.Color.Brand.yellow)
        .overlay(alignment: .bottom) {
            UndoToast()
        }
        .fullScreenCover(item: Binding(
            get: { deepLinkRouter.presentingReport },
            set: { newValue in if newValue == nil { deepLinkRouter.dismissed() } }
        )) { report in
            ReportScrollContainer(report: report)
        }
        .task {
            await deepLinkRouter.consume()
        }
        // Hydrate ReportStore from Supabase once per userId transition.
        // RootTabView always exists (auth/onboarding is a cover over it),
        // so keying on user?.appleUserID fires on cold launch, sign-in,
        // and sign-out. AuthState has no `userId`; appleUserID is the
        // stable per-user identifier and String? is Hashable. A bare
        // .task would re-fire on every tab switch into this view; the
        // id-gated form fires only on the identity change we want.
        .task(id: AuthState.shared.user?.appleUserID) {
            let triggerStart = Date()
            print("[\(triggerStart)] [perf] RootTabView.task(id:) FIRED, isAuth=\(AuthState.shared.isAuthenticated)")

            if AuthState.shared.isAuthenticated {
                // Sequence: pre-warm completes (or is already in-flight,
                // coalesced) BEFORE hydrate. Eliminates the auth.session race
                // between BetAutopsyApp.task and this .task that f4e7e69 didn't
                // address (both fired concurrently when their views appeared).
                await BetAutopsyApp.sessionPrewarm.value
                let prewarmSyncDone = Date()
                print("[\(prewarmSyncDone)] [perf] RootTabView pre-warm sync done, elapsed=\(String(format: "%.2f", prewarmSyncDone.timeIntervalSince(triggerStart)))s")

                await reportStore.hydrate()
                let hydrateDone = Date()
                print("[\(hydrateDone)] [perf] RootTabView hydrate done, hydrate-only=\(String(format: "%.2f", hydrateDone.timeIntervalSince(prewarmSyncDone)))s, total=\(String(format: "%.2f", hydrateDone.timeIntervalSince(triggerStart)))s")
            } else {
                reportStore.clear()
            }
        }
        .onChange(of: AuthState.shared.isAuthenticated) { _, isAuth in
            if isAuth {
                Task { await deepLinkRouter.consume() }
            }
        }
    }

    private var todayTab: some View {
        NavigationStack {
            TodayView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(DS.Color.V3.canvasGradientEnd, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    #if DEBUG
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { coordinator.reset() }) {
                            Text("RESET")
                                .font(.custom("JetBrainsMono-Regular", size: 10))
                                .tracking(10 * 0.15)
                                .foregroundStyle(DS.Color.V3.textTertiary)
                        }
                    }
                    #endif
                }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DS.Color.V3.canvasGradientEnd)

        let inactive = UIColor(DS.Color.V3.textTertiary)
        let active   = UIColor(DS.Color.Brand.yellow)

        for itemAppearance in [
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ] {
            itemAppearance.normal.iconColor = inactive
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: inactive]
            itemAppearance.selected.iconColor = active
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: active]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    RootTabView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
