//
//  UndoToast.swift
//  BetAutopsy
//
//  Transient bottom-anchored banner that appears whenever the user
//  marks a Chapter 7 action as completed. Tapping "Undo" within 5
//  seconds resets the checkoff via ActionCheckoffStore.flip(to: false).
//
//  Mounted on RootTabView via .overlay(alignment: .bottom) — NOT
//  .fullScreenCover, since DeepLinkRouter already owns the
//  RootTabView-level fullScreenCover for deep-link presentation.
//
//  Triggers only on user-initiated completions (FlipEvent where
//  previousCompleted == false && newCompleted == true). The undo's
//  own FlipEvent (previousCompleted == true) is ignored, so tapping
//  Undo dismisses without re-presenting. POST-failure reverts mutate
//  the dict directly (bypassing flip()) so they never publish a
//  FlipEvent — UndoToast cannot accidentally trigger on those either.
//
//  Last-write-wins on a new completion mid-toast: cancels the pending
//  dismiss Task and re-arms the 5-second window with the new event.
//

import SwiftUI

struct UndoToast: View {
    @State private var store = ActionCheckoffStore.shared
    @State private var activeEvent: ActionCheckoffStore.FlipEvent?
    @State private var dismissTask: Task<Void, Never>?

    /// 5s window from the spec.
    private static let dismissDelay: Duration = .seconds(5)

    var body: some View {
        Group {
            if let event = activeEvent {
                toastView(event: event)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 64)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onChange(of: store.lastFlip?.id) { _, _ in
            handleFlip()
        }
    }

    // MARK: - Toast layout

    private func toastView(event: ActionCheckoffStore.FlipEvent) -> some View {
        HStack(spacing: 12) {
            Text("Marked done.")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)

            Spacer(minLength: 0)

            Button(action: { undo(event: event) }) {
                Text("Undo")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(DS.Color.V3.ctaText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Undo. Resets this action.")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceRaised)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Event handling

    /// Inspects the latest FlipEvent. Only completions (previousCompleted
    /// == false) trigger the toast; resets are silent.
    private func handleFlip() {
        guard let flip = store.lastFlip else { return }
        guard flip.previousCompleted == false, flip.newCompleted == true else {
            return
        }

        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.3)) {
            activeEvent = flip
        }

        let scheduled = flip.id
        dismissTask = Task {
            try? await Task.sleep(for: Self.dismissDelay)
            if Task.isCancelled { return }
            await MainActor.run {
                // Only auto-dismiss if a newer event hasn't replaced this one.
                guard activeEvent?.id == scheduled else { return }
                withAnimation(.spring(duration: 0.3)) {
                    activeEvent = nil
                }
            }
        }
    }

    /// Tap Undo: reset the checkoff via the store. The store's flip()
    /// publishes a new FlipEvent (previousCompleted == true) which
    /// handleFlip() skips, so this dismiss isn't fought by a re-show.
    private func undo(event: ActionCheckoffStore.FlipEvent) {
        dismissTask?.cancel()
        withAnimation(.spring(duration: 0.3)) {
            activeEvent = nil
        }
        store.flip(
            recommendationId: event.recommendationId,
            reportId: event.reportId,
            to: false
        )
    }
}

#if DEBUG
#Preview {
    ZStack {
        DS.Color.V3.canvasGradientEnd.ignoresSafeArea()
        VStack {
            Spacer()
            UndoToast()
        }
        Button("Trigger flip") {
            ActionCheckoffStore.shared.flip(
                recommendationId: "preview-report:1",
                reportId: "preview-report",
                to: true
            )
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
#endif
