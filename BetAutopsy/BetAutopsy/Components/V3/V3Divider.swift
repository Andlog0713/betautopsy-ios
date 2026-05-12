//
//  V3Divider.swift
//  BetAutopsy
//
//  Hairline 0.5pt divider for V3 surfaces. Always uses borderSubtle.
//

import SwiftUI

struct V3Divider: View {
    var body: some View {
        Rectangle()
            .fill(DS.Color.V3.borderSubtle)
            .frame(height: 0.5)
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Above").foregroundStyle(.white)
        V3Divider()
        Text("Below").foregroundStyle(.white)
    }
    .padding()
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
