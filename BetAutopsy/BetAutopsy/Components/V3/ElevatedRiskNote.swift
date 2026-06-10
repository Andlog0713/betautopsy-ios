//
//  ElevatedRiskNote.swift
//  BetAutopsy
//
//  Elevated-tier note (web ElevatedRiskNote, PR #71). A single dismissible,
//  non-clinical heads-up shown at the top of SectionVerdict when the
//  report-baked riskTier is 'elevated'. No helpline, no metric renaming, no
//  recovery framing - those are recovery-tier only, matching web's
//  message-fatigue gating. Dismissal is per-report via @AppStorage keyed on
//  the report id, mirroring web's per-report localStorage dismissal.
//

import SwiftUI

struct ElevatedRiskNote: View {
    let reportId: String

    @AppStorage private var dismissed: Bool

    init(reportId: String) {
        self.reportId = reportId
        _dismissed = AppStorage(
            wrappedValue: false,
            "elevatedNoteDismissed.\(reportId)"
        )
    }

    var body: some View {
        if !dismissed {
            VStack(alignment: .leading, spacing: 10) {
                Text("This report shows a few elevated-risk patterns worth a look. They are flagged in the findings below. Nothing here is a diagnosis, just a heads-up so you can decide what to adjust.")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Got it") {
                    dismissed = true
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Color.Brand.yellow)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#if DEBUG
#Preview {
    ElevatedRiskNote(reportId: "preview-1")
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.V3.canvasGradientEnd)
        .preferredColorScheme(.dark)
}
#endif
