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

    init() {
        configureTabBarAppearance()
    }

    var body: some View {
        TabView {
            todayTab
                .tabItem {
                    Label("Today", systemImage: "circle.dotted")
                }

            ContentUnavailableView("No sessions yet", systemImage: "list.bullet.rectangle")
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet.rectangle")
                }

            ReportListView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text")
                }
        }
        .tint(DS.Color.Accent.luminolSoft)
    }

    private var todayTab: some View {
        NavigationStack {
            TodayView()
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(DS.Color.Surface.canvas, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    #if DEBUG
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { coordinator.reset() }) {
                            Text("RESET")
                                .font(.custom("JetBrainsMono-Regular", size: 10))
                                .tracking(10 * 0.15)
                                .foregroundStyle(DS.Color.Text.tertiary)
                        }
                    }
                    #endif
                }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(DS.Color.Surface.canvas)

        let inactive = UIColor(DS.Color.Text.tertiary)
        let active   = UIColor(DS.Color.Accent.luminolSoft)

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
