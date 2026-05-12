//
//  ChapterYourBiasesView.swift
//  BetAutopsy
//
//  Chapter 4: biases detected, strategic leaks, and contradictions.
//  Biases sort by severity (critical first), then by estimated cost.
//

import SwiftUI

struct ChapterYourBiasesView: View {
    let report: AutopsyReport

    @State private var showingPaywall: Bool = false

    private var sortedBiases: [BiasDetected] {
        report.analysis.biasesDetected.sorted { a, b in
            if a.severity.sortOrder != b.severity.sortOrder {
                return a.severity.sortOrder > b.severity.sortOrder
            }
            return a.estimatedCost > b.estimatedCost
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ChapterHeader(
                    chipText: "YOUR BIASES",
                    alertChip: (
                        text: "\(report.analysis.biasesDetected.count) DETECTED",
                        color: DS.Color.Semantic.blood
                    ),
                    title: "Five biases are costing you money.",
                    pullQuote: "Loss chasing alone explains 64% of your losses. Three others stack on top."
                )
                .padding(.top, DS.Spacing.md)

                biasSection.padding(.top, DS.Spacing.xl)
                leaksSection.padding(.top, DS.Spacing.xl)
                contradictionsSection.padding(.top, DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, 60)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    // MARK: - Bias section

    private var biasSection: some View {
        VStack(spacing: 12) {
            ForEach(sortedBiases) { bias in
                biasCard(bias)
            }

            // Snapshot mode: after the (single) returned bias, show one
            // teaser card for the first withheld bias name from
            // _snapshot_teaser.biasNames. Empty teaser → render nothing.
            if report.reportType == "snapshot",
               let teaser = report.analysis.snapshotTeaser,
               let firstTeaser = teaser.biasNames.first {
                WithheldBiasTeaserCard(teaserBias: firstTeaser) {
                    Analytics.signal(
                        "paywall.triggered",
                        parameters: ["source": "bias_teaser_card"]
                    )
                    showingPaywall = true
                }
            }
        }
    }

    private func biasCard(_ bias: BiasDetected) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(bias.biasName.uppercased())
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.15)
                    .foregroundStyle(DS.Color.Text.primary)
                Spacer()
                SeverityChip(severity: bias.severity)
            }

            Text(bias.biasName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .padding(.top, 8)

            Text(bias.description)
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(DS.Color.Border.subtle)
                .frame(height: DS.Stroke.hairline)
                .padding(.top, 12)

            Text("EVIDENCE")
                .font(.custom("JetBrainsMono-Regular", size: 9))
                .tracking(9 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, 12)

            Text(bias.evidence)
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("ESTIMATED COST")
                    .font(.custom("JetBrainsMono-Regular", size: 9))
                    .tracking(9 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                Spacer()
                Text(formatCurrency(bias.estimatedCost))
                    .font(.custom("JetBrainsMono-Medium", size: 18))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Semantic.blood)
            }
            .padding(.top, 12)

            Text("FIX")
                .font(.custom("JetBrainsMono-Regular", size: 9))
                .tracking(9 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, 12)

            Text(bias.fix)
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.primary)
                .lineSpacing(3)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Strategic leaks

    private var leaksSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("STRATEGIC LEAKS")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("Specific situations where your edge is upside down.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.bottom, DS.Spacing.xs)

            ForEach(report.analysis.strategicLeaks) { leak in
                leakCard(leak)
            }
        }
    }

    private func leakCard(_ leak: StrategicLeak) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(leak.category.uppercased())
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Semantic.blood)

            Text(leak.detail)
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.Text.primary)
                .lineSpacing(3)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text("ROI \(formatPct(leak.roiImpact, signed: false))")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .monospacedDigit()
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Semantic.blood)
                Spacer()
                Text("\(leak.sampleSize) BETS")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .monospacedDigit()
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
            }
            .padding(.top, 8)

            Text(leak.suggestion)
                .font(.custom("Georgia-Italic", size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Contradictions

    private var contradictionsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text("CONTRADICTIONS")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("Where you do two opposite things in the same dataset.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.bottom, DS.Spacing.xs)

            ForEach(report.analysis.contradictions ?? []) { c in
                contradictionCard(c)
            }
        }
    }

    private func contradictionCard(_ c: Contradiction) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(c.title.uppercased())
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.primary)

            Text(c.insight)
                .font(.custom("Georgia-Italic", size: 16))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(4)
                .padding(.top, 12)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(DS.Color.Border.subtle)
                .frame(height: DS.Stroke.hairline)
                .padding(.top, 12)

            HStack(alignment: .top, spacing: DS.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.volumeLabel.uppercased())
                        .font(.custom("JetBrainsMono-Regular", size: 9))
                        .tracking(9 * 0.15)
                        .foregroundStyle(DS.Color.Text.tertiary)
                    Text(c.volumeData)
                        .font(.custom("JetBrainsMono-Regular", size: 16))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.Text.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(c.edgeLabel.uppercased())
                        .font(.custom("JetBrainsMono-Regular", size: 9))
                        .tracking(9 * 0.15)
                        .foregroundStyle(DS.Color.Text.tertiary)
                    Text(c.edgeData)
                        .font(.custom("JetBrainsMono-Regular", size: 16))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.Text.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 12)

            if let annualCost = c.annualCost {
                Text("ANNUAL COST \(formatCurrency(annualCost))")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .monospacedDigit()
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Semantic.blood)
                    .padding(.top, 8)
            }
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}

// MARK: - Withheld bias teaser card (PR-7.5 Phase 2)

/// Snapshot-only card placed after the returned bias in Chapter 4.
/// Shows the SAME card frame as bias #1 (Surface.card + hairline border
/// + DS.Radius.card corners) so the visual register doesn't drift.
/// The severity badge and name are real (from _snapshot_teaser); the
/// estimated cost is replaced by a solid redaction bar — no character
/// glyphs underneath. Whole card is tappable and triggers the paywall.
private struct WithheldBiasTeaserCard: View {
    let teaserBias: TeaserBias
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(teaserBias.name.uppercased())
                        .font(.custom("JetBrainsMono-Regular", size: 11))
                        .tracking(11 * 0.15)
                        .foregroundStyle(DS.Color.Text.primary)
                    Spacer()
                    SeverityChip(severity: teaserBias.severity)
                }

                Text(teaserBias.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.Color.Text.primary)
                    .padding(.top, 8)

                // Redaction bar where the estimated cost would appear in
                // a full bias card. Width 72pt approximates a 4-figure
                // dollar render at JetBrainsMono-Medium 18pt; height 18pt
                // matches the font size. Solid fill, no characters.
                RoundedRectangle(cornerRadius: 2)
                    .fill(DS.Color.Border.subtle)
                    .frame(width: 72, height: 18)
                    .padding(.top, 16)

                HStack {
                    Text("Read this in your full report")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Color.Text.tertiary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DS.Color.Text.tertiary)
                }
                .padding(.top, 16)
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.Surface.card)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
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
