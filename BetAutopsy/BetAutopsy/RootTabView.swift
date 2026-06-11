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
    @Environment(\.scenePhase) private var scenePhase

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
        // Cache-first hydrate, keyed on userId so it fires once per identity
        // transition (cold launch, sign-in, sign-out). RootTabView always
        // exists (auth/onboarding is a cover over it). AuthState has no
        // `userId`; appleUserID is the stable per-user identifier and String?
        // is Hashable. A bare .task would re-fire on every tab switch into
        // this view; the id-gated form fires only on the identity change we
        // want. No longer awaits sessionPrewarm: network is off the critical
        // path of first paint now that cached reports render synchronously.
        .task(id: AuthState.shared.user?.appleUserID) {
            if let userId = AuthState.shared.user?.appleUserID {
                // Synchronous: swaps in this user's cached reports BEFORE any
                // await fires, so the UI re-renders with cached state instantly.
                reportStore.updateUser(userId)
                // Network refresh in the background. If it hangs or fails, the
                // user already sees their cached reports - they never know.
                await reportStore.hydrate()
            } else {
                reportStore.clear()
            }
        }
        .onChange(of: AuthState.shared.isAuthenticated) { _, isAuth in
            if isAuth {
                Task { await deepLinkRouter.consume() }
            }
        }
        // Out-of-sheet unlock resume: a purchase whose full report had not
        // materialized when the paywall closed completes here when the app
        // becomes active (cold launch + every foreground). No-op unless a
        // pending unlock is persisted; past the failure ceiling it surfaces
        // the recoverable failure banner on the Reports tab.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await RevenueCatStore.shared.resumePendingUnlockIfNeeded() }
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
