//
//  UploadFlowCoordinator.swift
//  BetAutopsy
//
//  @Observable state machine for the upload + analyze flow. Owns the
//  AnalyzeClient instance, tracks streaming state, and produces an
//  AutopsyReport on success.
//

import Foundation
import Observation

@Observable
final class UploadFlowCoordinator {
    enum State {
        case idle
        case picking
        case uploading                          // request sent, no events yet
        case streaming(metricsReceived: Bool)   // events arriving
        case succeeded(AutopsyReport)
        case failed(AnalyzeError)
    }

    var state: State = .idle
    private let client = AnalyzeClient()
    private var currentTask: Task<Void, Never>?

    func startUpload(csvData: Data, filename: String,
                     reportType: String = "snapshot") {
        // Cancel any in-flight task.
        currentTask?.cancel()
        currentTask = nil

        state = .uploading

        currentTask = Task { @MainActor in
            do {
                let stream = try await client.analyze(
                    csvData: csvData,
                    filename: filename,
                    reportType: reportType
                )

                var metricsReceived = false

                for try await event in stream {
                    if Task.isCancelled {
                        state = .failed(.cancelled)
                        return
                    }

                    switch event {
                    case .metrics:
                        metricsReceived = true
                        state = .streaming(metricsReceived: true)

                    case .complete(let analysis, let reportType,
                                   let bets, let dateRange,
                                   let createdAt):
                        let report = AutopsyReport(
                            id: UUID().uuidString,
                            caseNumber: Self.generateCaseNumber(),
                            reportType: reportType,
                            betCountAnalyzed: bets,
                            dateRangeStart: dateRange.0,
                            dateRangeEnd: dateRange.1,
                            createdAt: createdAt,
                            analysis: analysis
                        )
                        state = .succeeded(report)
                        return

                    case .error(let message):
                        state = .failed(.streamError(message: message))
                        return
                    }

                    if !metricsReceived {
                        state = .streaming(metricsReceived: false)
                    }
                }

                // Stream ended without .complete.
                if case .succeeded = state { return }
                state = .failed(.streamParseError(
                    detail: "Stream ended. \(AnalyzeClient.lastDiagnostics)"))

            } catch let e as AnalyzeError {
                // User-initiated cancellation (e.g. dragged the progress
                // sheet down mid-stream) bubbles up as AnalyzeError.cancelled
                // via AnalyzeClient.mapStreamError. Reset state silently —
                // they know they canceled; no error UI flash.
                if case .cancelled = e {
                    state = .idle
                    return
                }
                state = .failed(e)
            } catch let urlError as URLError where urlError.code == .cancelled {
                // Cancellation that bypassed AnalyzeClient's mapping (e.g.
                // session.bytes(for:) throws before the stream Task is
                // even constructed). Same silent-dismiss treatment.
                state = .idle
            } catch is CancellationError {
                // Swift Task cancellation. Same path.
                state = .idle
            } catch {
                state = .failed(.streamParseError(detail: "\(error)"))
            }
        }
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
    }

    func dismiss() {
        currentTask?.cancel()
        currentTask = nil
        state = .idle
    }

    // MARK: - Case number generation

    private static var caseCounter: Int = 247  // Continue past mock 0247.

    private static func generateCaseNumber() -> String {
        caseCounter += 1
        return String(format: "%04d", caseCounter)
    }
}
