//
//  ReportModels.swift
//  BetAutopsy
//
//  Canonical Codable shapes for AutopsyAnalysis + report wrappers.
//  Shared chapter chrome (SeverityChip, LabelChip).
//  Formatting helpers (formatCurrency, formatPct).
//

import Foundation
import SwiftUI

// MARK: - Enums

enum BiasSeverity: String, Codable {
    case low, medium, high, critical

    var displayLabel: String {
        switch self {
        case .low: return "LOW"
        case .medium: return "NOTABLE"
        case .high: return "HIGH"
        case .critical: return "CRITICAL"
        }
    }

    var color: Color {
        switch self {
        case .critical: return DS.Color.V3.Severity.red
        case .high:     return DS.Color.V3.Severity.red.opacity(0.85)
        case .medium:   return DS.Color.V3.Severity.yellow
        case .low:      return DS.Color.V3.Severity.gray
        }
    }

    var sortOrder: Int {
        switch self {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

enum BankrollHealth: String, Codable {
    case healthy, caution, danger
    var label: String {
        switch self {
        case .healthy: return "HEALTHY"
        case .caution: return "CAUTION"
        case .danger:  return "DANGER"
        }
    }
    var color: Color {
        switch self {
        case .healthy: return DS.Color.V3.Severity.green
        case .caution: return DS.Color.V3.Severity.yellow
        case .danger:  return DS.Color.V3.Severity.red
        }
    }
}

enum BetClassification: String, Codable {
    case disciplined, emotional, chasing, impulsive, neutral
    var color: Color {
        switch self {
        case .disciplined: return DS.Color.V3.Severity.green
        case .emotional:   return DS.Color.V3.Severity.yellow
        case .chasing:     return DS.Color.V3.Severity.red
        case .impulsive:   return DS.Color.V3.Severity.red.opacity(0.85)
        case .neutral:     return DS.Color.V3.Severity.gray
        }
    }
    var label: String { rawValue.uppercased() }
}

// MARK: - Core shapes

struct AutopsySummary: Codable {
    let totalBets: Int
    let record: String
    let totalProfit: Double
    let roiPercent: Double
    let avgStake: Double
    let dateRange: String
    let overallGrade: String
}

struct BiasDetected: Codable, Identifiable {
    var id: String { biasName }
    let biasName: String
    let severity: BiasSeverity
    let description: String
    let evidence: String
    let estimatedCost: Double
    let fix: String
    let evidenceBetIds: [String]?

    // Engine V2 snapshot side-channel. Each visibility tag may carry:
    // "visible"          -> full prose, render as-is
    // "redacted_dollar"  -> engine shipped sentinel zero or $••• prose
    // "hidden"           -> withhold entirely
    // Optional + try? on every consumer so older engines without the
    // tags decode cleanly and current UI behavior is unchanged.
    let estimatedCostVisibility: String?
    let evidenceVisibility: String?
    let descriptionVisibility: String?
    let fixVisibility: String?

    init(
        biasName: String,
        severity: BiasSeverity,
        description: String,
        evidence: String,
        estimatedCost: Double,
        fix: String,
        evidenceBetIds: [String]?,
        estimatedCostVisibility: String? = nil,
        evidenceVisibility: String? = nil,
        descriptionVisibility: String? = nil,
        fixVisibility: String? = nil
    ) {
        self.biasName = biasName
        self.severity = severity
        self.description = description
        self.evidence = evidence
        self.estimatedCost = estimatedCost
        self.fix = fix
        self.evidenceBetIds = evidenceBetIds
        self.estimatedCostVisibility = estimatedCostVisibility
        self.evidenceVisibility = evidenceVisibility
        self.descriptionVisibility = descriptionVisibility
        self.fixVisibility = fixVisibility
    }
}

struct StrategicLeak: Codable, Identifiable {
    var id: String { category }
    let category: String
    let detail: String
    let roiImpact: Double
    let sampleSize: Int
    let suggestion: String
}

struct BehavioralPattern: Codable, Identifiable {
    var id: String { patternName }
    let patternName: String
    let description: String
    let frequency: String
    let impact: String
    let dataPoints: String
}

struct Recommendation: Codable, Identifiable {
    var id: Int { priority }
    let priority: Int
    let title: String
    let description: String
    let expectedImprovement: String
    let difficulty: String

    // Engine V2 may populate a numeric cost_savings (positive dollars)
    // and a cost_savings_visibility tag mirroring the bias pattern.
    // Both optional — older engines just ship expectedImprovement prose.
    let costSavings: Double?
    let costSavingsVisibility: String?

    init(
        priority: Int,
        title: String,
        description: String,
        expectedImprovement: String,
        difficulty: String,
        costSavings: Double? = nil,
        costSavingsVisibility: String? = nil
    ) {
        self.priority = priority
        self.title = title
        self.description = description
        self.expectedImprovement = expectedImprovement
        self.difficulty = difficulty
        self.costSavings = costSavings
        self.costSavingsVisibility = costSavingsVisibility
    }
}

struct EmotionBreakdown: Codable {
    let stakeVolatility: Int
    let lossChasing: Int
    let streakBehavior: Int
    let sessionDiscipline: Int
}

struct DisciplineScore: Codable {
    let total: Int
    let tracking: Int
    let sizing: Int
    let control: Int
    let strategy: Int
    let percentile: Int?
}

struct BetIQComponents: Codable {
    let lineValue: Int
    let calibration: Int
    let sophistication: Int
    let specialization: Int
    let timing: Int
    let confidence: Int

    init(
        lineValue: Int,
        calibration: Int,
        sophistication: Int,
        specialization: Int,
        timing: Int,
        confidence: Int
    ) {
        self.lineValue = lineValue
        self.calibration = calibration
        self.sophistication = sophistication
        self.specialization = specialization
        self.timing = timing
        self.confidence = confidence
    }

    private enum CodingKeys: String, CodingKey {
        case lineValue, calibration, sophistication
        case specialization, timing, confidence
    }

    /// Tolerant decoder. Snapshot wire may ship a sparse components
    /// object (or omit it entirely); any per-field shape mismatch
    /// would otherwise cascade up to BetIQResult and collapse the
    /// hero-ring score to 0. Mirrors the PR-15 DetectedSession fix.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.lineValue      = (try? c.decode(Int.self, forKey: .lineValue))      ?? 0
        self.calibration    = (try? c.decode(Int.self, forKey: .calibration))    ?? 0
        self.sophistication = (try? c.decode(Int.self, forKey: .sophistication)) ?? 0
        self.specialization = (try? c.decode(Int.self, forKey: .specialization)) ?? 0
        self.timing         = (try? c.decode(Int.self, forKey: .timing))         ?? 0
        self.confidence     = (try? c.decode(Int.self, forKey: .confidence))     ?? 0
    }

    /// All-zero default used as the BetIQResult.components fallback
    /// when the wire ships no components object at all.
    static let zero = BetIQComponents(
        lineValue: 0, calibration: 0, sophistication: 0,
        specialization: 0, timing: 0, confidence: 0
    )
}

struct BetIQResult: Codable {
    let score: Int
    let components: BetIQComponents
    let percentile: Int
    let interpretation: String
    let insufficientData: Bool

    init(
        score: Int,
        components: BetIQComponents,
        percentile: Int,
        interpretation: String,
        insufficientData: Bool
    ) {
        self.score = score
        self.components = components
        self.percentile = percentile
        self.interpretation = interpretation
        self.insufficientData = insufficientData
    }

    private enum CodingKeys: String, CodingKey {
        case score, components, percentile, interpretation, insufficientData
    }

    /// Tolerant decoder. Snapshot wire (e.g. 24d12db7) ships a betiq
    /// object with `score` populated but may omit `components`,
    /// `interpretation`, or `insufficientData`. Synthesized Codable
    /// would fail the whole BetIQResult decode on any single missing
    /// required field, collapsing AutopsyAnalysis.betiq to nil via
    /// the parent try? and rendering the Ch 1 hero ring as 0.
    /// Each field reads with try? and a neutral default; score is
    /// additionally accepted as Double in case the engine ever ships
    /// 69.0 instead of 69.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let intScore = try? c.decode(Int.self, forKey: .score) {
            self.score = intScore
        } else if let doubleScore = try? c.decode(Double.self, forKey: .score) {
            self.score = Int(doubleScore.rounded())
        } else {
            self.score = 0
        }
        self.components       = (try? c.decode(BetIQComponents.self, forKey: .components)) ?? .zero
        self.percentile       = (try? c.decode(Int.self, forKey: .percentile))            ?? 0
        self.interpretation   = (try? c.decode(String.self, forKey: .interpretation))      ?? ""
        self.insufficientData = (try? c.decode(Bool.self, forKey: .insufficientData))      ?? false
    }
}

struct TiltSignals: Codable {
    let betSizingVolatility: Int
    let lossReaction: Int
    let streakBehavior: Int
    let sessionDiscipline: Int
    let sessionAcceleration: Int
    let oddsDriftAfterLoss: Int
}

struct EnhancedTiltResult: Codable {
    let score: Int
    let signals: TiltSignals
    let riskLevel: String
    let worstTrigger: String
    let percentile: Int
}

struct TimingBucket: Codable, Identifiable {
    var id: String { label }
    let label: String
    let bets: Int
    let wins: Int
    let losses: Int
    let staked: Double
    let profit: Double
    let roi: Double
    let winRate: Double
}

struct TimingWindow: Codable {
    let label: String
    let roi: Double
    let count: Int
}

struct LateNightStats: Codable {
    let count: Int
    let roi: Double
    let pctOfTotal: Double
}

struct TimingAnalysis: Codable {
    let byHour: [TimingBucket]
    let byDay: [TimingBucket]
    let bestWindow: TimingWindow?
    let worstWindow: TimingWindow?
    let lateNightStats: LateNightStats?
    let hasTimeData: Bool
}

struct OddsBucket: Codable, Identifiable {
    var id: String { label }
    let label: String
    let range: String
    let bets: Int
    let wins: Int
    let losses: Int
    let staked: Double
    let profit: Double
    let roi: Double
    let winRate: Double
    let impliedProb: Double
    let actualWinRate: Double
    let edge: Double
}

struct BucketHighlight: Codable {
    let label: String
    let edge: Double
    let count: Int
}

struct OddsAnalysis: Codable {
    let buckets: [OddsBucket]
    let expectedWins: Double
    let actualWins: Int
    let luckRating: Double
    let luckLabel: String
    let totalSettled: Int
    let bestBucket: BucketHighlight?
    let worstBucket: BucketHighlight?
}

struct DetectedSession: Codable, Identifiable {
    let id: String
    let date: String
    let dayOfWeek: String
    let startTime: String
    let endTime: String
    let durationMinutes: Int
    let bets: Int
    let wins: Int
    let losses: Int
    let pushes: Int
    let staked: Double
    let profit: Double
    let roi: Double
    let avgStake: Double
    let stakeEscalation: Double
    let betsPerHour: Double
    let chaseCount: Int
    let lateNight: Bool
    let grade: String
    let gradeReasons: [String]
    let isHeated: Bool
    let heatSignals: [String]

    init(
        id: String,
        date: String,
        dayOfWeek: String,
        startTime: String,
        endTime: String,
        durationMinutes: Int,
        bets: Int,
        wins: Int,
        losses: Int,
        pushes: Int,
        staked: Double,
        profit: Double,
        roi: Double,
        avgStake: Double,
        stakeEscalation: Double,
        betsPerHour: Double,
        chaseCount: Int,
        lateNight: Bool,
        grade: String,
        gradeReasons: [String],
        isHeated: Bool,
        heatSignals: [String]
    ) {
        self.id = id
        self.date = date
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.bets = bets
        self.wins = wins
        self.losses = losses
        self.pushes = pushes
        self.staked = staked
        self.profit = profit
        self.roi = roi
        self.avgStake = avgStake
        self.stakeEscalation = stakeEscalation
        self.betsPerHour = betsPerHour
        self.chaseCount = chaseCount
        self.lateNight = lateNight
        self.grade = grade
        self.gradeReasons = gradeReasons
        self.isHeated = isHeated
        self.heatSignals = heatSignals
    }

    private enum CodingKeys: String, CodingKey {
        case id, date, dayOfWeek, startTime, endTime
        case durationMinutes, bets, wins, losses, pushes
        case staked, profit, roi, avgStake, stakeEscalation
        case betsPerHour, chaseCount, lateNight, grade
        case gradeReasons, isHeated, heatSignals
    }

    /// Tolerant decoder. Every field uses try? with a neutral default so
    /// a single per-field shape mismatch (e.g. wire ships null for an
    /// array, or a numeric arrives as a string) does not collapse the
    /// whole [DetectedSession] decode and through it sessionDetection
    /// itself. Was the root cause of Ch 2 not rendering on snapshot
    /// 24d12db7-style payloads.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id              = (try? c.decode(String.self,   forKey: .id))              ?? ""
        self.date            = (try? c.decode(String.self,   forKey: .date))            ?? ""
        self.dayOfWeek       = (try? c.decode(String.self,   forKey: .dayOfWeek))       ?? ""
        self.startTime       = (try? c.decode(String.self,   forKey: .startTime))       ?? ""
        self.endTime         = (try? c.decode(String.self,   forKey: .endTime))         ?? ""
        self.durationMinutes = (try? c.decode(Int.self,      forKey: .durationMinutes)) ?? 0
        self.bets            = (try? c.decode(Int.self,      forKey: .bets))            ?? 0
        self.wins            = (try? c.decode(Int.self,      forKey: .wins))            ?? 0
        self.losses          = (try? c.decode(Int.self,      forKey: .losses))          ?? 0
        self.pushes          = (try? c.decode(Int.self,      forKey: .pushes))          ?? 0
        self.staked          = (try? c.decode(Double.self,   forKey: .staked))          ?? 0
        self.profit          = (try? c.decode(Double.self,   forKey: .profit))          ?? 0
        self.roi             = (try? c.decode(Double.self,   forKey: .roi))             ?? 0
        self.avgStake        = (try? c.decode(Double.self,   forKey: .avgStake))        ?? 0
        self.stakeEscalation = (try? c.decode(Double.self,   forKey: .stakeEscalation)) ?? 0
        self.betsPerHour     = (try? c.decode(Double.self,   forKey: .betsPerHour))     ?? 0
        self.chaseCount      = (try? c.decode(Int.self,      forKey: .chaseCount))      ?? 0
        self.lateNight       = (try? c.decode(Bool.self,     forKey: .lateNight))       ?? false
        self.grade           = (try? c.decode(String.self,   forKey: .grade))           ?? ""
        self.gradeReasons    = (try? c.decode([String].self, forKey: .gradeReasons))    ?? []
        self.isHeated        = (try? c.decode(Bool.self,     forKey: .isHeated))        ?? false
        self.heatSignals     = (try? c.decode([String].self, forKey: .heatSignals))     ?? []
    }
}

struct SessionGradeDistribution: Codable, Identifiable {
    var id: String { grade }
    let grade: String
    let count: Int
    let percent: Double
}

struct SessionDetectionResult: Codable {
    let sessions: [DetectedSession]
    let totalSessions: Int
    let avgSessionDuration: Double
    let sessionGradeDistribution: [SessionGradeDistribution]
    let heatedSessionCount: Int
    let heatedSessionPercent: Double
    let insight: String
}

struct BetAnnotation: Codable, Identifiable {
    var id: Int { betIndex }
    let betIndex: Int
    let classification: BetClassification
    let confidence: Double
    let primaryReason: String
    let sessionGrade: String?
    let isInHeatedSession: Bool
}

struct ClassificationStats: Codable, Identifiable {
    var id: String { classification.rawValue }
    let classification: BetClassification
    let count: Int
    let percent: Double
    let totalStaked: Double
    let totalProfit: Double
    let roi: Double
}

struct AnnotationSummary: Codable {
    let annotations: [BetAnnotation]
    let distribution: [ClassificationStats]
    let emotionalCost: Double
    let insight: String

    init(annotations: [BetAnnotation], distribution: [ClassificationStats],
         emotionalCost: Double, insight: String) {
        self.annotations = annotations
        self.distribution = distribution
        self.emotionalCost = emotionalCost
        self.insight = insight
    }

    private enum CodingKeys: String, CodingKey {
        case annotations, distribution, emotionalCost, insight
    }

    /// Helper used when backend ships `distribution` as a dict keyed by
    /// classification name (vs an array of {classification, ...} objects).
    private struct DistributionEntry: Decodable {
        let count: Int
        let percent: Double
        let totalStaked: Double
        let totalProfit: Double
        let roi: Double
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.annotations = (try? container.decode([BetAnnotation].self, forKey: .annotations)) ?? []
        self.emotionalCost = (try? container.decode(Double.self, forKey: .emotionalCost)) ?? 0
        self.insight = (try? container.decode(String.self, forKey: .insight)) ?? ""

        if let arr = try? container.decode([ClassificationStats].self, forKey: .distribution) {
            self.distribution = arr
        } else if let dict = try? container.decode([String: DistributionEntry].self, forKey: .distribution) {
            self.distribution = dict.compactMap { key, entry in
                guard let classification = BetClassification(rawValue: key) else { return nil }
                return ClassificationStats(
                    classification: classification,
                    count: entry.count,
                    percent: entry.percent,
                    totalStaked: entry.totalStaked,
                    totalProfit: entry.totalProfit,
                    roi: entry.roi
                )
            }
        } else {
            self.distribution = []
        }
    }
}

struct SportSpecificFinding: Codable, Identifiable {
    var id: String { findingId ?? "\(sport)_\(name)" }
    let findingId: String?
    let name: String
    let sport: String
    let severity: BiasSeverity
    let description: String
    let evidence: String
    let estimatedCost: Double?
    let recommendation: String

    // Engine V2 additive visibility tag (see BiasDetected for semantics).
    let estimatedCostVisibility: String?

    init(
        findingId: String?,
        name: String,
        sport: String,
        severity: BiasSeverity,
        description: String,
        evidence: String,
        estimatedCost: Double?,
        recommendation: String,
        estimatedCostVisibility: String? = nil
    ) {
        self.findingId = findingId
        self.name = name
        self.sport = sport
        self.severity = severity
        self.description = description
        self.evidence = evidence
        self.estimatedCost = estimatedCost
        self.recommendation = recommendation
        self.estimatedCostVisibility = estimatedCostVisibility
    }
}

struct DFSPickCountRow: Codable, Identifiable {
    var id: Int { picks }
    let picks: Int
    let count: Int
    let roi: Double
    let profit: Double
    let winRate: Double
}

struct PowerVsFlex: Codable {
    let powerCount: Int
    let powerROI: Double
    let powerProfit: Double
    let flexCount: Int
    let flexROI: Double
    let flexProfit: Double
}

struct DFSMetrics: Codable {
    let pickCountDistribution: [DFSPickCountRow]
    let powerVsFlex: PowerVsFlex?
    let avgPickCount: Double
    let pickCountAfterLoss: Double
    let pickCountAfterWin: Double
}

struct PertinentNegative: Codable, Identifiable {
    var id: String { pattern }
    let pattern: String
    let finding: String
    let detail: String
    let populationPercent: Double
}

struct Contradiction: Codable, Identifiable {
    var id: String { title }
    let title: String
    let insight: String
    let volumeLabel: String
    let volumeData: String
    let edgeLabel: String
    let edgeData: String
    let annualCost: Double?
}

// MARK: - Snapshot side-channel (PR-7.5 Phase 2)
//
// Snapshot responses ship two extra fields on `report_json` describing
// what the full paid report would contain: `_snapshot_teaser` lists the
// names + severities of withheld biases (and grade/leak previews we
// don't surface in v1), `_snapshot_counts` rolls up category totals.
// Backend omits both for full-paid responses; optional decoding handles
// that cleanly.

struct TeaserBias: Codable, Identifiable {
    let name: String
    let severity: BiasSeverity

    var id: String { name }
}

struct SnapshotTeaser: Codable {
    let biasNames: [TeaserBias]
    // sessionGrades, leakCategories, heatedSessionCount also on wire;
    // intentionally not decoded in v1 — add when a surface needs them.
}

struct SnapshotCounts: Codable {
    let totalBiases: Int
    let leaks: Int
    let patterns: Int
    let sessions: Int
    let sportFindings: Int
}

struct BettingArchetypeData: Codable {
    let name: String
    let description: String

    var color: Color {
        switch name {
        case "The Chaser":         return DS.Color.Archetype.chaser
        case "The Tilter":         return DS.Color.Archetype.tilter
        case "The Sharp":          return DS.Color.Archetype.sharp
        case "The Lottery Bettor": return DS.Color.Archetype.lotteryBettor
        case "The Grinder":        return DS.Color.Archetype.grinder
        case "The Action Junkie":  return DS.Color.Archetype.actionJunkie
        default:                   return DS.Color.Archetype.methodical
        }
    }
}

// MARK: - Longitudinal memory (PR-WHATCHANGED)
//
// Optional diff payload comparing this report to the user's previous
// report. Omitted entirely by the backend on first reports; iOS treats
// the entire whatChanged field as optional and renders nothing when nil.

struct ArchetypeChange: Codable {
    let from: String
    let to: String
}

enum BetIQDirection: String, Codable {
    case improved
    case regressed
    case stable
}

struct BetIQDelta: Codable {
    let from: Int
    let to: Int
    let direction: BetIQDirection
}

enum ImpactConfidence: String, Codable {
    case high
    case medium
    case low
}

struct ImpactDelta: Codable, Identifiable {
    var id: String { biasName }
    let biasName: String
    let previousImpact: Double
    let currentImpact: Double
    let deltaPercent: Int
    let confidence: ImpactConfidence
}

struct WhatChanged: Codable {
    let previousReportDate: String
    let daysSincePrevious: Int
    let archetypeChange: ArchetypeChange?
    let betIQDelta: BetIQDelta?
    let topImpactDeltas: [ImpactDelta]?
}

// MARK: - Top-level analysis

struct AutopsyAnalysis: Codable {
    let schemaVersion: Int?
    let summary: AutopsySummary
    let biasesDetected: [BiasDetected]
    let strategicLeaks: [StrategicLeak]
    let behavioralPatterns: [BehavioralPattern]
    let recommendations: [Recommendation]
    let emotionScore: Int
    let emotionBreakdown: EmotionBreakdown?
    let bankrollHealth: BankrollHealth
    let disciplineScore: DisciplineScore?
    let betiq: BetIQResult?
    let enhancedTilt: EnhancedTiltResult?
    let timingAnalysis: TimingAnalysis?
    let oddsAnalysis: OddsAnalysis?
    let sessionDetection: SessionDetectionResult?
    let betAnnotations: AnnotationSummary?
    let sportSpecificFindings: [SportSpecificFinding]?
    let dfsMode: Bool
    let dfsPlatform: String?
    let dfsMetrics: DFSMetrics?
    let executiveDiagnosis: String?
    let pertinentNegatives: [PertinentNegative]?
    let contradictions: [Contradiction]?
    let bettingArchetype: BettingArchetypeData?
    let quizArchetype: String?
    let snapshotTeaser: SnapshotTeaser?
    let snapshotCounts: SnapshotCounts?
    let whatChanged: WhatChanged?

    init(schemaVersion: Int?, summary: AutopsySummary,
         biasesDetected: [BiasDetected], strategicLeaks: [StrategicLeak],
         behavioralPatterns: [BehavioralPattern], recommendations: [Recommendation],
         emotionScore: Int, emotionBreakdown: EmotionBreakdown?,
         bankrollHealth: BankrollHealth, disciplineScore: DisciplineScore?,
         betiq: BetIQResult?, enhancedTilt: EnhancedTiltResult?,
         timingAnalysis: TimingAnalysis?, oddsAnalysis: OddsAnalysis?,
         sessionDetection: SessionDetectionResult?, betAnnotations: AnnotationSummary?,
         sportSpecificFindings: [SportSpecificFinding]?, dfsMode: Bool,
         dfsPlatform: String?, dfsMetrics: DFSMetrics?,
         executiveDiagnosis: String?, pertinentNegatives: [PertinentNegative]?,
         contradictions: [Contradiction]?, bettingArchetype: BettingArchetypeData?,
         quizArchetype: String?,
         snapshotTeaser: SnapshotTeaser? = nil,
         snapshotCounts: SnapshotCounts? = nil,
         whatChanged: WhatChanged? = nil) {
        self.schemaVersion = schemaVersion
        self.summary = summary
        self.biasesDetected = biasesDetected
        self.strategicLeaks = strategicLeaks
        self.behavioralPatterns = behavioralPatterns
        self.recommendations = recommendations
        self.emotionScore = emotionScore
        self.emotionBreakdown = emotionBreakdown
        self.bankrollHealth = bankrollHealth
        self.disciplineScore = disciplineScore
        self.betiq = betiq
        self.enhancedTilt = enhancedTilt
        self.timingAnalysis = timingAnalysis
        self.oddsAnalysis = oddsAnalysis
        self.sessionDetection = sessionDetection
        self.betAnnotations = betAnnotations
        self.sportSpecificFindings = sportSpecificFindings
        self.dfsMode = dfsMode
        self.dfsPlatform = dfsPlatform
        self.dfsMetrics = dfsMetrics
        self.executiveDiagnosis = executiveDiagnosis
        self.pertinentNegatives = pertinentNegatives
        self.contradictions = contradictions
        self.bettingArchetype = bettingArchetype
        self.quizArchetype = quizArchetype
        self.snapshotTeaser = snapshotTeaser
        self.snapshotCounts = snapshotCounts
        self.whatChanged = whatChanged
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, summary, biasesDetected, strategicLeaks
        case behavioralPatterns, recommendations, emotionScore, emotionBreakdown
        case bankrollHealth, disciplineScore, betiq, enhancedTilt
        case timingAnalysis, oddsAnalysis, sessionDetection, betAnnotations
        case sportSpecificFindings, dfsMode, dfsPlatform, dfsMetrics
        case executiveDiagnosis, pertinentNegatives, contradictions
        case bettingArchetype, quizArchetype
        // Backend snapshot side-channel. Leading underscore on the wire
        // survives the convertFromSnakeCase strategy (it strips internal
        // underscores only, not leading), so the post-conversion form is
        // _snapshotTeaser / _snapshotCounts. Explicit raw values pin the
        // match.
        case snapshotTeaser = "_snapshotTeaser"
        case snapshotCounts = "_snapshotCounts"
        case whatChanged
    }

    /// Tolerant decoder. Every nested struct is wrapped in `try?` so any
    /// single-field shape mismatch from the backend collapses to nil or
    /// an empty default instead of blowing up the whole AutopsyAnalysis
    /// decode. Required scalars fall back to neutral defaults.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.schemaVersion        = try? c.decode(Int.self, forKey: .schemaVersion)
        self.summary              = (try? c.decode(AutopsySummary.self, forKey: .summary))
            ?? AutopsySummary(totalBets: 0, record: "", totalProfit: 0,
                              roiPercent: 0, avgStake: 0, dateRange: "",
                              overallGrade: "")
        self.biasesDetected       = (try? c.decode([BiasDetected].self, forKey: .biasesDetected)) ?? []
        self.strategicLeaks       = (try? c.decode([StrategicLeak].self, forKey: .strategicLeaks)) ?? []
        self.behavioralPatterns   = (try? c.decode([BehavioralPattern].self, forKey: .behavioralPatterns)) ?? []
        self.recommendations      = (try? c.decode([Recommendation].self, forKey: .recommendations)) ?? []
        self.emotionScore         = (try? c.decode(Int.self, forKey: .emotionScore)) ?? 0
        self.emotionBreakdown     = try? c.decode(EmotionBreakdown.self, forKey: .emotionBreakdown)
        self.bankrollHealth       = (try? c.decode(BankrollHealth.self, forKey: .bankrollHealth)) ?? .healthy
        self.disciplineScore      = try? c.decode(DisciplineScore.self, forKey: .disciplineScore)
        self.betiq                = try? c.decode(BetIQResult.self, forKey: .betiq)
        self.enhancedTilt         = try? c.decode(EnhancedTiltResult.self, forKey: .enhancedTilt)
        self.timingAnalysis       = try? c.decode(TimingAnalysis.self, forKey: .timingAnalysis)
        self.oddsAnalysis         = try? c.decode(OddsAnalysis.self, forKey: .oddsAnalysis)
        self.sessionDetection     = try? c.decode(SessionDetectionResult.self, forKey: .sessionDetection)
        self.betAnnotations       = try? c.decode(AnnotationSummary.self, forKey: .betAnnotations)
        self.sportSpecificFindings = try? c.decode([SportSpecificFinding].self, forKey: .sportSpecificFindings)
        self.dfsMode              = (try? c.decode(Bool.self, forKey: .dfsMode)) ?? false
        self.dfsPlatform          = try? c.decode(String.self, forKey: .dfsPlatform)
        self.dfsMetrics           = try? c.decode(DFSMetrics.self, forKey: .dfsMetrics)
        self.executiveDiagnosis   = try? c.decode(String.self, forKey: .executiveDiagnosis)
        self.pertinentNegatives   = try? c.decode([PertinentNegative].self, forKey: .pertinentNegatives)
        self.contradictions       = try? c.decode([Contradiction].self, forKey: .contradictions)
        self.bettingArchetype     = try? c.decode(BettingArchetypeData.self, forKey: .bettingArchetype)
        self.quizArchetype        = try? c.decode(String.self, forKey: .quizArchetype)
        self.snapshotTeaser       = try? c.decode(SnapshotTeaser.self, forKey: .snapshotTeaser)
        self.snapshotCounts       = try? c.decode(SnapshotCounts.self, forKey: .snapshotCounts)
        self.whatChanged          = try? c.decode(WhatChanged.self, forKey: .whatChanged)
    }
}

struct AutopsyReport: Codable, Identifiable {
    let id: String
    let caseNumber: String
    let reportType: String
    let betCountAnalyzed: Int
    let dateRangeStart: String?
    let dateRangeEnd: String?
    let createdAt: String
    let analysis: AutopsyAnalysis
}

// MARK: - Display helpers

func formatCurrency(_ value: Double, signed: Bool = false) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    let absVal = abs(value)
    let absStr = formatter.string(from: NSNumber(value: Int(absVal))) ?? "0"
    if signed {
        let sign = value >= 0 ? "+" : "-"
        return "\(sign)$\(absStr)"
    } else {
        return value < 0 ? "-$\(absStr)" : "$\(absStr)"
    }
}

func formatPct(_ value: Double, signed: Bool = false, decimals: Int = 0) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = decimals
    formatter.minimumFractionDigits = decimals
    let str = formatter.string(from: NSNumber(value: abs(value))) ?? "0"
    if signed {
        let sign = value >= 0 ? "+" : "-"
        return "\(sign)\(str)%"
    } else {
        return value < 0 ? "-\(str)%" : "\(str)%"
    }
}

// MARK: - Shared views

struct SeverityChip: View {
    let severity: BiasSeverity
    var body: some View {
        Text(severity.displayLabel)
            .font(.custom("JetBrainsMono-Regular", size: 10))
            .tracking(10 * 0.15)
            .foregroundStyle(severity.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(severity.color.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tile))
    }
}

struct LabelChip: View {
    let text: String
    let color: Color
    var bgOpacity: Double = 0.18

    var body: some View {
        Text(text)
            .font(.custom("JetBrainsMono-Regular", size: 10))
            .tracking(10 * 0.15)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(bgOpacity))
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tile))
    }
}

