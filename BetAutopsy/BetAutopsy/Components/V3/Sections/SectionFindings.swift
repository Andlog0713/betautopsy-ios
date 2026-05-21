//
//  SectionFindings.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2: single-scroll section extracted verbatim from
//  ChapterYourBiasesView (Ch4). Strips the ScrollView wrapper, the
//  ChapterNavigator chrome, the canvas background, and the per-chapter
//  PaywallView sheet. The "SEE THE PATTERNS" chapter-advance CTA is now
//  prose-only.
//
//  The Phase 1 RepeatedCTABlock(.mid) that lived at the bottom of this
//  chapter is REMOVED here: the container owns the .mid CTAs (one after
//  Verdict, one after Findings), so keeping the section-internal one would
//  render two adjacent .mid CTAs. The BiasEvidenceSheet (section-local UI
//  state) is preserved.
//

import SwiftUI

struct SectionFindings: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    @State private var expandedBias: BiasDetected?

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var materialBiases: [BiasDetected] {
        if isSnapshot {
            return Array(
                report.analysis.biasesDetected
                    .sorted { $0.severity.sortOrder > $1.severity.sortOrder }
                    .prefix(3)
            )
        }
        return report.analysis.biasesDetected
            .filter { $0.estimatedCost > 0 }
            .sorted { $0.estimatedCost > $1.estimatedCost }
    }

    private var maxCost: Double {
        materialBiases.map { $0.estimatedCost }.max() ?? 1
    }

    private struct BiasRowEntry: Identifiable {
        var id: UUID { row.id }
        let row: BiasRow.Bias
        let source: BiasDetected
    }

    private var biasRowEntries: [BiasRowEntry] {
        let useFixedWidths = isSnapshot || materialBiases.count == 1
        return materialBiases.map { bias in
            let lockedCost = isSnapshot
                || bias.estimatedCostVisibility == "redacted_dollar"
                || bias.estimatedCost == 0
            let evidenceVisible = bias.evidenceVisibility != "hidden"
            let row = BiasRow.Bias(
                biasName: bias.biasName.uppercased(),
                costAbs: Int(abs(bias.estimatedCost).rounded()),
                severityLabel: severityCaps(bias.severity),
                severityColor: severityColor(bias.severity),
                widthRatio: useFixedWidths
                    ? fixedSeverityWidth(bias.severity)
                    : (maxCost > 0 ? abs(bias.estimatedCost) / maxCost : 0),
                evidence: bias.evidence,
                evidenceVisible: evidenceVisible,
                translation: bias.description,
                fix: bias.fix,
                isLockedCost: lockedCost
            )
            return BiasRowEntry(row: row, source: bias)
        }
    }

    private func fixedSeverityWidth(_ severity: BiasSeverity) -> Double {
        switch severity {
        case .critical: return 1.0
        case .high:     return 0.66
        case .medium:   return 0.40
        case .low:      return 0.20
        }
    }

    private var pertinentNegatives: [PertinentNegative] {
        Array(
            (report.analysis.pertinentNegatives ?? [])
                .filter { item in
                    let f = item.finding.trimmingCharacters(in: .whitespacesAndNewlines)
                    return !f.isEmpty && !f.lowercased().contains("not detected")
                }
                .prefix(3)
        )
    }

    private var strategicLeaks: [StrategicLeak] {
        Array(report.analysis.strategicLeaks.prefix(5))
    }

    var body: some View {
        VStack(spacing: 0) {
            FindingsCounterChips(report: report)
                .padding(.horizontal, 16)

            if !strategicLeaks.isEmpty {
                Spacer().frame(height: 24)

                Text("WHERE YOU BLEED")
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.5)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 12)

                VStack(spacing: 12) {
                    ForEach(strategicLeaks) { leak in
                        StrategicLeakCard(
                            leak: leak,
                            isLockedDetail: isSnapshot,
                            onLockedTap: { onPaywallTap("section_findings_strategic_leak_locked") }
                        )
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 24)
                V3Divider()
                    .padding(.horizontal, 16)
            }

            if !biasRowEntries.isEmpty {
                Spacer().frame(height: 24)
                biasCard
                    .padding(.horizontal, 16)
            }

            if !pertinentNegatives.isEmpty {
                Spacer().frame(height: 28)

                Text("WHAT YOU'RE DOING RIGHT")
                    .font(DS.Font.V3.navigatorSubtitle)
                    .tracking(1.8)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 12)

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(pertinentNegatives) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.pattern.uppercased())
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(1.1)
                                .foregroundStyle(DS.Color.V3.textTertiary)
                            Text(item.finding)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(DS.Color.V3.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            }
            // Exec-diagnosis InsightCallout removed (Q3 dedup): it duplicated
            // SectionVerdict's insight. Section-specific prose is unaffected.
        }
        .frame(maxWidth: .infinity)
        .sheet(item: $expandedBias) { bias in
            BiasEvidenceSheet(
                bias: bias,
                isSnapshot: isSnapshot,
                onLockedTap: { onPaywallTap("section_findings_bias_locked") }
            )
        }
    }

    private var biasCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(biasRowEntries.enumerated()), id: \.element.id) { index, entry in
                biasRowView(for: entry)
                if index < biasRowEntries.count - 1 {
                    V3Divider()
                        .padding(.horizontal, 16)
                }
            }
        }
        .padding(.vertical, 2)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func biasRowView(for entry: BiasRowEntry) -> some View {
        BiasRow(
            bias: entry.row,
            onLockedTap: { onPaywallTap("section_findings_bias_locked") },
            onTap: { handleBiasRowTap(entry.source) }
        )
        .padding(.horizontal, 16)
    }

    private func handleBiasRowTap(_ bias: BiasDetected) {
        Analytics.signal(
            "ch4.bias_evidence.opened",
            parameters: ["bias_name": bias.biasName]
        )
        expandedBias = bias
    }

    private func severityCaps(_ severity: BiasSeverity) -> String {
        switch severity {
        case .critical: return "CRITICAL"
        case .high:     return "HIGH"
        case .medium:   return "MEDIUM"
        case .low:      return "LOW"
        }
    }

    private func severityColor(_ severity: BiasSeverity) -> Color {
        switch severity {
        case .critical, .high: return DS.Color.V3.Severity.red
        case .medium:          return DS.Color.V3.Severity.yellow
        case .low:             return DS.Color.V3.textTertiary
        }
    }
}

#Preview {
    ScrollView {
        SectionFindings(report: MockReport.heatedBettor, onPaywallTap: { _ in })
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
