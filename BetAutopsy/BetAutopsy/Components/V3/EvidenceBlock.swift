//
//  EvidenceBlock.swift
//  BetAutopsy
//
//  3B component library: THE tap-expand evidence layer of the
//  three-layer report (60-second skim / 5-8 minute read / tap-expand
//  evidence). Renders a finding's sub_splits (web PR #74) as
//  comparison rows behind a collapsed "Evidence" affordance, so the
//  numbers expand on tap instead of living in prose.
//
//  Row shape: label over "1,226 bets · ROI -12.4% · -$9,805". All
//  numbers BAFormat. Null roiPct / netUSD segments are omitted, and
//  isSnapshot suppresses the dollar segment entirely (the engine nulls
//  net_usd in snapshot mode; the flag keeps the contract explicit).
//
//  Pre-#74 reports have no sub_splits: pass the evidence sentence as
//  fallbackProse and the block renders it in the expanded layer
//  instead. With no splits AND no prose the block renders nothing.
//
//  Value-driven: takes decoded values, never AutopsyReport.
//

import SwiftUI

struct EvidenceBlock: View {
    let splits: [FindingSubSplit]
    var confidence: String? = nil
    var fallbackProse: String? = nil
    let isSnapshot: Bool
    var initiallyExpanded: Bool = false
    var onExpand: (() -> Void)? = nil

    @State private var expanded: Bool
    @State private var hasFiredExpandSignal = false

    init(
        splits: [FindingSubSplit],
        confidence: String? = nil,
        fallbackProse: String? = nil,
        isSnapshot: Bool,
        initiallyExpanded: Bool = false,
        onExpand: (() -> Void)? = nil
    ) {
        self.splits = splits
        self.confidence = confidence
        self.fallbackProse = fallbackProse
        self.isSnapshot = isSnapshot
        self.initiallyExpanded = initiallyExpanded
        self.onExpand = onExpand
        var startExpanded = initiallyExpanded
        #if DEBUG
        startExpanded = startExpanded || DebugReveal.forceExpandEvidence
        #endif
        self._expanded = State(initialValue: startExpanded)
    }

    private var trimmedProse: String? {
        guard let prose = fallbackProse?.trimmingCharacters(in: .whitespacesAndNewlines),
              !prose.isEmpty else { return nil }
        return prose
    }

    private var hasContent: Bool {
        !splits.isEmpty || trimmedProse != nil
    }

    private var trimmedConfidence: String? {
        guard let c = confidence?.trimmingCharacters(in: .whitespacesAndNewlines),
              !c.isEmpty else { return nil }
        return c
    }

    var body: some View {
        if hasContent {
            VStack(alignment: .leading, spacing: 0) {
                header

                if expanded {
                    VStack(alignment: .leading, spacing: 10) {
                        if !splits.isEmpty {
                            ForEach(splits) { split in
                                splitRow(split)
                            }
                        } else if let prose = trimmedProse {
                            Text(prose)
                                .font(DS.Font.V3.bodyRegular)
                                .foregroundStyle(DS.Color.V3.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 10)
                }
            }
        }
    }

    private var header: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                expanded.toggle()
            }
            if expanded, !hasFiredExpandSignal {
                hasFiredExpandSignal = true
                onExpand?()
            }
        } label: {
            HStack(spacing: 8) {
                Text("EVIDENCE")
                    .font(DS.Font.V3.rowCapsLabel)
                    .tracking(1.4)
                    .foregroundStyle(DS.Color.V3.textTertiary)

                if let conf = trimmedConfidence {
                    Text("\(conf.uppercased()) CONFIDENCE")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DS.Color.V3.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous))
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .rotationEffect(.degrees(expanded ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(expanded ? "Evidence, expanded. Tap to collapse." : "Evidence. Tap to expand.")
    }

    @ViewBuilder
    private func splitRow(_ split: FindingSubSplit) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(split.label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(metricsLine(for: split))
                .font(.system(size: 12, weight: .regular))
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(split.label): \(metricsLine(for: split))")
    }

    private func metricsLine(for split: FindingSubSplit) -> String {
        var segments: [String] = [BAFormat.sampleSize(split.bets)]
        if let roi = split.roiPct {
            segments.append("ROI \(BAFormat.percent(roi, signed: true))")
        }
        if !isSnapshot, let net = split.netUSD {
            segments.append(BAFormat.currency(net, signed: true))
        }
        return segments.joined(separator: " \u{00B7} ")
    }
}

#if DEBUG
#Preview {
    VStack(alignment: .leading, spacing: 24) {
        // Full mode: splits with dollars, high confidence, expanded.
        EvidenceBlock(
            splits: [
                FindingSubSplit(label: "Bets after a loss", bets: 1226, roiPct: -12.43, netUSD: -9804.69),
                FindingSubSplit(label: "Bets after a win", bets: 730, roiPct: 9.31, netUSD: 2378.38)
            ],
            confidence: "high",
            isSnapshot: false,
            initiallyExpanded: true
        )
        // Snapshot: netUSD null on the wire; bets + ROI only.
        EvidenceBlock(
            splits: [
                FindingSubSplit(label: "Bets after a loss", bets: 1226, roiPct: -12.43, netUSD: nil),
                FindingSubSplit(label: "Bets after a win", bets: 730, roiPct: 9.31, netUSD: nil)
            ],
            confidence: "medium",
            isSnapshot: true,
            initiallyExpanded: true
        )
        // Pre-#74: no splits, prose fallback, collapsed.
        EvidenceBlock(
            splits: [],
            fallbackProse: "Across 47 wagers placed within 30 minutes of a previous loss, your average stake increased 2.3x your baseline.",
            isSnapshot: false
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
