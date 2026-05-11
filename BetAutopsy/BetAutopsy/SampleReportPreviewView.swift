//
//  SampleReportPreviewView.swift
//  BetAutopsy
//
//  Step 2: preview what an analyzed report looks like before the user invests
//  any effort. Single sample chapter card, fades on scroll.
//

import SwiftUI

struct SampleReportPreviewView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: DS.Spacing.md) {
                        header
                            .padding(.top, DS.Spacing.lg)
                            .padding(.bottom, DS.Spacing.md)

                        sampleCard
                            .padding(.horizontal, DS.Spacing.md)
                            .scrollTransition { content, phase in
                                content.opacity(1.0 - abs(phase.value) * 0.6)
                            }

                        Spacer(minLength: DS.Spacing.xxl)
                    }
                }

                bottomActions
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("SAMPLE REPORT")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(11 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Text("Here's what we'll find in yours.")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.lg)

            Text("Behavioral patterns most bettors never see in themselves.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.Text.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, DS.Spacing.lg)
        }
    }

    // MARK: - Sample chapter card

    private var sampleCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm) {
                chip("CONFIRMATION BIAS", textColor: DS.Color.Text.tertiary, background: DS.Color.Surface.raised)
                chip("NOTABLE", textColor: DS.Color.Semantic.blood, background: DS.Color.Semantic.blood.opacity(0.18))
            }

            Text("You only remember the wins that proved you right.")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text("47 wagers after a winning bet. Stakes increased 2.3x. Win rate did not.")
                .font(.custom("Georgia-Italic", size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("EVIDENCE: 47 wagers · IMPACT: -$2,847")
                .font(.custom("JetBrainsMono-Medium", size: 11))
                .monospacedDigit()
                .tracking(11 * 0.08)
                .foregroundStyle(DS.Color.Text.tertiary)
                .padding(.top, DS.Spacing.xs)
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

    private func chip(_ text: String, textColor: Color, background: Color) -> some View {
        Text(text)
            .font(.custom("JetBrainsMono-Medium", size: 9))
            .tracking(9 * 0.15)
            .foregroundStyle(textColor)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        VStack(spacing: DS.Spacing.md) {
            Button(action: { coordinator.advance() }) {
                Text("Start your assessment")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.Text.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(DS.Color.Accent.luminol)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            }

            Button(action: { coordinator.skipQuiz() }) {
                Text("Skip preview")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Color.Text.tertiary)
            }
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.lg)
        .background(DS.Color.Surface.canvas)
    }
}

#Preview {
    SampleReportPreviewView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
