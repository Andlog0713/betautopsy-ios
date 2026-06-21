// ────────────────────────────────────────────────────────────
// AuthState.swift
// BetAutopsy
//
// Single source of truth for client-side auth state. @Observable
// singleton bridged to UserDefaults under keys "auth.user" and
// "auth.isAuthenticated". Supabase session itself is persisted
// to Keychain by supabase-swift internally (see SupabaseService).
//
// @AppStorage is the typical pattern for view-bound persistence,
// but a non-View class accesses UserDefaults directly with the
// same keys. SwiftUI views may still read these keys via
// @AppStorage if useful; they stay in sync.
//
// Created May 14 2026 (PR-13).
// ────────────────────────────────────────────────────────────

import Foundation
import Supabase

@Observable
@MainActor
final class AuthState {
    static let shared = AuthState()

    private(set) var user: User?
    private(set) var isAuthenticated: Bool = false

    private static let userKey = "auth.user"
    private static let authStateKey = "auth.isAuthenticated"

    private init() {
        loadFromStorage()
    }

    /// Shared post-session tail for EVERY provider (Apple / Google / email).
    /// Persists the user, flushes a pending push token, and logs the Supabase
    /// uid into RevenueCat (the IAP webhook joins on auth.uid(), not the
    /// provider id). Call AFTER a Supabase session is established.
    func handleSignedIn(user: User) {
        setAuthenticated(user: user)
        PushTokenStore.shared.flushIfPending()
        Task {
            guard let uid = await SupabaseService.currentUserId() else { return }
            await RevenueCatStore.shared.login(userId: uid)
        }
    }

    /// Sets the authenticated user, merging any non-nil fields from the
    /// existing record (preserves displayName + email + firstSignedInAt
    /// on subsequent sign-ins, since Apple returns those only the first
    /// time). Should only be called AFTER a Supabase session is
    /// established and persisted to Keychain.
    func setAuthenticated(user: User) {
        var merged = user
        if let existing = self.user, Self.sameIdentity(existing, user) {
            if merged.displayName == nil { merged.displayName = existing.displayName }
            if merged.email == nil { merged.email = existing.email }
            merged = User(
                provider: merged.provider,
                appleUserID: merged.appleUserID ?? existing.appleUserID,
                supabaseUID: merged.supabaseUID ?? existing.supabaseUID,
                displayName: merged.displayName,
                email: merged.email,
                timezone: merged.timezone,
                firstSignedInAt: existing.firstSignedInAt,
                lastSignedInAt: merged.lastSignedInAt
            )
        }
        self.user = merged
        self.isAuthenticated = true
        persistToStorage()
    }

    /// Same person across sign-ins. Prefer the cross-provider Supabase uid;
    /// fall back to appleUserID for records that predate supabaseUID.
    private static func sameIdentity(_ a: User, _ b: User) -> Bool {
        if let au = a.supabaseUID, let bu = b.supabaseUID { return au == bu }
        if let aa = a.appleUserID, let ba = b.appleUserID { return aa == ba }
        return false
    }

    func signOut() async {
        do {
            try await SupabaseService.shared.auth.signOut()
        } catch {
            // Best-effort: clear local state even if remote sign-out fails.
        }
        self.user = nil
        self.isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: Self.userKey)
        UserDefaults.standard.set(false, forKey: Self.authStateKey)
        PushTokenStore.shared.clearPendingToken()
        ActionCheckoffStore.shared.clearAll()
        // Wipe the disk-backed report cache immediately on sign-out (security:
        // never serve one user's cached reports to the next). RootTabView's
        // task(id:) also clears when the user id goes nil, but that fires only
        // when the view re-evaluates; doing it here makes it immediate.
        ReportStore.shared.clear()
        Task { await RevenueCatStore.shared.logout() }
    }

    private func loadFromStorage() {
        guard UserDefaults.standard.bool(forKey: Self.authStateKey),
              let data = UserDefaults.standard.data(forKey: Self.userKey),
              let decoded = try? JSONDecoder().decode(User.self, from: data) else {
            return
        }
        self.user = decoded
        self.isAuthenticated = true
    }

    private func persistToStorage() {
        guard let user else { return }
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Self.userKey)
            UserDefaults.standard.set(true, forKey: Self.authStateKey)
        }
    }
}
