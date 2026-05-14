//
//  AnalyzeClient.swift
//  BetAutopsy
//
//  SSE-aware POST client for /api/analyze. Uses URLSession.upload(for:from:)
//  which preserves streaming semantics (URLSession.bytes(for:) does NOT
//  stream when request.httpBody is set).
//
//  Backend contract:
//    - Pre-stream JSON responses (Content-Type: application/json): 401, 402,
//      429, 400, 500/etc.
//    - SSE stream (text/event-stream) carries three event types:
//        event: metrics  — fast JS-computed metrics
//        event: complete — full AutopsyAnalysis (either at top level or
//                          wrapped under report.report_json)
//        event: error    — stream-level error message
//    - Keepalive lines (start with ":") are skipped.
//

import Foundation
import Sentry

enum AnalyzeEvent {
    case metrics([String: AnyCodableValue])
    /// Fires before metrics. Carries the server-side report id so the
    /// client can correlate against the final `complete` event and (in
    /// v1.1) poll /api/reports/:id if the SSE stream drops.
    case reportStarted(reportId: String)
    case complete(AutopsyAnalysis,
                  reportId: String?,
                  reportType: String,
                  betCount: Int,
                  dateRange: (String?, String?),
                  createdAt: String)
    case error(String)
}

/// Loose decoder for the metrics event (shape may evolve on the backend).
/// `@unchecked Sendable` is safe here: the decoded values are immutable
/// JSON scalars/containers (Int, Double, Bool, String, [Any], [String:Any],
/// NSNull), all of which are themselves Sendable in practice.
struct AnyCodableValue: Codable, @unchecked Sendable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Int.self) {
            value = v; return
        }
        if let v = try? container.decode(Double.self) {
            value = v; return
        }
        if let v = try? container.decode(Bool.self) {
            value = v; return
        }
        if let v = try? container.decode(String.self) {
            value = v; return
        }
        if let v = try? container.decode([AnyCodableValue].self) {
            value = v.map(\.value); return
        }
        if let v = try? container.decode([String: AnyCodableValue].self) {
            value = v.mapValues(\.value); return
        }
        if container.decodeNil() {
            value = NSNull(); return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "AnyCodableValue: unknown type")
    }

    func encode(to encoder: Encoder) throws {
        // Encoding not needed for decode-only use, but conform.
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

/// Wrapper-shape `complete` payload (backend may return this).
private struct WrappedReportPayload: Decodable {
    let report: Inner
    struct Inner: Decodable {
        let id: String?
        let reportType: String
        let betCountAnalyzed: Int
        let dateRangeStart: String?
        let dateRangeEnd: String?
        let createdAt: String?
        let reportJson: AutopsyAnalysis
    }
}

/// Direct-shape `complete` payload — AutopsyAnalysis fields at top level
/// plus optional metadata siblings.
private struct DirectPayload: Decodable {
    let analysis: AutopsyAnalysis
    let reportType: String
    let betCountAnalyzed: Int
    let dateRangeStart: String?
    let dateRangeEnd: String?
    let createdAt: String

    init(from decoder: Decoder) throws {
        let single = try decoder.singleValueContainer()
        analysis = try single.decode(AutopsyAnalysis.self)

        let keyed = try decoder.container(keyedBy: MetaKeys.self)
        reportType = (try? keyed.decode(
            String.self, forKey: .reportType)) ?? "full"
        betCountAnalyzed = (try? keyed.decode(
            Int.self, forKey: .betCountAnalyzed))
            ?? analysis.summary.totalBets
        dateRangeStart = try? keyed.decode(
            String.self, forKey: .dateRangeStart)
        dateRangeEnd = try? keyed.decode(
            String.self, forKey: .dateRangeEnd)
        createdAt = (try? keyed.decode(
            String.self, forKey: .createdAt))
            ?? ISO8601DateFormatter().string(from: Date())
    }

    enum MetaKeys: String, CodingKey {
        case reportType, betCountAnalyzed
        case dateRangeStart, dateRangeEnd, createdAt
    }
}

private struct PreStreamErrorResponse: Decodable {
    let error: String?
    let message: String?
}

/// AnalyzeClient is a `final class` (on MainActor by project default)
/// rather than an `actor`. The original spec called for `actor`, but the
/// project's MainActor default isolation means types in ReportModels.swift
/// have MainActor-isolated Decodable conformances. An `actor`'s nonisolated
/// static methods can't call those conformances, while a MainActor class
/// can. URLSession streaming via `bytes(for:)` suspends without blocking
/// the main thread, so MainActor here is safe.
final class AnalyzeClient {
    private let session: URLSession

    /// Last-stream diagnostic counters, surfaced into user-facing errors
    /// so we don't depend on the Xcode console being attached.
    static var lastDiagnostics: String = ""

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 300
        // Auth header is set per-request so a re-authenticated user's
        // new JWT is picked up without rebuilding the session.
        self.session = URLSession(configuration: config)
    }

    /// Streams AnalyzeEvents from POST /api/analyze. Throws AnalyzeError on
    /// pre-stream errors or stream parsing failures. The returned stream may
    /// terminate with .error or finish cleanly after .complete.
    func analyze(
        csvData: Data,
        filename: String,
        reportType: String = "snapshot",
        idempotencyKey: String? = nil
    ) async throws -> AsyncThrowingStream<AnalyzeEvent, Error> {
        guard let token = await APIConfig.bearerToken else {
            throw AnalyzeError.noJWTConfigured
        }

        let boundary = "Boundary-\(UUID().uuidString)-\(UUID().uuidString)"
        var request = URLRequest(url: APIConfig.analyzeURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)",
                         forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream",
                         forHTTPHeaderField: "Accept")
        // Server ignores Idempotency-Key today; the wire is now ready
        // for backend network-retry dedup in v1.1.
        if let idempotencyKey {
            request.setValue(idempotencyKey,
                             forHTTPHeaderField: "Idempotency-Key")
        }

        request.httpBody = Self.makeMultipartBody(
            boundary: boundary,
            csvData: csvData,
            filename: filename,
            reportType: reportType
        )

        // bytes(for:) returns (URLSession.AsyncBytes, URLResponse) and
        // streams the response, including when httpBody is set on the
        // request. The earlier suggestion to use upload(for:from:) was
        // incorrect; that variant buffers the response into Data.
        //
        // Wrap the call so its errors share the same mapping logic as
        // mid-stream errors. Without this, an OS cancel (-999) during
        // the pre-stream phase would propagate to UploadFlowCoordinator
        // unmapped and stringify into a 600-char NSError blob.
        var (bytes, http) = try await fireRequest(request)

        // 401 retry once. Race-shape: access token expired mid-flight
        // or auto-refresh hasn't fired yet. Refresh + retry once. If
        // the retry is also 401, the session is genuinely invalid.
        if http.statusCode == 401 {
            try await drainQuietly(bytes)

            let crumb = Breadcrumb(level: .warning, category: "auth")
            crumb.message = "401 received, refreshing session and retrying"
            SentrySDK.addBreadcrumb(crumb)

            do {
                try await SupabaseService.refreshSession()
            } catch {
                throw AnalyzeError.unauthenticated
            }
            guard let refreshed = await APIConfig.bearerToken else {
                throw AnalyzeError.noJWTConfigured
            }
            request.setValue("Bearer \(refreshed)",
                             forHTTPHeaderField: "Authorization")

            (bytes, http) = try await fireRequest(request)

            if http.statusCode == 401 {
                try await drainQuietly(bytes)
                throw AnalyzeError.unauthenticated
            }
        }

        let contentType = http.value(
            forHTTPHeaderField: "Content-Type") ?? ""

        // Pre-stream JSON error path
        if contentType.contains("application/json") {
            var data = Data()
            for try await byte in bytes {
                data.append(byte)
            }
            try Self.throwPreStreamError(
                status: http.statusCode, data: data, response: http)
            throw AnalyzeError.streamParseError(
                detail: "Unreachable")
        }

        guard http.statusCode == 200 else {
            throw AnalyzeError.serverError(
                message: "Unexpected HTTP \(http.statusCode)")
        }
        guard contentType.contains("text/event-stream") else {
            throw AnalyzeError.streamParseError(
                detail: "Expected SSE, got \(contentType)")
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var currentEvent: String?
                    var dataLines: [String] = []
                    var lineCount = 0
                    var dataLineCount = 0
                    var dispatchCount = 0
                    print("[AnalyzeClient] SSE stream started, contentType=\(contentType)")

                    for try await line in bytes.lines {
                        lineCount += 1
                        if line.hasPrefix(":") {
                            continue
                        }

                        if line.isEmpty {
                            if !dataLines.isEmpty {
                                let joined = dataLines.joined(
                                    separator: "\n")
                                if let event = currentEvent {
                                    try Self.dispatchEvent(
                                        name: event,
                                        dataJSON: joined,
                                        continuation: continuation
                                    )
                                    dispatchCount += 1
                                } else if let envelope =
                                    Self.extractEnvelope(from: joined) {
                                    try Self.dispatchEvent(
                                        name: envelope.type,
                                        dataJSON: envelope.dataJSON,
                                        continuation: continuation
                                    )
                                    dispatchCount += 1
                                }
                            }
                            currentEvent = nil
                            dataLines = []
                            continue
                        }

                        if line.hasPrefix("event: ") {
                            currentEvent = String(line.dropFirst(7))
                        } else if line.hasPrefix("event:") {
                            currentEvent = String(line.dropFirst(6))
                        } else if line.hasPrefix("data: ") || line.hasPrefix("data:") {
                            let payload = line.hasPrefix("data: ")
                                ? String(line.dropFirst(6))
                                : String(line.dropFirst(5))
                            dataLines.append(payload)
                            dataLineCount += 1

                            // Eager dispatch: URLSession.AsyncBytes.lines doesn't
                            // reliably yield the empty lines between SSE events,
                            // so we can't depend on an empty-line boundary to
                            // trigger dispatch. If this data: line on its own is
                            // a complete envelope ({"type":"...","data":...}),
                            // dispatch and clear the buffer immediately.
                            if currentEvent == nil,
                               let envelope = Self.extractEnvelope(from: payload) {
                                try Self.dispatchEvent(
                                    name: envelope.type,
                                    dataJSON: envelope.dataJSON,
                                    continuation: continuation
                                )
                                dispatchCount += 1
                                dataLines = []
                            }
                        }
                        // Ignore other SSE fields (id, retry, etc.)
                    }

                    // Flush any event still buffered at end-of-stream (no
                    // trailing empty line). Some senders omit the final \n\n.
                    if !dataLines.isEmpty {
                        let joined = dataLines.joined(separator: "\n")
                        if let event = currentEvent {
                            try Self.dispatchEvent(
                                name: event, dataJSON: joined,
                                continuation: continuation)
                            dispatchCount += 1
                        } else if let envelope =
                            Self.extractEnvelope(from: joined) {
                            try Self.dispatchEvent(
                                name: envelope.type,
                                dataJSON: envelope.dataJSON,
                                continuation: continuation)
                            dispatchCount += 1
                        }
                    }

                    Self.lastDiagnostics = "lines=\(lineCount) data=\(dataLineCount) dispatched=\(dispatchCount) ct=\(contentType.prefix(20))"
                    print("[AnalyzeClient] SSE stream done: \(Self.lastDiagnostics)")

                    continuation.finish()
                } catch is CancellationError {
                    print("[AnalyzeClient] SSE stream cancelled")
                    continuation.finish(throwing: AnalyzeError.cancelled)
                } catch {
                    print("[AnalyzeClient] SSE stream error: \(error)")
                    let mapped = Self.mapStreamError(error)
                    continuation.finish(throwing: mapped)
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Request helpers (PR-15)

    /// Fires a single request, maps URLSession-layer errors to
    /// AnalyzeError, and unwraps the response as HTTPURLResponse.
    /// Used by the initial /analyze call and its 401 retry.
    private func fireRequest(
        _ request: URLRequest
    ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let (bytes, response): (URLSession.AsyncBytes, URLResponse)
        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch {
            throw Self.mapStreamError(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw AnalyzeError.streamParseError(
                detail: "No HTTP response")
        }
        return (bytes, http)
    }

    /// Drains an AsyncBytes stream, swallowing any errors. Used after
    /// a discarded response (the 401 first attempt) so the underlying
    /// connection can be released cleanly before the retry.
    private func drainQuietly(_ bytes: URLSession.AsyncBytes) async throws {
        do {
            for try await _ in bytes { /* discard */ }
        } catch {
            // Intentionally ignored; the response body we're draining
            // is from a request whose status code already told us what
            // we needed to know.
        }
    }

    // MARK: - Multipart body

    private static func makeMultipartBody(
        boundary: String,
        csvData: Data,
        filename: String,
        reportType: String
    ) -> Data {
        var body = Data()
        let crlf = "\r\n"
        let crlfData = crlf.data(using: .utf8)!

        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append(
            ("Content-Disposition: form-data; name=\"file\"; " +
             "filename=\"\(filename)\"\(crlf)").data(using: .utf8)!
        )
        body.append("Content-Type: text/csv\(crlf)\(crlf)"
                    .data(using: .utf8)!)
        body.append(csvData)
        body.append(crlfData)

        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append(
            ("Content-Disposition: form-data; name=\"report_type\"" +
             "\(crlf)\(crlf)").data(using: .utf8)!
        )
        body.append(reportType.data(using: .utf8)!)
        body.append(crlfData)

        body.append("--\(boundary)--\(crlf)".data(using: .utf8)!)
        return body
    }

    // MARK: - Pre-stream error mapping

    private static func throwPreStreamError(
        status: Int, data: Data, response: HTTPURLResponse
    ) throws {
        let payload = try? JSONDecoder().decode(
            PreStreamErrorResponse.self, from: data)
        let message = payload?.error ?? payload?.message

        switch status {
        case 401:
            throw AnalyzeError.unauthenticated
        case 402:
            throw AnalyzeError.paymentRequired
        case 429:
            let retryAfter = response.value(
                forHTTPHeaderField: "Retry-After")
                .flatMap(Double.init)
            throw AnalyzeError.rateLimited(retryAfter: retryAfter)
        case 400:
            throw AnalyzeError.badRequest(
                message: message ?? "Invalid CSV.")
        case 500...599:
            throw AnalyzeError.serverError(message: message)
        default:
            throw AnalyzeError.serverError(
                message: "HTTP \(status): \(message ?? "Unknown")")
        }
    }

    // MARK: - Stream network error mapping

    private static func mapStreamError(_ error: Error) -> AnalyzeError {
        // NSError-level cancel check runs BEFORE the URLError cast.
        // URLSession's streaming layer can hand back a raw NSError code
        // -999 that doesn't auto-bridge cleanly to URLError, which used
        // to fall through to the bottom `streamParseError(detail:
        // "\(error)")` path and dump a 600-char description blob.
        // Only NSURLErrorCancelled (-999) takes this shortcut; every
        // other NSURLDomain code keeps the existing handling below so
        // timeout / unreachable / connection-lost still surface as
        // real errors.
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled {
            return .cancelled
        }
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet, .networkConnectionLost,
                 .cannotConnectToHost, .cannotFindHost:
                return .networkUnreachable
            case .cancelled:
                return .cancelled
            default:
                return .streamParseError(detail: urlError.localizedDescription)
            }
        }
        if let analyzeError = error as? AnalyzeError {
            return analyzeError
        }
        return .streamParseError(detail: "\(error)")
    }

    // MARK: - Envelope unwrap

    /// Backend ships SSE events as `data: {"type":"...","data":...}` without
    /// an `event:` line. This helper peeks at the JSON; if it has a `type`
    /// field, returns the type string and the re-serialized inner `data`
    /// so the rest of the pipeline can treat it like a standard SSE event.
    private static func extractEnvelope(
        from json: String
    ) -> (type: String, dataJSON: String)? {
        guard let data = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data)
                            as? [String: Any],
              let type = obj["type"] as? String
        else {
            return nil
        }
        let inner = obj["data"] ?? [String: Any]()
        guard let innerData = try? JSONSerialization.data(
                withJSONObject: inner,
                options: [.fragmentsAllowed]),
              let innerString = String(data: innerData, encoding: .utf8)
        else {
            return nil
        }
        return (type, innerString)
    }

    // MARK: - SSE event dispatch

    private static func dispatchEvent(
        name: String,
        dataJSON: String,
        continuation: AsyncThrowingStream<AnalyzeEvent, Error>.Continuation
    ) throws {
        guard let data = dataJSON.data(using: .utf8) else {
            throw AnalyzeError.streamParseError(
                detail: "Couldn't encode event data as UTF-8")
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        switch name {
        case "metrics":
            do {
                let dict = try decoder.decode(
                    [String: AnyCodableValue].self, from: data)
                continuation.yield(.metrics(dict))
            } catch {
                throw AnalyzeError.streamParseError(
                    detail: "metrics decode: \(error)")
            }

        case "report_started":
            struct ReportStartedPayload: Decodable {
                let reportId: String
            }
            do {
                let payload = try decoder.decode(
                    ReportStartedPayload.self, from: data)
                #if DEBUG
                print("[AnalyzeClient] report_started received: \(payload.reportId)")
                #endif
                continuation.yield(
                    .reportStarted(reportId: payload.reportId))
            } catch {
                throw AnalyzeError.streamParseError(
                    detail: "report_started decode: \(error)")
            }

        case "complete":
            var wrappedErr: Error?
            do {
                let wrapped = try decoder.decode(
                    WrappedReportPayload.self, from: data)
                continuation.yield(.complete(
                    wrapped.report.reportJson,
                    reportId: wrapped.report.id,
                    reportType: wrapped.report.reportType,
                    betCount: wrapped.report.betCountAnalyzed,
                    dateRange: (wrapped.report.dateRangeStart,
                                wrapped.report.dateRangeEnd),
                    createdAt: wrapped.report.createdAt
                                ?? ISO8601DateFormatter().string(from: Date())
                ))
                return
            } catch {
                wrappedErr = error
                print("[AnalyzeClient] WrappedReportPayload decode failed: \(error)")
            }
            do {
                let direct = try decoder.decode(
                    DirectPayload.self, from: data)
                continuation.yield(.complete(
                    direct.analysis,
                    reportId: nil,
                    reportType: direct.reportType,
                    betCount: direct.betCountAnalyzed,
                    dateRange: (direct.dateRangeStart,
                                direct.dateRangeEnd),
                    createdAt: direct.createdAt
                ))
            } catch {
                throw AnalyzeError.streamParseError(
                    detail: "wrapped: \(wrappedErr.map { "\($0)" } ?? "nil"). direct: \(error)")
            }

        case "error":
            let payload = try? decoder.decode(
                PreStreamErrorResponse.self, from: data)
            let message = payload?.message ?? payload?.error
                          ?? "Unknown stream error"
            continuation.yield(.error(message))

        default:
            // Unknown event type — ignore for forward compatibility.
            break
        }
    }
}
