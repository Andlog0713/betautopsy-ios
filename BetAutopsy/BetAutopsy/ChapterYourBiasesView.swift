//
//  ChapterYourBiasesView.swift
//  BetAutopsy
//
//  Chapter 4: The Bias Sheet.
//
//  Layout (top-to-bottom):
//      ChapterNavigator (no hero ring)
//      ->  Single container card with BiasRow per material bias
//          (tappable expansion shows evidence / translation / fix)
//      ->  Optional snapshot teaser card (paywall trigger, preserved
//          from PR-7.5 Phase 2)
//      ->  WHAT YOU'RE DOING RIGHT section (pertinent negatives)
//      ->  InsightCallout
//
//  Severity color encoding:
//      critical / high  -> DS.Color.V3.Severity.red
//      medium           -> DS.Color.V3.Severity.yellow
//      low              -> DS.Color.V3.textTertiary
//

import SwiftUI

struct ChapterYourBiasesView: View {
    let report: AutopsyReport

    @State private var showingPaywall: Bool = false
    @State private var expandedBias: BiasDetected?

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    /// Snapshot mode: top 3 by severity (engine V2 sorts desc on the
    /// wire). Full mode: filter to estimatedCost > 0 sorted by cost
    /// (existing behavior).
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

    /// Per-row view-model pair: a UI Bias for the row chrome plus the
    /// original BiasDetected so the chapter can pass the source object
    /// into the evidence sheet on tap. UUID id on BiasRow.Bias is the
    /// ForEach identity.
    private struct BiasRowEntry: Identifiable {
        var id: UUID { row.id }
        let row: BiasRow.Bias
        let source: BiasDetected
    }

    private var biasRowEntries: [BiasRowEntry] {
        // With only one material bias, the relative-cost bar reduces
        // to full width regardless of severity, which visually
        // contradicts the severity label. Fall back to a severity-
        // anchored fixed width in that case. Engine V2 ships zero
        // estimatedCost in snapshot mode, so always use severity widths
        // there too.
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
        // Drop empty findings and "not detected" placeholder rows; they
        // read as filler under WHAT YOU'RE DOING RIGHT.
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

    private var insightBody: String {
        (report.analysis.executiveDiagnosis ?? "").firstSentences(2)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ChapterNavigator(chapterNumber: 4, subtitle: "THE BIAS SHEET")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                // REBUILD-PHASE-1: findings tally at the top of the bias
                // sheet. Self-hides when there are no findings.
                Spacer().frame(height: 24)
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
                                onLockedTap: handleStrategicLeakLockedTap
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

                // iOS-PR-SNAPSHOT-RICHER-FOLLOWUP: the PR-7.5 Phase 2
                // WithheldBiasTeaserCard rendered a 4th legacy bias
                // ("Read this in your full report") below the 3-bias
                // container in snapshot mode. The new 3-bias display
                // with first-sentence evidence + LockedDollarBar
                // already carries that story; the legacy teaser was
                // visual redundancy. The WithheldBiasTeaserCard private
                // type is retained at file bottom for now in case full
                // mode ever wants it back; it has zero consumers today.

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

                if !insightBody.isEmpty {
                    Spacer().frame(height: 24)
                    InsightCallout(
                        text: insightBody,
                        ctaLabel: "SEE THE PATTERNS",
                        onTap: handleInsightTap
                    )
                    .padding(.horizontal, 16)
                }

                // REBUILD-PHASE-1: repeated conversion CTA at the bottom of
                // the bias sheet, snapshot mode only.
                if isSnapshot {
                    Spacer().frame(height: 24)
                    RepeatedCTABlock(variant: .mid, onTap: handleRepeatedCTATap)
                        .padding(.horizontal, 16)
                }

                Spacer().frame(height: 60)
            }
            .frame(maxWidth: .infinity)
        }
        .background(canvasGradient.ignoresSafeArea())
        .sheet(isPresented: $showingPaywall) {
            PaywallView(snapshotReportId: report.id)
        }
        .sheet(item: $expandedBias) { bias in
            BiasEvidenceSheet(
                bias: bias,
                isSnapshot: isSnapshot,
                onLockedTap: handleBiasCostTap
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
            onLockedTap: handleBiasCostTap,
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

    private func handleBiasCostTap() {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": "ch4_bias_locked_cost"]
        )
        showingPaywall = true
    }

    private func handleRepeatedCTATap() {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": "ch4_repeated_cta"]
        )
        showingPaywall = true
    }

    private func handleStrategicLeakLockedTap() {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": "ch4_strategic_leak_locked"]
        )
        showingPaywall = true
    }

    private var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                DS.Color.V3.canvasGradientStart,
                DS.Color.V3.canvasGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
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

    private func handleInsightTap() {
        #if DEBUG
        print("InsightCallout tapped on Chapter 4 (V1 stub).")
        #endif
    }
}

// MARK: - Withheld bias teaser card (PR-7.5 Phase 2, preserved)

/// Snapshot-only card placed after the bias list. Shows the name +
/// severity from _snapshot_teaser; replaces the estimated cost with a
/// solid redaction bar. Tapping fires paywall.triggered telemetry and
/// presents the paywall. Preserved verbatim from PR-7.5 Phase 2 except
/// the surface tokens are migrated to V3 to match the new card register.
private struct WithheldBiasTeaserCard: View {
    let teaserBias: TeaserBias
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(teaserBias.name.uppercased())
                        .font(DS.Font.V3.rowCapsLabel)
                        .tracking(1.1)
                        .foregroundStyle(DS.Color.V3.textPrimary)
                    Spacer()
                    SeverityChip(severity: teaserBias.severity)
                }

                Text(teaserBias.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .padding(.top, 8)

                RoundedRectangle(cornerRadius: 2)
                    .fill(DS.Color.V3.borderSubtle)
                    .frame(width: 72, height: 18)
                    .padding(.top, 16)

                HStack {
                    Text("Read this in your full report")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Color.V3.textTertiary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DS.Color.V3.textTertiary)
                }
                .padding(.top, 16)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Withheld bias: \(teaserBias.name), \(teaserBias.severity.rawValue) severity. Tap to read full analysis in your report.")
        .accessibilityHint("Opens paywall")
    }
}

#Preview {
    ChapterYourBiasesView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
