//
//  HeatedSessionPreviewCard.swift
//  BetAutopsy
//
//  Snapshot-mode preview of one heated session: grade pill, date stamp,
//  bet count, locked dollar value, heat-signal chips. Single-card by
//  design in v1; the remaining heated sessions land in the full report.
//
//  Replaces the multi-card TiltSessionCard list on Ch 2 when the report
//  is in snapshot mode. Full-report mode keeps the existing list so the
//  paid render still surfaces every session's signed P&L.
//

import SwiftUI

struct HeatedSessionPreviewCard: View {
    struct Session: Identifiable, Hashable {
        let id: UUID
        let grade: String         // "F", "D", "C", "B", "A"
        let dateLabel: String     // "TUE MAR 12 - 11:47 PM"
        let betCount: Int
        let heatSignals: [String] // already truncated to <= 3 by caller

        init(grade: String, dateLabel: String, betCount: Int, heatSignals: [String]) {
            self.id = UUID()
            self.grade = grade
            self.dateLabel = dateLabel
            self.betCount = betCount
            self.heatSignals = heatSignals
        }
    }

    let session: Session
    let onLockedTap: () -> Void

    private var gradeColor: Color {
        switch session.grade.uppercased() {
        case "F":      return DS.Color.V3.Severity.red
        case "D":      return DS.Color.V3.Severity.red.opacity(0.85)
        case "C":      return DS.Color.V3.Severity.yellow
        default:       return DS.Color.V3.Severity.green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("GRADE \(session.grade.uppercased())")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(gradeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(gradeColor, lineWidth: 1)
                    )

                Spacer()

                Text(session.dateLabel)
                    .font(.system(size: 11, weight: .regular))
                    .tracking(0.8)
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }

            HStack(alignment: .center, spacing: 12) {
                Text("\(session.betCount) bets")
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Spacer()

                HStack(spacing: 8) {
                    Text("LOST")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.V3.Severity.red)
                    LockedDollarBar(width: 140, onTap: onLockedTap)
                }
            }

            if !session.heatSignals.isEmpty {
                FlowChips(signals: session.heatSignals)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// Pill-style heat-signal chips. Wraps if too wide for the row by laying
/// chips out into rows of cumulative width <= the container width.
struct FlowChips: View {
    let signals: [String]

    var body: some View {
        FlexibleChipLayout(spacing: 6, runSpacing: 6) {
            ForEach(Array(signals.enumerated()), id: \.offset) { _, signal in
                chip(signal)
            }
        }
    }

    private func chip(_ raw: String) -> some View {
        let label = truncate(raw)
        return Text(label.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.9)
            .foregroundStyle(DS.Color.V3.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(
                Capsule()
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 1)
            )
    }

    private func truncate(_ raw: String) -> String {
        let s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.count <= 30 { return s }
        let cut = s.index(s.startIndex, offsetBy: 28)
        return String(s[..<cut]) + "\u{2026}"
    }
}

/// Two-row flow layout. SwiftUI Layout protocol makes this concise:
/// each subview is placed left-to-right until the cumulative width
/// would exceed the container, then a new row starts.
private struct FlexibleChipLayout: Layout {
    let spacing: CGFloat
    let runSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let result = layout(maxWidth: maxWidth, subviews: subviews)
        return CGSize(width: result.width, height: result.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let positions = layout(maxWidth: bounds.width, subviews: subviews).positions
        for (i, sub) in subviews.enumerated() {
            let pos = positions[i]
            sub.place(
                at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(
        maxWidth: CGFloat,
        subviews: Subviews
    ) -> (width: CGFloat, height: CGFloat, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widestRow: CGFloat = 0

        for sub in subviews {
            let size = sub.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                widestRow = max(widestRow, x - spacing)
                x = 0
                y += rowHeight + runSpacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        widestRow = max(widestRow, x - spacing)
        return (widestRow, y + rowHeight, positions)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        HeatedSessionPreviewCard(
            session: HeatedSessionPreviewCard.Session(
                grade: "F",
                dateLabel: "WED DEC 3 - 11:14 PM",
                betCount: 8,
                heatSignals: ["Loss chasing", "Stake escalation", "Late-night start"]
            ),
            onLockedTap: { }
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
