//
//  StatusBarScrim.swift
//  BetAutopsy
//
//  TESTFLIGHT-MIN safe-area audit: full-bleed scrolling surfaces with
//  no navigation bar (report reader, Reports tab, Sessions tab) let
//  scrolled content collide with the clock / Dynamic Island. This is
//  the deliberate fix: a canvas-colored gradient pinned to the screen
//  top, sized from the actual safe-area inset (not a padding
//  constant), fading into the content so scrolled text dims out under
//  the status bar instead of fighting it.
//
//  Overlay-positioned and non-interactive: takes no layout space,
//  moves no content, blocks no taps. Screens WITH a navigation bar
//  (Today, Settings, Glossary) get the system bar material and do not
//  need this.
//

import SwiftUI

struct StatusBarScrim: View {
    var body: some View {
        GeometryReader { geo in
            LinearGradient(
                colors: [
                    DS.Color.V3.canvasGradientStart,
                    DS.Color.V3.canvasGradientStart.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            // safeAreaInsets here reports the inset this view ignores:
            // the status bar / Dynamic Island height on this device.
            .frame(height: geo.safeAreaInsets.top + 12)
        }
        .ignoresSafeArea(edges: .top)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Pins a StatusBarScrim over this view's top edge. Apply to the
    /// root container of bar-less full-bleed scroll screens.
    func statusBarScrim() -> some View {
        overlay(alignment: .top) { StatusBarScrim() }
    }
}

#if DEBUG
#Preview {
    ZStack {
        DS.Color.V3.canvasGradient.ignoresSafeArea()
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<30, id: \.self) { i in
                    Text("Row \(i) scrolls under the clock without the scrim.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
        }
    }
    .statusBarScrim()
    .preferredColorScheme(.dark)
}
#endif
