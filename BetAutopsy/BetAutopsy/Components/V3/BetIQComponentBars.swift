//
//  BetIQComponentBars.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2.5 surface #2: the BetIQ skill-component breakdown,
//  ported from web's "VIEW SKILL BREAKDOWN" grid (AutopsyReport.tsx
//  994-1012). Six components, each scored against its own max:
//    line value / 25, calibration / 20, sophistication / 15,
//    specialization / 15, timing / 10, sample size (confidence) / 15.
//
//  Placed in SectionVerdict between the BetIQ ring and the archetype
//  prose. The ring already shows the composite score; these bars open
//  it up into its skill drivers. Bars are tinted by fill ratio
//  (higher is better -> green) using the V3 severity zone scale.
//
//  Snapshot follows web's `isSharp` gate: the breakdown is paid-tier
//  depth, so snapshot shows six blurred shell rows under a single
//  tappable teaser overlay (NOT per-row LockedDollarBar, since these
//  are scores, not dollars). Tap routes to the paywall.
//
//  Full mode only renders when betiq exists and is not insufficient
//  (the ring shows the insufficient-sample treatment in that case).
//

import SwiftUI

struct BetIQComponentBars: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private struct Component: Identifiable {
        let label: String
        let value: Int
        let max: Int
        var id: String { label }
        var ratio: Double { max > 0 ? Double(value) / Double(max) : 0 }
    }

    private var components: [Component] {
        guard let c = report.analysis.betiq?.components else { return [] }
        return [
            Component(label: "Line value", value: c.lineValue, max: 25),
            Component(label: "Calibration", value: c.calibration, max: 20),
            Component(label: "Sophistication", value: c.sophistication, max: 15),
            Component(label: "Specialization", value: c.specialization, max: 15),
            Component(label: "Timing", value: c.timing, max: 10),
            Component(label: "Sample size", value: c.confidence, max: 15),
        ]
    }

    /// Six rows are always available for layout (labels + maxes are static);
    /// only the per-component values come from the wire. Used to draw the
    /// snapshot shell so the teaser matches the full layout exactly.
    private var shellComponents: [Component] {
        [
            Component(label: "Line value", value: 0, max: 25),
            Component(label: "Calibration", value: 0, max: 20),
            Component(label: "Sophistication", value: 0, max: 15),
            Component(label: "Specialization", value: 0, max: 15),
            Component(label: "Timing", value: 0, max: 10),
            Component(label: "Sample size", value: 0, max: 15),
        ]
    }

    private var shouldRender: Bool {
        if isSnapshot { return report.analysis.betiq != nil }
        guard let betiq = report.analysis.betiq else { return false }
        return !betiq.insufficientData
    }

    var body: some View {
        if shouldRender {
            VStack(alignment: .leading, spacing: 12) {
                Text("SKILL BREAKDOWN")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                if isSnapshot {
                    lockedTeaser
                } else {
                    // 3B-2: full-mode rows recomposed onto ContributorBars
                    // (same zone-tinted ratio bars, BAFormat.score readout).
                    // The snapshot teaser keeps the legacy shell rows so the
                    // blurred lock renders byte-identical to before.
                    ContributorBars(
                        contributors: components.map {
                            ContributorBars.Contributor(label: $0.label, value: $0.value, max: $0.max)
                        }
                    )
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Locked teaser (snapshot)

    private var lockedTeaser: some View {
        ZStack {
            VStack(spacing: 14) {
                ForEach(shellComponents) { component in
                    barRow(component, locked: true)
                }
            }
            .blur(radius: 3)
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                Text("Read the full report to see your skill breakdown.")
                    .font(.system(size: 13, weight: .regular))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture { onPaywallTap("section_verdict_score_bars_locked") }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Skill breakdown locked. Tap to read the full report.")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Bar row

    private func barRow(_ component: Component, locked: Bool) -> some View {
        let fill = DS.Color.V3.Severity.zoneColor(
            forScore: Int((component.ratio * 100).rounded()),
            higherIsWorse: false
        )
        return VStack(spacing: 6) {
            HStack {
                Text(component.label)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                Spacer()
                if !locked {
                    Text("\(component.value)")
                        .font(.system(size: 13, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textPrimary)
                    + Text("/\(component.max)")
                        .font(.system(size: 12, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textTertiary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(DS.Color.V3.surfaceRaised)
                        .frame(height: 4)
                    if !locked {
                        Capsule()
                            .fill(fill)
                            .frame(width: geo.size.width * component.ratio, height: 4)
                    }
                }
            }
            .frame(height: 4)
        }
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            BetIQComponentBars(report: MockReport.heatedBettor, onPaywallTap: { _ in })
        }
        .padding(16)
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
