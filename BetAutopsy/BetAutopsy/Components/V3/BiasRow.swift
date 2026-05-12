//
//  BiasRow.swift
//  BetAutopsy
//
//  V3 expandable bias row. Used in Chapter 4 (The Bias Sheet). Tap to
//  expand; reveals evidence, translation, and fix. Custom @State
//  expansion (NOT DisclosureGroup) for precise animation control.
//
//  NOT card-wrapped at component level. The CHAPTER VIEW wraps multiple
//  BiasRows in one container card with V3Divider between rows.
//

import SwiftUI

struct BiasRow: View {
    struct Bias: Identifiable, Hashable {
        let id: UUID
        let biasName: String       // caps display
        let costAbs: Int           // positive int dollars
        let severityLabel: String  // "CRITICAL"/"HIGH"/"MEDIUM"/"LOW"
        let severityColor: Color   // resolved by chapter
        let widthRatio: Double     // 0...1
        let evidence: String?
        let translation: String?
        let fix: String?

        init(
            biasName: String,
            costAbs: Int,
            severityLabel: String,
            severityColor: Color,
            widthRatio: Double,
            evidence: String? = nil,
            translation: String? = nil,
            fix: String? = nil
        ) {
            self.id = UUID()
            self.biasName = biasName
            self.costAbs = costAbs
            self.severityLabel = severityLabel
            self.severityColor = severityColor
            self.widthRatio = widthRatio
            self.evidence = evidence
            self.translation = translation
            self.fix = fix
        }
    }

    let bias: Bias
    @State private var expanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(bias.biasName)
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.1)
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Spacer()

                Text("-$\(bias.costAbs)")
                    .font(DS.Font.V3.rowValue)
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.Severity.red)

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

            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    if let evidence = bias.evidence, !evidence.isEmpty {
                        labeled("EVIDENCE", body: evidence)
                    }
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
            withAnimation(.easeInOut(duration: 0.2)) {
                expanded.toggle()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(bias.biasName). Cost: \(bias.costAbs) dollars. Severity: \(bias.severityLabel). Tap to expand or collapse details."
        )
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
            costAbs: 290,
            severityLabel: "MEDIUM",
            severityColor: DS.Color.V3.Severity.yellow,
            widthRatio: 0.16
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
