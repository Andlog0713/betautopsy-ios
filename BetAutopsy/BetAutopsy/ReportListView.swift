//
//  ReportListView.swift
//  BetAutopsy
//
//  Reports tab. Lists available reports as case-file cards; tap opens the
//  full ReportView as a fullScreenCover. PR-3 ships one mock report.
//

import SwiftUI

struct ReportListView: View {
    @State private var presentedReport: AutopsyReport?

    private let report = MockReport.heatedBettor

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("AUTOPSY REPORTS")
                        .font(.custom("JetBrainsMono-Regular", size: 10))
                        .tracking(10 * 0.15)
                        .foregroundStyle(DS.Color.Text.tertiary)
                        .padding(.top, DS.Spacing.md)

                    Text("Your behavioral diagnostics")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(DS.Color.Text.primary)
                        .padding(.top, DS.Spacing.xs)

                    Button {
                        presentedReport = report
                    } label: {
                        reportCard
                            .padding(.top, DS.Spacing.xl)
                    }
                    .buttonStyle(.plain)

                    Text("More reports unlock after each weekly upload.")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.Text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, DS.Spacing.xl)
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.xl)
            }
        }
        .fullScreenCover(item: $presentedReport) { r in
            ReportView(report: r)
        }
    }

    private var reportCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("CASE \(report.caseNumber)")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                Spacer()
                Text("TAP TO READ")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Accent.luminolSoft)
            }

            Text(report.analysis.bettingArchetype?.name ?? "Report")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .padding(.top, DS.Spacing.sm)

            Text("\(report.betCountAnalyzed) bets analyzed")
                .font(.custom("JetBrainsMono-Regular", size: 13))
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.top, 2)

            Text("Your impatience cost you \(formatCurrency(abs(report.analysis.summary.totalProfit))) since November.")
                .font(.custom("Georgia-Italic", size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .padding(.top, DS.Spacing.md)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.md)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }
}
