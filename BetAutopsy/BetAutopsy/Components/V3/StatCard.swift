//
//  StatCard.swift
//  BetAutopsy
//
//  3B component library: the skim-layer labeled metric. Label + big
//  value + optional sub-label, formatted INSIDE the component via the
//  typed Value enum so call sites cannot reintroduce raw number
//  formatting. Composable anywhere a headline number belongs (vitals,
//  finding counts, score summaries).
//
//  Value-driven: takes decoded values, never AutopsyReport. Gating and
//  data selection stay in the host section.
//

import SwiftUI

struct StatCard: View {
    /// Typed value so BAFormat is applied inside the component.
    enum Value {
        case score(Int)
        case currency(Double, signed: Bool = true)
        case percent(Double, signed: Bool = true)
        case count(Int)
        /// Non-numeric strings ONLY (e.g. the "120-95" record, a grade
        /// letter). NEVER a pre-formatted number string; numbers route
        /// through the typed cases so BAFormat owns their shape.
        case text(String)

        var formatted: String {
            switch self {
            case .score(let value):
                return "\(value)"
            case .currency(let value, let signed):
                return BAFormat.currency(value, signed: signed)
            case .percent(let value, let signed):
                return BAFormat.percent(value, signed: signed, headline: true)
            case .count(let value):
                return "\(value)"
            case .text(let value):
                return value
            }
        }
    }

    let label: String
    let value: Value
    var subLabel: String? = nil
    var tint: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text(value.formatted)
                .font(.system(size: 18, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(tint ?? DS.Color.V3.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subLabel, !subLabel.isEmpty {
                Text(subLabel)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(value.formatted)\(subLabel.map { ". \($0)" } ?? "")")
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        HStack(spacing: 12) {
            StatCard(label: "BETIQ", value: .score(62))
            StatCard(label: "NET P&L", value: .currency(-7862),
                     tint: DS.Color.V3.Severity.red)
        }
        HStack(spacing: 12) {
            StatCard(label: "ROI", value: .percent(-12.4),
                     tint: DS.Color.V3.Severity.red)
            StatCard(label: "BIASES", value: .count(7),
                     subLabel: "3 critical")
        }
        StatCard(label: "RECORD", value: .text("120-95"),
                 subLabel: "across 215 settled bets")
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
