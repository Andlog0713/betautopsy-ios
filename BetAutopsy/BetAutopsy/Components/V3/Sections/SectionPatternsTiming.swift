//
//  SectionPatternsTiming.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2: single-scroll section combining ChapterYourPatternsView
//  (Ch5, "The Patterns") with the TIMING half of ChapterYourSportsView
//  (Ch6 BY HOUR chart + BY DAY tiles + late-night insight). Order: pattern
//  cards, then ContradictionCard (top 1 snapshot / top 3 full, AFTER the
//  cards per the Phase 1 spec), then the patterns insight prose, then the
//  timing charts.
//
//  Strips ScrollView / ChapterNavigator / canvas background / PaywallView
//  sheet. The patterns "SEE THE SPORT BREAKDOWN" CTA was a pure chapter
//  advance (no paywall) and is now prose-only.
//
//  Gate preserved: D6 (BY HOUR ROI bars stay; no dollar tooltip surface).
//
//  Copy note: the snapshot fallback string previously read "Unlock to see
//  your detected patterns..." ("Unlock" is banned, COPY_SYSTEM §2.1).
//  Restructured to drop the gate verb (the string now lands in new code).
//

import SwiftUI
import Charts

struct SectionPatternsTiming: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    // MARK: - Patterns data

    private var contradictions: [Contradiction] {
        let all = report.analysis.contradictions ?? []
        return Array(all.prefix(isSnapshot ? 1 : 3))
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

        if let worst = sessions.filter({ $0.profit < 0 })
                                .min(by: { $0.profit < $1.profit }) {
            result.append(PatternCard.Pattern(
                title: "BIGGEST LOSS",
                bigNumber: BAFormat.currency(worst.profit, signed: true),
                bigNumberColor: DS.Color.V3.Severity.red,
                namedEntity: worst.date,
                supportingLine: "\(BAFormat.sampleSize(worst.bets)) in a \(worst.durationMinutes)-minute session."
            ))
        }

        if let worstDay = byDay.filter({ $0.profit < 0 })
                                .min(by: { $0.profit < $1.profit }) {
            result.append(PatternCard.Pattern(
                title: "WORST DAY",
                bigNumber: BAFormat.currency(worstDay.profit, signed: true),
                bigNumberColor: DS.Color.V3.Severity.red,
                namedEntity: singularizedEntityLabel(dayLabel(worstDay.label), betCount: worstDay.bets),
                supportingLine: roiSupportingLine(bets: worstDay.bets, roi: worstDay.roi, winRate: worstDay.winRate)
            ))
        }

        if let worstHour = byHour.filter({ $0.profit < 0 })
                                  .min(by: { $0.profit < $1.profit }) {
            result.append(PatternCard.Pattern(
                title: "WORST HOUR",
                bigNumber: BAFormat.currency(worstHour.profit, signed: true),
                bigNumberColor: DS.Color.V3.Severity.red,
                namedEntity: hourEntityLabel(worstHour.label),
                supportingLine: roiSupportingLine(bets: worstHour.bets, roi: worstHour.roi, winRate: worstHour.winRate)
            ))
        }

        if let skid = longestSkid() {
            result.append(skid)
        }

        if let best = sessions.filter({ $0.profit > 0 })
                               .max(by: { $0.profit < $1.profit }) {
            let winRate = best.bets > 0 ? Double(best.wins) / Double(best.bets) * 100 : 0
            result.append(PatternCard.Pattern(
                title: "BIGGEST WIN",
                bigNumber: BAFormat.currency(best.profit, signed: true),
                bigNumberColor: DS.Color.V3.textPrimary,
                namedEntity: best.date,
                supportingLine: roiSupportingLine(bets: best.bets, roi: best.roi, winRate: winRate)
            ))
        }

        return result
    }

    /// Supporting line under a dollar big-number. ROI display is capped:
    /// tiny-stake outliers produce four-digit ROIs ("+1,411.1%") that
    /// read as broken, so past the cap the line shows win rate instead
    /// (the dollar figure is already the card's big number).
    private func roiSupportingLine(bets: Int, roi: Double, winRate: Double?) -> String {
        if abs(roi) >= BAFormat.roiDisplayCap {
            if let winRate {
                return "\(BAFormat.sampleSize(bets)), \(BAFormat.percent(winRate, headline: true)) win rate."
            }
            return "\(BAFormat.sampleSize(bets))."
        }
        return "\(BAFormat.sampleSize(bets)), \(BAFormat.percent(roi, signed: true)) ROI."
    }

    private var snapshotPatternCards: [PatternCard.Pattern] {
        (report.analysis.patternsSnapshot ?? []).map { entry in
            let title = snapshotTitle(entry.kind)
            let entity = singularizedEntityLabel(entry.entityLabel, betCount: entry.betCount)
            if entry.kind == "longest_skid" {
                return PatternCard.Pattern(
                    title: title,
                    bigNumber: "\(entry.betCount) STRAIGHT",
                    bigNumberColor: DS.Color.V3.textPrimary,
                    namedEntity: entity,
                    supportingLine: skidSupportingLine(entry)
                )
            }
            let isWin = entry.kind == "biggest_win"
            let color = isWin ? DS.Color.V3.textPrimary : DS.Color.V3.Severity.red
            // Lock the Biggest Win dollar in snapshot too. The engine marks
            // biggest_win visible, but leaving it the lone unredacted dollar
            // next to a locked Biggest Loss is an asymmetric leak; the paid
            // report still shows it (full path, patternCards, always visible).
            let locked = isWin || entry.dollarVisibility == "redacted_dollar" || entry.dollarValue == nil
            if locked {
                return PatternCard.Pattern(
                    title: title,
                    bigNumber: "",
                    bigNumberColor: color,
                    namedEntity: entity,
                    supportingLine: snapshotSupportingLine(entry),
                    isLockedDollar: true,
                    onLockedTap: { onPaywallTap("section_patterns_timing_pattern_locked") }
                )
            }
            return PatternCard.Pattern(
                title: title,
                bigNumber: BAFormat.currency(entry.dollarValue ?? 0, signed: true),
                bigNumberColor: color,
                namedEntity: entity,
                supportingLine: snapshotSupportingLine(entry)
            )
        }
    }

    private static let weekdayPlurals: Set<String> = [
        "Mondays", "Tuesdays", "Wednesdays", "Thursdays",
        "Fridays", "Saturdays", "Sundays"
    ]

    private func singularizedEntityLabel(_ label: String, betCount: Int) -> String {
        guard betCount == 1, Self.weekdayPlurals.contains(label) else { return label }
        return String(label.dropLast())
    }

    private func snapshotTitle(_ kind: String) -> String {
        switch kind {
        case "biggest_loss": return "BIGGEST LOSS"
        case "worst_day":    return "WORST DAY"
        case "worst_hour":   return "WORST HOUR"
        case "longest_skid": return "LONGEST SKID"
        case "biggest_win":  return "BIGGEST WIN"
        default:             return kind.uppercased()
        }
    }

    private func snapshotSupportingLine(_ entry: PatternsSnapshotEntry) -> String {
        // ROI cap: PatternsSnapshotEntry carries no win rate, so a capped
        // outlier line falls back to the bet count alone.
        roiSupportingLine(bets: entry.betCount, roi: entry.roi, winRate: nil)
    }

    private func skidSupportingLine(_ entry: PatternsSnapshotEntry) -> String {
        "Consecutive losing sessions."
    }

    private var patternCount: Int {
        report.analysis.snapshotCounts?.patterns
            ?? report.analysis.patternsSnapshot?.count
            ?? report.analysis.behavioralPatterns.count
    }

    private var hasAnyPatterns: Bool {
        !patternCards.isEmpty || !snapshotPatternCards.isEmpty
    }

    private var fallbackText: String {
        if patternCount > 0 {
            return "You've got \(patternCount) detected behavioral patterns. The full report names them and shows what they cost you."
        }
        return "Pattern analysis lives in the full report, with your detected patterns and what they cost you."
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let cards = isSnapshot ? snapshotPatternCards : patternCards
            if !cards.isEmpty {
                VStack(spacing: 12) {
                    ForEach(cards) { p in
                        PatternCard(pattern: p)
                    }
                }
                .padding(.horizontal, 16)
            }

            if !contradictions.isEmpty {
                Spacer().frame(height: 24)
                VStack(spacing: 12) {
                    ForEach(contradictions) { contradiction in
                        ContradictionCard(
                            contradiction: contradiction,
                            isLockedCost: isSnapshot,
                            onLockedTap: { onPaywallTap("section_patterns_timing_contradiction_locked") }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }

            // Q3 dedup: the exec-diagnosis InsightCallout is removed (it
            // duplicated SectionVerdict). The section-specific fallback prose
            // is kept, but only when there are no pattern cards to show (it
            // is a "patterns live in the full report" nudge, not exec prose).
            if !hasAnyPatterns, !fallbackText.isEmpty {
                Spacer().frame(height: 24)
                InsightCallout(text: fallbackText)
                    .padding(.horizontal, 16)
            }

            // TIMING half (BY HOUR + BY DAY) extracted from Ch6.
            hourChartSection.padding(.top, 32)
            dayTilesSection.padding(.top, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    // MARK: - Timing sub-views (from ChapterYourSportsView)

    /// One BY HOUR bar, keyed by parsed hour-of-day. The engine ships
    /// byHour labels as "9pm"-style strings live (and "0"-"23" in older
    /// fixtures); parsing to a numeric hour makes the axis, ordering, and
    /// best/worst callouts data-driven instead of label-string-driven.
    private struct HourDatum: Identifiable {
        let hour: Int
        let roi: Double
        let bets: Int
        var id: Int { hour }
    }

    private var hourData: [HourDatum] {
        byHour.compactMap { bucket in
            guard let hour = parseHour(bucket.label) else { return nil }
            return HourDatum(hour: hour, roi: bucket.roi, bets: bucket.bets)
        }
        .sorted { $0.hour < $1.hour }
    }

    /// Best/worst hours computed from the underlying byHour data, never
    /// from the engine's bestWindow/worstWindow label strings (those are
    /// free-form and have shipped day labels like "Wed" under the HOURLY
    /// chart). Buckets need a minimum sample so a 1-bet fluke can't own
    /// the callout; the floor relaxes when nothing qualifies.
    private var hourCalloutPool: [HourDatum] {
        let qualified = hourData.filter { $0.bets >= 3 }
        if !qualified.isEmpty { return qualified }
        return hourData.filter { $0.bets > 0 }
    }

    private var bestHourDatum: HourDatum? {
        hourCalloutPool.max { $0.roi < $1.roi }
    }

    private var worstHourDatum: HourDatum? {
        hourCalloutPool.min { $0.roi < $1.roi }
    }

    @ViewBuilder
    private var hourChartSection: some View {
        // D6: the BY HOUR bar shape is the moat and stays visible in every
        // mode. Bars encode ROI percent (non-redacted) with hour labels;
        // no per-bar tap or dollar/bet-count tooltip surface to gate.
        //
        // TODO(engine raw-values): the engine is adding typed
        // timeOfDayPnl/dayOfWeekPnl arrays in a parallel change; move this
        // chart onto them when they land. Until then it parses the byHour
        // bucket labels (which carry the same raw hour data).
        if !hourData.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY HOUR")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Chart(hourData) { datum in
                    BarMark(
                        x: .value("Hour", datum.hour),
                        y: .value("ROI", datum.roi),
                        width: .ratio(0.7)
                    )
                    .foregroundStyle(datum.roi >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red)
                }
                .chartXScale(domain: -0.5...23.5)
                .chartXAxis {
                    AxisMarks(values: [0, 4, 8, 12, 16, 20]) { value in
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text(BAFormat.hourLabel(hour))
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(DS.Color.V3.textTertiary)
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .frame(height: 100)
                .padding(.top, 8)

                // Both callouts render only when there are at least two
                // distinct qualifying hours; a single bucket can't be both
                // the best and the worst hour of the day.
                if let best = bestHourDatum,
                   let worst = worstHourDatum,
                   best.hour != worst.hour {
                    HStack {
                        Text("BEST: \(BAFormat.hourLabel(best.hour))")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.V3.Severity.green)
                        Spacer()
                        Text("WORST: \(BAFormat.hourLabel(worst.hour))")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.V3.Severity.red)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    /// Parses an engine byHour label into an hour of day. Accepts "0"-"23"
    /// and "12am"/"9pm" shapes (case-insensitive, optional space).
    private func parseHour(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let plain = Int(trimmed) {
            return (0...23).contains(plain) ? plain : nil
        }
        let isPM = trimmed.hasSuffix("pm")
        let isAM = trimmed.hasSuffix("am")
        guard isPM || isAM else { return nil }
        let digits = trimmed.dropLast(2).trimmingCharacters(in: .whitespaces)
        guard let hour12 = Int(digits), (1...12).contains(hour12) else { return nil }
        if isAM { return hour12 == 12 ? 0 : hour12 }
        return hour12 == 12 ? 12 : hour12 + 12
    }

    @ViewBuilder
    private var dayTilesSection: some View {
        if let timing = report.analysis.timingAnalysis, !timing.byDay.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("BY DAY")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                HStack(spacing: 6) {
                    ForEach(timing.byDay) { day in
                        dayTile(day)
                    }
                }
                .padding(.top, 16)

                if let lateNight = timing.lateNightStats, lateNight.count > 0 {
                    Text(lateNightLine(lateNight))
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineSpacing(3)
                        .padding(.top, 12)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// The late-night summary line. The "cut these" recommendation only
    /// attaches to a NEGATIVE-ROI window; the old copy recommended cutting
    /// the bucket unconditionally, which read as incoherent when the
    /// window was profitable. Absurd outlier ROIs drop the percent (cap
    /// rule); the recommendation still keys off the raw sign.
    private func lateNightLine(_ stats: LateNightStats) -> String {
        let lead: String
        if abs(stats.roi) >= BAFormat.roiDisplayCap {
            lead = "\(BAFormat.sampleSize(stats.count)) after 10pm."
        } else {
            lead = "\(BAFormat.sampleSize(stats.count)) after 10pm, ROI \(BAFormat.percent(stats.roi, signed: true, headline: true))."
        }
        if stats.roi < 0 {
            return "\(lead) Cut these and recover most of the bleed."
        }
        return "\(lead) Late night is not your leak."
    }

    private func dayTile(_ day: TimingBucket) -> some View {
        let tint: Color = day.roi >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red
        let tintOpacity = min(0.25, abs(day.roi) / 100)

        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(DS.Color.V3.surfaceCard)
            RoundedRectangle(cornerRadius: 8)
                .fill(tint.opacity(tintOpacity))

            VStack(spacing: 4) {
                Text(day.label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                if isSnapshot {
                    LockedDollarBar(width: 56, onTap: { onPaywallTap("section_patterns_timing_dollar_locked") })
                } else {
                    Text(BAFormat.currency(day.profit, signed: true))
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
    }

    // MARK: - Pattern computations

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

        let range = "\(BAFormat.date(start)) to \(BAFormat.date(end))"

        return PatternCard.Pattern(
            title: "LONGEST SKID",
            bigNumber: "\(bestRun) STRAIGHT",
            bigNumberColor: DS.Color.V3.textPrimary,
            namedEntity: range,
            supportingLine: "Consecutive losing sessions."
        )
    }

    private func parseSessionDate(_ raw: String) -> Date? {
        BAFormat.parseEngineDate(raw)
    }

    private func dayLabel(_ raw: String) -> String {
        let map: [String: String] = [
            "MON": "Mondays",  "TUE": "Tuesdays", "WED": "Wednesdays",
            "THU": "Thursdays","FRI": "Fridays",  "SAT": "Saturdays",
            "SUN": "Sundays"
        ]
        if let label = map[raw.uppercased()] { return label }
        return raw
    }

    private func hourEntityLabel(_ raw: String) -> String {
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
}

#Preview {
    ScrollView {
        SectionPatternsTiming(report: MockReport.heatedBettor, onPaywallTap: { _ in })
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
