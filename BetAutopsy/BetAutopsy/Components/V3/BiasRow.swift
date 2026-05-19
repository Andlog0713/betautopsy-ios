//
//  BiasRow.swift
//  BetAutopsy
//
//  V3 expandable bias row. Used in Chapter 4 (The Bias Sheet). Tap to
//  expand; reveals translation and fix. Custom @State expansion
//  (NOT DisclosureGroup) for precise animation control.
//
//  Snapshot mode passes isLockedCost=true and onLockedTap; the row
//  renders a LockedDollarBar in place of the signed dollar value. The
//  evidence first-sentence renders inline in collapsed view when present
//  (engine V2 scrubs dollars to $... so it is safe to show), with full
//  evidence and the rest of the body inside the expanded view.
//
//  NOT card-wrapped at component level. The CHAPTER VIEW wraps multiple
//  BiasRows in one container card with V3Divider between rows.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct BiasRow: View {
    struct Bias: Identifiable, Hashable {
        let id: UUID
        let biasName: String         // caps display
        let costAbs: Int             // positive int dollars; ignored when isLockedCost
        let severityLabel: String    // "CRITICAL"/"HIGH"/"MEDIUM"/"LOW"
        let severityColor: Color     // resolved by chapter
        let widthRatio: Double       // 0...1
        let evidence: String?
        let evidenceVisible: Bool    // default true; false hides inline evidence
        let translation: String?
        let fix: String?
        let isLockedCost: Bool       // snapshot mode -> LockedDollarBar replaces "-$N"

        init(
            biasName: String,
            costAbs: Int,
            severityLabel: String,
            severityColor: Color,
            widthRatio: Double,
            evidence: String? = nil,
            evidenceVisible: Bool = true,
            translation: String? = nil,
            fix: String? = nil,
            isLockedCost: Bool = false
        ) {
            self.id = UUID()
            self.biasName = biasName
            self.costAbs = costAbs
            self.severityLabel = severityLabel
            self.severityColor = severityColor
            self.widthRatio = widthRatio
            self.evidence = evidence
            self.evidenceVisible = evidenceVisible
            self.translation = translation
            self.fix = fix
            self.isLockedCost = isLockedCost
        }
    }

    let bias: Bias

    /// Called when the LockedDollarBar is tapped. No-op when the row is
    /// not in locked-cost mode.
    var onLockedTap: (() -> Void)? = nil

    /// Tap target for the row itself. When non-nil, the chevron rotates
    /// to a navigational rest pose and the row fires onTap on tap
    /// (instead of the existing expand toggle). Used by Ch 4 to present
    /// the BiasEvidenceSheet.
    var onTap: (() -> Void)? = nil

    @State private var expanded: Bool = false

    private var evidenceFirstSentence: String? {
        guard bias.evidenceVisible,
              let raw = bias.evidence?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else {
            return nil
        }
        let firstSentence = raw.firstSentences(1)
        return firstSentence.isEmpty ? raw : firstSentence
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(bias.biasName)
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.1)
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Spacer()

                if bias.isLockedCost {
                    HStack(spacing: 8) {
                        Text("EST. COST")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(1.5)
                            .foregroundStyle(DS.Color.V3.Severity.red)
                        LockedDollarBar(width: 110, onTap: { onLockedTap?() })
                    }
                } else {
                    Text("-$\(bias.costAbs)")
                        .font(DS.Font.V3.rowValue)
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.Severity.red)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .rotationEffect(.degrees(expanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: expanded)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DS.Color.V3.borderSubtle)
                        .frame(height: 3)
                    Rectangle()
                        .fill(bias.severityColor)
                        .frame(
                            width: max(0, geo.size.width * bias.widthRatio),
                            height: 3
                        )
                }
            }
            .frame(height: 3)

            Text(bias.severityLabel)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(bias.severityColor)

            if let evidenceText = evidenceFirstSentence {
                Text(evidenceText)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .lineSpacing(2)
                    .padding(.top, 2)
            }

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let translation = bias.translation, !translation.isEmpty {
                        labeled("TRANSLATION", body: translation)
                    }
                    if let fix = bias.fix, !fix.isEmpty {
                        labeled("FIX", body: fix)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            if let onTap {
                #if canImport(UIKit)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                #endif
                onTap()
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expanded.toggle()
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint(onTap != nil ? "Tap for evidence bets and full fix" : "")
    }

    private var accessibilityDescription: String {
        var parts: [String] = ["\(bias.biasName)"]
        if bias.isLockedCost {
            parts.append("Estimated cost locked.")
        } else {
            parts.append("Cost: \(bias.costAbs) dollars")
        }
        parts.append("Severity: \(bias.severityLabel)")
        parts.append("Tap to expand or collapse details.")
        return parts.joined(separator: ". ")
    }

    @ViewBuilder
    private func labeled(_ label: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(DS.Color.V3.textTertiary)
            Text(body)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 0) {
        BiasRow(bias: BiasRow.Bias(
            biasName: "LOSS CHASING",
            costAbs: 1840,
            severityLabel: "CRITICAL",
            severityColor: DS.Color.V3.Severity.red,
            widthRatio: 1.0,
            evidence: "Across 47 wagers placed within 30 minutes of a previous loss, your average stake increased 2.3x your baseline.",
            translation: "You bet bigger after losses to get even.",
            fix: "Set a 60-minute cooldown after any loss."
        ))
        V3Divider()
        BiasRow(bias: BiasRow.Bias(
            biasName: "PARLAY ADDICTION",
            costAbs: 0,
            severityLabel: "HIGH",
            severityColor: DS.Color.V3.Severity.red.opacity(0.85),
            widthRatio: 0.66,
            evidence: "31% of your wagers were parlays of 3+ legs. Win rate on those: 6.2%.",
            isLockedCost: true
        ))
    }
    .padding(.vertical, 2)
    .padding(.horizontal, 16)
    .background(DS.Color.V3.surfaceCard)
    .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
