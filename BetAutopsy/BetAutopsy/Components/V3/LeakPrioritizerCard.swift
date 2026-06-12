//
//  LeakPrioritizerCard.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2.5 surface #4: the ranked fix-sequence. Synthesizes
//  BOTH the bias stream (shown in Verdict's DamagesCard) and the leak
//  stream (shown in Findings' WHERE YOU BLEED cards) into one list
//  ordered by dollar cost, so the reader gets a single "fix this first"
//  payoff. Ported from web's Leak Prioritizer (AutopsyReport.tsx
//  2340-2407); the dedup + cost ranking already lives in
//  TotalRecoverable.ranked(for:).
//
//  Deliberately omits web's internal "Total Recoverable" header: that sum
//  is already rendered by TotalRecoverableHero up in SectionVerdict, so
//  repeating it here would double the headline.
//
//  Snapshot: every dollar input is redacted, so TotalRecoverable.ranked
//  is empty. The card instead shows a locked preview ordered by severity
//  (biases) / roi (leaks) with a LockedDollarBar in the cost slot, per
//  the snapshot $-lock convention.
//

import SwiftUI

struct LeakPrioritizerCard: View {
    let report: AutopsyReport
    let onPaywallTap: (String) -> Void

    @State private var expandedId: String?

    private var isSnapshot: Bool { report.reportType == "snapshot" }

    private var items: [PrioritizedItem] {
        if isSnapshot { return snapshotPreviewItems }
        return Array(TotalRecoverable.ranked(for: report.analysis).prefix(6))
    }

    /// Snapshot has no dollar values to rank, so order biases by severity
    /// and leaks by roi, cap at five, and lock every cost slot.
    private var snapshotPreviewItems: [PrioritizedItem] {
        var rows: [PrioritizedItem] = []

        let biases = report.analysis.biasesDetected
            .sorted { $0.severity.sortOrder > $1.severity.sortOrder }
            .prefix(3)
        for bias in biases {
            rows.append(PrioritizedItem(
                rank: rows.count + 1,
                name: bias.biasName,
                type: .bias,
                costDollars: 0,
                costVisibility: "redacted_dollar",
                detail: bias.description,
                fix: bias.fix
            ))
        }

        let leaks = report.analysis.strategicLeaks
            .filter { $0.roiImpact < 0 }
            .sorted { $0.roiImpact < $1.roiImpact }
            .prefix(2)
        for leak in leaks {
            rows.append(PrioritizedItem(
                rank: rows.count + 1,
                name: leak.category,
                type: .leak,
                costDollars: 0,
                costVisibility: "redacted_dollar",
                detail: leak.detail,
                fix: leak.suggestion
            ))
        }

        return Array(rows.prefix(5))
    }

    var body: some View {
        if !items.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    row(for: item)
                    if index < items.count - 1 {
                        V3Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 2)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Row

    // Locked pill is snapshot-only redaction UI. Full-mode items come from
    // TotalRecoverable.ranked, which only emits cost > 0 entries, so a paid
    // report never shows a lock here.
    private func isLocked(_ item: PrioritizedItem) -> Bool {
        isSnapshot
    }

    @ViewBuilder
    private func row(for item: PrioritizedItem) -> some View {
        let expanded = expandedId == item.id
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                rankBadge(item.rank)

                Text(item.name.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.8)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                typeChip(item.type)

                Spacer(minLength: 8)

                costView(item)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedId = expanded ? nil : item.id
                }
            }

            if expanded {
                expandedDetail(for: item)
                    .padding(.top, 12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func rankBadge(_ rank: Int) -> some View {
        Text("\(rank)")
            .font(.system(size: 12, weight: .bold))
            .monospacedDigit()
            .foregroundStyle(DS.Color.Brand.canvasDark)
            .frame(width: 22, height: 22)
            .background(Circle().fill(DS.Color.Brand.yellow))
    }

    private func typeChip(_ type: PrioritizedItemType) -> some View {
        let tint = type == .bias ? DS.Color.V3.Severity.yellow : DS.Color.V3.Severity.red
        return Text(type == .bias ? "BIAS" : "LEAK")
            .font(.system(size: 9, weight: .bold))
            .tracking(1.0)
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous)
                    .fill(tint.opacity(0.15))
            )
    }

    @ViewBuilder
    private func costView(_ item: PrioritizedItem) -> some View {
        if isLocked(item) {
            LockedDollarBar(width: 90, onTap: { onPaywallTap("section_findings_leak_prioritizer_dollar_locked") })
        } else {
            Text(BAFormat.currency(-abs(item.costDollars)))
                .font(.system(size: 14, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.Severity.red)
        }
    }

    @ViewBuilder
    private func expandedDetail(for item: PrioritizedItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let detail = item.detail,
               !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(isSnapshot ? detail.firstSentences(1) : detail)
                    .font(DS.Font.V3.bodyRegular)
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !isSnapshot,
               let fix = item.fix,
               !fix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FIX")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                    Text(fix)
                        .font(DS.Font.V3.bodyRegular)
                        .italic()
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#if DEBUG
#Preview {
    ScrollView {
        VStack(spacing: 24) {
            LeakPrioritizerCard(report: MockReport.heatedBettor, onPaywallTap: { _ in })
        }
        .padding(16)
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
