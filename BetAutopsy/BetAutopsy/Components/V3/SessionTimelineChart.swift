//
//  SessionTimelineChart.swift
//  BetAutopsy
//
//  3A hero chart (report-trust wire, web PR #74): the heated-session
//  stake-escalation curve. Data source is charts.sessionTimeline +
//  charts.heroSession; x is minutes since the session's first bet,
//  y is the stake. The line/area carries the framing tint (loss ->
//  severity red, win-but-risky -> severity amber); per-bet points are
//  outcome-colored (win green / loss red); chase bets get an amber
//  halo. Severity amber (not brand yellow) for chase emphasis: chase
//  is a data/severity semantic, and brand yellow is reserved for
//  CTAs, wordmark, and chrome.
//
//  Renders ONLY with a heroSession and at least two timeline points.
//  One point cannot draw an escalation curve and would read as a
//  broken chart; the host (SectionVerdict) also gates on full mode +
//  heroSession != nil, so snapshots and pre-#74 reports show exactly
//  what they showed before.
//
//  All numbers through BAFormat (currency, sample size, minutes).
//

import SwiftUI
import Charts

struct SessionTimelineChart: View {
    let timeline: [SessionTimelinePoint]
    let hero: HeroSession

    /// Stage C: when set (the report id) and the hero draw-on hasn't been
    /// seen for this report, the chart draws on once the first time it
    /// scrolls into view - the quieter secondary beat (no haptic). nil or
    /// already-seen renders static. Independent per-report flag from the
    /// cover money shot.
    var revealKey: String? = nil

    /// 0 = undrawn, 1 = full. Initialized to 1 (static) unless this is the
    /// first draw-on for revealKey, so a re-open shows the full chart with
    /// no empty-frame flash.
    @State private var drawProgress: CGFloat

    init(timeline: [SessionTimelinePoint], hero: HeroSession, revealKey: String? = nil) {
        self.timeline = timeline
        self.hero = hero
        self.revealKey = revealKey
        let willDraw = revealKey.map { !RevealFlags.heroSeen($0) } ?? false
        _drawProgress = State(initialValue: willDraw ? 0 : 1)
    }

    /// Index-keyed wrapper: tOffsetMin is not guaranteed unique.
    private struct Bet: Identifiable {
        let id: Int
        let offsetMin: Double
        let stakeUSD: Double
        let isWin: Bool
        let isChase: Bool
    }

    private var bets: [Bet] {
        timeline
            .sorted { $0.tOffsetMin < $1.tOffsetMin }
            .enumerated()
            .map { index, point in
                Bet(
                    id: index,
                    offsetMin: point.tOffsetMin,
                    stakeUSD: point.stakeUSD,
                    isWin: point.outcome == "win",
                    isChase: point.isChaseMarker
                )
            }
    }

    private var isLossFraming: Bool { hero.framing != "win-but-risky" }

    private var curveTint: Color {
        isLossFraming ? DS.Color.V3.Severity.red : DS.Color.V3.Severity.yellow
    }

    private var framingHeadline: String {
        isLossFraming
            ? "Heated session. Finished down."
            : "Heated session. Won, but risky."
    }

    private var metaLine: String {
        "\(BAFormat.date(parsing: hero.date, includeYear: true)) \u{00B7} \(BAFormat.sampleSize(hero.bets))"
    }

    private var chaseCount: Int { bets.filter { $0.isChase }.count }

    /// Data-driven caption: the escalation in one sentence, plus the
    /// chase-marker legend when any chase bets exist.
    private var caption: String {
        var parts: [String] = []
        if let first = bets.first, let last = bets.last, last.stakeUSD != first.stakeUSD {
            let span = last.offsetMin - first.offsetMin
            let run = "Stakes ran \(BAFormat.currency(first.stakeUSD)) to \(BAFormat.currency(last.stakeUSD))"
            parts.append(span > 0 ? "\(run) in \(BAFormat.minutes(span))." : "\(run).")
        }
        if chaseCount > 0 {
            parts.append("Amber halos mark chase bets placed right after a loss.")
        }
        return parts.joined(separator: " ")
    }

    private var accessibilitySummary: String {
        var parts: [String] = [framingHeadline, metaLine]
        if let first = bets.first, let last = bets.last {
            parts.append("Stakes from \(BAFormat.currency(first.stakeUSD)) to \(BAFormat.currency(last.stakeUSD))")
        }
        if chaseCount > 0 {
            parts.append("\(chaseCount) chase \(chaseCount == 1 ? "bet" : "bets")")
        }
        return parts.joined(separator: ". ") + "."
    }

    var body: some View {
        if bets.count >= 2 {
            VStack(alignment: .leading, spacing: 0) {
                Text("STAKE ESCALATION")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Text(framingHeadline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

                Text(metaLine)
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .padding(.top, 2)

                chart
                    // Draw-on: a left-to-right mask reveals the line/area/
                    // points as drawProgress animates 0->1. Static (=1) shows
                    // the full plot, no clipping.
                    .mask(alignment: .leading) {
                        GeometryReader { geo in
                            Rectangle().frame(width: geo.size.width * drawProgress)
                        }
                    }
                    .padding(.top, 16)

                if !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                        .opacity(drawProgress)
                }
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilitySummary)
            // Fires once when the hero first scrolls into view (LazyVStack
            // realizes it). Guarded by the per-report hero flag so later
            // opens render static. No haptic - the money shot owns that.
            .onAppear {
                guard let key = revealKey,
                      !RevealFlags.heroSeen(key),
                      drawProgress < 1 else { return }
                withAnimation(.easeOut(duration: 0.7 * Self.revealScale)) {
                    drawProgress = 1
                }
                RevealFlags.markHeroSeen(key)
            }
        }
    }

    private static var revealScale: Double {
        #if DEBUG
        return DebugReveal.scale
        #else
        return 1
        #endif
    }

    private var chart: some View {
        Chart {
            ForEach(bets) { bet in
                AreaMark(
                    x: .value("Minutes", bet.offsetMin),
                    y: .value("Stake", bet.stakeUSD)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    LinearGradient(
                        colors: [curveTint.opacity(0.22), curveTint.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Minutes", bet.offsetMin),
                    y: .value("Stake", bet.stakeUSD)
                )
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(curveTint)
            }

            // Chase halo behind the outcome point. Severity amber.
            ForEach(bets.filter { $0.isChase }) { bet in
                PointMark(
                    x: .value("Minutes", bet.offsetMin),
                    y: .value("Stake", bet.stakeUSD)
                )
                .symbolSize(220)
                .foregroundStyle(DS.Color.V3.Severity.yellow.opacity(0.35))
            }

            // Per-bet outcome points: win green, loss red.
            ForEach(bets) { bet in
                PointMark(
                    x: .value("Minutes", bet.offsetMin),
                    y: .value("Stake", bet.stakeUSD)
                )
                .symbolSize(64)
                .foregroundStyle(bet.isWin ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { value in
                AxisValueLabel {
                    if let minutes = value.as(Double.self) {
                        Text(BAFormat.minutes(minutes))
                            .font(.system(size: 9, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(DS.Color.V3.textTertiary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                    .foregroundStyle(DS.Color.V3.borderSubtle)
                AxisValueLabel {
                    if let stake = value.as(Double.self) {
                        Text(BAFormat.currency(stake))
                            .font(.system(size: 9, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(DS.Color.V3.textTertiary)
                    }
                }
            }
        }
        .frame(height: 160)
    }
}

#if DEBUG
#Preview("Loss framing (real shape)") {
    ScrollView {
        SessionTimelineChart(
            timeline: [
                SessionTimelinePoint(tOffsetMin: 0, stakeUSD: 100, outcome: "loss", isChaseMarker: false),
                SessionTimelinePoint(tOffsetMin: 30, stakeUSD: 250, outcome: "loss", isChaseMarker: true),
                SessionTimelinePoint(tOffsetMin: 60, stakeUSD: 500, outcome: "loss", isChaseMarker: true),
                SessionTimelinePoint(tOffsetMin: 90, stakeUSD: 1000, outcome: "loss", isChaseMarker: true)
            ],
            hero: HeroSession(sessionId: "SESSION-304", date: "May 22, 2026", framing: "loss", bets: 4)
        )
        .padding(16)
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}

#Preview("Win-but-risky framing") {
    ScrollView {
        SessionTimelineChart(
            timeline: [
                SessionTimelinePoint(tOffsetMin: 0, stakeUSD: 50, outcome: "loss", isChaseMarker: false),
                SessionTimelinePoint(tOffsetMin: 18, stakeUSD: 140, outcome: "loss", isChaseMarker: true),
                SessionTimelinePoint(tOffsetMin: 41, stakeUSD: 300, outcome: "win", isChaseMarker: true),
                SessionTimelinePoint(tOffsetMin: 64, stakeUSD: 220, outcome: "win", isChaseMarker: false)
            ],
            hero: HeroSession(sessionId: "SESSION-112", date: "Apr 3, 2026", framing: "win-but-risky", bets: 4)
        )
        .padding(16)
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
