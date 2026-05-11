//
//  APIConfig.swift
//  BetAutopsy
//
//  Base URL + JWT loader. JWT is read from Info.plist key
//  BETAUTOPSY_JWT, which is a placeholder in git. Andrew pastes a
//  real Supabase access token locally before testing.
//

import Foundation

enum APIConfig {
    nonisolated static let baseURL = URL(string: "https://betautopsy.com")!

    nonisolated static var jwt: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey:
            "BETAUTOPSY_JWT") as? String,
              !value.isEmpty,
              value != "PASTE_SUPABASE_JWT_HERE",
              value != "$(BETAUTOPSY_JWT)"
        else {
            #if DEBUG
            print("BETAUTOPSY_JWT not set in Info.plist. Real API calls will fail with 401.")
            #endif
            return nil
        }
        return value
    }

    nonisolated static var analyzeURL: URL {
        baseURL.appendingPathComponent("api/analyze")
    }
}
