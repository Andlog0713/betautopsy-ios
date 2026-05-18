//
//  SampleReportPreviewView.swift
//  BetAutopsy
//
//  Step 2: preview what an analyzed report looks like before the user invests
//  any effort. Single sample chapter card, fades on scroll. Migrated to V3
//  in PR-V12.
//

import SwiftUI

struct SampleReportPreviewView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    /// Optional closure that, when non-nil, switches the view into
    /// preview-sheet mode: bottom actions collapse to a single Done
    /// button that calls this closure instead of advancing onboarding.
    /// Used by AuthView reviewer paths (5-tap bypass + Sample Report
    /// button). Default nil preserves the linear onboarding step.
    var previewDismiss: (() -> Void)? = nil

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

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
                .font(.system(size: 11, weight: .bold))
                .tracking(11 * 0.18)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Text("Here's what we'll find in yours.")
                .font(.system(size: 24, weight: .bold))
                .tracking(-24 * 0.015)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Spacing.lg)

            Text("Behavioral patterns most bettors never see in themselves.")
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, DS.Spacing.lg)
        }
    }

    // MARK: - Sample chapter card

    private var sampleCard: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            HStack(spacing: DS.Spacing.sm) {
                chip("CONFIRMATION BIAS",
                     textColor: DS.Color.V3.textTertiary,
                     background: DS.Color.V3.surfaceRaised)
                chip("NOTABLE",
                     textColor: DS.Color.V3.Severity.red,
                     background: DS.Color.V3.Severity.red.opacity(0.18))
            }

            Text("You only remember the wins that proved you right.")
                .font(DS.Font.V3.buttonLabel)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text("47 wagers after a winning bet. Stakes increased 2.3x. Win rate did not.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Text("EVIDENCE: 47 wagers · IMPACT: -$2,847")
                .font(.system(size: 11, weight: .semibold))
                .monospacedDigit()
                .tracking(11 * 0.08)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .padding(.top, DS.Spacing.xs)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    private func chip(_ text: String, textColor: Color, background: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(9 * 0.15)
            .foregroundStyle(textColor)
            .padding(.horizontal, DS.Spacing.sm)
            .padding(.vertical, DS.Spacing.xs)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.chip))
    }

    // MARK: - Bottom actions

    @ViewBuilder
    private var bottomActions: some View {
        if let dismiss = previewDismiss {
            VStack(spacing: DS.Spacing.md) {
                Button(action: dismiss) {
                    Text("Done")
                        .font(DS.Font.V3.buttonLabel)
                        .foregroundStyle(DS.Color.V3.primaryFillText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(DS.Color.V3.primaryFill)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.lg)
            .background(DS.Color.V3.canvasGradientEnd)
        } else {
            VStack(spacing: DS.Spacing.md) {
                Button(action: { coordinator.advance() }) {
                    Text("Start your assessment")
                        .font(DS.Font.V3.buttonLabel)
                        .foregroundStyle(DS.Color.V3.primaryFillText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(DS.Color.V3.primaryFill)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                }

                Button(action: { coordinator.skipQuiz() }) {
                    Text("Skip preview")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.Color.V3.textTertiary)
                }
            }
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.lg)
            .background(DS.Color.V3.canvasGradientEnd)
        }
    }
}

#Preview {
    SampleReportPreviewView()
        .environment(OnboardingCoordinator())
        .preferredColorScheme(.dark)
}
