//
//  LockedDollarBar.swift
//  BetAutopsy
//
//  Forensic-redaction bar that stands in for a paywalled dollar value.
//  Yellow capsule with a $ glyph on the left and a lock icon on the
//  right, sized to slot anywhere a dollar Text would have rendered.
//
//  Used at five snapshot surfaces:
//    Ch 2  HeatedSessionPreviewCard session profit
//    Ch 4  BiasRow estimated_cost column
//    Ch 6  BY DAY tile profit
//    Ch 6  Sport-specific finding ESTIMATED COST line
//    Ch 7  Recommendation projectedImpact label
//
//  Tap fires the existing PaywallView trigger owned by the host chapter
//  (each chapter wires its own showingPaywall state to the onTap).
//
//  Lives in Components/V3/ to match the rest of the era's components;
//  callers reference it as `LockedDollarBar(...)` consistent with
//  BiasRow, TiltSessionCard, PatternCard, ActionCard.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LockedDollarBar: View {
    let width: CGFloat
    let onTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(width: CGFloat = 140, onTap: (() -> Void)? = nil) {
        self.width = width
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: 6) {
            Text("$")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.Color.Brand.canvasDark)
            Spacer(minLength: 0)
            Image(systemName: "lock.fill")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DS.Color.Brand.canvasDark)
        }
        .padding(.horizontal, 12)
        .frame(width: width, height: 32)
        .background(
            Capsule()
                .fill(DS.Color.Brand.yellow.opacity(0.95))
                .overlay(
                    Capsule()
                        .stroke(DS.Color.Brand.yellow, lineWidth: 1)
                )
        )
        .contentShape(Capsule())
        .onTapGesture {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            onTap?()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Locked dollar amount")
        .accessibilityHint("Tap to read the full report for \(RevenueCatStore.shared.priceString)")
        .accessibilityAddTraits(.isButton)
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        LockedDollarBar()
        LockedDollarBar(width: 110)
        LockedDollarBar(width: 70)
        HStack(spacing: 12) {
            Text("ESTIMATED COST")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(DS.Color.V3.textTertiary)
            LockedDollarBar(width: 110)
        }
    }
    .padding(24)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
