//
//  RepeatedCTABlock.swift
//  BetAutopsy
//
//  Reusable snapshot-mode conversion CTA, placed at multiple scroll
//  positions so the path to the full report is never far away. Two
//  variants set the visual weight and copy:
//
//    .mid       secondary (yellow text + border). "See your full dollar
//               costs (price)." Used mid-chapter as a soft continuation
//               nudge (Ch 4 bias chapter).
//    .terminal  primary (solid yellow). "Read the full report (price)."
//               Used near a chapter end as the firm conversion CTA (Ch 7).
//
//  Copy note: the original spec label for the terminal variant was
//  "Unlock full report," a banned-phrase violation (COPY_SYSTEM §2.1:
//  "Unlock" is casino-coded). The canonical replacement library is §8.
//  The terminal variant uses "See the full autopsy" (§8 list item 3)
//  rather than "Read the full report" specifically so it does NOT duplicate
//  the byte-identical CTA on the adjacent Ch 7 snapshotPaywallCard /
//  PaywallView; both remain canonical full-report CTAs. Price is
//  interpolated from RevenueCatStore.priceString (Step 4).
//
//  Presentational only, mirroring LockedDollarBar: the host owns the
//  showingPaywall sheet state and passes an onTap closure that fires the
//  paywall.triggered analytics signal and presents PaywallView. The host
//  also gates mounting to snapshot mode, so this block never appears in a
//  full report.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct RepeatedCTABlock: View {
    enum Variant {
        case mid
        case terminal
    }

    let variant: Variant
    let onTap: () -> Void

    private var price: String { RevenueCatStore.shared.priceString }

    private var label: String {
        switch variant {
        case .mid:      return "See your full dollar costs (\(price))."
        case .terminal: return "See the full autopsy (\(price))."
        }
    }

    var body: some View {
        Button(action: handleTap) {
            Text(label)
                .font(DS.Font.V3.buttonLabel)
                .foregroundStyle(foreground)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(background)
                .overlay(border)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
    }

    private func handleTap() {
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
        onTap()
    }

    // MARK: - Variant styling

    private var foreground: Color {
        switch variant {
        case .mid:      return DS.Color.Brand.yellow
        case .terminal: return DS.Color.Brand.canvasDark
        }
    }

    @ViewBuilder
    private var background: some View {
        switch variant {
        case .mid:      DS.Color.V3.surfaceCard
        case .terminal: DS.Color.Brand.yellow
        }
    }

    @ViewBuilder
    private var border: some View {
        switch variant {
        case .mid:
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .stroke(DS.Color.Brand.yellowBorder, lineWidth: 1)
        case .terminal:
            EmptyView()
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        RepeatedCTABlock(variant: .mid, onTap: {})
        RepeatedCTABlock(variant: .terminal, onTap: {})
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
