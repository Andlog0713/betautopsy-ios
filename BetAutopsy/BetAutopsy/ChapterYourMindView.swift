//
//  ChapterYourMindView.swift
//  BetAutopsy
//
//  Chapter 2: The Heated File.
//
//  Layout (top-to-bottom):
//      ChapterNavigator  ->  HeroRingView (Emotion, higherIsWorse: true)
//
//      Snapshot mode:
//          ->  "X of Y sessions flagged as heated" summary line
//          ->  HeatedSessionPreviewCard (single, with LockedDollarBar)
//          ->  InsightCallout, CTA "UNLOCK THE DOLLAR DAMAGE"
//
//      Full mode:
//          ->  "TOP HEATED SESSIONS - N TOTAL" header
//          ->  Up to 3 TiltSessionCards with signed P&L
//          ->  InsightCallout, CTA "READ THE DISCIPLINE AUDIT"
//
//  Brand rule: "tilt" never appears in product UI. The component type
//  name TiltSessionCard is unchanged (internal identifier); user-visible
//  copy reads "heated" only.
//

import SwiftUI

struct ChapterYourMindView: View {
    let report: AutopsyReport

    @State private var showingPaywall: Bool = false

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var emotionScore: Int {
        report.analysis.emotionScore
    }

    private var heatedSessions: [DetectedSession] {
        (report.analysis.sessionDetection?.sessions ?? [])
            .filter { $0.isHeated }
    }

    private var totalHeatedCount: Int {
        report.analysis.sessionDetection?.heatedSessionCount
            ?? heatedSessions.count
    }

    private var totalSessionCount: Int {
        report.analysis.sessionDetection?.totalSessions
            ?? (report.analysis.sessionDetection?.sessions.count ?? heatedSessions.count)
    }

    private var topHeatedSessions: [TiltSessionCard.Session] {
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
                    timeRangeLabel: usableTimeRange(
                        start: session.startTime,
                        end: session.endTime
                    ),
                    pnl: Int(session.profit.rounded()),
                    betCount: session.bets,
                    triggerLabel: trigger,
                    behavioralSignal: secondarySignal,
                    triggerEvent: session.triggerEvent
                )
            }
    }

    /// First heated session that carries at least one heatSignal,
    /// falling back to the first heated session if none carry signals.
    private var previewSession: HeatedSessionPreviewCard.Session? {
        let withSignals = heatedSessions.first { !$0.heatSignals.isEmpty }
        let source = withSignals ?? heatedSessions.first
        guard let s = source else { return nil }
        return HeatedSessionPreviewCard.Session(
            grade: s.grade,
            dateLabel: previewDateLabel(date: s.date, dayOfWeek: s.dayOfWeek, startTime: s.startTime),
            betCount: s.bets,
            heatSignals: Array(s.heatSignals.prefix(3)),
            triggerEvent: s.triggerEvent
        )
    }

    private func hasAnySignal(_ signals: TiltSignals) -> Bool {
        signals.betSizingVolatility > 0
            || signals.lossReaction > 0
            || signals.streakBehavior > 0
            || signals.sessionDiscipline > 0
            || signals.sessionAcceleration > 0
            || signals.oddsDriftAfterLoss > 0
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
                ChapterNavigator(chapterNumber: 2, subtitle: "THE HEATED FILE")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer().frame(height: 28)

                HeroRingView(
                    score: emotionScore,
                    metricLabel: "EMOTION",
                    higherIsWorse: true
                )

                if isSnapshot {
                    snapshotHeatedSection
                } else {
                    fullHeatedSection
                }

                if let signals = report.analysis.enhancedTilt?.signals,
                   hasAnySignal(signals) {
                    Spacer().frame(height: 24)
                    TiltSignalBreakdownCard(
                        signals: signals,
                        worstTrigger: report.analysis.enhancedTilt?.worstTrigger
                    )
                    .padding(.horizontal, 16)
                }

                if !insightBody.isEmpty {
                    Spacer().frame(height: 24)

                    InsightCallout(
                        text: insightBody,
                        ctaLabel: isSnapshot
                            ? "UNLOCK THE DOLLAR DAMAGE"
                            : "READ THE DISCIPLINE AUDIT",
                        onTap: handleInsightTap
                    )
                    .padding(.horizontal, 16)
                }

                Spacer().frame(height: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .background(canvasGradient.ignoresSafeArea())
        .sheet(isPresented: $showingPaywall) {
            PaywallView(snapshotReportId: report.id)
        }
    }

    @ViewBuilder
    private var snapshotHeatedSection: some View {
        if let preview = previewSession {
            Spacer().frame(height: 28)

            Text("\(totalHeatedCount) of \(totalSessionCount) sessions flagged as heated.")
                .font(DS.Font.V3.navigatorSubtitle)
                .tracking(1.8)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            Spacer().frame(height: 8)

            HeatedSessionPreviewCard(
                session: preview,
                onLockedTap: showPaywall
            )
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var fullHeatedSection: some View {
        if !topHeatedSessions.isEmpty {
            Spacer().frame(height: 28)

            Text("TOP HEATED SESSIONS \u{00B7} \(totalHeatedCount) TOTAL")
                .font(DS.Font.V3.navigatorSubtitle)
                .tracking(1.8)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            Spacer().frame(height: 8)

            VStack(spacing: 8) {
                ForEach(topHeatedSessions) { session in
                    TiltSessionCard(session: session)
                }
            }
            .padding(.horizontal, 16)
        }
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

    private func showPaywall() {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": "ch2_heated_session_card"]
        )
        showingPaywall = true
    }

    private func handleInsightTap() {
        if isSnapshot {
            Analytics.signal(
                "paywall.triggered",
                parameters: ["source": "ch2_insight_cta"]
            )
            showingPaywall = true
        } else {
            #if DEBUG
            print("InsightCallout tapped on Chapter 2 (V1 stub).")
            #endif
        }
    }

    /// Suppress the time-range row when the engine's session start and
    /// end both fall back to "12:00 AM" - that's the symptom of a
    /// date-only CSV that has no per-bet timestamps. The proper fix is
    /// a backend nullable/sentinel + hasTimeData flag; this iOS-side
    /// guard prevents the misleading "12:00 AM - 12:00 AM" rendering
    /// in the meantime.
    private func usableTimeRange(start: String, end: String) -> String {
        let s = start.trimmingCharacters(in: .whitespacesAndNewlines)
        let e = end.trimmingCharacters(in: .whitespacesAndNewlines)
        if s == "12:00 AM" && e == "12:00 AM" {
            return ""
        }
        return "\(start) - \(end)"
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

    /// Format like "WED DEC 3 - 11:14 PM" for the heated preview card.
    /// Falls back to uppercased raw values when parsing fails.
    private func previewDateLabel(date: String, dayOfWeek: String, startTime: String) -> String {
        let dow = dayOfWeek.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let dateShort = shortDateLabel(date)
        let time = startTime.trimmingCharacters(in: .whitespacesAndNewlines)
        let leftSide: String
        if dow.isEmpty {
            leftSide = dateShort
        } else if dateShort.isEmpty {
            leftSide = dow
        } else {
            leftSide = "\(dow) \(dateShort)"
        }
        if time.isEmpty || time == "12:00 AM" {
            return leftSide
        }
        return "\(leftSide) \u{00B7} \(time)"
    }
}

#Preview {
    ChapterYourMindView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
