// ────────────────────────────────────────────────────────────
// SupabaseService.swift
// BetAutopsy
//
// Lazy singleton wrapping the supabase-swift SupabaseClient.
// URL + anon key load from Info.plist. Session persistence is
// explicit Keychain via KeychainLocalStorage (the SDK default on
// iOS, passed explicitly for clarity).
//
// Created May 14 2026 (PR-13).
// ────────────────────────────────────────────────────────────

import Foundation
import Supabase

enum SupabaseService {
    static let shared: SupabaseClient = {
        SupabaseClient(
            supabaseURL: loadURL(),
            supabaseKey: loadAnonKey(),
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    storage: KeychainLocalStorage(),
                    autoRefreshToken: true
                )
            )
        )
    }()

    private static func loadURL() -> URL {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !value.isEmpty,
              let url = URL(string: value) else {
            #if DEBUG
            print("[SupabaseService] SUPABASE_URL missing or invalid in Info.plist.")
            #endif
            return URL(string: "https://invalid.supabase.co")!
        }
        return url
    }

    private static func loadAnonKey() -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !value.isEmpty,
              value != "PASTE_REAL_KEY_HERE" else {
            #if DEBUG
            print("[SupabaseService] SUPABASE_ANON_KEY not set in Info.plist. Auth calls will fail.")
            #endif
            return ""
        }
        return value
    }
}
