//
//  TodayView.swift
//  BetAutopsy
//
//  Today tab. Reads the latest cached report from ReportStore for the
//  BetIQ hero, verdict, and discipline/emotion ranges. No fabricated
//  numbers: every figure is sourced from a real report, and when no
//  report exists yet the figures are hidden and the surface invites an
//  upload instead. The "About to bet" check-in CTA is always present.
//

import SwiftUI

struct TodayView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    // Archetype identity is captured at quiz reveal and is real (not mock),
    // so it stays AppStorage-backed and renders before any report exists.
    @AppStorage("userArchetype")         private var userArchetype: String = ""
    @AppStorage("userArchetypeColorHex") private var userArchetypeColorHex: String = ""

    @State private var reportStore = ReportStore.shared
    @State private var checkInHistory = PreBetCheckInHistory.shared
    @State private var reengage = PreBetReengageRouter.shared
    @State private var showingCheckIn = false
    @State private var showingSettings = false
    @State private var showingPushPrompt = false

    // MARK: - Report-derived state

    private var latest: AutopsyReport? { reportStore.reports.first }
    private var isSnapshot: Bool { latest?.reportType == "snapshot" }

    /// BetIQ score, only when a report carries a real, sufficient-data score.
    private var betIQScore: Int? {
        guard let betiq = latest?.analysis.betiq,
              !betiq.insufficientData,
              betiq.score > 0 else { return nil }
        return betiq.score
    }

    /// One-sentence verdict from the report's executive diagnosis (the
    /// snapshot-safe variant in snapshot mode). nil when no prose exists.
    private var verdictText: String? {
        guard let insight = latest?.analysis
            .executiveDiagnosisInsight(snapshot: isSnapshot)
            .firstSentence,
              !insight.isEmpty else { return nil }
        return insight
    }

    private var disciplineValue: Int? { latest?.analysis.disciplineScore?.total }

    private var emotionValue: Int? {
        guard let analysis = latest?.analysis,
              analysis.emotionScoreInsufficientData != true else { return nil }
        return analysis.emotionScore
    }

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

                    if checkInHistory.hasHistory {
                        calmDecisionsCard
                            .padding(.horizontal, 16)
                    }

                    if rangeCardHasContent {
                        rangeCard
                            .padding(.horizontal, 16)
                    }

                    Spacer(minLength: 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textPrimary)
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            PreBetCheckInView()
                .preferredColorScheme(.dark)
        }
        // A cool-off notification tap re-opens the check-in so the user
        // lands back where the decision lives, not on a cold Today screen.
        .onChange(of: reengage.pendingReopen) { _, reopen in
            if reopen {
                showingCheckIn = true
                reengage.consume()
            }
        }
        .task {
            if reengage.pendingReopen {
                showingCheckIn = true
                reengage.consume()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .preferredColorScheme(.dark)
        }
        // Push primer (moved off SectionAction.onAppear, which presented
        // it OVER the action plan - the report's key CTA). Per CLAUDE.md it
        // belongs after the first report is viewed, so it fires here on the
        // calm Today tab once a report exists, never covering a CTA.
        .fullScreenCover(isPresented: $showingPushPrompt) {
            PushPermissionView()
        }
        .onAppear { maybePromptForPush() }
    }

    /// Present the push primer once per install, only after a report
    /// exists (the user has been through the core flow). PushPermissionView
    /// sets the asked flag on response, so this never re-prompts.
    private func maybePromptForPush() {
        guard latest != nil,
              !UserDefaults.standard.bool(forKey: "betautopsy.push_permission_asked") else { return }
        showingPushPrompt = true
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

    // MARK: - Calm-decisions counter

    /// Closes the local loop: the user watches their own pauses add up.
    /// Sourced entirely from on-device PreBetCheckInHistory, shown only
    /// once at least one check-in exists.
    private var calmDecisionsCard: some View {
        HStack(spacing: 14) {
            Text("\(checkInHistory.totalCheckIns)")
                .font(.system(size: 28, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(DS.Color.Brand.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text("Bets checked before placing")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textPrimary)

                if checkInHistory.steppedBackCount > 0 {
                    Text("You stepped back \(checkInHistory.steppedBackCount) \(checkInHistory.steppedBackCount == 1 ? "time" : "times").")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                }
            }

            Spacer(minLength: 0)
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

    // MARK: - Case header

    private var caseHeader: some View {
        Text(latest.map { "CASE \($0.caseNumber)" } ?? "TODAY")
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
                if let score = betIQScore {
                    Text("\(score)")
                        .font(.system(size: 48, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textPrimary)
                }

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

    @ViewBuilder
    private var verdict: some View {
        if let verdictText {
            Text(verdictText)
                .font(.custom("Georgia-Italic", size: 17))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)
        } else if latest == nil {
            Text("Upload your bet history to see your full autopsy.")
                .font(.custom("Georgia-Italic", size: 17))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Range card

    private var rangeCardHasContent: Bool {
        disciplineValue != nil || emotionValue != nil
    }

    private var rangeCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            if let disciplineValue {
                RangeBar(
                    label: "Discipline",
                    value: disciplineValue,
                    dotColor: DS.Color.V3.Severity.zoneColor(
                        forScore: disciplineValue,
                        higherIsWorse: false
                    )
                )
            }
            if let emotionValue {
                RangeBar(
                    label: "Emotion score",
                    value: emotionValue,
                    dotColor: DS.Color.V3.Severity.zoneColor(
                        forScore: emotionValue,
                        higherIsWorse: true
                    )
                )
            }
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
