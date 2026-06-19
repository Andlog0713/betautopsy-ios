//
//  MockReport.swift
//  BetAutopsy
//
//  The Tilter archetype mock. 247 bets, 103-138-6 record, -$2,847 net.
//  Sunday-night NFL → midnight NBA spirals. Bottom 12% discipline, top
//  8% emotional volatility. Real data wires in PR-4 via SSE.
//

import Foundation

enum MockReport {
    static var heatedBettor: AutopsyReport {
        AutopsyReport(
            id: "00000000-0000-4000-8000-000000000001",
            caseNumber: "0247",
            reportType: "full",
            betCountAnalyzed: 247,
            dateRangeStart: "2025-11-14",
            dateRangeEnd: "2026-05-10",
            createdAt: "2026-05-10T22:00:00Z",
            analysis: analysis,
            isFullBody: true
        )
    }

    /// Snapshot twin of heatedBettor for cover/shell harnesses. Reuses the
    /// same analysis; reportType "snapshot" drives the snapshot render paths
    /// (cover blurs the net, hides grade/percentile; sections lock).
    static var heatedBettorSnapshot: AutopsyReport {
        AutopsyReport(
            id: "00000000-0000-4000-8000-000000000002",
            caseNumber: "0247",
            reportType: "snapshot",
            betCountAnalyzed: 247,
            dateRangeStart: "2025-11-14",
            dateRangeEnd: "2026-05-10",
            createdAt: "2026-05-10T22:00:00Z",
            analysis: analysis,
            isFullBody: true
        )
    }

    private static let analysis = AutopsyAnalysis(
        schemaVersion: 1,
        summary: AutopsySummary(
            totalBets: 247,
            record: "103-138-6",
            totalProfit: -2847.50,
            roiPercent: -9.4,
            avgStake: 122.30,
            dateRange: "Nov 14, 2025 to May 10, 2026",
            overallGrade: "F"
        ),
        biasesDetected: [
            BiasDetected(
                biasName: "Loss Chasing",
                severity: .critical,
                description: "You bet bigger or more frequently after losses to get even. This is the most expensive habit in sports betting.",
                evidence: "Across 47 wagers placed within 30 minutes of a previous loss, your average stake increased 2.3x your baseline. Your win rate on those bets was 38%, not 50%.",
                estimatedCost: 1840.00,
                fix: "Set a 60-minute cooldown after any loss before placing another bet. Even a phone timer helps.",
                evidenceBetIds: ["b_142", "b_167", "b_189", "b_201"]
            ),
            BiasDetected(
                biasName: "Emotional Sizing",
                severity: .high,
                description: "Your bet sizes swing based on feelings, not strategy. Big after a win, bigger after a loss. This amplifies every mistake.",
                evidence: "Stake coefficient of variation is 0.71. Disciplined bettors run between 0.2 and 0.4. Your largest 10 bets landed in the bottom quartile of your win-rate windows.",
                estimatedCost: 620.00,
                fix: "Lock your unit size at 1% of bankroll. Same dollar amount on every straight bet, regardless of confidence.",
                evidenceBetIds: nil
            ),
            BiasDetected(
                biasName: "Parlay Addiction",
                severity: .medium,
                description: "The lure of big payouts keeps you stacking legs. Each leg you add increases the sportsbook's edge.",
                evidence: "31% of your wagers were parlays of 3+ legs. Win rate on those: 6.2%. Implied breakeven for the average odds was 11.4%. You lost $390 on parlays alone.",
                estimatedCost: 290.00,
                fix: "Cap parlays at 2 legs and only when both have independent positive expected value.",
                evidenceBetIds: nil
            ),
            BiasDetected(
                biasName: "Action Hunger",
                severity: .medium,
                description: "You bet for action, not value. Late-night random lines, sports you don't follow.",
                evidence: "23 wagers placed between 11pm and 2am on Sunday through Tuesday. ROI on those: -41%. Most were live bets on NBA games already in the second half.",
                estimatedCost: 240.00,
                fix: "Delete sportsbook apps after 10pm. Treat the late-night urge to bet as a signal to step away.",
                evidenceBetIds: nil
            ),
            BiasDetected(
                biasName: "Confirmation Bias",
                severity: .low,
                description: "You sought information that confirmed bets you wanted to make.",
                evidence: "Pattern is not statistically distinct from baseline. Mentioned here because every bettor has it.",
                estimatedCost: 0,
                fix: "Before placing a bet, write down the strongest argument against it. If you can't, you haven't done the research.",
                evidenceBetIds: nil
            )
        ],
        strategicLeaks: [
            StrategicLeak(
                category: "NBA player props (late night)",
                detail: "47 bets on NBA player props placed between 10pm and 1am. ROI: -28%. Your daytime NBA props ROI is +4% on the same prop types.",
                roiImpact: -28.0,
                sampleSize: 47,
                suggestion: "Stop betting NBA props after 10pm. Screen Time downtime on the sportsbook app does this for you."
            ),
            StrategicLeak(
                category: "NFL betting against key numbers",
                detail: "12 of your 18 NFL spread losses pushed through key numbers 3 and 7. You were taking points but on the wrong side of the line.",
                roiImpact: -22.0,
                sampleSize: 12,
                suggestion: "Never bet an NFL spread that has not crossed the key number you need. Wait for line movement or take the alternate."
            ),
            StrategicLeak(
                category: "Live betting after a loss",
                detail: "All 11 of your live bets placed within 20 minutes of a recent loss were on the team you just lost a bet on. Win rate: 18%.",
                roiImpact: -36.0,
                sampleSize: 11,
                suggestion: "No live betting in the same session as a loss. Period."
            )
        ],
        behavioralPatterns: [
            BehavioralPattern(
                patternName: "Sunday-night spiral",
                description: "Sunday losses on the NFL slate consistently produced midnight-hour chase bets on West Coast NBA games. The pattern repeats weekly during NBA season.",
                frequency: "14 of 21 NFL Sundays in dataset",
                impact: "negative",
                dataPoints: "Avg loss on follow-up NBA bets: $87. Total: $1,218."
            ),
            BehavioralPattern(
                patternName: "Win-day discipline collapse",
                description: "After a winning day, your next-day stake sizes increased an average of 47%. Your win rate on those bets dropped 11 percentage points.",
                frequency: "23 win-day to next-day pairs",
                impact: "negative",
                dataPoints: "Avg stake post-win: $148. Baseline: $101."
            ),
            BehavioralPattern(
                patternName: "Bonus-bet discipline",
                description: "On bonus-bet wagers you were dramatically more selective and more disciplined in sizing. Your bonus-bet ROI was +18%.",
                frequency: "31 bonus-bet wagers",
                impact: "positive",
                dataPoints: "Bonus-bet win rate: 47%. Cash win rate: 41%."
            )
        ],
        recommendations: [
            Recommendation(
                priority: 1,
                title: "Skip Sunday nights between 10pm and 2am",
                description: "Your single most expensive hour window. A phone alarm at 9:45pm that locks your sportsbook app costs you nothing and recovers most of the bleed.",
                expectedImprovement: "Recovers an estimated $1,840 over 12 weeks based on current pattern.",
                difficulty: "easy"
            ),
            Recommendation(
                priority: 2,
                title: "Lock unit size at 1% of bankroll",
                description: "Every straight bet, same dollar amount. No exceptions for confidence, hot streaks, or chase scenarios. Stake variance is what amplifies every mistake.",
                expectedImprovement: "Caps downside on emotional bets. Estimated $620 recovery.",
                difficulty: "medium"
            ),
            Recommendation(
                priority: 3,
                title: "60-minute cooldown after any loss",
                description: "No bet within 60 minutes of a settled losing wager. Set a phone timer. The bet you would have placed almost never aged well.",
                expectedImprovement: "Removes the conditions that produce your worst $290 chase bets.",
                difficulty: "medium"
            ),
            Recommendation(
                priority: 4,
                title: "Delete the sportsbook app from your home screen",
                description: "Friction matters. Move it to the second screen, the App Library, or delete it entirely between betting windows. Reduces unprompted opens by an estimated 70%.",
                expectedImprovement: "Reduces volume of low-quality late-night bets. Estimated $97 recovery.",
                difficulty: "easy"
            )
        ],
        emotionScore: 88,
        emotionBreakdown: EmotionBreakdown(
            stakeVolatility: 22,
            lossChasing: 24,
            streakBehavior: 19,
            sessionDiscipline: 23
        ),
        bankrollHealth: .danger,
        disciplineScore: DisciplineScore(
            total: 17, tracking: 8, sizing: 3, control: 2, strategy: 4, percentile: 12
        ),
        betiq: BetIQResult(
            score: 23,
            components: BetIQComponents(
                lineValue: 4, calibration: 5, sophistication: 3,
                specialization: 6, timing: 2, confidence: 3
            ),
            percentile: 18,
            interpretation: "You have a slight specialization edge in NBA daytime props that the rest of your activity bleeds out.",
            insufficientData: false
        ),
        enhancedTilt: EnhancedTiltResult(
            score: 88,
            signals: TiltSignals(
                betSizingVolatility: 22, lossReaction: 24, streakBehavior: 18,
                sessionDiscipline: 21, sessionAcceleration: 19, oddsDriftAfterLoss: 23
            ),
            riskLevel: "critical",
            worstTrigger: "Sunday-night NFL losses",
            percentile: 92
        ),
        timingAnalysis: TimingAnalysis(
            byHour: Self.mockHourlyBuckets(),
            byDay: Self.mockDailyBuckets(),
            bestWindow: TimingWindow(label: "Saturday 1pm to 5pm", roi: 14.2, count: 38),
            worstWindow: TimingWindow(label: "Sunday 10pm to 2am", roi: -41.3, count: 23),
            lateNightStats: LateNightStats(count: 39, roi: -33.1, pctOfTotal: 0.158),
            hasTimeData: true
        ),
        oddsAnalysis: OddsAnalysis(
            buckets: Self.mockOddsBuckets(),
            expectedWins: 108.4,
            actualWins: 103,
            luckRating: -5.4,
            luckLabel: "Running slightly cold",
            totalSettled: 241,
            bestBucket: BucketHighlight(label: "Heavy chalk", edge: 3.0, count: 14),
            worstBucket: BucketHighlight(label: "Pick em area", edge: -5.0, count: 92)
        ),
        sessionDetection: SessionDetectionResult(
            sessions: Self.mockSessions(),
            totalSessions: 38,
            avgSessionDuration: 94,
            sessionGradeDistribution: [
                SessionGradeDistribution(grade: "A", count: 4, percent: 10.5),
                SessionGradeDistribution(grade: "B", count: 7, percent: 18.4),
                SessionGradeDistribution(grade: "C", count: 11, percent: 28.9),
                SessionGradeDistribution(grade: "D", count: 9, percent: 23.7),
                SessionGradeDistribution(grade: "F", count: 7, percent: 18.4)
            ],
            heatedSessionCount: 12,
            heatedSessionPercent: 31.6,
            insight: "Roughly 1 in 3 sessions ran heated. Heated sessions cost an average of $187 each, while disciplined sessions averaged +$34."
        ),
        betAnnotations: AnnotationSummary(
            annotations: [],
            distribution: [
                ClassificationStats(classification: .disciplined, count: 142, percent: 57.5, totalStaked: 14310, totalProfit: 412, roi: 2.9),
                ClassificationStats(classification: .emotional,   count: 48,  percent: 19.4, totalStaked: 7104,  totalProfit: -892,  roi: -12.6),
                ClassificationStats(classification: .chasing,     count: 32,  percent: 13.0, totalStaked: 6240,  totalProfit: -1840, roi: -29.5),
                ClassificationStats(classification: .impulsive,   count: 18,  percent: 7.3,  totalStaked: 2160,  totalProfit: -510,  roi: -23.6),
                ClassificationStats(classification: .neutral,     count: 7,   percent: 2.8,  totalStaked: 420,   totalProfit: -17,   roi: -4.0)
            ],
            emotionalCost: 3242.00,
            insight: "57% of your bets were disciplined and made money. The other 43% lost more than three thousand dollars."
        ),
        sportSpecificFindings: [
            SportSpecificFinding(
                findingId: "nba_late_props",
                name: "NBA late-night prop overexposure",
                sport: "NBA",
                severity: .high,
                description: "Your NBA player-prop ROI flips from +4% in daytime windows to -28% after 10pm. The props themselves are not the leak. The timing is.",
                evidence: "47 NBA props placed 10pm to 1am with average stake of $94 vs baseline stake $61.",
                estimatedCost: 720.00,
                recommendation: "Sportsbook downtime between 10pm and 7am. NBA props excluded entirely from that window."
            ),
            SportSpecificFinding(
                findingId: "nfl_key_numbers",
                name: "NFL spreads on the wrong side of key numbers",
                sport: "NFL",
                severity: .medium,
                description: "You repeatedly took NFL teams getting fewer points than the key numbers 3 or 7 needed. Twelve of your eighteen NFL spread losses pushed through a key number.",
                evidence: "Sample of 18 settled NFL spread bets, 67% loss rate, average margin of defeat 1.4 points.",
                estimatedCost: 410.00,
                recommendation: "Bet NFL spreads only after the line has moved past the relevant key number, or wait for an alternate line."
            )
        ],
        dfsMode: false,
        dfsPlatform: nil,
        dfsMetrics: nil,
        executiveDiagnosis: "You move fastest when you should slow down. Your profitable bets are concentrated in a window between Friday and early Sunday afternoon when you research and size like a disciplined bettor. Your losing bets are concentrated in a window between Sunday night and Tuesday morning when an NFL loss has just resolved and your emotional state takes over your sizing. The pattern is consistent, it repeats almost weekly, and the math is clear. A single behavioral rule, no Sunday-night NBA bets between 10pm and 2am, would have recovered roughly two thirds of your losses over the analyzed period.",
        pertinentNegatives: [
            PertinentNegative(
                pattern: "Steam chasing",
                finding: "You do not chase line movement.",
                detail: "Only 4% of your bets were placed within 5 minutes of a 0.5+ point line move in your direction. Most bettors at your discipline tier sit at 15 to 20%. This is genuinely a strength.",
                populationPercent: 4
            ),
            PertinentNegative(
                pattern: "Shopping books",
                finding: "You consistently get the best available number on lines you do shop.",
                detail: "Across your last 60 bets, your average edge versus the closing line was +2.1 cents. That is sharp behavior. The problem is not your number, it is your stake control after a loss.",
                populationPercent: 87
            ),
            PertinentNegative(
                pattern: "Bonus-bet discipline",
                finding: "Your bonus-bet decisions are unusually disciplined.",
                detail: "Bonus-bet ROI was +18% versus cash ROI of -9%. You make better decisions when the downside feels lower, which is its own kind of tell.",
                populationPercent: 12
            )
        ],
        contradictions: [
            Contradiction(
                title: "You are sharp until you are not",
                insight: "Your daytime NBA prop ROI is +4%. Your late-night NBA prop ROI is -28%. Same sport, same bet type, same bettor. The window is the only variable.",
                volumeLabel: "Late-night NBA props",
                volumeData: "47 bets",
                edgeLabel: "Late-night ROI",
                edgeData: "-28.0%",
                annualCost: 720
            ),
            Contradiction(
                title: "Your discipline is loudest on small money",
                insight: "On bonus bets you size flat and pick selectively. On cash you swing and chase. The skill is there. The conditions you let yourself bet under are the leak.",
                volumeLabel: "Bonus-bet bets",
                volumeData: "31 wagers, +18%",
                edgeLabel: "Cash bets",
                edgeData: "216 wagers, -9%",
                annualCost: nil
            )
        ],
        bettingArchetype: BettingArchetypeData(
            name: "The Tilter",
            description: "Your reads aren't bad, but your emotions turn winners into losing weeks. The bets after losses are where your bankroll goes to die."
        ),
        quizArchetype: "The Tilter",
        // schema_version 3 wire (web PR #74). recovery drives the
        // DollarImpactCard's method form; charts carries the typed
        // sessionTimeline (the hero SessionTimelineChart + its Stage C
        // reveal) and betTypeMix (no legacy fallback exists for it). The
        // other typed arrays are left empty so the legacy timing/odds/
        // streak fallbacks keep rendering (they have valid mock data).
        recovery: ReportRecovery(
            biggestSingleLeakUSD: 1840,
            method: "exit_worst_category",
            overlapsExist: true,
            rangeLow: 1400,
            rangeHigh: 2300,
            netUSD: -2848
        ),
        charts: ReportCharts(
            sessionTimeline: [
                SessionTimelinePoint(tOffsetMin: 0,  stakeUSD: 100,  outcome: "loss", isChaseMarker: false),
                SessionTimelinePoint(tOffsetMin: 30, stakeUSD: 250,  outcome: "loss", isChaseMarker: true),
                SessionTimelinePoint(tOffsetMin: 60, stakeUSD: 500,  outcome: "loss", isChaseMarker: true),
                SessionTimelinePoint(tOffsetMin: 90, stakeUSD: 1000, outcome: "loss", isChaseMarker: true)
            ],
            heroSession: HeroSession(sessionId: "SESSION-304", date: "May 22, 2026", framing: "loss", bets: 4),
            betTypeMix: [
                BetTypeMixEntry(betClass: "straight", count: 1576, pct: 77.6),
                BetTypeMixEntry(betClass: "parlay",   count: 312,  pct: 15.4),
                BetTypeMixEntry(betClass: "prop",     count: 142,  pct: 7.0)
            ]
        )
    )

    // MARK: - Helpers

    private static func mockHourlyBuckets() -> [TimingBucket] {
        let pattern: [(label: String, roi: Double, bets: Int)] = [
            ("0", -38, 8), ("1", -41, 6), ("2", -22, 3), ("3", 0, 0),
            ("4", 0, 0), ("5", 0, 0), ("6", 0, 0), ("7", 0, 0),
            ("8", 2, 4), ("9", 4, 7), ("10", 6, 9), ("11", 8, 11),
            ("12", 12, 14), ("13", 14, 18), ("14", 13, 19), ("15", 11, 22),
            ("16", 10, 21), ("17", 8, 18), ("18", 4, 14), ("19", -2, 16),
            ("20", -6, 18), ("21", -11, 16), ("22", -24, 12), ("23", -33, 11)
        ]
        return pattern.map { p in
            let wins = max(0, Int(Double(p.bets) * (0.5 + p.roi / 200)))
            return TimingBucket(
                label: p.label,
                bets: p.bets,
                wins: wins,
                losses: max(0, p.bets - wins),
                staked: Double(p.bets) * 122,
                profit: Double(p.bets) * 122 * (p.roi / 100),
                roi: p.roi,
                winRate: p.bets > 0 ? Double(wins) / Double(p.bets) : 0
            )
        }
    }

    private static func mockDailyBuckets() -> [TimingBucket] {
        let days: [(String, Double, Int)] = [
            ("MON", -14, 28), ("TUE", -8, 24), ("WED", 2, 19),
            ("THU", 6, 22), ("FRI", 9, 31), ("SAT", 14, 52),
            ("SUN", -22, 71)
        ]
        return days.map { d in
            let wins = max(0, Int(Double(d.2) * (0.5 + d.1 / 200)))
            return TimingBucket(
                label: d.0, bets: d.2,
                wins: wins, losses: max(0, d.2 - wins),
                staked: Double(d.2) * 122,
                profit: Double(d.2) * 122 * (d.1 / 100),
                roi: d.1,
                winRate: d.2 > 0 ? Double(wins) / Double(d.2) : 0
            )
        }
    }

    private static func mockOddsBuckets() -> [OddsBucket] {
        [
            OddsBucket(label: "Heavy chalk", range: "-300 or worse", bets: 14, wins: 11, losses: 3, staked: 4200, profit: -212, roi: -5.0, winRate: 79.0, impliedProb: 76.0, actualWinRate: 79.0, edge: 3.0),
            OddsBucket(label: "Moderate favorites", range: "-200 to -149", bets: 38, wins: 22, losses: 16, staked: 4636, profit: -278, roi: -6.0, winRate: 58.0, impliedProb: 62.0, actualWinRate: 58.0, edge: -4.0),
            OddsBucket(label: "Pick em area", range: "-130 to +130", bets: 92, wins: 41, losses: 51, staked: 11224, profit: -1418, roi: -12.6, winRate: 45.0, impliedProb: 50.0, actualWinRate: 45.0, edge: -5.0),
            OddsBucket(label: "Moderate dogs", range: "+131 to +200", bets: 51, wins: 18, losses: 33, staked: 6222, profit: -424, roi: -6.8, winRate: 35.0, impliedProb: 37.0, actualWinRate: 35.0, edge: -2.0),
            OddsBucket(label: "Long shots", range: "+201 or longer", bets: 46, wins: 11, losses: 35, staked: 4324, profit: -515, roi: -11.9, winRate: 24.0, impliedProb: 27.0, actualWinRate: 24.0, edge: -3.0)
        ]
    }

    private static func mockSessions() -> [DetectedSession] {
        [
            DetectedSession(id: "s_0247", date: "Dec 3, 2025", dayOfWeek: "WED", startTime: "11:14 PM", endTime: "1:38 AM", durationMinutes: 144, bets: 8, wins: 2, losses: 6, pushes: 0, staked: 1840, profit: -920, roi: -50.0, avgStake: 230, stakeEscalation: 3.1, betsPerHour: 3.3, chaseCount: 6, lateNight: true, grade: "F", gradeReasons: ["6 chase bets", "Stake escalated 3x", "Late-night session", "Negative ROI"], isHeated: true, heatSignals: ["Loss chasing", "Stake escalation", "Late-night start"]),
            DetectedSession(id: "s_0231", date: "Nov 22, 2025", dayOfWeek: "FRI", startTime: "11:42 PM", endTime: "12:51 AM", durationMinutes: 69, bets: 5, wins: 1, losses: 4, pushes: 0, staked: 920, profit: -540, roi: -58.7, avgStake: 184, stakeEscalation: 2.4, betsPerHour: 4.3, chaseCount: 4, lateNight: true, grade: "F", gradeReasons: ["4 chase bets", "Stake escalation"], isHeated: true, heatSignals: ["Loss chasing", "Stake escalation"]),
            DetectedSession(id: "s_0214", date: "Jan 7, 2026", dayOfWeek: "SUN", startTime: "11:55 PM", endTime: "1:12 AM", durationMinutes: 77, bets: 4, wins: 1, losses: 3, pushes: 0, staked: 720, profit: -380, roi: -52.8, avgStake: 180, stakeEscalation: 1.9, betsPerHour: 3.1, chaseCount: 3, lateNight: true, grade: "F", gradeReasons: ["NFL Sunday spiral pattern", "3 chase bets"], isHeated: true, heatSignals: ["Sunday-night spiral", "Loss chasing"]),
            DetectedSession(id: "s_0198", date: "Feb 2, 2026", dayOfWeek: "MON", startTime: "8:14 PM", endTime: "10:32 PM", durationMinutes: 138, bets: 6, wins: 3, losses: 3, pushes: 0, staked: 760, profit: 87, roi: 11.4, avgStake: 127, stakeEscalation: 1.1, betsPerHour: 2.6, chaseCount: 1, lateNight: false, grade: "B", gradeReasons: ["Flat staking", "Stop point respected"], isHeated: false, heatSignals: []),
            DetectedSession(id: "s_0156", date: "Mar 14, 2026", dayOfWeek: "SAT", startTime: "1:14 PM", endTime: "5:21 PM", durationMinutes: 247, bets: 9, wins: 6, losses: 3, pushes: 0, staked: 1100, profit: 284, roi: 25.8, avgStake: 122, stakeEscalation: 1.0, betsPerHour: 2.2, chaseCount: 0, lateNight: false, grade: "A", gradeReasons: ["Flat staking maintained", "Selective", "Strong win rate"], isHeated: false, heatSignals: []),
            DetectedSession(id: "s_0142", date: "Apr 8, 2026", dayOfWeek: "WED", startTime: "7:42 PM", endTime: "11:14 PM", durationMinutes: 212, bets: 7, wins: 3, losses: 4, pushes: 0, staked: 980, profit: -120, roi: -12.2, avgStake: 140, stakeEscalation: 1.4, betsPerHour: 2.0, chaseCount: 2, lateNight: false, grade: "C", gradeReasons: ["Mild stake escalation", "Stayed below midnight"], isHeated: false, heatSignals: []),
            DetectedSession(id: "s_0117", date: "Apr 27, 2026", dayOfWeek: "SAT", startTime: "12:48 PM", endTime: "4:01 PM", durationMinutes: 193, bets: 5, wins: 3, losses: 2, pushes: 0, staked: 610, profit: 142, roi: 23.3, avgStake: 122, stakeEscalation: 1.0, betsPerHour: 1.6, chaseCount: 0, lateNight: false, grade: "A", gradeReasons: ["Flat sizing", "Highly selective"], isHeated: false, heatSignals: []),
            DetectedSession(id: "s_0103", date: "May 4, 2026", dayOfWeek: "MON", startTime: "9:18 PM", endTime: "11:47 PM", durationMinutes: 149, bets: 5, wins: 1, losses: 4, pushes: 0, staked: 820, profit: -340, roi: -41.5, avgStake: 164, stakeEscalation: 1.8, betsPerHour: 2.0, chaseCount: 3, lateNight: false, grade: "D", gradeReasons: ["3 chase bets", "Stake escalation"], isHeated: true, heatSignals: ["Loss chasing"])
        ]
    }
}
