import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            BAColor.surface0.ignoresSafeArea()

            VStack(spacing: BASpacing.l) {
                // Forensic chrome label
                Text("CASE #001")
                    .font(BAFont.chrome)
                    .foregroundStyle(BAColor.textTertiary)
                    .tracking(1.2)

                // Hero number — the dollar impact pattern
                Text("$1,847")
                    .font(BAFont.heroNumber)
                    .foregroundStyle(BAColor.textPrimary)
                    .monospacedDigit()

                // Subtitle
                Text("lost to heated sessions")
                    .font(BAFont.bodyDefault)
                    .foregroundStyle(BAColor.textSecondary)

                // Color swatch row
                HStack(spacing: BASpacing.s) {
                    Circle().fill(BAColor.scalpelTeal).frame(width: 20, height: 20)
                    Circle().fill(BAColor.bleedRed).frame(width: 20, height: 20)
                    Circle().fill(BAColor.midnight).frame(width: 20, height: 20)
                }
                .padding(.top, BASpacing.l)
            }
        }
    }
}

#Preview {
    ContentView()
}
