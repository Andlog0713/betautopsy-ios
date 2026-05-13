//
//  AnalyzeError.swift
//  BetAutopsy
//
//  Typed errors for the analyze pipeline. Carries enough information
//  for the UI to decide whether to show a retry button via `isRetriable`.
//

import Foundation

enum AnalyzeError: Error, LocalizedError {
    case unauthenticated
    case paymentRequired
    case rateLimited(retryAfter: TimeInterval?)
    case badRequest(message: String)
    case serverError(message: String?)
    case timeout
    case streamParseError(detail: String)
    case noJWTConfigured
    case networkUnreachable
    case streamError(message: String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .unauthenticated:
            return "Sign in expired. Tap to sign in again."
        case .paymentRequired:
            return "This requires a paid plan. Tap to upgrade."
        case .rateLimited(let retryAfter):
            if let after = retryAfter {
                return "Too many requests. Try again in \(Int(after))s."
            }
            return "Too many requests. Try again in a minute."
        case .badRequest(let message):
            return message
        case .serverError(let message):
            return message ?? "Server error. Try again."
        case .timeout:
            return "Analysis timed out. The server may be busy."
        case .streamParseError(let detail):
            return "Couldn't read the analysis response. \(detail)"
        case .noJWTConfigured:
            return "Sign in to analyze your data."
        case .networkUnreachable:
            return "No internet connection."
        case .streamError(let message):
            return message
        case .cancelled:
            // Silent dismiss — the user already knows they cancelled,
            // and OS-triggered cancels (backgrounding, etc.) don't
            // need a "we cancelled" toast either.
            return ""
        }
    }

    /// Whether the user should be shown a retry button.
    var isRetriable: Bool {
        switch self {
        case .rateLimited, .serverError, .timeout, .networkUnreachable,
             .streamParseError, .streamError:
            return true
        case .unauthenticated, .paymentRequired, .badRequest,
             .noJWTConfigured, .cancelled:
            return false
        }
    }
}
