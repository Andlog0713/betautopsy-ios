//
//  WhatChangedCard.swift
//  BetAutopsy
//
//  V3 longitudinal-memory card. Renders the diff between this report
//  and the user's previous report: relative date, optional archetype
//  shift, optional BetIQ delta, optional top-impact deltas.
//
//  The caller (ChapterTheVerdictView) is responsible for guarding the
//  parent whatChanged optional. This card assumes whatChanged is
//  non-nil, but defensively hides each sub-section when its own sub-
//  field is absent (or, for BetIQ, when direction is .stable).
//
//  Surface conventions match DamagesCard: surfaceCard bg, 0.5pt
//  borderSubtle stroke, 12pt continuous corner radius.
//

import SwiftUI

struct WhatChangedCard: View {
    let whatChanged: WhatChanged

    private var hasArchetype: Bool {
        whatChanged.archetypeChange != nil
    }

    private var hasBetIQ: Bool {
        guard let biq = whatChanged.betIQDelta else { return false }
        return biq.direction != .stable
    }

    private var hasImpacts: Bool {
        (whatChanged.topImpactDeltas?.isEmpty == false)
    }

    /// Defensive double-check: if backend ships an empty whatChanged
    /// envelope, the card hides entirely. Backend should already omit
    /// the field in that case.
    private var hasAnyContent: Bool {
        hasArchetype || hasBetIQ || hasImpacts
    }

    var body: some View {
        if hasAnyContent {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 14)

                if hasArchetype, let arch = whatChanged.archetypeChange {
                    V3Divider()
                    archetypeRow(arch)
                }

                if hasBetIQ, let biq = whatChanged.betIQDelta {
                    V3Divider()
                    betIQRow(biq)
                }

                if hasImpacts, let deltas = whatChanged.topImpactDeltas {
                    V3Divider()
                    impactSection(deltas)
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
        VStack(alignment: .leading, spacing: 4) {
            Text("WHAT CHANGED")
                .font(.system(size: 10, weight: .semibold))
                .tracking(10 * 0.18)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text(relativeDateString(daysAgo: whatChanged.daysSincePrevious))
                .font(DS.Font.V3.captionLabel)
                .foregroundStyle(DS.Color.V3.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "What changed since \(relativeDateString(daysAgo: whatChanged.daysSincePrevious))"
        )
    }

    // MARK: - Archetype row

    private func archetypeRow(_ change: ArchetypeChange) -> some View {
        HStack(spacing: 6) {
            Text("Archetype shifted:")
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textSecondary)

            Text(change.from)
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textPrimary)

            Text("\u{2192}")
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text(change.to)
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textPrimary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Archetype shifted from \(change.from) to \(change.to)")
    }

    // MARK: - BetIQ row

    private func betIQRow(_ delta: BetIQDelta) -> some View {
        let diff = delta.to - delta.from
        let directionColor = betIQColor(direction: delta.direction)
        let verb = delta.direction == .improved ? "improved" : "regressed"

        return HStack(spacing: 8) {
            Group {
                Text("BetIQ ")
                    .foregroundStyle(DS.Color.V3.textPrimary)
                + Text(verb)
                    .foregroundStyle(directionColor)
                + Text(" \(abs(diff)) points (\(delta.from) \u{2192} \(delta.to))")
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }
            .font(DS.Font.V3.bodyRegular)
            .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            signedChip(value: diff, color: directionColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "BetIQ \(verb) \(abs(diff)) points, from \(delta.from) to \(delta.to)"
        )
    }

    private func betIQColor(direction: BetIQDirection) -> Color {
        switch direction {
        case .improved:  return DS.Color.V3.Severity.green
        case .regressed: return DS.Color.V3.Severity.red
        case .stable:    return DS.Color.V3.textTertiary
        }
    }

    // MARK: - Impact section

    private func impactSection(_ deltas: [ImpactDelta]) -> some View {
        VStack(spacing: 0) {
            Text("TOP IMPACT SHIFTS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(10 * 0.18)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 6)

            ForEach(deltas) { delta in
                impactRow(delta)
            }
        }
    }

    private func impactRow(_ delta: ImpactDelta) -> some View {
        let color = impactColor(deltaPercent: delta.deltaPercent)

        return HStack(spacing: 10) {
            Text(delta.biasName)
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            Text(signedPercentString(delta.deltaPercent))
                .font(DS.Font.V3.rowValue)
                .monospacedDigit()
                .foregroundStyle(color)

            Text(delta.confidence.rawValue.uppercased())
                .font(DS.Font.V3.captionLabel)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .frame(minWidth: 52, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(delta.biasName), \(signedPercentString(delta.deltaPercent)), \(delta.confidence.rawValue) confidence"
        )
    }

    /// Negative delta = bias cost dropped = improvement = green.
    /// Positive delta = bias cost rose = regression = red.
    private func impactColor(deltaPercent: Int) -> Color {
        if deltaPercent < 0 { return DS.Color.V3.Severity.green }
        if deltaPercent > 0 { return DS.Color.V3.Severity.red }
        return DS.Color.V3.textTertiary
    }

    // MARK: - Helpers

    private func signedChip(value: Int, color: Color) -> some View {
        Text(signedIntString(value))
            .font(.system(size: 11, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private func signedIntString(_ value: Int) -> String {
        if value > 0 { return "+\(value)" }
        if value < 0 { return "\u{2212}\(abs(value))" }
        return "0"
    }

    private func signedPercentString(_ value: Int) -> String {
        if value > 0 { return "+\(value)%" }
        if value < 0 { return "\u{2212}\(abs(value))%" }
        return "0%"
    }
}

/// Localized relative-date string for "X days/weeks/months ago." iOS
/// has no project-wide helper for this yet — keeping it file-local
/// avoids a new Extensions/ file for a single one-off helper.
private func relativeDateString(daysAgo: Int) -> String {
    if daysAgo <= 0 { return "Today" }
    if daysAgo == 1 { return "Yesterday" }
    if daysAgo < 7 { return "\(daysAgo) days ago" }
    if daysAgo < 30 {
        let weeks = daysAgo / 7
        return weeks == 1 ? "1 week ago" : "\(weeks) weeks ago"
    }
    let months = daysAgo / 30
    return months == 1 ? "1 month ago" : "\(months) months ago"
}

#Preview {
    VStack(spacing: 16) {
        WhatChangedCard(whatChanged: WhatChanged(
            previousReportDate: "2026-04-15",
            daysSincePrevious: 22,
            archetypeChange: ArchetypeChange(from: "The Chaser", to: "The Sharp"),
            betIQDelta: BetIQDelta(from: 42, to: 51, direction: .improved),
            topImpactDeltas: [
                ImpactDelta(biasName: "Post-Loss Escalation",
                            previousImpact: 1840, currentImpact: 1030,
                            deltaPercent: -44, confidence: .high),
                ImpactDelta(biasName: "Stake Volatility",
                            previousImpact: 620, currentImpact: 484,
                            deltaPercent: -22, confidence: .medium),
                ImpactDelta(biasName: "Loss Chasing",
                            previousImpact: 290, currentImpact: 342,
                            deltaPercent: 18, confidence: .low)
            ]
        ))

        WhatChangedCard(whatChanged: WhatChanged(
            previousReportDate: "2026-05-01",
            daysSincePrevious: 14,
            archetypeChange: nil,
            betIQDelta: BetIQDelta(from: 58, to: 51, direction: .regressed),
            topImpactDeltas: nil
        ))
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
