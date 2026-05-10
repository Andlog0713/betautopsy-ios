//
//  ContentView.swift
//  BetAutopsy
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            BAColor.surface0.ignoresSafeArea()

            ScrollView {
                VStack(spacing: BASpacing.l) {
                    VStack(spacing: BASpacing.s) {
                        BAChromeLabel("Case #001")

                        Text("$1,847")
                            .font(BAFont.heroNumber)
                            .foregroundStyle(BAColor.textPrimary)
                            .monospacedDigit()

                        Text("lost to heated sessions")
                            .font(BAFont.bodyDefault)
                            .foregroundStyle(BAColor.textSecondary)
                    }
                    .padding(.top, BASpacing.xxl)

                    BACard {
                        VStack(alignment: .leading, spacing: BASpacing.s) {
                            BAChromeLabel("Exhibit A")
                            Text("Recency bias detected")
                                .font(BAFont.bodyLarge)
                                .foregroundStyle(BAColor.textPrimary)
                            Text("5 of your last 7 bets followed a win. Win rate dropped to 31%.")
                                .font(BAFont.bodyDefault)
                                .foregroundStyle(BAColor.textSecondary)
                        }
                    }

                    BAButton("View full autopsy", style: .primary) {
                        print("Tapped autopsy")
                    }
                    .padding(.top, BASpacing.m)
                }
                .padding(BASpacing.m)
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
