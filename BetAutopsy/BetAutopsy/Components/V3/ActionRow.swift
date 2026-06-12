//
//  ActionRow.swift
//  BetAutopsy
//
//  3B component library: the lighter sibling of ActionCard. One
//  action-plan line with a check-off affordance: 44pt checkbox tap
//  target, strikethrough + dim on completion, optional detail line.
//  Store-agnostic: completion state and the toggle callback come from
//  the host (ActionCheckoffStore stays outside).
//
//  NOT card-wrapped: the host stacks rows inside one container card
//  with V3Divider between them (the BehavioralImpactRow pattern).
//

import SwiftUI

struct ActionRow: View {
    let title: String
    var detail: String? = nil
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            checkbox
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .strikethrough(isCompleted, color: DS.Color.V3.textTertiary)
                    .opacity(isCompleted ? 0.6 : 1)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .opacity(isCompleted ? 0.6 : 1)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)\(detail.map { ". \($0)" } ?? "")")
        .accessibilityValue(isCompleted ? "Done" : "Not done")
        .accessibilityAddTraits(.isButton)
    }

    private var checkbox: some View {
        Button(action: onToggle) {
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
    VStack(spacing: 0) {
        ActionRow(
            title: "Skip Sunday nights between 10pm and 2am",
            detail: "$1,840 projected next 90 days",
            isCompleted: false,
            onToggle: {}
        )
        V3Divider()
        ActionRow(
            title: "Lock unit size at 1% of bankroll",
            isCompleted: true,
            onToggle: {}
        )
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 4)
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
