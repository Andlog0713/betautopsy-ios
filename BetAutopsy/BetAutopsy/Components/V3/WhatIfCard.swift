//
//  WhatIfCard.swift
//  BetAutopsy
//
//  REBUILD-PHASE-2.5 surface #3 (fast-follow): the What-If simulator,
//  the sixth and final web content surface. Ported from web's What-If
//  block (AutopsyReport.tsx 2409-2447). Web computes scenarios client-
//  side from the raw bets array; iOS has no bets array, so the engine
//  (a658305) now ships 1-3 precomputed scenarios on `what_if_scenarios`
//  for full reports only.
//
//  Placed in SectionVerdict between DamagesCard and the exec-diagnosis
//  insight (the slot the Phase 2.5 layout left open). The host gates on
//  full-mode + non-empty before instantiating; the card also self-hides
//  when handed an empty array.
//
//  Each scenario: a label, then a three-column readout of ACTUAL / IF
//  FIXED / DELTA. P&L figures are green when non-negative, red when
//  negative; the delta is green when the change helps, red otherwise.
//  All dollar figures use tabular mono digits per the type system.
//

import SwiftUI

struct WhatIfCard: View {
    let scenarios: [WhatIfScenario]

    var body: some View {
        if !scenarios.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WHAT-IF SIMULATOR")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(DS.Color.V3.textTertiary)

                    Text("What each change would have done to your bottom line.")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    ForEach(scenarios) { scenario in
                        scenarioCard(scenario)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func scenarioCard(_ scenario: WhatIfScenario) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(scenario.label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 8) {
                metricColumn(
                    label: "ACTUAL",
                    text: BAFormat.currency(scenario.actual, signed: true),
                    tint: pnlTint(scenario.actual)
                )
                metricColumn(
                    label: "IF FIXED",
                    text: BAFormat.currency(scenario.hypothetical, signed: true),
                    tint: pnlTint(scenario.hypothetical)
                )
                metricColumn(
                    label: "DELTA",
                    text: BAFormat.currency(scenario.deltaDollars, signed: true),
                    tint: scenario.deltaDollars > 0
                        ? DS.Color.V3.Severity.green
                        : (scenario.deltaDollars < 0 ? DS.Color.V3.Severity.red : DS.Color.V3.textSecondary)
                )
            }
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

    private func metricColumn(label: String, text: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(DS.Color.V3.textTertiary)
            Text(text)
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pnlTint(_ value: Double) -> Color {
        value >= 0 ? DS.Color.V3.Severity.green : DS.Color.V3.Severity.red
    }
}

#if DEBUG
private func whatIfPreview(_ scenarios: [WhatIfScenario]) -> some View {
    ScrollView {
        VStack(spacing: 24) {
            WhatIfCard(scenarios: scenarios)
        }
        .padding(16)
    }
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}

#Preview("All 3 scenarios") {
    // Losing bettor: parlays present, mixed profitability. Every fix helps.
    whatIfPreview([
        WhatIfScenario(label: "Flat-staked at $51 on every bet", actual: -4280, hypothetical: -1190),
        WhatIfScenario(label: "Eliminated all parlays over 3 legs", actual: -4280, hypothetical: -2010),
        WhatIfScenario(label: "Only bet your profitable sports/types", actual: -4280, hypothetical: 640),
    ])
}

#Preview("1 scenario only") {
    // Uniform sizing, no big parlays, no profitable subset: only the flat-
    // stake counterfactual survives engine-side.
    whatIfPreview([
        WhatIfScenario(label: "Flat-staked at $51 on every bet", actual: -1850, hypothetical: -940),
    ])
}

#Preview("Winning bettor (negative deltas)") {
    // Already profitable: the alternatives are worse than reality, so every
    // delta is negative (red).
    whatIfPreview([
        WhatIfScenario(label: "Flat-staked at $51 on every bet", actual: 3200, hypothetical: 1100),
        WhatIfScenario(label: "Only bet your profitable sports/types", actual: 3200, hypothetical: 2450),
    ])
}
#endif
