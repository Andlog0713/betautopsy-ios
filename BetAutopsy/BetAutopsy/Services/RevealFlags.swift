//
//  RevealFlags.swift
//  BetAutopsy
//
//  Prompt 4 / Stage C: per-report "reveal seen" flags in UserDefaults,
//  keyed by report id. The reveal (the cover net-dollar blur-to-real
//  money shot, and the hero session chart draw-on) plays exactly ONCE
//  per report - the first viewing of the full report. Every later open
//  renders the resolved state statically: no animation, no haptic, no
//  blur-in.
//
//  Two independent flags, both "once per report":
//    moneyShot - the cover net-dollar resolve (set when it completes)
//    hero      - the SessionTimelineChart draw-on (set on first
//                scroll-into-view; may be a later session than the
//                money shot if the user never scrolled to it)
//

import Foundation

enum RevealFlags {
    private static func moneyShotKey(_ id: String) -> String { "reveal_seen_\(id)" }
    private static func heroKey(_ id: String) -> String { "reveal_hero_\(id)" }

    static func moneyShotSeen(_ id: String) -> Bool {
        UserDefaults.standard.bool(forKey: moneyShotKey(id))
    }
    static func markMoneyShotSeen(_ id: String) {
        UserDefaults.standard.set(true, forKey: moneyShotKey(id))
    }

    static func heroSeen(_ id: String) -> Bool {
        UserDefaults.standard.bool(forKey: heroKey(id))
    }
    static func markHeroSeen(_ id: String) {
        UserDefaults.standard.set(true, forKey: heroKey(id))
    }

    #if DEBUG
    /// Clears both flags for an id so a harness can replay the reveal.
    static func clear(_ id: String) {
        UserDefaults.standard.removeObject(forKey: moneyShotKey(id))
        UserDefaults.standard.removeObject(forKey: heroKey(id))
    }
    #endif
}

#if DEBUG
/// DEBUG reveal instrumentation. -RevealHarness sets slowMotion so the
/// blur-to-real is slow enough to capture a frame sequence with timed
/// screenshots (a still can't prove a resolve).
enum DebugReveal {
    @MainActor static var slowMotion = false
    /// Multiplier on the reveal timings when slowMotion is on. Wide so a
    /// frame sequence is capturable despite cold-launch timing jitter.
    @MainActor static var scale: Double { slowMotion ? 8 : 1 }

    /// App-state audit: force every EvidenceBlock to render expanded so the
    /// tap-expand evidence layer shows in a deep-scroll screenshot without a
    /// live tap. Set by the section harness; never touched in Release.
    @MainActor static var forceExpandEvidence = false
}
#endif
