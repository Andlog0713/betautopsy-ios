//
//  BetDNAQuizView.swift
//  BetAutopsy
//
//  Step 3: 7-question Quick Start Quiz. Reads questions + scoring from
//  QuizScoring. Answers are recorded into the coordinator; on the last
//  answer, the coordinator computes the archetype and we advance to reveal.
//
//  Per-question style:
//    .default → 22pt section-title + stacked option rows with radio
//    .bold    → 28pt bold title + rows
//    .slider  → 22pt section-title + horizontal 5-segment strip
//
//  Migrated to V3 in PR-V12. Selection accent shifted from luminol (#6B5BFF)
//  to V3.ctaText (#8B86E8) — slightly bluer, softer.
//

import SwiftUI

struct BetDNAQuizView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State private var currentIndex = 0
    @State private var selectedValue: String? = nil
    @State private var isAdvancing = false

    private var questions: [QuizQuestion] { QuizScoring.questions }
    private var question: QuizQuestion { questions[currentIndex] }

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            VStack(alignment: .leading, spacing: DS.Spacing.lg) {
                progressBar
                    .padding(.top, DS.Spacing.md)

                counter

                title
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtext = question.subtext {
                    Text(subtext)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, -DS.Spacing.sm)
                }

                options

                Spacer(minLength: DS.Spacing.md)
            }
            .padding(.horizontal, DS.Spacing.md)
            .padding(.bottom, DS.Spacing.lg)
        }
    }

    // MARK: - Progress + counter

    private var progressBar: some View {
        HStack(spacing: DS.Spacing.xs) {
            ForEach(0..<questions.count, id: \.self) { i in
                Rectangle()
                    .fill(progressColor(for: i))
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
    }

    private func progressColor(for index: Int) -> Color {
        if index < currentIndex { return DS.Color.V3.ctaText }
        if index == currentIndex { return DS.Color.V3.ctaText.opacity(0.6) }
        return DS.Color.V3.surfaceRaised
    }

    private var counter: some View {
        Text("QUESTION \(currentIndex + 1) OF \(questions.count)")
            .font(.system(size: 10, weight: .semibold))
            .monospacedDigit()
            .tracking(10 * 0.18)
            .foregroundStyle(DS.Color.V3.textTertiary)
    }

    // MARK: - Title (per style)

    @ViewBuilder
    private var title: some View {
        switch question.style {
        case .default, .slider:
            Text(question.question)
                .font(DS.Font.V3.sectionTitle)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        case .bold:
            Text(question.question)
                .font(.system(size: 28, weight: .bold))
                .tracking(-28 * 0.015)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
    }

    // MARK: - Options (per style)

    @ViewBuilder
    private var options: some View {
        switch question.style {
        case .default, .bold:
            VStack(spacing: 12) {
                ForEach(question.options) { option in
                    optionRow(option)
                }
            }
        case .slider:
            VStack(spacing: DS.Spacing.sm) {
                HStack(spacing: 6) {
                    ForEach(question.options) { option in
                        sliderSegment(option)
                    }
                }

                HStack {
                    Text("EASY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(10 * 0.18)
                        .foregroundStyle(DS.Color.V3.textTertiary)

                    Spacer()

                    Text("RUINS MY WEEK")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(10 * 0.18)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                }
            }
        }
    }

    // MARK: - Default/bold row

    private func optionRow(_ option: QuizOption) -> some View {
        let isSelected = selectedValue == option.value
        return Button(action: { select(option) }) {
            HStack(alignment: .center, spacing: DS.Spacing.md) {
                radio(selected: isSelected)

                Text(option.label)
                    .font(.system(size: 16))
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(DS.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(isSelected ? DS.Color.V3.surfaceRaised : DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(
                        isSelected ? DS.Color.V3.ctaText : DS.Color.V3.borderSubtle,
                        lineWidth: isSelected ? 1 : DS.Stroke.hairline
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
        .buttonStyle(.plain)
        .disabled(isAdvancing && !isSelected)
    }

    private func radio(selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? DS.Color.V3.ctaText : DS.Color.V3.borderSubtle, lineWidth: 1)
                .frame(width: 14, height: 14)

            if selected {
                Circle()
                    .fill(DS.Color.V3.ctaText)
                    .frame(width: 14, height: 14)

                Circle()
                    .fill(DS.Color.V3.surfaceCard)
                    .frame(width: 10, height: 10)

                Circle()
                    .fill(DS.Color.V3.ctaText)
                    .frame(width: 6, height: 6)
            }
        }
        .frame(width: 14, height: 14)
    }

    // MARK: - Slider segment

    private func sliderSegment(_ option: QuizOption) -> some View {
        let isSelected = selectedValue == option.value
        return Button(action: { select(option) }) {
            Text(option.label)
                .font(.system(size: 16, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(isSelected ? DS.Color.Brand.canvasDark : DS.Color.V3.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isSelected ? DS.Color.V3.ctaText : DS.Color.V3.surfaceCard)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.tile)
                        .stroke(
                            isSelected ? Color.clear : DS.Color.V3.borderSubtle,
                            lineWidth: DS.Stroke.hairline
                        )
                )
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.tile))
        }
        .buttonStyle(.plain)
        .disabled(isAdvancing && !isSelected)
    }

    // MARK: - Selection + advance

    private func select(_ option: QuizOption) {
        guard !isAdvancing else { return }
        selectedValue = option.value
        isAdvancing = true
        coordinator.recordAnswer(questionId: question.id, value: option.value)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            advance()
        }
    }

    private func advance() {
        if currentIndex < questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
            selectedValue = nil
            isAdvancing = false
        } else {
            coordinator.computeArchetype()
            coordinator.advance()
        }
    }
}

#Preview {
    BetDNAQuizView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
