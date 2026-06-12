//
//  StatusBarScrim.swift
//  BetAutopsy
//
//  TESTFLIGHT-MIN safe-area audit: full-bleed scrolling surfaces with
//  no navigation bar (report reader, Reports tab, Sessions tab) let
//  scrolled content collide with the clock / Dynamic Island. This
//  scrim is a canvas-colored fill over the status-bar region with a
//  short fade into content, so scrolled text dims out under the bar.
//
//  V2 (verified in the simulator; v1 shipped as a no-op): the first
//  version read the inset from a GeometryReader INSIDE the component,
//  which reports ZERO once a parent consumed the safe area, and
//  relied on ignoresSafeArea inside an overlay, which gets re-inset.
//  This version is deliberately dumb instead:
//    - the inset comes from the UIKit key window (always the real
//      status-bar/Dynamic Island height, regardless of where in the
//      hierarchy the scrim sits) - the documented exception case for
//      UIKit ("absolutely required");
//    - positioning is a plain offset from the safe-area top, which
//      no safe-area machinery can re-inset.
//  Attachment sites must top-align it (overlay(alignment: .top) via
//  the .statusBarScrim() modifier, or a top-aligned ZStack slot). It
//  then occupies [0, topInset + 28] in screen coordinates.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct StatusBarScrim: View {
    private var topInset: CGFloat {
        #if canImport(UIKit)
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.safeAreaInsets.top ?? 0
        #else
        0
        #endif
    }

    var body: some View {
        let inset = topInset
        VStack(spacing: 0) {
            DS.Color.V3.canvasGradientStart
                .frame(height: inset)
            LinearGradient(
                colors: [
                    DS.Color.V3.canvasGradientStart,
                    DS.Color.V3.canvasGradientStart.opacity(0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
        }
        .frame(maxWidth: .infinity)
        .offset(y: -inset)
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
        .defaultScrollAnchor(.bottom)
    }
    .statusBarScrim()
    .preferredColorScheme(.dark)
}
#endif
