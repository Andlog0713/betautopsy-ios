//
//  BetAutopsyApp.swift
//  BetAutopsy
//

import SwiftUI

@main
struct BetAutopsyApp: App {
    init() {
        Analytics.initialize()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}
