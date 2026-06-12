//
//  BiasEvidenceSheet.swift
//  BetAutopsy
//
//  Sheet presentation triggered by tapping a BiasRow in Ch 4. Surfaces
//  the bias's full evidence prose, estimated cost (or LockedDollarBar
//  in snapshot mode), evidence-bet count caption, and full FIX prose.
//
//  Path B render: no individual bet rows are fetched because no
//  /api/bets endpoint exists today and iOS does not access Supabase
//  bets-table directly. The caption ("Based on N specific bets in your
//  history.") preserves the evidence-attribution narrative without
//  requiring a backend endpoint. Adding the endpoint + populating an
//  EVIDENCE BETS list is a future PR.
//

import SwiftUI

struct BiasEvidenceSheet: View {
    let bias: BiasDetected
    var isSnapshot: Bool = false
    var onLockedTap: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    private var severityColor: Color {
        switch bias.severity {
        case .critical, .high: return DS.Color.V3.Severity.red
        case .medium:          return DS.Color.V3.Severity.yellow
        case .low:             return DS.Color.V3.textTertiary
        }
    }

    private var evidenceBetCount: Int {
        bias.evidenceBetIds?.count ?? 0
    }

    private var evidenceText: String {
        let raw = bias.evidence.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Evidence prose unavailable for this bias." : raw
    }

    private var fixText: String {
        let raw = bias.fix.trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? "Fix guidance unavailable for this bias." : raw
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                V3Divider()
                    .padding(.vertical, 16)

                Text("EVIDENCE")
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.4)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Spacer().frame(height: 8)

                Text(evidenceText)
                    .font(DS.Font.V3.bodyRegular)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if evidenceBetCount > 0 {
                    Spacer().frame(height: 12)
                    Text("Based on \(evidenceBetCount) specific bets in your history.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .italic()
                }

                V3Divider()
                    .padding(.vertical, 16)

                Text("FIX")
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.4)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                Spacer().frame(height: 8)

                Text(fixText)
                    .font(DS.Font.V3.bodyRegular)
                    .italic()
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(DS.Color.Brand.canvasDark.ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(bias.biasName)
                .font(DS.Font.V3.sectionTitle)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center, spacing: 12) {
                SeverityChip(severity: bias.severity)
                Spacer()
                costBlock
            }
        }
    }

    @ViewBuilder
    private var costBlock: some View {
        // Locked pill is snapshot-only redaction UI; never in a paid report.
        let locked = isSnapshot
        HStack(spacing: 8) {
            Text("EST. COST")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.Severity.red)
            if locked {
                LockedDollarBar(width: 110, onTap: { onLockedTap?() })
            } else {
                Text(BAFormat.currency(-abs(bias.estimatedCost)))
                    .font(DS.Font.V3.rowValue)
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.Severity.red)
            }
        }
    }
}

#if DEBUG
#Preview {
    BiasEvidenceSheet(
        bias: BiasDetected(
            biasName: "Loss Chasing",
            severity: .critical,
            description: "You bet bigger or more frequently after losses to get even.",
            evidence: "Across 47 wagers placed within 30 minutes of a previous loss, your average stake increased 2.3x your baseline. Win rate on those bets dropped from 41% to 38%, and the cumulative damage was $1,840 over the analyzed period.",
            estimatedCost: 1840,
            fix: "Set a 60-minute cooldown after any loss before placing another bet. Even a phone timer helps.",
            evidenceBetIds: ["b_142", "b_167", "b_189", "b_201", "b_233", "b_271", "b_298", "b_322"]
        )
    )
    .preferredColorScheme(.dark)
}
#endif
