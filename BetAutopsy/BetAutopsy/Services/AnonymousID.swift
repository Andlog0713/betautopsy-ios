// ────────────────────────────────────────────────────────────
// AnonymousID.swift
// BetAutopsy
//
// Stable anonymous UUID for Sentry session grouping. Generated
// on first call, persisted to UserDefaults under
// "sentry.anonymousID". Decoupled from the Apple user ID so that
// Sentry events cannot be tied back to a specific person.
//
// Created May 14 2026 (PR-14).
// ────────────────────────────────────────────────────────────

import Foundation

enum AnonymousID {
    nonisolated private static let key = "sentry.anonymousID"

    /// Returns a stable anonymous UUID. Created on first call,
    /// persists across launches. UserDefaults is thread-safe, so this
    /// is callable from any actor context including Sentry's
    /// non-MainActor configureScope callback.
    nonisolated static var current: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: key)
        return new
    }
}
