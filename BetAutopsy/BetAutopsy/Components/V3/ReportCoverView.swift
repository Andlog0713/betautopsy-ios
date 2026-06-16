//
//  ReportCoverView.swift
//  BetAutopsy
//
//  Prompt 4 / Stage B: the opening movement of the report. Bold
//  editorial restraint - one dominant typographic spine (the archetype
//  name), one hero number (the net dollar landing beat), grade +
//  percentile as quiet supporting marks, the y-mark as a signature.
//  Dark, full-bleed, generous negative space; it is a cover, it breathes.
//
//  It is the first item in the report scroll content (above
//  SectionVerdict), not a separate takeover - you scroll past it into
//  the verdict. It renders in BOTH modes:
//    full     - net resolved, grade + percentile shown (the paid payoff)
//    snapshot - net BLURRED as the hook, grade + percentile hidden
//
//  Stage B is STATIC. The net-dollar beat is a deliberately addressable
//  subview (netDollarBeat) so Stage C can run the blur-to-real money
//  shot on it in place; nothing here animates yet.
//
//  Tokens only: bone (#EDEDF3) for the spine + number, brand yellow for
//  the single accent word (a sanctioned chrome/accent use), tertiary
//  grey for labels. No severity colors - the cover carries no data
//  severity. JetBrains Mono for the net dollar + percentile figures.
//

import SwiftUI

struct ReportCoverView: View {
    let report: AutopsyReport

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var archetypeName: String {
        report.analysis.bettingArchetype?.name
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    /// Net dollar is redacted on the snapshot wire (totalProfit zeroed,
    /// tagged redacted_dollar). Either signal blurs the beat.
    private var netRedacted: Bool {
        isSnapshot || report.analysis.summary.totalProfitVisibility == "redacted_dollar"
    }

    private var netDollar: Double { report.analysis.summary.totalProfit }

    /// Grade + percentile are new-at-full (snapshot hides them). Defensive
    /// omission: absent or empty values lay out gracefully, no empty slot.
    private var grade: String? {
        guard !isSnapshot,
              let g = report.analysis.summary.overallGrade?
                .trimmingCharacters(in: .whitespacesAndNewlines),
              !g.isEmpty else { return nil }
        return g
    }

    private var percentile: Int? {
        guard !isSnapshot, let p = report.analysis.betiq?.percentile, p > 0 else { return nil }
        return p
    }

    private var hasSupporting: Bool { grade != nil || percentile != nil }

    /// Realistic blurred placeholder for the redacted net - a dollar
    /// shape, not the real figure (the snapshot wire withholds it). The
    /// established paywall blur pattern; Stage C swaps the real value in
    /// and lifts the blur.
    private let redactedPlaceholder = "-$4,820"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("y-mark-yellow")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)

            Spacer().frame(height: 56)

            archetypeSpine
                // keep long names off the right-edge rail
                .padding(.trailing, 24)

            Spacer().frame(height: 40)

            netDollarBeat

            if hasSupporting {
                Spacer().frame(height: 28)
                supportingCluster
            }

            Spacer().frame(height: 56)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Spine (archetype name)

    private var archetypeSpine: some View {
        spineText
            .font(.system(size: 52, weight: .bold))
            .kerning(-0.5)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// Last word gets the yellow accent, the rest bone; a single-word
    /// name is all accent. The brand lockup one-accent-word pattern.
    private var spineText: Text {
        let words = archetypeName.split(separator: " ").map(String.init)
        guard let last = words.last else { return Text("") }
        if words.count == 1 {
            return Text(last).foregroundStyle(DS.Color.Brand.yellow)
        }
        let head = words.dropLast().joined(separator: " ")
        return Text(head + " ").foregroundStyle(DS.Color.V3.bone)
            + Text(last).foregroundStyle(DS.Color.Brand.yellow)
    }

    // MARK: - Net dollar (the landing beat) - ADDRESSABLE for Stage C

    private var netDollarBeat: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NET")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text(netRedacted ? redactedPlaceholder : BAFormat.currency(netDollar, signed: true))
                .font(.custom("JetBrainsMono-Bold", size: 56))
                .foregroundStyle(DS.Color.V3.bone)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .blur(radius: netRedacted ? 16 : 0)
                .accessibilityHidden(netRedacted)
        }
    }

    // MARK: - Supporting cluster (grade + percentile, full only)

    private var supportingCluster: some View {
        HStack(alignment: .top, spacing: 32) {
            if let grade {
                clusterStat(
                    "GRADE",
                    Text(grade).font(.system(size: 22, weight: .bold))
                )
            }
            if let percentile {
                clusterStat(
                    "PERCENTILE",
                    Text(percentile.ordinalText).font(.custom("JetBrainsMono-Bold", size: 18))
                )
            }
        }
    }

    private func clusterStat(_ label: String, _ value: Text) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)
            value
                .foregroundStyle(DS.Color.V3.textSecondary)
        }
    }

    // MARK: - Accessibility

    private var accessibilityText: String {
        var parts: [String] = [archetypeName]
        if netRedacted {
            parts.append("Net result hidden in the snapshot")
        } else {
            parts.append("Net \(BAFormat.currency(netDollar, signed: true))")
        }
        if let grade { parts.append("Grade \(grade)") }
        if let percentile { parts.append("\(percentile.ordinalText) percentile") }
        return parts.joined(separator: ". ") + "."
    }
}

#if DEBUG
#Preview("Full") {
    ScrollView {
        ReportCoverView(report: MockReport.heatedBettor)
    }
    .background(DS.Color.V3.canvasGradient.ignoresSafeArea())
    .preferredColorScheme(.dark)
}

#Preview("Snapshot") {
    ScrollView {
        ReportCoverView(report: MockReport.heatedBettorSnapshot)
    }
    .background(DS.Color.V3.canvasGradient.ignoresSafeArea())
    .preferredColorScheme(.dark)
}
#endif
