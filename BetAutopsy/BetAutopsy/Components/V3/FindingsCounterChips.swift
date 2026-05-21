//
//  FindingsCounterChips.swift
//  BetAutopsy
//
//  Chapter 4 header element: a "We found N findings." line over three
//  count chips (biases / leaks / patterns).
//
//  Counts come from snapshotCounts in snapshot mode (the engine's
//  pre-redaction tallies) and from the decoded analysis arrays in full
//  mode. iOS has no `summaryCounts` wire field, so full-mode counts are
//  read directly off biasesDetected / strategicLeaks / behavioralPatterns.
//
//  Chips lay out horizontally on iPhone. Numbers use JetBrains Mono per
//  the type system.
//

import SwiftUI

struct FindingsCounterChips: View {
    let report: AutopsyReport

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var biasCount: Int {
        if isSnapshot, let c = report.analysis.snapshotCounts { return c.totalBiases }
        return report.analysis.biasesDetected.count
    }

    private var leakCount: Int {
        if isSnapshot, let c = report.analysis.snapshotCounts { return c.leaks }
        return report.analysis.strategicLeaks.count
    }

    private var patternCount: Int {
        if isSnapshot, let c = report.analysis.snapshotCounts { return c.patterns }
        return report.analysis.behavioralPatterns.count
    }

    private var totalFindings: Int { biasCount + leakCount + patternCount }

    var body: some View {
        if totalFindings > 0 {
            VStack(alignment: .leading, spacing: 10) {
                Text("We found \(totalFindings.pluralized("finding", "findings")).")
                    .font(DS.Font.V3.sectionTitle)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    chip(count: biasCount, label: biasCount == 1 ? "bias" : "biases")
                    chip(count: leakCount, label: leakCount == 1 ? "leak" : "leaks")
                    chip(count: patternCount, label: patternCount == 1 ? "pattern" : "patterns")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                "We found \(totalFindings) findings: \(biasCount) biases, \(leakCount) leaks, \(patternCount) patterns."
            )
        }
    }

    private func chip(count: Int, label: String) -> some View {
        HStack(spacing: 6) {
            Text("\(count)")
                .font(.custom("JetBrainsMono-Bold", size: 15))
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textPrimary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DS.Color.V3.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DS.Color.V3.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.tile, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tile, style: .continuous))
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 24) {
        FindingsCounterChips(report: MockReport.heatedBettor)
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
