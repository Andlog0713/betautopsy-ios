//
//  TriggerEventChip.swift
//  BetAutopsy
//
//  Small pill rendered above a heated session card when the engine
//  attributed a specific trigger to the session. Tint, icon, and caps
//  label are driven by the trigger type ("loss", "late_night",
//  "stake_volatility"). Unknown types fall through to a neutral chrome.
//

import SwiftUI

struct TriggerEventChip: View {
    let event: TriggerEvent

    private var tint: Color {
        switch event.type {
        case "loss":             return DS.Color.V3.Severity.red
        case "late_night":       return DS.Color.V3.Severity.orange
        case "stake_volatility": return DS.Color.V3.Severity.yellow
        default:                 return DS.Color.V3.textTertiary
        }
    }

    private var iconName: String {
        switch event.type {
        case "loss":             return "arrow.down.right.circle.fill"
        case "late_night":       return "moon.fill"
        case "stake_volatility": return "dollarsign.circle.fill"
        default:                 return "exclamationmark.circle.fill"
        }
    }

    private var label: String {
        switch event.type {
        case "loss":             return "POST LOSS"
        case "late_night":       return "LATE NIGHT"
        case "stake_volatility": return "STAKE SPIKE"
        default:                 return "TRIGGERED"
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(tint)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous)
                .fill(tint.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous)
                        .stroke(tint.opacity(0.3), lineWidth: DS.Stroke.hairline)
                )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trigger: \(label). \(event.description)")
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 10) {
        TriggerEventChip(event: TriggerEvent(
            type: "loss",
            description: "Started 14 minutes after a $420 NFL loss settled.",
            triggeringBetId: "b_4422"
        ))
        TriggerEventChip(event: TriggerEvent(
            type: "late_night",
            description: "First bet placed at 12:47 AM.",
            triggeringBetId: nil
        ))
        TriggerEventChip(event: TriggerEvent(
            type: "stake_volatility",
            description: "Average stake jumped 2.6x baseline within the session.",
            triggeringBetId: nil
        ))
        TriggerEventChip(event: TriggerEvent(
            type: "unknown_future_type",
            description: "Fallthrough rendering for engine variation.",
            triggeringBetId: nil
        ))
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
