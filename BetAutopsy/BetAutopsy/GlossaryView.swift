//
//  GlossaryView.swift
//  BetAutopsy
//
//  Browseable library of the behavioral patterns BetAutopsy looks for
//  in user-uploaded bet histories. Sourced from BehavioralPatternsData
//  (engine emit names + classic cognitive biases).
//
//  Mounted as a NavigationLink from SettingsView's Legal section.
//  Apple Guideline 4.2 thin-app defense per
//  APPLE_REVIEW_COMPLIANCE.md §13.
//

import SwiftUI

struct GlossaryView: View {
    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    Text("\(BehavioralPatterns.all.count) patterns BetAutopsy looks for in your bets.")
                        .font(DS.Font.V3.bodyRegular)
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.top, DS.Spacing.sm)
                        .padding(.bottom, DS.Spacing.md)

                    ForEach(BehavioralPatterns.all) { pattern in
                        patternRow(pattern)
                    }

                    ResponsibleUseLink()
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.lg)
                }
            }
        }
        .navigationTitle("Behavioral Patterns")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func patternRow(_ pattern: GlossaryEntry) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                Text(pattern.definition)
                    .font(DS.Font.V3.bodyRegular)
                    .foregroundStyle(DS.Color.V3.textPrimary)
                Text(pattern.example)
                    .font(.system(size: 13, weight: .regular).italic())
                    .foregroundStyle(DS.Color.V3.textSecondary)
            }
            .padding(.top, DS.Spacing.xs)
        } label: {
            Text(pattern.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.sm)
        .tint(DS.Color.Brand.yellow)
    }
}

#Preview {
    NavigationStack {
        GlossaryView()
    }
    .preferredColorScheme(.dark)
}
