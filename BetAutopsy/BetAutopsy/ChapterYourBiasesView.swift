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

    private var biasRows: [BiasRow.Bias] {
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
            return BiasRow.Bias(
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
        Array((report.analysis.pertinentNegatives ?? []).prefix(3))
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

                if !biasRows.isEmpty {
                    Spacer().frame(height: 24)
                    biasCard
                        .padding(.horizontal, 16)
                }

                // PR-7.5 Phase 2 snapshot teaser: render after the bias
                // list when in snapshot mode. Triggers the paywall.
                if report.reportType == "snapshot",
                   let teaser = report.analysis.snapshotTeaser,
                   let firstTeaser = teaser.biasNames.first {
                    Spacer().frame(height: 12)
                    WithheldBiasTeaserCard(teaserBias: firstTeaser) {
                        Analytics.signal(
                            "paywall.triggered",
                            parameters: ["source": "bias_teaser_card"]
                        )
                        showingPaywall = true
                    }
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

                if !insightBody.isEmpty {
                    Spacer().frame(height: 24)
                    InsightCallout(
                        text: insightBody,
                        ctaLabel: "SEE THE PATTERNS",
                        onTap: handleInsightTap
                    )
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
    }

    private var biasCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(biasRows.enumerated()), id: \.element.id) { index, row in
                biasRowView(for: row)
                if index < biasRows.count - 1 {
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
    private func biasRowView(for row: BiasRow.Bias) -> some View {
        BiasRow(bias: row, onLockedTap: handleBiasCostTap)
            .padding(.horizontal, 16)
    }

    private func handleBiasCostTap() {
        Analytics.signal(
            "paywall.triggered",
            parameters: ["source": "ch4_bias_locked_cost"]
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
