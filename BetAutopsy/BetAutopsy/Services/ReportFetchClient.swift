//
//  ReportFetchClient.swift
//  BetAutopsy
//
//  GET /api/reports/[id] client. Used by DeepLinkRouter to materialize
//  an AutopsyReport from a notification's report_id when the report
//  isn't already in the in-memory ReportStore (cold launch from
//  notification tap, or push for a report the user has never opened).
//
//  Wire shape (PR #37 backend ship):
//    { report: <raw autopsy_reports row> }
//
//  This client's response wrapper mirrors AnalyzeClient.WrappedReportPayload
//  verbatim — same .convertFromSnakeCase strategy, same Inner struct
//  shape, same field set — with two adjustments for the fetch context:
//    - id and createdAt are REQUIRED on fetch (always present on a
//      persisted row); AnalyzeClient's are optional because the
//      pre-insert path may not have them yet
//    - caseNumber is added because raw rows have case_number and we
//      need it to construct the final AutopsyReport. Defensive
//      fallback "BA-<8 hex>" handles any future schema drift
//
//  Mirrors PreBetCheckInClient on the auth pattern: 401 refresh-retry,
//  Sentry breadcrumb on the retry path, no user-visible UI on failure
//  (DeepLinkRouter captures via Sentry and clears pendingReportId).
//

import Foundation
import Sentry

final class ReportFetchClient {
    static let shared = ReportFetchClient()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    /// Public entry point. Returns the fully-decoded AutopsyReport ready
    /// for ReportView presentation.
    func fetch(id: String) async throws -> AutopsyReport {
        do {
            return try await attemptFetch(id: id)
        } catch ReportFetchError.unauthorized {
            let crumb = Breadcrumb(level: .warning, category: "auth")
            crumb.message = "reportfetch 401, refreshing session and retrying"
            SentrySDK.addBreadcrumb(crumb)

            do {
                try await SupabaseService.refreshSession()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw ReportFetchError.unauthorized
            }
            return try await attemptFetch(id: id)
        }
    }

    private func attemptFetch(id: String) async throws -> AutopsyReport {
        guard let bearer = await APIConfig.bearerToken else {
            throw ReportFetchError.unauthorized
        }

        var urlRequest = URLRequest(url: APIConfig.reportFetchURL(id: id), timeoutInterval: 15)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: urlRequest)
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let urlError as URLError {
            throw ReportFetchError.networkError(urlError)
        } catch {
            throw ReportFetchError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ReportFetchError.unexpectedStatus(-1)
        }

        switch http.statusCode {
        case 200:
            let decoded: ReportFetchResponse
            do {
                decoded = try decoder.decode(ReportFetchResponse.self, from: data)
            } catch {
                throw ReportFetchError.decodingError(error)
            }
            return Self.makeAutopsyReport(from: decoded.report)

        case 401:
            throw ReportFetchError.unauthorized
        case 403:
            throw ReportFetchError.forbidden
        case 404:
            throw ReportFetchError.notFound
        case 500...599:
            throw ReportFetchError.serverError(http.statusCode)
        default:
            throw ReportFetchError.unexpectedStatus(http.statusCode)
        }
    }

    /// Construct the final AutopsyReport, applying the case_number
    /// fallback for schema-drift defensiveness.
    private static func makeAutopsyReport(from row: ReportFetchResponse.Row) -> AutopsyReport {
        let caseNumber = row.caseNumber ?? "BA-\(String(row.id.prefix(8)).uppercased())"
        return AutopsyReport(
            id: row.id,
            caseNumber: caseNumber,
            reportType: row.reportType,
            betCountAnalyzed: row.betCountAnalyzed,
            dateRangeStart: row.dateRangeStart,
            dateRangeEnd: row.dateRangeEnd,
            createdAt: row.createdAt,
            analysis: row.reportJson
        )
    }
}

/// Mirrors AnalyzeClient.WrappedReportPayload's shape. Decoded with
/// .convertFromSnakeCase so wire `report_json` → swift `reportJson`,
/// `case_number` → `caseNumber`, etc.
private struct ReportFetchResponse: Decodable {
    let report: Row

    struct Row: Decodable {
        let id: String
        let caseNumber: String?
        let reportType: String
        let betCountAnalyzed: Int
        let dateRangeStart: String?
        let dateRangeEnd: String?
        let createdAt: String
        let reportJson: AutopsyAnalysis
    }
}

/// No LocalizedError conformance — failures are silent per the
/// locked decision. DeepLinkRouter captures with kind=push tag.
enum ReportFetchError: Error {
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int)
    case networkError(Error)
    case decodingError(Error)
    case unexpectedStatus(Int)
}
