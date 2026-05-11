//
//  UploadProgressView.swift
//  BetAutopsy
//
//  Full-screen states for the upload + analyze flow. Reads
//  UploadFlowCoordinator.state and renders one of five UX paths
//  (idle/picking is rendered as empty; the parent only shows this view
//  during active flow states).
//

import SwiftUI

struct UploadProgressView: View {
    let coordinator: UploadFlowCoordinator
    let onCancel: () -> Void
    let onRetry: () -> Void

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                Text("CASE FILE IN PROGRESS")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .padding(.top, 60)

                Spacer()

                content

                Spacer()

                if !isSucceeded {
                    cancelButton.padding(.bottom, DS.Spacing.xxl)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.state {
        case .idle, .picking:
            EmptyView()

        case .uploading:
            VStack(spacing: DS.Spacing.lg) {
                ProgressView().tint(DS.Color.Accent.luminol)
                Text("UPLOADING YOUR CSV")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.18)
                    .foregroundStyle(DS.Color.Text.tertiary)
            }

        case .streaming(let metricsReceived):
            VStack(spacing: DS.Spacing.lg) {
                ProgressView().tint(DS.Color.Accent.luminol)
                if metricsReceived {
                    Text("Reading your patterns...")
                        .font(.custom("Georgia-Italic", size: 17))
                        .foregroundStyle(DS.Color.Text.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Analyzing your bets...")
                        .font(.system(size: 16))
                        .foregroundStyle(DS.Color.Text.primary)
                }
            }

        case .succeeded:
            VStack(spacing: DS.Spacing.md) {
                Image(systemName: "checkmark")
                    .font(.system(size: 32))
                    .foregroundStyle(DS.Color.Semantic.win)
                Text("DONE")
                    .font(.custom("JetBrainsMono-Regular", size: 11))
                    .tracking(11 * 0.18)
                    .foregroundStyle(DS.Color.Text.tertiary)
            }

        case .failed(let error):
            VStack(spacing: DS.Spacing.lg) {
                Text(error.errorDescription ?? "Something went wrong.")
                    .font(.system(size: 16))
                    .foregroundStyle(DS.Color.Semantic.blood)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.xl)

                if error.isRetriable {
                    Button(action: onRetry) {
                        Text("Try again")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(DS.Color.Text.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(DS.Color.Accent.luminol)
                            .clipShape(RoundedRectangle(
                                cornerRadius: DS.Radius.card))
                    }
                    .padding(.horizontal, DS.Spacing.lg)
                }
            }
        }
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text(isFailed ? "Close" : "Cancel")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.Color.Text.tertiary)
        }
    }

    private var isSucceeded: Bool {
        if case .succeeded = coordinator.state { return true }
        return false
    }

    private var isFailed: Bool {
        if case .failed = coordinator.state { return true }
        return false
    }
}
