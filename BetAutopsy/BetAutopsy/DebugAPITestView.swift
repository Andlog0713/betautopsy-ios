//
//  DebugAPITestView.swift
//  BetAutopsy
//
//  DEBUG-only manual harness for AnalyzeClient. Lets Andrew verify the
//  network/SSE plumbing before the full upload UI ships in Phase 2.
//  Hidden in Release builds via #if DEBUG.
//

#if DEBUG
import SwiftUI

struct DebugAPITestView: View {
    @State private var status = "Ready"
    @State private var eventCount = 0
    @State private var lastEvent: String = "—"
    @State private var error: String?

    private let client = AnalyzeClient()

    /// Five-row test CSV. Adjust columns if backend rejects.
    private let testCSV = """
    date,sport,wager_type,stake,odds,result
    2026-04-01,NBA,spread,50,-110,won
    2026-04-02,NFL,moneyline,75,+150,lost
    2026-04-03,MLB,total,25,-105,won
    2026-04-04,NBA,player_prop,40,-120,lost
    2026-04-05,NHL,moneyline,30,+200,push
    """

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()
            VStack(spacing: DS.Spacing.lg) {
                Text("API TEST")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.18)
                    .foregroundStyle(DS.Color.Text.tertiary)

                Text("Status: \(status)")
                    .font(.custom("JetBrainsMono-Regular", size: 14))
                    .foregroundStyle(DS.Color.Text.primary)

                Text("Events received: \(eventCount)")
                    .font(.custom("JetBrainsMono-Regular", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Text.secondary)

                Text("Last: \(lastEvent)")
                    .font(.custom("JetBrainsMono-Regular", size: 12))
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .lineLimit(3)

                if let error = error {
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.Semantic.blood)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DS.Spacing.md)
                }

                Button(action: runTest) {
                    Text("Run test request")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Color.Text.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(DS.Color.Accent.luminol)
                        .clipShape(RoundedRectangle(
                            cornerRadius: DS.Radius.card))
                }
                .padding(.horizontal, DS.Spacing.lg)
            }
            .padding()
        }
    }

    private func runTest() {
        status = "Sending..."
        eventCount = 0
        lastEvent = "—"
        error = nil

        Task {
            do {
                let stream = try await client.analyze(
                    csvData: Data(testCSV.utf8),
                    filename: "test.csv",
                    reportType: "snapshot"
                )
                for try await event in stream {
                    await MainActor.run {
                        eventCount += 1
                        switch event {
                        case .metrics:
                            lastEvent = "metrics"
                            status = "Got metrics"
                        case .complete(_, let reportType, let bets, _, _):
                            lastEvent = "complete (\(reportType), \(bets) bets)"
                            status = "Done"
                        case .error(let msg):
                            lastEvent = "error: \(msg)"
                            error = msg
                        }
                    }
                }
                await MainActor.run { status = "Stream ended" }
            } catch let e as AnalyzeError {
                await MainActor.run {
                    error = e.errorDescription
                    status = "Failed"
                }
            } catch {
                await MainActor.run {
                    self.error = "\(error)"
                    status = "Failed"
                }
            }
        }
    }
}

#Preview {
    DebugAPITestView()
        .preferredColorScheme(.dark)
}
#endif
