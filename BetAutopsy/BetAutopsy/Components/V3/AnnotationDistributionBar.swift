//
//  AnnotationDistributionBar.swift
//  BetAutopsy
//
//  5-segment horizontal bar showing the share of bets that fell into
//  each classification (disciplined, neutral, emotional, impulsive,
//  chasing). Used in Ch 3 (Discipline Audit) on top of the new
//  bet_annotations hero section.
//
//  Caption row above the bar reads "CHASING 12%  EMOTIONAL 24%  ..."
//  with each mini-label tinted to its class. No dollar values, safe to
//  render verbatim in snapshot mode.
//

import SwiftUI

struct AnnotationDistributionBar: View {
    let distribution: [ClassificationStats]

    private var total: Int {
        distribution.reduce(0) { $0 + $1.count }
    }

    private var insightText: String?
    init(distribution: [ClassificationStats], insightText: String? = nil) {
        self.distribution = distribution
        self.insightText = insightText
    }

    var body: some View {
        if distribution.isEmpty || total == 0 {
            placeholder
        } else {
            populated
        }
    }

    private var populated: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                HStack(spacing: 1) {
                    ForEach(distribution) { stat in
                        Rectangle()
                            .fill(stat.classification.color)
                            .frame(width: width(for: stat, total: geo.size.width))
                    }
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            legend

            if let insight = insightText?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !insight.isEmpty {
                Text(insight)
                    .font(DS.Font.V3.bodyRegular)
                    .italic()
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
        }
    }

    private var placeholder: some View {
        Text("Annotation data not available.")
            .font(DS.Font.V3.bodyRegular)
            .foregroundStyle(DS.Color.V3.textTertiary)
    }

    /// Stacked legend below the bar (blocker #5). The prior inline caption
    /// row wrapped mid-word on long class labels; one row per class with a
    /// color swatch eliminates any mid-word break.
    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(distribution) { stat in
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(stat.classification.color)
                        .frame(width: 8, height: 8)
                    Text(stat.classification.label)
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.0)
                        .foregroundStyle(stat.classification.color)
                    Spacer(minLength: 8)
                    Text("\(stat.count)")
                        .font(.system(size: 10, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textSecondary)
                    Text(BAFormat.percent(stat.percent, headline: true))
                        .font(.system(size: 10, weight: .regular))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .frame(minWidth: 36, alignment: .trailing)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func width(for stat: ClassificationStats, total: CGFloat) -> CGFloat {
        guard self.total > 0 else { return 0 }
        let ratio = CGFloat(stat.count) / CGFloat(self.total)
        return max(0, total * ratio)
    }
}

#if DEBUG
#Preview {
    AnnotationDistributionBar(
        distribution: [
            ClassificationStats(classification: .disciplined, count: 142, percent: 57.5, totalStaked: 14310, totalProfit: 412, roi: 2.9),
            ClassificationStats(classification: .neutral,     count: 7,   percent: 2.8,  totalStaked: 420,   totalProfit: -17,   roi: -4.0),
            ClassificationStats(classification: .emotional,   count: 48,  percent: 19.4, totalStaked: 7104,  totalProfit: -892,  roi: -12.6),
            ClassificationStats(classification: .impulsive,   count: 18,  percent: 7.3,  totalStaked: 2160,  totalProfit: -510,  roi: -23.6),
            ClassificationStats(classification: .chasing,     count: 32,  percent: 13.0, totalStaked: 6240,  totalProfit: -1840, roi: -29.5)
        ],
        insightText: "57% of your bets were disciplined and made money. The other 43% lost more than three thousand dollars."
    )
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
