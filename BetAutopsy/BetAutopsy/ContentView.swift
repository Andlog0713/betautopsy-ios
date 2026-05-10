//
//  ContentView.swift
//  BetAutopsy
//
//  Created by Andrew Hochhauser on 5/9/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Text("BetAutopsy")
                .font(.largeTitle)
            Text("v0 — foundation")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
