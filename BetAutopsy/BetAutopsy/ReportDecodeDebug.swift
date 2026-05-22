//
//  ReportDecodeDebug.swift
//  BetAutopsy
//
//  DEBUG-only round-trip decode harness for the P0 full-report rebuild.
//  Hidden in Release builds via #if DEBUG (the whole file compiles to
//  nothing). Called once from BetAutopsyApp.init() under #if DEBUG; logs a
//  structured decode report to the Xcode console at launch.
//
//  Purpose: decode a fixture that mirrors the schema_version=2 contract of
//  production row 05392003-4c49-4cf7-9bfe-02e8e98ed301 through the SAME
//  decoder the network path uses (.convertFromSnakeCase, see
//  ReportFetchClient), and assert every field iOS renders survives. The
//  fixture deliberately reproduces the v2 quirks that broke the full report:
//    - summary is snake_case with overall_grade: null (the decode bug)
//    - session_detection ships camelCase keys (convert is a no-op on them)
//    - both executive_diagnosis (string) and executiveDiagnosis (object)
//      exist (the convertFromSnakeCase key collision)
//    - emotion_score is a bare int; schema_version is a number
//
//  Arrays are trimmed to 1-2 entries; shapes are byte-faithful to the live
//  row. If any assertion fails the harness prints FAIL lines (it never traps,
//  so it can't crash a debug launch).
//

#if DEBUG
import Foundation

enum ReportDecodeDebug {
    /// Decode the fixture through the network decoder config and log the
    /// final state of every field the reader renders. Safe to call at launch.
    static func run() {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        guard let data = fixtureV2.data(using: .utf8) else {
            print("[DecodeDebug] FAIL: fixture is not valid UTF-8")
            return
        }

        let analysis: AutopsyAnalysis
        do {
            analysis = try decoder.decode(AutopsyAnalysis.self, from: data)
        } catch {
            print("[DecodeDebug] FAIL: AutopsyAnalysis threw (should never happen, decode is tolerant): \(error)")
            return
        }

        print("==================== [DecodeDebug] v2 round-trip ====================")

        // --- summary (the bug) ---
        let s = analysis.summary
        let summaryPopulated = s.totalBets != 0 || !s.record.isEmpty
        line("summary populated (not zero-fallback)", summaryPopulated, expected: true)
        line("summary.record", s.record, expected: "725W-1203L-26P")
        line("summary.totalProfit", s.totalProfit, expected: -2405.49, tol: 0.01)
        line("summary.roiPercent", s.roiPercent, expected: -2.43, tol: 0.01)
        line("summary.avgStake", s.avgStake, expected: 49.57, tol: 0.01)
        line("summary.totalBets", s.totalBets, expected: 2000)

        // --- scalars the brief flagged ---
        line("emotionScore (bare int)", analysis.emotionScore, expected: 73)
        line("schemaVersion (number)", analysis.schemaVersion ?? -1, expected: 2)
        line("bankrollHealth", analysis.bankrollHealth.rawValue, expected: "healthy")
        line("disciplineScore.total", analysis.disciplineScore?.total ?? -1, expected: 44)
        line("betiq.score", analysis.betiq?.score ?? -1, expected: 80)
        line("betiq.components.lineValue", analysis.betiq?.components.lineValue ?? -1, expected: 19)

        // --- collections ---
        line("biasesDetected.count", analysis.biasesDetected.count, expected: 1, note: "(fixture trims to 1; live = 5)")
        line("strategicLeaks.count", analysis.strategicLeaks.count, expected: 1, note: "(live = 5)")
        line("behavioralPatterns.count", analysis.behavioralPatterns.count, expected: 1, note: "(live = 6)")
        line("recommendations.count", analysis.recommendations.count, expected: 1, note: "(live = 5)")
        line("whatIfScenarios.count", analysis.whatIfScenarios?.count ?? -1, expected: 1, note: "(live = 3)")

        // --- session_detection (camelCase keys; the patternCards source) ---
        let sd = analysis.sessionDetection
        line("sessionDetection decoded (NOT nil)", sd != nil, expected: true)
        line("sessionDetection.sessions.count", sd?.sessions.count ?? -1, expected: 2, note: "(live = 297)")
        line("sessionDetection.totalSessions", sd?.totalSessions ?? -1, expected: 297)
        line("sessionDetection.gradeDist.count", sd?.sessionGradeDistribution.count ?? -1, expected: 1)
        line("sessionDetection has a profit<0 session (BIGGEST LOSS)",
             (sd?.sessions.contains { $0.profit < 0 }) ?? false, expected: true)

        // --- timing + odds + tilt ---
        line("timingAnalysis.byHour.count", analysis.timingAnalysis?.byHour.count ?? -1, expected: 1, note: "(live = 24)")
        line("timingAnalysis.byDay.count", analysis.timingAnalysis?.byDay.count ?? -1, expected: 1, note: "(live = 7)")
        line("oddsAnalysis decoded (NOT nil)", analysis.oddsAnalysis != nil, expected: true)
        line("oddsAnalysis.buckets.count", analysis.oddsAnalysis?.buckets.count ?? -1, expected: 1, note: "(live = 7)")
        line("enhancedTilt decoded (NOT nil)", analysis.enhancedTilt != nil, expected: true)
        line("emotionBreakdown decoded (NOT nil)", analysis.emotionBreakdown != nil, expected: true)

        // --- executive diagnosis (dual snake/camel) ---
        // executiveDiagnosis accessor is added in A.1. Until then this reads
        // the legacy String?; after A.1 it exposes insightFull/insightSnapshot.
        let full = analysis.executiveDiagnosisInsight(snapshot: false)
        let snap = analysis.executiveDiagnosisInsight(snapshot: true)
        line("execDiagnosis insightFull contains the $8,840 figure",
             full.contains("8,840"), expected: true,
             note: "(legitimate in FULL mode)")
        line("execDiagnosis insightSnapshot does NOT leak $8,840",
             !snap.contains("8,840"), expected: true,
             note: "(snapshot must not show dollars)")

        print("=====================================================================")
    }

    // MARK: - Assertion logging

    private static func line<T: Equatable>(_ label: String, _ actual: T, expected: T, note: String = "") {
        let ok = actual == expected
        print("[DecodeDebug] \(ok ? "PASS" : "FAIL") \(label): \(actual) \(ok ? "" : "(expected \(expected)) ")\(note)")
    }

    private static func line(_ label: String, _ actual: Double, expected: Double, tol: Double, note: String = "") {
        let ok = abs(actual - expected) <= tol
        print("[DecodeDebug] \(ok ? "PASS" : "FAIL") \(label): \(actual) \(ok ? "" : "(expected ~\(expected)) ")\(note)")
    }

    // MARK: - Fixture (faithful to live row 05392003, arrays trimmed)

    private static let fixtureV2 = """
    {
      "schema_version": 2,
      "summary": {
        "record": "725W-1203L-26P",
        "avg_stake": 49.57,
        "date_range": "2025-05-12 to 2026-04-03",
        "total_bets": 2000,
        "roi_percent": -2.43,
        "total_profit": -2405.49,
        "overall_grade": null
      },
      "emotion_score": 73,
      "bankroll_health": "healthy",
      "discipline_score": { "total": 44, "sizing": 7, "control": 0, "strategy": 20, "tracking": 17, "percentile": 30 },
      "emotion_breakdown": { "loss_chasing": 15, "streak_behavior": 21, "stake_volatility": 12, "session_discipline": 25 },
      "tilt_breakdown": { "loss_chasing": 15, "streak_behavior": 21, "stake_volatility": 12, "session_discipline": 25 },
      "betiq": {
        "score": 80,
        "components": { "timing": 10, "confidence": 15, "line_value": 19, "calibration": 15, "sophistication": 6, "specialization": 15 },
        "percentile": null,
        "interpretation": "Elite-level betting skill.",
        "insufficient_data": false
      },
      "enhanced_tilt": {
        "score": 73, "percentile": 70, "risk_level": "high", "worst_trigger": "post-loss escalation",
        "signals": { "loss_reaction": 15, "streak_behavior": 21, "session_discipline": 25, "session_acceleration": 15, "bet_sizing_volatility": 12, "odds_drift_after_loss": 0 }
      },
      "betting_archetype": { "name": "The Sharp", "description": "You've got real edges but your sizing is holding you back." },
      "biases_detected": [
        {
          "bias_name": "Post-Loss Escalation", "severity": "high",
          "description": "Every time this bettor takes a loss, the next bet gets bigger.",
          "evidence": "Loss Chase Ratio of 1.70x.",
          "fix": "Cap the next bet at the prior bet size.",
          "estimated_cost": 1200, "severity_bar_ratio": 0.75,
          "evidence_bet_ids": ["4aec083b-d7ca-420a-b7a4-9257ea2a058c"],
          "description_visibility": "visible", "evidence_visibility": "visible",
          "fix_visibility": "visible", "estimated_cost_visibility": "visible"
        }
      ],
      "strategic_leaks": [
        { "category": "High-Volume NBA Props", "detail": "Volume without edge.", "suggestion": "Cut the prop volume.", "roi_impact": -8.2, "sample_size": 240, "detail_visibility": "visible", "suggestion_visibility": "visible" }
      ],
      "behavioral_patterns": [
        { "pattern_name": "Chasing", "description": "Stakes climb after losses.", "frequency": "frequent", "data_points": "48% of bets", "impact": "negative" }
      ],
      "recommendations": [
        { "title": "Lock your unit size", "priority": 1, "difficulty": "medium", "description": "Fix stake at 1u.", "expected_improvement": "Recover ~$2,200.", "description_visibility": "visible", "expected_improvement_visibility": "visible" }
      ],
      "session_detection": {
        "totalSessions": 297,
        "avgSessionDuration": 405.72,
        "avgSessionLength": 22.1,
        "avgGradedROI": -2.4,
        "heatedSessionCount": 80,
        "heatedSessionPercent": 26.94,
        "insight": "Most damage happens in heated sessions.",
        "sessionGradeDistribution": [ { "grade": "A", "count": 67, "percent": 22.56 } ],
        "sessions": [
          { "id": "SESSION-001", "date": "May 31, 2025", "dayOfWeek": "Sat", "startTime": "10:00", "endTime": "23:00", "durationMinutes": 780, "bets": 11, "wins": 2, "losses": 9, "pushes": 0, "staked": 1400, "profit": -693, "roi": -49.5, "avgStake": 127, "stakeEscalation": 2.1, "betsPerHour": 0.8, "chaseCount": 4, "lateNight": true, "grade": "F", "gradeReasons": ["chasing"], "isHeated": true, "heatSignals": ["stake_volatility"] },
          { "id": "SESSION-002", "date": "Jun 2, 2025", "dayOfWeek": "Mon", "startTime": "18:00", "endTime": "20:00", "durationMinutes": 120, "bets": 4, "wins": 3, "losses": 1, "pushes": 0, "staked": 200, "profit": 145, "roi": 12.5, "avgStake": 50, "stakeEscalation": 1.0, "betsPerHour": 2.0, "chaseCount": 0, "lateNight": false, "grade": "B", "gradeReasons": ["disciplined"], "isHeated": false, "heatSignals": [] }
        ]
      },
      "session_analysis": {
        "insight": "Your worst sessions cluster on weekends.",
        "best_session": { "net": 312, "bets": 6, "date": "Jul 4, 2025", "duration": "2h", "description": "Clean session." },
        "worst_session": { "net": -693, "bets": 11, "date": "May 31, 2025", "duration": "Full day", "description": "Spiraled fast." },
        "total_sessions": 297, "avg_bets_per_winning_session": 5.2, "avg_bets_per_losing_session": 7.8
      },
      "timing_analysis": {
        "has_time_data": true,
        "by_day": [ { "label": "Mon", "roi": 4.42, "bets": 235, "wins": 95, "losses": 140, "profit": 512.49, "staked": 11587.11, "win_rate": 40.43, "profit_visibility": "visible", "staked_visibility": "visible" } ],
        "by_hour": [ { "label": "9pm", "roi": 59.05, "bets": 95, "wins": 60, "losses": 35, "profit": 1200.0, "staked": 4000.0, "win_rate": 63.1, "profit_visibility": "visible", "staked_visibility": "visible" } ],
        "best_window": { "label": "9pm", "roi": 59.05, "count": 95 },
        "worst_window": { "label": "2am", "roi": -40.0, "count": 30 },
        "late_night_stats": { "roi": 21.01, "count": 62, "pct_of_total": 3.22 }
      },
      "odds_analysis": {
        "expected_wins": 700.0, "actual_wins": 725, "luck_rating": 1.03, "luck_label": "Slightly lucky", "total_settled": 1928,
        "best_bucket": { "edge": 23.81, "count": 10, "label": "Heavy Chalk" },
        "worst_bucket": { "edge": -18.0, "count": 120, "label": "Longshot" },
        "buckets": [
          { "label": "Heavy Chalk", "range": "-300 or worse", "roi": 31.25, "bets": 10, "wins": 10, "losses": 0, "profit": 142.27, "staked": 455.33, "win_rate": 100, "implied_prob": 76.19, "actual_win_rate": 100, "edge": 23.81, "staked_visibility": "visible" }
        ]
      },
      "edge_profile": {
        "sharp_score": 71,
        "profitable_areas": [ { "category": "MLB Straight", "roi": 19, "sample_size": 121, "confidence": "medium" } ],
        "unprofitable_areas": [ { "category": "NBA Props", "roi": -12, "sample_size": 240, "estimated_loss": 980 } ]
      },
      "personal_rules": [ { "rule": "No bet after a loss exceeds the prior bet.", "reason": "Caps post-loss escalation.", "based_on": "Loss Chase Ratio 1.70x" } ],
      "contradictions": [ { "title": "Sharp but tilted", "insight": "Edge undone by sizing.", "edgeLabel": "Edge", "edgeData": "+5% CLV", "volumeLabel": "Volume", "volumeData": "2000 bets", "annualCost": 2216 } ],
      "pertinent_negatives": [ { "pattern": "No parlay addiction", "finding": "You avoid lottery parlays.", "detail": "Only 3% of stake on 4+ leg parlays vs 31% population.", "populationPercent": 31 } ],
      "summaryCounts": { "biasesDetected": 5, "sessionsAnalyzed": 297, "patternsIdentified": 0, "sportLevelFindings": 0, "leakPatternsFlagged": 20 },
      "what_if_scenarios": [ { "label": "If you cut post-loss escalation", "actual": -2405.49, "hypothetical": -189.0 } ],
      "executive_diagnosis": "This bettor has real edges in MLB, DFS, and longshots, but post-loss behavior is quietly burning the bankroll. Nearly half of all bets (48%) show signs of chasing, costing an estimated $8,840 in edge.",
      "executiveDiagnosis": {
        "insightFull": "This bettor has real edges in MLB, DFS, and longshots, but post-loss behavior is quietly burning the bankroll. Nearly half of all bets (48%) show signs of chasing, costing an estimated $8,840 in edge. That pattern is costing roughly $2,216 in measurable leak cost.",
        "insightSnapshot": "Your betting shows post-loss escalation patterns. The full report breaks down 2000 bets across 297 sessions."
      },
      "dfs_mode": false,
      "dfs_platform": null
    }
    """
}
#endif
