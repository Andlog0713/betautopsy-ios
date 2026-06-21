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

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    // MARK: - Headline counts (3B: StatCard row)
    //
    // Same sources FindingsCounterChips used: snapshotCounts in snapshot
    // mode (the engine's pre-redaction tallies), decoded arrays in full
    // mode. The chips component itself is untouched (Prompt 4 retires it).

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
            // Locked pill is snapshot-only redaction UI; full-mode rows are
            // already filtered to estimatedCost > 0 above, so a paid report
            // never shows a lock here.
            let lockedCost = isSnapshot
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
                isLockedCost: lockedCost,
                subSplits: bias.subSplits,
                confidence: bias.confidence,
                suppressDollars: isSnapshot
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

    /// 3B recovery surface inputs. The fallback mirrors the Verdict hero:
    /// the single largest prioritized leak, never a sum.
    private var largestPrioritizedLeakUSD: Double? {
        TotalRecoverable.ranked(for: report.analysis).first?.costDollars
    }

    private var showRecoverySurface: Bool {
        report.analysis.recovery != nil || (largestPrioritizedLeakUSD ?? 0) > 0
    }

    /// #4 leak prioritizer gate. Full mode needs at least one dollar-bearing
    /// ranked item; snapshot needs a bias or a negative-ROI leak to preview
    /// (costs are locked). Mirrors LeakPrioritizerCard's own emptiness check
    /// so the section header never orphans an empty card.
    private var showLeakPrioritizer: Bool {
        if isSnapshot {
            return !report.analysis.biasesDetected.isEmpty
                || report.analysis.strategicLeaks.contains { $0.roiImpact < 0 }
        }
        return !TotalRecoverable.ranked(for: report.analysis).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // 3B skim layer: headline sentence + StatCard count row
            // (replaces FindingsCounterChips in this section; same data).
            if totalFindings > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("We found \(totalFindings.pluralized("finding", "findings")).")
                        .font(DS.Font.V3.sectionTitle)
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        StatCard(label: "BIASES", value: .count(biasCount))
                        StatCard(label: "LEAKS", value: .count(leakCount))
                        StatCard(label: "PATTERNS", value: .count(patternCount))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "We found \(totalFindings) findings: \(biasCount) biases, \(leakCount) leaks, \(patternCount) patterns."
                )
            }

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

            // #4 leak prioritizer: AFTER the bias rows, BEFORE the clean
            // findings. It synthesizes both the leak and bias streams above
            // into one "fix order" ranking, so it follows both. The framing
            // (FIX IN THIS ORDER) distinguishes it from WHERE YOU BLEED.
            if showLeakPrioritizer {
                Spacer().frame(height: 28)

                Text("FIX IN THIS ORDER")
                    .font(DS.Font.V3.navigatorSubtitle)
                    .tracking(1.8)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 4)

                Text("Your leaks and biases, ranked by impact.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Spacer().frame(height: 12)

                LeakPrioritizerCard(report: report, onPaywallTap: onPaywallTap)
                    .padding(.horizontal, 16)
            }

            // 3B recovery surface: the engine's non-additive recoverable
            // range right after the fix-order list (what to fix -> what
            // fixing it is worth). Full mode only; pre-#74 reports fall
            // back to the single largest prioritized leak, and the spacer
            // is gated with the card so an empty card leaves no gap.
            if !isSnapshot, showRecoverySurface {
                Spacer().frame(height: 16)
                DollarImpactCard(
                    recovery: report.analysis.recovery,
                    fallbackLargestLeakUSD: largestPrioritizedLeakUSD
                )
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

                VStack(alignment: .leading, spacing: 16) {
                    ForEach(pertinentNegatives) { item in
                        cleanFindingRow(item)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

                // #5 footer: provenance line. v1 cannot produce a cross-user
                // cohort comparison, so the prior "population benchmarks /
                // aggregate research" framing was cut (App Store + trust risk:
                // it implied a percentile the engine never computes). This
                // section is derived entirely from the user's own bet history;
                // the line now says exactly that. No cohort language anywhere.
                Text("Based on patterns in your own bet history.")
                    .font(.system(size: 11, weight: .regular))
                    .italic()
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }
            // Exec-diagnosis InsightCallout removed (Q3 dedup): it duplicated
            // SectionVerdict's insight. Section-specific prose is unaffected.
        }
        .frame(maxWidth: .infinity)
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
        // 3B: inline EvidenceBlock expansion replaces the
        // BiasEvidenceSheet presentation. The signal name and parameters
        // are preserved; it now fires on first inline expand.
        BiasRow(
            bias: entry.row,
            onLockedTap: { onPaywallTap("section_findings_bias_locked") },
            onExpanded: {
                Analytics.signal(
                    "ch4.bias_evidence.opened",
                    parameters: ["bias_name": entry.source.biasName]
                )
            }
        )
        .padding(.horizontal, 16)
    }

    /// #5 clean-finding row. Web shows pattern (win-colored), finding, and
    /// detail (AutopsyReport.tsx 1603-1608). iOS previously rendered only
    /// pattern + finding; this adds the detail line (which carries the
    /// population benchmark sentence) and lifts the label to the win color.
    @ViewBuilder
    private func cleanFindingRow(_ item: PertinentNegative) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.pattern.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.1)
                .foregroundStyle(DS.Color.V3.Severity.green)
            Text(item.finding)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            if !item.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(item.detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
