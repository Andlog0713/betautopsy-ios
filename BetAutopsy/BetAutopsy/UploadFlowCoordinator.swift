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

    /// Tracks whether the in-flight upload was aborted by the user (Cancel
    /// button) vs failed organically. URLSession.bytes(for:) sometimes
    /// closes its stream gracefully on task cancellation rather than
    /// throwing URLError.cancelled — when that happens, the for-await
    /// loop completes normally and the "Stream ended without complete"
    /// path fires, which previously surfaced the PR-4 diagnostic dump as
    /// a "Try again" error. This flag distinguishes "user wanted out"
    /// from "actual stream failure" regardless of how cancellation
    /// propagates through URLSession.
    private var userInitiatedCancel: Bool = false

    func startUpload(csvData: Data, filename: String,
                     reportType: String = "snapshot") {
        // Cancel any in-flight task.
        currentTask?.cancel()
        currentTask = nil

        // Reset the cancel flag on every fresh upload.
        userInitiatedCancel = false

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
                        // Cancellation noticed mid-iteration. Treat as
                        // user-initiated (only path that cancels the task).
                        state = .idle
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

                // Stream ended without .complete. User-initiated cancel
                // beats the diagnostic-surface path — they don't need to
                // see "Stream ended. lines=… data=… dispatched=…" when
                // they themselves chose to stop.
                if case .succeeded = state { return }
                if userInitiatedCancel {
                    state = .idle
                    return
                }
                state = .failed(.streamParseError(
                    detail: "Stream ended. \(AnalyzeClient.lastDiagnostics)"))

            } catch let e as AnalyzeError {
                if userInitiatedCancel { state = .idle; return }
                if case .cancelled = e {
                    state = .idle
                    return
                }
                state = .failed(e)
            } catch let urlError as URLError where urlError.code == .cancelled {
                state = .idle
            } catch is CancellationError {
                state = .idle
            } catch {
                if userInitiatedCancel { state = .idle; return }
                state = .failed(.streamParseError(detail: "\(error)"))
            }
        }
    }

    func cancel() {
        // Flag MUST be set before cancelling the task. The task's catch
        // path reads the flag synchronously when cancellation propagates,
        // and we want it to see true regardless of how URLSession
        // surfaces the cancel (throw vs graceful close).
        userInitiatedCancel = true
        currentTask?.cancel()
        currentTask = nil
        state = .idle
    }

    func dismiss() {
        userInitiatedCancel = true
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
