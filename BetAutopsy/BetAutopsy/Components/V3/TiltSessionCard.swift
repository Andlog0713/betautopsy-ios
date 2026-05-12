//
//  TiltSessionCard.swift
//  BetAutopsy
//
//  V3 tilt session card. Used in Chapter 2 (The Tilt File) to show
//  evidence-driven heated sessions: date, time range, net P&L,
//  optional bet count, optional trigger and behavioral signal.
//
//  The chapter view filters + sorts + limits sessions; this card
//  renders whatever it receives.
//

import SwiftUI

struct TiltSessionCard: View {
    struct Session: Identifiable, Hashable {
        let id: UUID
        let dateLabel: String         // "DEC 3"
        let timeRangeLabel: String    // "11:14 PM - 1:38 AM"
        let pnl: Int                  // signed; negative = loss
        let betCount: Int?            // rendered only if > 1
        let triggerLabel: String?     // optional, will be uppercased
        let behavioralSignal: String? // optional, will be uppercased

        init(
            dateLabel: String,
            timeRangeLabel: String,
            pnl: Int,
            betCount: Int? = nil,
            triggerLabel: String? = nil,
            behavioralSignal: String? = nil
        ) {
            self.id = UUID()
            self.dateLabel = dateLabel
            self.timeRangeLabel = timeRangeLabel
            self.pnl = pnl
            self.betCount = betCount
            self.triggerLabel = triggerLabel
            self.behavioralSignal = behavioralSignal
        }
    }

    let session: Session

    private var pnlLabel: String {
        let absVal = abs(session.pnl)
        let sign = session.pnl < 0 ? "-" : "+"
        return "\(sign)$\(absVal)"
    }

    private var pnlColor: Color {
        session.pnl < 0 ? DS.Color.V3.Severity.red : DS.Color.V3.textPrimary
    }

    private var accessibilityDescription: String {
        var parts: [String] = [
            "\(session.dateLabel) \(session.timeRangeLabel)",
            "Net \(pnlLabel) dollars"
        ]
        if let betCount = session.betCount, betCount > 1 {
            parts.append("\(betCount) bets")
        }
        if let trigger = session.triggerLabel,
           !trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append("Triggered by \(trigger)")
        }
        if let signal = session.behavioralSignal,
           !signal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(signal)
        }
        return parts.joined(separator: ". ") + "."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.dateLabel)
                        .font(DS.Font.V3.rowCapsLabel)
                        .tracking(1.1)
                        .foregroundStyle(DS.Color.V3.textPrimary)
                    Text(session.timeRangeLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                }
                Spacer()
                Text(pnlLabel)
                    .font(DS.Font.V3.rowValue)
                    .monospacedDigit()
                    .foregroundStyle(pnlColor)
            }

            if let betCount = session.betCount, betCount > 1 {
                Text("\(betCount) BETS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }

            if let trigger = session.triggerLabel,
               !trigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(DS.Color.V3.Severity.red)
                    Text("TRIGGERED BY: \(trigger.uppercased())")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineLimit(2)
                }
                .padding(.top, 2)
            }

            if let signal = session.behavioralSignal,
               !signal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(signal.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.0)
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 14)
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
        TiltSessionCard(session: TiltSessionCard.Session(
            dateLabel: "DEC 3",
            timeRangeLabel: "11:14 PM - 1:38 AM",
            pnl: -920,
            betCount: 8,
            triggerLabel: "Loss chasing",
            behavioralSignal: "Stake escalated 3x"
        ))
        TiltSessionCard(session: TiltSessionCard.Session(
            dateLabel: "NOV 22",
            timeRangeLabel: "11:42 PM - 12:51 AM",
            pnl: -540,
            betCount: 5
        ))
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
