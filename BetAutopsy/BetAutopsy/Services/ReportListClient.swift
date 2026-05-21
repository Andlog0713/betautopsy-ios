//
//  ReportListClient.swift
//  BetAutopsy
//
//  GET /api/reports client. Fetches the authenticated user's full
//  report list for ReportStore cold-launch hydration (P0 persistence)
//  and pull-to-refresh re-sync. Backend (web 5cc8356) returns the list
//  RLS-scoped via auth.uid()=user_id, sorted created_at DESC, limit 100.
//
//  Mirrors ReportFetchClient verbatim on the auth + decode pattern:
//  singleton, .convertFromSnakeCase decoder, 401 refresh-retry with a
//  Sentry breadcrumb, shared ReportFetchError type. The list response is
//  decoded through the same Row intermediary both ReportFetchClient and
//  RevenueCatStore.UpgradedListResponse use, because AutopsyReport is not
//  directly decodable from a raw autopsy_reports row (wire `report_json`
//  maps to swift `analysis`, and `case_number` needs the BA-<hex> drift
//  fallback). makeAutopsyReport mirrors ReportFetchClient's construction.
//

import Foundation
import Sentry

final class ReportListClient {
    static let shared = ReportListClient()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    /// Public entry point. Returns every report for the authenticated
    /// user, newest-first (server-sorted).
    func fetchList() async throws -> [AutopsyReport] {
        do {
            return try await attemptFetch()
        } catch ReportFetchError.unauthorized {
            let crumb = Breadcrumb(level: .warning, category: "auth")
            crumb.message = "reportlist 401, refreshing session and retrying"
            SentrySDK.addBreadcrumb(crumb)

            do {
                try await SupabaseService.refreshSession()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw ReportFetchError.unauthorized
            }
            return try await attemptFetch()
        }
    }

    private func attemptFetch() async throws -> [AutopsyReport] {
        guard let bearer = await APIConfig.bearerToken else {
            throw ReportFetchError.unauthorized
        }

        var urlRequest = URLRequest(url: APIConfig.reportsListURL, timeoutInterval: 15)
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
            let decoded: ReportListResponse
            do {
                decoded = try decoder.decode(ReportListResponse.self, from: data)
            } catch {
                throw ReportFetchError.decodingError(error)
            }
            return decoded.reports.map(Self.makeAutopsyReport(from:))

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
    /// fallback for schema-drift defensiveness. Mirrors
    /// ReportFetchClient.makeAutopsyReport.
    private static func makeAutopsyReport(from row: ReportListResponse.Row) -> AutopsyReport {
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

/// Envelope for GET /api/reports: { reports: [<raw autopsy_reports row>] }.
/// Decoded with .convertFromSnakeCase so wire `report_json` → `reportJson`,
/// `case_number` → `caseNumber`, etc. Row mirrors ReportFetchResponse.Row.
private struct ReportListResponse: Decodable {
    let reports: [Row]

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
