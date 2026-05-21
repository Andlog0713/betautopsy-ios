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
