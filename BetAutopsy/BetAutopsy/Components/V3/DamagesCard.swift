//
//  DamagesCard.swift
//  BetAutopsy
//
//  V3 trailer-pattern damages card. Used on Chapter 1 (Verdict) to
//  show the top 1-3 detected biases by dollar cost, as plain
//  text rows (no bars, no severity colors, no sub-text).
//
//  Chapter 4 (Biases) uses a different visual treatment with bars +
//  severity coloring + per-row depth. This card is for the trailer,
//  not the autopsy.
//
//  The caller is responsible for filtering, sorting, and limiting
//  the input array. The card renders whatever it's given.
//

import SwiftUI

struct DamagesCard: View {
    struct Damage: Identifiable, Hashable {
        let id: UUID
        let name: String   // will be uppercased on render
        let cost: Int      // positive integer dollars; minus sign added on render

        init(name: String, cost: Int) {
            self.id = UUID()
            self.name = name
            self.cost = cost
        }
    }

    let damages: [Damage]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(damages) { damage in
                HStack(spacing: 12) {
                    Text(damage.name.uppercased())
                        .font(DS.Font.V3.rowCapsLabel)
                        .tracking(1.1)
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\u{2212}$\(damage.cost)")
                        .font(DS.Font.V3.rowValue)
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textPrimary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(damage.name), negative \(damage.cost) dollars"
                )
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

#Preview {
    VStack(spacing: 16) {
        DamagesCard(damages: [
            .init(name: "Loss Chasing", cost: 1840),
            .init(name: "Emotional Sizing", cost: 620),
            .init(name: "Parlay Addiction", cost: 290)
        ])
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
