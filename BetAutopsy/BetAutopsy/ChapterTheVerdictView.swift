//
//  ChapterTheVerdictView.swift
//  BetAutopsy
//
//  Chapter 1: cold-open hero. Case number, BetIQ ring tinted by archetype
//  color, archetype name, percentile, executive diagnosis as italic verdict,
//  and a pulsing "SWIPE TO BEGIN" hint at the bottom.
//

import SwiftUI

struct ChapterTheVerdictView: View {
    let report: AutopsyReport

    @State private var hintOffset: CGFloat = 0

    private var archetypeColor: Color {
        report.analysis.bettingArchetype?.color ?? DS.Color.Accent.luminol
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Text("CASE \(report.caseNumber)")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.18)
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .padding(.top, DS.Spacing.lg)

                Text(report.analysis.summary.dateRange.uppercased())
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .padding(.top, 6)

                if report.reportType == "snapshot" {
                    LabelChip(text: "FREE SNAPSHOT",
                              color: DS.Color.Accent.luminolSoft)
                        .padding(.top, 6)
                }

                Spacer().frame(height: 80)

                ZStack {
                    Circle()
                        .stroke(archetypeColor, lineWidth: 3)
                        .frame(width: 130, height: 130)
                        .shadow(color: archetypeColor.opacity(0.22),
                                radius: 12, x: 0, y: 0)

                    VStack(spacing: 4) {
                        Text("\(report.analysis.betiq?.score ?? 0)")
                            .font(.system(size: 48, weight: .semibold))
                            .monospacedDigit()
                            .foregroundStyle(DS.Color.Text.primary)

                        Text("BETIQ")
                            .font(.custom("JetBrainsMono-Regular", size: 10))
                            .tracking(10 * 0.15)
                            .foregroundStyle(DS.Color.Text.tertiary)
                    }
                }

                Spacer().frame(height: 24)

                Text(report.analysis.bettingArchetype?.name.uppercased() ?? "")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(22 * 0.22)
                    .foregroundStyle(archetypeColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.lg)

                Spacer().frame(height: 8)

                Text("\(report.analysis.betiq?.percentile ?? 0)TH PERCENTILE")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)

                Spacer().frame(height: 32)

                Text(report.analysis.executiveDiagnosis
                     ?? report.analysis.bettingArchetype?.description
                     ?? "")
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundStyle(DS.Color.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DS.Spacing.xl)

                Spacer()

                HStack(spacing: 6) {
                    Text("SWIPE TO BEGIN")
                        .font(.custom("JetBrainsMono-Regular", size: 10))
                        .tracking(10 * 0.15)
                        .foregroundStyle(DS.Color.Text.tertiary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.Color.Text.tertiary)
                }
                .offset(x: hintOffset)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, DS.Spacing.lg) + 40)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1)
                            .repeatForever(autoreverses: true)
                    ) {
                        hintOffset = 4
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview {
    ChapterTheVerdictView(report: MockReport.heatedBettor)
        .preferredColorScheme(.dark)
}
