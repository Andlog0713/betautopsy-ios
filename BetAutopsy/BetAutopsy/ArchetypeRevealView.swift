//
//  ArchetypeRevealView.swift
//  BetAutopsy
//
//  Step 5: render the computed archetype from coordinator.quizResult.
//  Animation timing matches PR-2 sequence: 0–800ms underline reveal,
//  200/600 name, 800/400 description, 1100/400 stats, 1400/400 CTA.
//

import SwiftUI

struct ArchetypeRevealView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    @State private var underlineProgress: CGFloat = 0
    @State private var nameVisible = false
    @State private var descriptionVisible = false
    @State private var statsVisible = false
    @State private var ctaVisible = false

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            if let result = coordinator.quizResult {
                revealLayout(for: result)
            } else {
                fallbackLoading
            }
        }
        .onAppear(perform: runRevealSequence)
    }

    // MARK: - Layout

    private func revealLayout(for result: QuizResult) -> some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                Text("YOUR ARCHETYPE")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .padding(.top, 48)

                Spacer().frame(height: 80)

                Text(result.archetype.name)
                    .font(.system(size: 36, weight: .bold))
                    .tracking(36 * 0.02)
                    .foregroundStyle(DS.Color.Text.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)
                    .opacity(nameVisible ? 1 : 0)
                    .offset(y: nameVisible ? 0 : 12)

                Spacer().frame(height: DS.Spacing.md)

                RoundedRectangle(cornerRadius: 1)
                    .fill(result.archetype.color)
                    .frame(width: 80 * underlineProgress, height: 2)
                    .frame(width: 80, height: 2, alignment: .leading)

                Spacer().frame(height: DS.Spacing.xl)

                Text(result.archetype.description)
                    .font(.custom("Georgia-Italic", size: 17))
                    .foregroundStyle(DS.Color.Text.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, DS.Spacing.xl)
                    .opacity(descriptionVisible ? 1 : 0)

                Spacer()

                HStack(spacing: 0) {
                    statBlock(label: "EMOTION SCORE", value: "\(result.emotionEstimate)", tint: result.archetype.color)
                    statBlock(label: "DISCIPLINE",    value: "\(result.disciplineEstimate)", tint: result.archetype.color)
                    statBlock(label: "GRADE",         value: result.grade, tint: result.archetype.color)
                }
                .padding(.horizontal, DS.Spacing.lg)
                .opacity(statsVisible ? 1 : 0)

                Spacer().frame(height: DS.Spacing.lg)

                Button(action: { coordinator.completeOnboarding() }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(DS.Color.Text.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.card)
                                .stroke(DS.Color.Accent.luminol, lineWidth: 1)
                        )
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.bottom, max(geo.safeAreaInsets.bottom, DS.Spacing.lg) + DS.Spacing.lg)
                .opacity(ctaVisible ? 1 : 0)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func statBlock(label: String, value: String, tint: Color) -> some View {
        VStack(spacing: DS.Spacing.xs) {
            Text(label)
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
    }

    private var fallbackLoading: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .tint(DS.Color.Text.tertiary)
            Text("CALCULATING")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
        }
    }

    // MARK: - Animation

    private func runRevealSequence() {
        withAnimation(.easeOut(duration: 0.8)) {
            underlineProgress = 1
        }
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            nameVisible = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(0.8)) {
            descriptionVisible = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(1.1)) {
            statsVisible = true
        }
        withAnimation(.easeOut(duration: 0.4).delay(1.4)) {
            ctaVisible = true
        }
    }
}

#Preview {
    let coord = OnboardingCoordinator()
    coord.recordAnswer(questionId: "q3", value: "max")
    coord.recordAnswer(questionId: "q4", value: "yes")
    coord.recordAnswer(questionId: "q5", value: "swing")
    coord.recordAnswer(questionId: "q1", value: "bigger")
    coord.recordAnswer(questionId: "q7", value: "roll")
    coord.recordAnswer(questionId: "q10", value: "rush")
    coord.recordAnswer(questionId: "q14", value: "extreme")
    coord.computeArchetype()
    return ArchetypeRevealView()
        .environment(coord)
        .preferredColorScheme(.dark)
}
