//
//  ProgressRing.swift
//  BetAutopsy
//
//  Compact 44pt completion ring for the dashboard report card. Shows
//  "N/M" centered with a severity-encoded arc indicating ratio:
//    >= 80% completed → V3.Severity.green
//    >= 40% completed → V3.Severity.yellow
//    <  40% completed → V3.Severity.gray (neutral; incomplete is not
//                       a critical state)
//
//  Distinct from HeroRingView, which is 230pt, brand-watermarked, and
//  carries a /100 score. ProgressRing is purely a progress count
//  visualization — no brand chrome.
//

import SwiftUI

struct ProgressRing: View {
    let completed: Int
    let total: Int
    var diameter: CGFloat = 44
    var lineWidth: CGFloat = 4

    private var safeTotal: Int {
        max(1, total)
    }

    private var clampedCompleted: Int {
        max(0, min(safeTotal, completed))
    }

    private var ratio: Double {
        Double(clampedCompleted) / Double(safeTotal)
    }

    private var progress: CGFloat {
        CGFloat(ratio)
    }

    private var ringColor: Color {
        if ratio >= 0.80 { return DS.Color.V3.Severity.green }
        if ratio >= 0.40 { return DS.Color.V3.Severity.yellow }
        return DS.Color.V3.Severity.gray
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(DS.Color.V3.borderRingTrack, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("\(clampedCompleted)/\(safeTotal)")
                .font(.system(size: 10, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textPrimary)
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(clampedCompleted) of \(safeTotal) actions completed")
    }
}

#if DEBUG
#Preview {
    HStack(spacing: 20) {
        ProgressRing(completed: 0, total: 6)
        ProgressRing(completed: 2, total: 6)
        ProgressRing(completed: 3, total: 6)
        ProgressRing(completed: 5, total: 6)
        ProgressRing(completed: 6, total: 6)
    }
    .padding(24)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
