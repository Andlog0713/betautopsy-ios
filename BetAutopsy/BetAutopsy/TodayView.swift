//
//  TodayView.swift
//  BetAutopsy
//
//  Today tab. Mock data only — no API calls in PR-1.
//
//  PR-V10 Phase 2: token migration only. Visual structure preserved.
//  Inline hero ring kept (130pt archetype-tinted) rather than swapping
//  to HeroRingView (230pt severity-tinted) because the smaller
//  archetype-colored summary widget is intentionally distinct from the
//  chapter-view hero. Token swap only.
//

import SwiftUI

struct TodayView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    @AppStorage("userArchetype")         private var userArchetype: String = ""
    @AppStorage("userArchetypeColorHex") private var userArchetypeColorHex: String = ""
    @AppStorage("userEmotionScore")      private var userEmotionScore: Int = 0
    @AppStorage("userDisciplineScore")   private var userDisciplineScore: Int = 0

    @State private var showingCheckIn = false

    private var hasArchetype: Bool { !userArchetype.isEmpty }

    private var archetypeColor: Color {
        userArchetypeColorHex.isEmpty
            ? DS.Color.V3.ctaText
            : Color(hex: userArchetypeColorHex)
    }

    private var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [
                DS.Color.V3.canvasGradientStart,
                DS.Color.V3.canvasGradientEnd
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            canvasGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    caseHeader
                        .padding(.top, 16)

                    heroRing
                        .padding(.top, 24)

                    archetypeLabel

                    verdict
                        .padding(.horizontal, 32)

                    aboutToBetCard
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    rangeCard
                        .padding(.horizontal, 16)

                    Spacer(minLength: 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            PreBetCheckInView()
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - About to bet CTA

    private var aboutToBetCard: some View {
        Button {
            showingCheckIn = true
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("About to bet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Color.V3.textPrimary)
                    Text("Check this bet before you place it.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.ctaText)
                    .frame(width: 36, height: 36)
                    .background(DS.Color.V3.surfaceRaised)
                    .clipShape(Circle())
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DS.Color.V3.ctaText.opacity(0.5), lineWidth: 0.75)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Case header

    private var caseHeader: some View {
        Text("CASE 0247 · MAY 11")
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.65)
            .foregroundStyle(DS.Color.V3.textTertiary)
    }

    // MARK: - Hero ring

    private var heroRing: some View {
        ZStack {
            Circle()
                .stroke(archetypeColor, lineWidth: 3)
                .frame(width: 130, height: 130)
                .shadow(color: archetypeColor.opacity(0.22), radius: 12, x: 0, y: 0)

            VStack(spacing: 2) {
                Text("87")
                    .font(.system(size: 48, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)

                Text("BETIQ")
                    .font(.system(size: 8, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(DS.Color.V3.textTertiary)
            }
        }
    }

    // MARK: - Archetype label / assessment CTA

    @ViewBuilder
    private var archetypeLabel: some View {
        if hasArchetype {
            Text(userArchetype.uppercased())
                .font(.system(size: 14, weight: .bold))
                .tracking(3.08)
                .foregroundStyle(DS.Color.V3.ctaText)
        } else {
            Button(action: { coordinator.reset() }) {
                Text("TAKE YOUR ASSESSMENT")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(DS.Color.V3.ctaText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule()
                            .stroke(DS.Color.V3.ctaText, lineWidth: 1)
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
            .foregroundStyle(DS.Color.V3.textSecondary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Range card

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            RangeBar(
                label: "Discipline",
                value: userDisciplineScore,
                dotColor: DS.Color.V3.Severity.zoneColor(
                    forScore: userDisciplineScore,
                    higherIsWorse: false
                )
            )
            RangeBar(
                label: "Emotion score",
                value: userEmotionScore,
                dotColor: DS.Color.V3.Severity.red
            )
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - RangeBar

private struct RangeBar: View {
    let label: String
    let value: Int
    let dotColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Color.V3.textSecondary)

                Spacer()

                Text("\(value)")
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DS.Color.V3.surfaceRaised)
                        .frame(height: 4)

                    Circle()
                        .fill(dotColor)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(DS.Color.V3.canvasGradientEnd, lineWidth: 1.5)
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
