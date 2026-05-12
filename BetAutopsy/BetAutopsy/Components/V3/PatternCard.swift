//
//  PatternCard.swift
//  BetAutopsy
//
//  V3 pattern card. Used in Chapter 5 (The Patterns) to surface
//  uncanny moments: one big number + one named entity per card.
//
//  Slightly taller vertical padding (18pt) than the canonical V3 card
//  to give the big number room to breathe.
//

import SwiftUI

struct PatternCard: View {
    struct Pattern: Identifiable, Hashable {
        let id: UUID
        let title: String           // caps display
        let bigNumber: String       // pre-formatted display string
        let bigNumberColor: Color
        let namedEntity: String     // sentence case
        let supportingLine: String? // optional

        init(
            title: String,
            bigNumber: String,
            bigNumberColor: Color,
            namedEntity: String,
            supportingLine: String? = nil
        ) {
            self.id = UUID()
            self.title = title
            self.bigNumber = bigNumber
            self.bigNumberColor = bigNumberColor
            self.namedEntity = namedEntity
            self.supportingLine = supportingLine
        }
    }

    let pattern: Pattern

    private var accessibilityDescription: String {
        var parts = ["\(pattern.title): \(pattern.bigNumber) on \(pattern.namedEntity)"]
        if let supporting = pattern.supportingLine,
           !supporting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(supporting)
        }
        return parts.joined(separator: ". ") + "."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(pattern.title)
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.4)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text(pattern.bigNumber)
                .font(.system(size: 44, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(pattern.bigNumberColor)

            Text(pattern.namedEntity)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if let supporting = pattern.supportingLine,
               !supporting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(supporting)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        PatternCard(pattern: PatternCard.Pattern(
            title: "BIGGEST LOSS",
            bigNumber: "-$920",
            bigNumberColor: DS.Color.V3.Severity.red,
            namedEntity: "Dec 3, 2025",
            supportingLine: "8 bets across a 144-minute session."
        ))
        PatternCard(pattern: PatternCard.Pattern(
            title: "WORST DAY",
            bigNumber: "-$1,914",
            bigNumberColor: DS.Color.V3.Severity.red,
            namedEntity: "Sundays"
        ))
        PatternCard(pattern: PatternCard.Pattern(
            title: "LONGEST SKID",
            bigNumber: "4 STRAIGHT",
            bigNumberColor: DS.Color.V3.textPrimary,
            namedEntity: "Dec 3 to Jan 7"
        ))
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
