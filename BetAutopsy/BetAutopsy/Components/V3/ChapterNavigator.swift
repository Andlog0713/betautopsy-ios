//
//  ChapterNavigator.swift
//  BetAutopsy
//
//  V3 chapter navigator: chevron-left, "CHAPTER 01", chevron-right,
//  info glyph, and a single-line subtitle below.
//
//  V1 (PR-V1): chevrons + info are DECORATIVE. No tap targets.
//  Wired-up navigation is a v1.1 cascade item.
//

import SwiftUI

struct ChapterNavigator: View {
    let chapterNumber: Int   // 1...7
    let subtitle: String     // e.g. "THE VERDICT"

    private var chapterLabel: String {
        String(format: "CHAPTER %02d", chapterNumber)
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.iconStroke.opacity(0.7))

                Text(chapterLabel)
                    .font(DS.Font.V3.navigatorLabel)
                    .tracking(1.2)
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.iconStroke.opacity(0.7))

                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(DS.Color.V3.iconStroke.opacity(0.7))
                    .padding(.leading, 6)
            }

            Text(subtitle.uppercased())
                .font(DS.Font.V3.navigatorSubtitle)
                .tracking(1.6)
                .foregroundStyle(DS.Color.V3.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Chapter \(chapterNumber), \(subtitle)")
    }
}

#Preview {
    VStack {
        ChapterNavigator(chapterNumber: 1, subtitle: "THE VERDICT")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
