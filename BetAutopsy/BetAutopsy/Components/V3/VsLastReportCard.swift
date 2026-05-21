//
//  VsLastReportCard.swift
//  BetAutopsy
//
//  Chapter 1 longitudinal card: how the three headline scores moved
//  since the previous report, plus which biases are newly flagged.
//
//  Data source (REBUILD-PHASE-1, D1 thesis): the wire `whatChanged`
//  envelope only carries a BetIQ delta, so Emotion and Discipline deltas
//  and the new-bias set are computed CLIENT-SIDE by diffing this report's
//  analysis against the previous report's analysis. The host resolves the
//  previous report from ReportStore (skipping the snapshot/full twin of
//  the same upload) and passes its analysis in; the card hides entirely
//  when there is nothing to show.
//
//  This is NOT a duplicate of WhatChangedCard: that card RENDERS wire
//  deltas (archetype shift, BetIQ points, top impact shifts); this card
//  COMPUTES a score triplet + new-bias diff. No shared delta business
//  logic exists to reuse, so the chip/arrow rendering is local and styled
//  to match WhatChangedCard's idiom.
//
//  Direction semantics: Emotion is inverted (lower is better), so a drop
//  reads as an improvement (green down-arrow). Discipline and BetIQ are
//  higher-is-better. Sign characters (arrows + signed values) carry the
//  meaning so the red/green coding is not load-bearing for colorblind
//  readers.
//

import SwiftUI

struct VsLastReportCard: View {
    let current: AutopsyAnalysis
    let previous: AutopsyAnalysis

    // MARK: - Score-delta model

    private struct ScoreDelta: Identifiable {
        let id = UUID()
        let label: String
        let from: Int
        let to: Int
        /// Lower-is-better metric (Emotion). Flips improvement coloring.
        let lowerIsBetter: Bool

        var diff: Int { to - from }
        var improved: Bool { lowerIsBetter ? diff < 0 : diff > 0 }
    }

    /// The deltas worth showing. A metric is dropped when either side is
    /// flagged insufficient_data, or when the previous value is 0 (which
    /// reads as an absent/baseline value rather than a measured score), or
    /// when there is no movement.
    private var scoreDeltas: [ScoreDelta] {
        var out: [ScoreDelta] = []

        // Emotion (lower is better).
        if current.emotionScoreInsufficientData != true,
           previous.emotionScoreInsufficientData != true,
           previous.emotionScore > 0,
           current.emotionScore != previous.emotionScore {
            out.append(ScoreDelta(
                label: "EMOTION",
                from: previous.emotionScore,
                to: current.emotionScore,
                lowerIsBetter: true
            ))
        }

        // Discipline (higher is better).
        if let cur = current.disciplineScore, cur.insufficientData != true,
           let prev = previous.disciplineScore, prev.insufficientData != true,
           prev.total > 0, cur.total != prev.total {
            out.append(ScoreDelta(
                label: "DISCIPLINE",
                from: prev.total,
                to: cur.total,
                lowerIsBetter: false
            ))
        }

        // BetIQ (higher is better).
        if let cur = current.betiq, !cur.insufficientData,
           let prev = previous.betiq, !prev.insufficientData,
           prev.score > 0, cur.score != prev.score {
            out.append(ScoreDelta(
                label: "BETIQ",
                from: prev.score,
                to: cur.score,
                lowerIsBetter: false
            ))
        }

        return out
    }

    /// Bias names present now but absent in the previous report.
    private var newBiasNames: [String] {
        let prior = Set(previous.biasesDetected.map { $0.biasName })
        return current.biasesDetected
            .map { $0.biasName }
            .filter { !prior.contains($0) }
    }

    /// Top impact shifts, absorbed from the retired WhatChangedCard
    /// (REBUILD-PHASE-2 Step 5). Read from the wire whatChanged envelope.
    /// Drops self-contradictory -100% entries on a bias still active in
    /// this report (WhatChangedCard's blocker #4 filter).
    private var visibleImpactDeltas: [ImpactDelta] {
        let activeBiasNames = Set(current.biasesDetected.map { $0.biasName })
        return (current.whatChanged?.topImpactDeltas ?? []).filter { delta in
            !(delta.deltaPercent == -100 && activeBiasNames.contains(delta.biasName))
        }
    }

    private var hasContent: Bool {
        !scoreDeltas.isEmpty || !newBiasNames.isEmpty || !visibleImpactDeltas.isEmpty
    }

    var body: some View {
        if hasContent {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                ForEach(scoreDeltas) { delta in
                    V3Divider()
                    scoreRow(delta)
                }

                if !newBiasNames.isEmpty {
                    V3Divider()
                    newBiasSection
                }

                if !visibleImpactDeltas.isEmpty {
                    V3Divider()
                    impactSection
                }
            }
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("VS LAST REPORT")
            .font(.system(size: 10, weight: .semibold))
            .tracking(10 * 0.18)
            .foregroundStyle(DS.Color.V3.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Score row

    private func scoreRow(_ delta: ScoreDelta) -> some View {
        let color = delta.improved ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red
        let arrow = delta.diff > 0 ? "arrow.up" : "arrow.down"

        return HStack(spacing: 10) {
            Text(delta.label)
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.1)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(delta.from) \u{2192} \(delta.to)")
                .font(DS.Font.V3.captionLabel)
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textSecondary)

            HStack(spacing: 4) {
                Image(systemName: arrow)
                    .font(.system(size: 10, weight: .bold))
                Text(signedString(delta.diff))
                    .font(.system(size: 11, weight: .bold))
                    .monospacedDigit()
            }
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(delta.label) \(delta.improved ? "improved" : "regressed"), from \(delta.from) to \(delta.to)"
        )
    }

    // MARK: - New-bias section

    private var newBiasSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NEWLY FLAGGED")
                .font(.system(size: 10, weight: .semibold))
                .tracking(10 * 0.18)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .padding(.bottom, 2)

            ForEach(newBiasNames, id: \.self) { name in
                HStack(spacing: 8) {
                    Text(name)
                        .font(DS.Font.V3.bodyRegular)
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .fixedSize(horizontal: false, vertical: true)

                    LabelChip(text: "NEW", color: DS.Color.V3.Severity.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Top impact shifts (absorbed from WhatChangedCard)

    private var impactSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TOP IMPACT SHIFTS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(10 * 0.18)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 14)
                .padding(.bottom, 6)

            ForEach(visibleImpactDeltas) { delta in
                impactRow(delta)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 14)
    }

    private func impactRow(_ delta: ImpactDelta) -> some View {
        HStack(spacing: 10) {
            Text(delta.biasName)
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(signedPercentString(delta.deltaPercent))
                .font(DS.Font.V3.rowValue)
                .monospacedDigit()
                .foregroundStyle(impactColor(delta.deltaPercent))

            Text(delta.confidence.rawValue.uppercased())
                .font(DS.Font.V3.captionLabel)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(delta.biasName), \(signedPercentString(delta.deltaPercent)), \(delta.confidence.rawValue) confidence"
        )
    }

    /// Negative delta = bias cost dropped = improvement = green.
    private func impactColor(_ deltaPercent: Int) -> Color {
        if deltaPercent < 0 { return DS.Color.V3.Severity.green }
        if deltaPercent > 0 { return DS.Color.V3.Severity.red }
        return DS.Color.V3.textTertiary
    }

    private func signedPercentString(_ value: Int) -> String {
        if value > 0 { return "+\(value)%" }
        if value < 0 { return "\u{2212}\(abs(value))%" }
        return "0%"
    }

    private func signedString(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        if value < 0 { return "\u{2212}\(abs(value))" }
        return "0"
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        VsLastReportCard(
            current: MockReport.heatedBettor.analysis,
            previous: MockReport.heatedBettor.analysis
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
