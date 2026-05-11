//
//  ReportModels.swift
//  BetAutopsy
//
//  Canonical Codable shapes for AutopsyAnalysis + report wrappers.
//  Shared chapter chrome (ChapterHeader, SeverityChip, LabelChip).
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
        case .critical: return DS.Color.Semantic.blood
        case .high:     return DS.Color.Semantic.blood.opacity(0.85)
        case .medium:   return DS.Color.Accent.luminol
        case .low:      return DS.Color.Text.tertiary
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
        case .healthy: return DS.Color.Semantic.win
        case .caution: return DS.Color.Accent.luminol
        case .danger:  return DS.Color.Semantic.blood
        }
    }
}

enum BetClassification: String, Codable {
    case disciplined, emotional, chasing, impulsive, neutral
    var color: Color {
        switch self {
        case .disciplined: return DS.Color.Semantic.win
        case .emotional:   return DS.Color.Accent.luminol
        case .chasing:     return DS.Color.Semantic.blood
        case .impulsive:   return DS.Color.Semantic.blood.opacity(0.85)
        case .neutral:     return DS.Color.Text.tertiary
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
}

struct BetIQResult: Codable {
    let score: Int
    let components: BetIQComponents
    let percentile: Int
    let interpretation: String
    let insufficientData: Bool
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
}

struct SportSpecificFinding: Codable, Identifiable {
    var id: String { findingId }
    let findingId: String
    let name: String
    let sport: String
    let severity: BiasSeverity
    let description: String
    let evidence: String
    let estimatedCost: Double?
    let recommendation: String
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

struct BettingArchetypeData: Codable {
    let name: String
    let description: String

    var color: Color {
        switch name {
        case "The Natural":     return DS.Color.Archetype.natural
        case "Sharp Sleeper":   return DS.Color.Archetype.sharpSleeper
        case "Heated Bettor":   return DS.Color.Archetype.heatedBettor
        case "Chalk Grinder":   return DS.Color.Archetype.chalkGrinder
        case "Parlay Dreamer":  return DS.Color.Archetype.parlayDreamer
        case "Sniper":          return DS.Color.Archetype.sniper
        case "Volume Warrior":  return DS.Color.Archetype.volumeWarrior
        case "Degen King":      return DS.Color.Archetype.degenKing
        default:                return DS.Color.Archetype.grinder
        }
    }
}

// MARK: - Top-level analysis

struct AutopsyAnalysis: Codable {
    let schemaVersion: Int
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

struct ChapterHeader: View {
    let chipText: String
    let alertChip: (text: String, color: Color)?
    let title: String
    let pullQuote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                LabelChip(text: chipText, color: DS.Color.Text.tertiary, bgOpacity: 0.0)
                    .background(DS.Color.Surface.raised)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tile))

                if let alert = alertChip {
                    LabelChip(text: alert.text, color: alert.color)
                }
            }

            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .multilineTextAlignment(.leading)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 16)

            if let quote = pullQuote {
                HStack(alignment: .top, spacing: 12) {
                    Rectangle()
                        .fill(DS.Color.Accent.luminol)
                        .frame(width: 2)

                    Text(quote)
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundStyle(DS.Color.Text.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 16)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
