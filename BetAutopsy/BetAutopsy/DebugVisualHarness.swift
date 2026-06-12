//
//  DebugVisualHarness.swift
//  BetAutopsy
//
//  DEBUG-only launch-argument harness for screenshot-verifying visual
//  fixes in the simulator without auth. Added in the TESTFLIGHT-MIN
//  fix round after two compile-green no-ops shipped (StatusBarScrim
//  v1, keyboard toolbar Done): compile-green is not pixel-proof, and
//  auth blocks walking to the affected screens in a fresh simulator.
//  Keep this - it is reusable for every future visual fix.
//
//  Launch arguments (scheme arguments or `simctl launch <udid>
//  com.diagnosticsports.betautopsy.app <arg>`). NOTE the bundle id:
//  the real id is com.diagnosticsports.betautopsy.app, NOT the
//  com.diagnosticsports.BetAutopsy that CLAUDE.md documents - using
//  the documented one launches whatever stale app owns it on that
//  simulator (this exact mistake burned an hour of this fix round).
//    -ScrimHarness    stub scroll rows, pre-scrolled to the bottom so
//                     text sits in the status-bar collision zone, with
//                     .statusBarScrim() attached (the Reports/Sessions
//                     attachment idiom).
//    -ReaderHarness   the real ReportScrollContainer on MockReport
//                     (scrim under the floating xmark).
//    -CheckInHarness  the real PreBetCheckInView presented as a sheet
//                     with the stake field auto-focused, proving the
//                     decimal-pad Done row.
//

#if DEBUG
import SwiftUI

enum DebugVisualHarness {
    enum Kind: String {
        case scrim = "-ScrimHarness"
        case reader = "-ReaderHarness"
        case checkIn = "-CheckInHarness"
    }

    static var active: Kind? {
        let args = ProcessInfo.processInfo.arguments
        return Kind.allCases.first { args.contains($0.rawValue) }
    }
}

extension DebugVisualHarness.Kind: CaseIterable {}

struct DebugVisualHarnessRoot: View {
    let kind: DebugVisualHarness.Kind

    var body: some View {
        switch kind {
        case .scrim:
            scrimHarness
        case .reader:
            ReportScrollContainer(report: MockReport.heatedBettor)
        case .checkIn:
            checkInHarness
        }
    }

    /// Stub rows pre-scrolled to the bottom: the top rows sit in the
    /// status-bar region at launch, so a single screenshot proves the
    /// scrim occupies [0, topInset + 28] in screen coordinates.
    private var scrimHarness: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(0..<60, id: \.self) { i in
                        Text("Stub row \(i). This line must fade out under the clock, not collide with it.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Color.V3.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
            .defaultScrollAnchor(.bottom)
        }
        .statusBarScrim()
    }

    private var checkInHarness: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()
        }
        .sheet(isPresented: .constant(true)) {
            PreBetCheckInView(autoFocusStakeForHarness: true)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
