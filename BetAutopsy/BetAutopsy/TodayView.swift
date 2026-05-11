//
//  TodayView.swift
//  BetAutopsy
//
//  Today tab. Mock data only — no API calls in PR-1.
//

import SwiftUI

struct TodayView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    @AppStorage("userArchetype")         private var userArchetype: String = ""
    @AppStorage("userArchetypeColorHex") private var userArchetypeColorHex: String = ""
    @AppStorage("userEmotionScore")      private var userEmotionScore: Int = 0
    @AppStorage("userDisciplineScore")   private var userDisciplineScore: Int = 0

    private var hasArchetype: Bool { !userArchetype.isEmpty }

    private var archetypeColor: Color {
        userArchetypeColorHex.isEmpty
            ? DS.Color.Accent.luminol
            : Color(hex: userArchetypeColorHex)
    }

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.Spacing.lg) {
                    caseHeader
                        .padding(.top, DS.Spacing.md)

                    heroRing
                        .padding(.top, DS.Spacing.lg)

                    archetypeLabel

                    verdict
                        .padding(.horizontal, DS.Spacing.xl)

                    rangeCard
                        .padding(.horizontal, DS.Spacing.md)
                        .padding(.top, DS.Spacing.sm)

                    Spacer(minLength: DS.Spacing.xl)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Case header

    private var caseHeader: some View {
        Text("CASE 0247 · MAY 11")
            .font(.custom("JetBrainsMono-Regular", size: 11))
            .tracking(11 * 0.15)
            .foregroundStyle(DS.Color.Text.tertiary)
    }

    // MARK: - Hero ring

    private var heroRing: some View {
        ZStack {
            Circle()
                .stroke(archetypeColor, lineWidth: 3)
                .frame(width: 130, height: 130)
                .shadow(color: archetypeColor.opacity(0.22), radius: 12, x: 0, y: 0)

            VStack(spacing: DS.Spacing.xxs) {
                Text("87")
                    .font(.system(size: 48, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Text.primary)

                Text("BETIQ")
                    .font(.custom("JetBrainsMono-Regular", size: 8))
                    .tracking(8 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
            }
        }
    }

    // MARK: - Archetype label / assessment CTA

    @ViewBuilder
    private var archetypeLabel: some View {
        if hasArchetype {
            Text(userArchetype.uppercased())
                .font(.custom("Inter-Bold", size: 14))
                .tracking(14 * 0.22)
                .foregroundStyle(DS.Color.Accent.luminolSoft)
        } else {
            Button(action: { coordinator.reset() }) {
                Text("TAKE YOUR ASSESSMENT")
                    .font(.custom("JetBrainsMono-Regular", size: 12))
                    .tracking(12 * 0.15)
                    .foregroundStyle(DS.Color.Accent.luminolSoft)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule()
                            .stroke(DS.Color.Accent.luminol, lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Verdict

    private var verdict: some View {
        Text("Your impatience cost you $2,847 since November.")
            .font(.custom("Georgia-Italic", size: 17))
            .foregroundStyle(DS.Color.Text.secondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Range card

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.lg) {
            RangeBar(label: "Discipline", value: userDisciplineScore, dotColor: DS.Color.Accent.luminol)
            RangeBar(label: "Emotion score", value: userEmotionScore, dotColor: DS.Color.Semantic.blood)
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
}

// MARK: - RangeBar

private struct RangeBar: View {
    let label: String
    let value: Int
    let dotColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: DS.Spacing.sm) {
                Text(label)
                    .font(.custom("Inter-Medium", size: 13))
                    .foregroundStyle(DS.Color.Text.secondary)

                Spacer()

                Text("\(value)")
                    .font(.custom("JetBrainsMono-Medium", size: 13))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.Text.primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DS.Color.Surface.raised)
                        .frame(height: 4)

                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(DS.Color.Surface.canvas, lineWidth: 1.5)
                        )
                        .offset(x: max(0, min(geo.size.width - 8, geo.size.width * CGFloat(value) / 100 - 4)))
                }
                .frame(height: 8)
            }
            .frame(height: 8)
        }
    }
}

#Preview {
    TodayView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
