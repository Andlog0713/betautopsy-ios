// ────────────────────────────────────────────────────────────
// User.swift
// BetAutopsy
//
// Local user model. Persisted via JSON-encoded Data in
// UserDefaults under key "auth.user". appleUserID is the stable
// identifier returned by ASAuthorizationAppleIDCredential.user;
// displayName + email come from Apple at first sign-in only.
//
// Created May 14 2026 (PR-13).
// ────────────────────────────────────────────────────────────

import Foundation

struct User: Codable, Equatable {
    let appleUserID: String
    var displayName: String?
    var email: String?
    let timezone: String
    let firstSignedInAt: Date
    var lastSignedInAt: Date
}
