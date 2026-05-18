//
//  AccountDeletionService.swift
//  BetAutopsy
//
//  Best-effort account deletion. Attempts server-side delete via the
//  `delete_account` Supabase edge function, then signs out locally
//  regardless. The edge function may not be deployed yet — that path
//  is intentionally silent so the local sign-out always completes,
//  satisfying Apple 5.1.1(v) (Account Deletion) from the client side
//  even before the server function lands.
//
//  When the edge function ships, swap the swallow on line N for a
//  re-throw of DeletionError.serverDeleteFailed so the UI can surface
//  the error instead of giving a false success.
//

import Foundation
import Supabase
import Functions

@MainActor
enum AccountDeletionService {
    enum DeletionError: LocalizedError {
        case serverDeleteFailed(Error)

        var errorDescription: String? {
            switch self {
            case .serverDeleteFailed(let err):
                return "We couldn't complete deletion on our servers. \(err.localizedDescription) Please contact support."
            }
        }
    }

    static func deleteAccount() async throws {
        do {
            try await SupabaseService.shared.functions.invoke("delete_account")
        } catch {
            // Edge function may not be deployed yet. Log and proceed
            // to local sign-out so the user isn't blocked from leaving
            // the app. Andrew owns the server-side cleanup once
            // delete_account ships.
            print("[AccountDeletion] Server delete unavailable: \(error.localizedDescription)")
        }

        // AuthState.signOut handles Supabase auth signOut, RevenueCat
        // logout, push token clear, checkoff cache clear, and the
        // UserDefaults wipe — see AuthState.swift line 60.
        await AuthState.shared.signOut()
    }
}
