//
//  RootTabView.swift
//  BetAutopsy
//
//  3-tab root: Today, Sessions, Reports.
//  Mock placeholders for Sessions/Reports in PR-1.
//

import SwiftUI
import UIKit

struct RootTabView: View {
    init() {
        configureTabBarAppearance()
    }

    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "circle.dotted")
                }

            ContentUnavailableView("No sessions yet", systemImage: "list.bullet.rectangle")
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet.rectangle")
                }

            ContentUnavailableView("Your first report", systemImage: "doc.text")
                .tabItem {
                    Label("Reports", systemImage: "doc.text")
                }
        }
        .tint(DS.Color.Accent.luminolSoft)
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
        .preferredColorScheme(.dark)
}
