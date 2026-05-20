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
        let triggerEvent: TriggerEvent?

        init(
            grade: String,
            dateLabel: String,
            betCount: Int,
            heatSignals: [String],
            triggerEvent: TriggerEvent? = nil
        ) {
            self.id = UUID()
            self.grade = grade
            self.dateLabel = dateLabel
            self.betCount = betCount
            self.heatSignals = heatSignals
            self.triggerEvent = triggerEvent
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
            if let event = session.triggerEvent {
                TriggerEventChip(event: event)
            }

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
                Text(session.betCount.pluralized("bet", "bets"))
                    .font(.system(size: 16, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Spacer()

                HStack(spacing: 8) {
                    Text("LOST")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.V3.Severity.red)
                        .fixedSize(horizontal: true, vertical: false)
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

/// Heat-signal rows. Each signal renders on its own full-width row with
/// a red dot bullet so the full sentence stays readable. Replaces the
/// prior horizontal flow layout, which truncated mid-word on long
/// signals like "Stakes more than doubled while chasing losses".
struct FlowChips: View {
    let signals: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(signals.enumerated()), id: \.offset) { _, signal in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(DS.Color.V3.Severity.red.opacity(0.7))
                        .frame(width: 4, height: 4)
                        .padding(.top, 6)
                    Text(signal)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
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
