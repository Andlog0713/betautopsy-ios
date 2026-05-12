//
//  ChapterYourMindView.swift
//  BetAutopsy
//
//  Chapter 2: The Tilt File.
//
//  Layout (top-to-bottom):
//      ChapterNavigator  ->  HeroRingView (Emotion, higherIsWorse: true)
//      ->  TOP TILT SESSIONS list (up to 3 heated sessions)
//      ->  InsightCallout (worst trigger / executive diagnosis fallback)
//
//  Tilt predicate: session.isHeated == true.
//  Total count for header: sessionDetection.heatedSessionCount when
//  available, else filtered array count.
//

import SwiftUI

struct ChapterYourMindView: View {
    let report: AutopsyReport

    private var emotionScore: Int {
        report.analysis.emotionScore
    }

    private var heatedSessions: [DetectedSession] {
        (report.analysis.sessionDetection?.sessions ?? [])
            .filter { $0.isHeated }
    }

    private var totalTiltSessionCount: Int {
        report.analysis.sessionDetection?.heatedSessionCount
            ?? heatedSessions.count
    }

    private var topTiltSessions: [TiltSessionCard.Session] {
        heatedSessions
            .sorted { abs($0.profit) > abs($1.profit) }
            .prefix(3)
            .map { session in
                let trigger = session.heatSignals.first
                let secondarySignal: String?
                if session.heatSignals.count > 1 {
                    secondarySignal = session.heatSignals[1]
                } else {
                    secondarySignal = session.gradeReasons.first
                }
                return TiltSessionCard.Session(
                    dateLabel: shortDateLabel(session.date),
                    timeRangeLabel: "\(session.startTime) - \(session.endTime)",
                    pnl: Int(session.profit.rounded()),
                    betCount: session.bets,
                    triggerLabel: trigger,
                    behavioralSignal: secondarySignal
                )
            }
    }

    private var insightBody: String {
        if let trigger = report.analysis.enhancedTilt?.worstTrigger
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !trigger.isEmpty {
            return trigger
        }
        let exec = report.analysis.executiveDiagnosis ?? ""
        return exec.firstSentences(2)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ChapterNavigator(chapterNumber: 2, subtitle: "THE TILT FILE")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer().frame(height: 28)

                HeroRingView(
                    score: emotionScore,
                    metricLabel: "EMOTION",
                    higherIsWorse: true
                )

                if !topTiltSessions.isEmpty {
                    Spacer().frame(height: 28)

                    Text("TOP TILT SESSIONS \u{00B7} \(totalTiltSessionCount) TOTAL")
                        .font(DS.Font.V3.navigatorSubtitle)
                        .tracking(1.8)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)

                    Spacer().frame(height: 8)

                    VStack(spacing: 8) {
                        ForEach(topTiltSessions) { session in
                            TiltSessionCard(session: session)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if !insightBody.isEmpty {
                    Spacer().frame(height: 24)

                    InsightCallout(
                        text: insightBody,
                        ctaLabel: "READ THE DISCIPLINE AUDIT",
                        onTap: handleInsightTap
                    )
                    .padding(.horizontal, 16)
                }

                Spacer().frame(height: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .background(canvasGradient.ignoresSafeArea())
    }

    private var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                DS.Color.V3.canvasGradientStart,
                DS.Color.V3.canvasGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func handleInsightTap() {
        #if DEBUG
        print("InsightCallout tapped on Chapter 2 (V1 stub).")
        #endif
    }

    /// Best-effort short date label from the engine's date string.
    /// Input may be "Dec 3, 2025" or similar; falls back to the raw
    /// uppercased string if parsing fails.
    private func shortDateLabel(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsers: [String] = [
            "MMM d, yyyy",
            "MMMM d, yyyy",
            "yyyy-MM-dd"
        ]
        for fmt in parsers {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = fmt
            if let date = formatter.date(from: trimmed) {
                let out = DateFormatter()
                out.locale = Locale(identifier: "en_US_POSIX")
                out.dateFormat = "MMM d"
                return out.string(from: date).uppercased()
            }
        }
        return trimmed.uppercased()
    }
}

#Preview {
    ChapterYourMindView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
