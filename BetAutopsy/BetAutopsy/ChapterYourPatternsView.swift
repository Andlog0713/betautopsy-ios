//
//  ChapterYourPatternsView.swift
//  BetAutopsy
//
//  Chapter 5: The Patterns.
//
//  Layout (top-to-bottom):
//      ChapterNavigator (no hero ring)
//      ->  3-5 PatternCards: Biggest Loss, Worst Day, Worst Hour,
//          Longest Skid, Biggest Win. Computed client-side from
//          sessionDetection.sessions + timingAnalysis aggregates.
//      ->  InsightCallout (or fallback string if no patterns computed)
//
//  Engine doesn't ship a per-bet timeline; pattern extremes come from
//  session-level data and pre-aggregated hourly/daily buckets. Skip
//  silently when a pattern can't be computed. Do not fabricate.
//

import SwiftUI

struct ChapterYourPatternsView: View {
    let report: AutopsyReport

    /// Programmatic chapter advance used by the "SEE THE SPORT BREAKDOWN"
    /// CTA. Wired from ReportView at TabView construction time. Default
    /// no-op preserves preview / standalone usage.
    var onAdvance: () -> Void = {}

    @State private var showingPaywall: Bool = false

    private var heroContradiction: Contradiction? {
        report.analysis.contradictions?.first
    }

    private var sessions: [DetectedSession] {
        report.analysis.sessionDetection?.sessions ?? []
    }

    private var byHour: [TimingBucket] {
        report.analysis.timingAnalysis?.byHour ?? []
    }

    private var byDay: [TimingBucket] {
        report.analysis.timingAnalysis?.byDay ?? []
    }

    private var patternCards: [PatternCard.Pattern] {
        var result: [PatternCard.Pattern] = []

        // BIGGEST LOSS (session-level extreme; closest available proxy
        // for the per-bet biggest-loss the engine doesn't surface).
        if let worst = sessions.filter({ $0.profit < 0 })
                                .min(by: { $0.profit < $1.profit }) {
            result.append(PatternCard.Pattern(
                title: "BIGGEST LOSS",
                bigNumber: signedDollar(Int(worst.profit.rounded())),
                bigNumberColor: DS.Color.V3.Severity.red,
                namedEntity: worst.date,
                supportingLine: "\(worst.bets) bets in a \(worst.durationMinutes)-minute session."
            ))
        }

        // WORST DAY (pre-aggregated)
        if let worstDay = byDay.filter({ $0.profit < 0 })
                                .min(by: { $0.profit < $1.profit }) {
            result.append(PatternCard.Pattern(
                title: "WORST DAY",
                bigNumber: signedDollar(Int(worstDay.profit.rounded())),
                bigNumberColor: DS.Color.V3.Severity.red,
                namedEntity: dayLabel(worstDay.label),
                supportingLine: "\(worstDay.bets) bets, \(formatPct(worstDay.roi, signed: true, decimals: 1)) ROI."
            ))
        }

        // WORST HOUR (pre-aggregated)
        if let worstHour = byHour.filter({ $0.profit < 0 })
                                  .min(by: { $0.profit < $1.profit }) {
            result.append(PatternCard.Pattern(
                title: "WORST HOUR",
                bigNumber: signedDollar(Int(worstHour.profit.rounded())),
                bigNumberColor: DS.Color.V3.Severity.red,
                namedEntity: hourLabel(worstHour.label),
                supportingLine: "\(worstHour.bets) bets, \(formatPct(worstHour.roi, signed: true, decimals: 1)) ROI."
            ))
        }

        // LONGEST SKID (consecutive negative sessions, parsed-date order)
        if let skid = longestSkid() {
            result.append(skid)
        }

        // BIGGEST WIN
        if let best = sessions.filter({ $0.profit > 0 })
                               .max(by: { $0.profit < $1.profit }) {
            result.append(PatternCard.Pattern(
                title: "BIGGEST WIN",
                bigNumber: signedDollar(Int(best.profit.rounded())),
                bigNumberColor: DS.Color.V3.textPrimary,
                namedEntity: best.date,
                supportingLine: "\(best.bets) bets, \(formatPct(best.roi, signed: true, decimals: 1)) ROI."
            ))
        }

        return result
    }

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var wirePatterns: [BehavioralPattern] {
        Array(report.analysis.behavioralPatterns.prefix(2))
    }

    private var patternCount: Int {
        report.analysis.snapshotCounts?.patterns
            ?? report.analysis.behavioralPatterns.count
    }

    private var hasAnyPatterns: Bool {
        !patternCards.isEmpty || !wirePatterns.isEmpty
    }

    private var fallbackText: String {
        if patternCount > 0 {
            return "You've got \(patternCount) detected behavioral patterns. The full report names them and shows what they cost you."
        }
        return "Pattern analysis lives in the full report. Unlock to see your detected patterns and what they cost you."
    }

    private var insightBody: String {
        if !hasAnyPatterns {
            return fallbackText
        }
        let exec = (report.analysis.executiveDiagnosis ?? "").firstSentences(2)
        return exec.isEmpty ? fallbackText : exec
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ChapterNavigator(chapterNumber: 5, subtitle: "THE PATTERNS")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                if let contradiction = heroContradiction {
                    Spacer().frame(height: 24)
                    ContradictionCard(
                        contradiction: contradiction,
                        isLockedCost: isSnapshot,
                        onLockedTap: handleContradictionLockedTap
                    )
                    .padding(.horizontal, 16)
                }

                // Snapshot path: prefer wire-shipped behavioral_patterns
                // (engine V2 scrubs dollars in description, render as-is).
                // Full path: fall back to client-computed patternCards from
                // sessions + timing aggregates when behavioral_patterns is
                // empty, which preserves the rich full-report cadence.
                if isSnapshot && !wirePatterns.isEmpty {
                    Spacer().frame(height: 24)
                    VStack(spacing: 12) {
                        ForEach(wirePatterns) { p in
                            wirePatternCard(p)
                        }
                    }
                    .padding(.horizontal, 16)
                } else if !patternCards.isEmpty {
                    Spacer().frame(height: 24)
                    VStack(spacing: 12) {
                        ForEach(patternCards) { p in
                            PatternCard(pattern: p)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if !insightBody.isEmpty {
                    Spacer().frame(height: 24)
                    InsightCallout(
                        text: insightBody,
                        ctaLabel: "SEE THE SPORT BREAKDOWN",
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

    private func handleContradictionLockedTap() {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": "ch5_contradiction_locked"]
        )
        showingPaywall = true
    }

    @ViewBuilder
    private func wirePatternCard(_ pattern: BehavioralPattern) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pattern.patternName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(pattern.description)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .lineSpacing(3)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(pattern.patternName). \(pattern.description)")
    }

    // MARK: - Pattern computations

    /// Walk sessions in chronological order (parsed dates). Count the
    /// longest run of consecutive negative-profit sessions. Skip
    /// silently if dates can't be parsed or the longest run is < 2.
    private func longestSkid() -> PatternCard.Pattern? {
        let parsed: [(date: Date, session: DetectedSession)] = sessions.compactMap {
            guard let date = parseSessionDate($0.date) else { return nil }
            return (date, $0)
        }.sorted { $0.date < $1.date }

        guard parsed.count >= 2 else { return nil }

        var bestRun = 0
        var bestStart: Date?
        var bestEnd: Date?
        var currentRun = 0
        var currentStart: Date?
        var currentEnd: Date?

        for entry in parsed {
            if entry.session.profit < 0 {
                if currentRun == 0 { currentStart = entry.date }
                currentEnd = entry.date
                currentRun += 1
                if currentRun > bestRun {
                    bestRun = currentRun
                    bestStart = currentStart
                    bestEnd = currentEnd
                }
            } else {
                currentRun = 0
                currentStart = nil
                currentEnd = nil
            }
        }

        guard bestRun >= 2, let start = bestStart, let end = bestEnd else {
            return nil
        }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MMM d"
        let range = "\(dateFormatter.string(from: start)) to \(dateFormatter.string(from: end))"

        return PatternCard.Pattern(
            title: "LONGEST SKID",
            bigNumber: "\(bestRun) STRAIGHT",
            bigNumberColor: DS.Color.V3.textPrimary,
            namedEntity: range,
            supportingLine: "Consecutive losing sessions."
        )
    }

    private func parseSessionDate(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let formats = ["MMM d, yyyy", "MMMM d, yyyy", "yyyy-MM-dd"]
        for fmt in formats {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = fmt
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    private func signedDollar(_ value: Int) -> String {
        let absVal = abs(value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formatted = formatter.string(from: NSNumber(value: absVal)) ?? "\(absVal)"
        let sign = value < 0 ? "-" : (value > 0 ? "+" : "")
        return "\(sign)$\(formatted)"
    }

    /// Friendly day label from engine's short code ("SUN" -> "Sundays").
    private func dayLabel(_ raw: String) -> String {
        let map: [String: String] = [
            "MON": "Mondays",  "TUE": "Tuesdays", "WED": "Wednesdays",
            "THU": "Thursdays","FRI": "Fridays",  "SAT": "Saturdays",
            "SUN": "Sundays"
        ]
        if let label = map[raw.uppercased()] { return label }
        return raw
    }

    /// Friendly hour label from engine's hour-of-day integer string.
    private func hourLabel(_ raw: String) -> String {
        guard let hour = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return raw
        }
        switch hour {
        case 0: return "Midnight to 1am"
        case 1...4: return "Around \(hour)am"
        case 5...11: return "Early morning (\(hour)am)"
        case 12: return "Noon hour"
        case 13...17: return "Afternoon (\(hour - 12)pm)"
        case 18...20: return "Evening (\(hour - 12)pm)"
        case 21: return "After 9pm"
        case 22: return "After 10pm"
        case 23: return "After 11pm"
        default: return raw
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

    private func handleInsightTap() {
        onAdvance()
    }
}

#Preview {
    ChapterYourPatternsView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
