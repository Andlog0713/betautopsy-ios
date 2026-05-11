//
//  ChapterYourNext7DaysView.swift
//  BetAutopsy
//
//  Chapter 7: the four behavioral changes ranked by priority, plus a final
//  luminol-filled card with a "Continue" button that dismisses the report.
//

import SwiftUI

struct ChapterYourNext7DaysView: View {
    let report: AutopsyReport

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ChapterHeader(
                    chipText: "YOUR NEXT 7 DAYS",
                    alertChip: (text: "ACTION", color: DS.Color.Accent.luminolSoft),
                    title: "Four changes that recover most of the bleed.",
                    pullQuote: "Behavioral changes ranked by expected dollar recovery. Start with one."
                )
                .padding(.top, DS.Spacing.md)

                ForEach(report.analysis.recommendations
                        .sorted { $0.priority < $1.priority }) { rec in
                    recommendationCard(rec).padding(.top, DS.Spacing.md)
                }

                finalCard.padding(.top, DS.Spacing.xl)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, 60)
        }
    }

    private func recommendationCard(_ rec: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                LabelChip(text: "PRIORITY \(rec.priority)", color: DS.Color.Accent.luminolSoft)
                LabelChip(text: rec.difficulty.uppercased(),
                          color: DS.Color.Text.tertiary,
                          bgOpacity: 0.0)
                    .background(DS.Color.Surface.raised)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tile))
                Spacer()
            }

            Text(rec.title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .padding(.top, DS.Spacing.sm)
                .fixedSize(horizontal: false, vertical: true)

            Text(rec.description)
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .padding(.top, 4)
                .fixedSize(horizontal: false, vertical: true)

            Text(rec.expectedImprovement)
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .monospacedDigit()
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Semantic.win)
                .padding(.top, DS.Spacing.sm)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private var finalCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if report.reportType == "snapshot" {
                snapshotCardContent
            } else {
                fullCardContent
            }
        }
        .padding(DS.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.Accent.luminol)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    @ViewBuilder
    private var fullCardContent: some View {
        Text("We'll re-run your autopsy next Sunday.")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(DS.Color.Text.primary)
            .fixedSize(horizontal: false, vertical: true)

        Text("Upload a fresh CSV to see what changed.")
            .font(.system(size: 15))
            .foregroundStyle(DS.Color.Text.primary.opacity(0.85))
            .padding(.top, 6)
            .fixedSize(horizontal: false, vertical: true)

        Button(action: { dismiss() }) {
            Text("Continue")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Color.Text.primary, lineWidth: 1)
                )
        }
        .padding(.top, DS.Spacing.md)
    }

    @ViewBuilder
    private var snapshotCardContent: some View {
        Text("See your full autopsy.")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(DS.Color.Text.primary)
            .fixedSize(horizontal: false, vertical: true)

        Text("Unlock the dollar costs, recommendations, and session details for $9.99.")
            .font(.system(size: 15))
            .foregroundStyle(DS.Color.Text.primary.opacity(0.85))
            .lineSpacing(3)
            .padding(.top, 6)
            .fixedSize(horizontal: false, vertical: true)

        Button(action: handleUnlock) {
            Text("Unlock the full autopsy")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Color.Text.primary, lineWidth: 1)
                )
        }
        .padding(.top, DS.Spacing.md)
    }

    private func handleUnlock() {
        #if DEBUG
        print("Paywall would open here — PR-7")
        #endif
    }
}

#Preview {
    ChapterYourNext7DaysView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
