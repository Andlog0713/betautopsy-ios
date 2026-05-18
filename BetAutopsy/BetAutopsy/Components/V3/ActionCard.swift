//
//  ActionCard.swift
//  BetAutopsy
//
//  V3 action card. Used in Chapter 7 (The Action Plan) for ranked
//  behavioral changes plus an aggregate projection footer.
//
//  Two visual modes via `isAggregate`:
//    false  -> regular action: tiedToFinding label, title, impact,
//              difficulty. Standard 0.5pt border.
//    true   -> aggregate footer: title (caps), impact only. Thicker
//              1.0pt border in textPrimary.opacity(0.4) to elevate.
//

import SwiftUI

struct ActionCard: View {
    struct Action: Identifiable, Hashable {
        let id: UUID
        let title: String           // sentence case for actions; caps for aggregate
        let tiedToFinding: String   // caps; empty for aggregate
        let projectedImpact: String // formatted dollar string; ignored when isLockedImpact
        let difficulty: String      // "EASY"/"MODERATE"/"HARD"; empty for aggregate
        let isAggregate: Bool
        let isLockedImpact: Bool    // snapshot mode -> LockedDollarBar + "projected next 90 days"
        let impactFallback: String? // optional fallback when no dollars and no lock

        init(
            title: String,
            tiedToFinding: String,
            projectedImpact: String,
            difficulty: String,
            isAggregate: Bool,
            isLockedImpact: Bool = false,
            impactFallback: String? = nil
        ) {
            self.id = UUID()
            self.title = title
            self.tiedToFinding = tiedToFinding
            self.projectedImpact = projectedImpact
            self.difficulty = difficulty
            self.isAggregate = isAggregate
            self.isLockedImpact = isLockedImpact
            self.impactFallback = impactFallback
        }
    }

    let action: Action

    /// Whether this card is in a completed state. Drives the checkbox
    /// fill; ignored unless `onCheckoffTap` is non-nil and the card is
    /// non-aggregate.
    var isCompleted: Bool = false

    /// Callback when the checkbox is tapped. Nil means no checkbox is
    /// rendered (aggregate cards always skip the checkbox regardless
    /// of this value).
    var onCheckoffTap: (() -> Void)? = nil

    /// Callback when the LockedDollarBar is tapped. Only relevant when
    /// action.isLockedImpact is true.
    var onLockedTap: (() -> Void)? = nil

    private var strokeColor: Color {
        action.isAggregate
            ? DS.Color.V3.textPrimary.opacity(0.4)
            : DS.Color.V3.borderSubtle
    }

    private var strokeWidth: CGFloat {
        action.isAggregate ? 1.0 : 0.5
    }

    private var accessibilityDescription: String {
        if action.isAggregate {
            return "Aggregate: \(action.title). \(action.projectedImpact)."
        }
        var parts: [String] = []
        if !action.tiedToFinding.isEmpty {
            parts.append(action.tiedToFinding)
        }
        parts.append("Action: \(action.title)")
        parts.append(action.projectedImpact)
        if !action.difficulty.isEmpty {
            parts.append("Difficulty: \(action.difficulty)")
        }
        return parts.joined(separator: ". ") + "."
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if !action.isAggregate, let onTap = onCheckoffTap {
                checkbox(onTap: onTap)
                    .padding(.top, 2)
            }

            VStack(alignment: .leading, spacing: 8) {
                if !action.isAggregate && !action.tiedToFinding.isEmpty {
                    Text(action.tiedToFinding)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                }

                Text(action.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .strikethrough(isCompleted && !action.isAggregate,
                                   color: DS.Color.V3.textTertiary)
                    .opacity(isCompleted && !action.isAggregate ? 0.6 : 1)

                impactRow
                    .padding(.top, 4)

                if !action.isAggregate && !action.difficulty.isEmpty {
                    Text(action.difficulty)
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(strokeColor, lineWidth: strokeWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityAddTraits(onCheckoffTap == nil ? [] : .isButton)
    }

    @ViewBuilder
    private var impactRow: some View {
        if action.isLockedImpact {
            HStack(spacing: 8) {
                LockedDollarBar(width: 110, onTap: { onLockedTap?() })
                Text("projected next 90 days")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }
        } else if !action.projectedImpact.isEmpty {
            Text(action.projectedImpact)
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textSecondary)
        } else if let fallback = action.impactFallback, !fallback.isEmpty {
            Text(fallback)
                .font(.system(size: 13, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(DS.Color.Brand.yellow)
        }
    }

    @ViewBuilder
    private func checkbox(onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isCompleted
                          ? DS.Color.V3.Severity.green.opacity(0.18)
                          : Color.clear)
                    .frame(width: 22, height: 22)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(isCompleted
                            ? DS.Color.V3.Severity.green
                            : DS.Color.V3.textTertiary,
                            lineWidth: 1.5)
                    .frame(width: 22, height: 22)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Color.V3.Severity.green)
                }
            }
            .frame(width: 44, height: 44, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isCompleted ? "Marked done. Tap to reset." : "Mark done.")
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        ActionCard(action: ActionCard.Action(
            title: "Skip Sunday nights between 10pm and 2am",
            tiedToFinding: "FROM YOUR DIAGNOSIS",
            projectedImpact: "$1,840 projected next 90 days",
            difficulty: "EASY",
            isAggregate: false
        ))
        ActionCard(action: ActionCard.Action(
            title: "Lock unit size at 1% of bankroll",
            tiedToFinding: "FROM YOUR DIAGNOSIS",
            projectedImpact: "$620 projected next 90 days",
            difficulty: "MODERATE",
            isAggregate: false
        ))
        ActionCard(action: ActionCard.Action(
            title: "IF YOU DID ALL OF THESE",
            tiedToFinding: "",
            projectedImpact: "$2,847 projected next 90 days",
            difficulty: "",
            isAggregate: true
        ))
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
