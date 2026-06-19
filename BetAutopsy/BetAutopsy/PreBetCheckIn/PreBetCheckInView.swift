//
//  PreBetCheckInView.swift
//  BetAutopsy
//
//  Pre-bet check-in modal. Three states driven by
//  PreBetCheckInCoordinator.phase: input form -> scoring loader ->
//  result with flags + CTAs. Presented as a .sheet from TodayView's
//  "About to bet" CTA card (added in the same Phase 1 PR).
//
//  V3 tokens only. Severity colors use the existing
//  DS.Color.V3.Severity.zoneColor helper.
//
//  Telemetry signals are wired in the TodayView-CTA commit alongside
//  the launch surface, not here. This file is pure UI + flow.
//

import SwiftUI

struct PreBetCheckInView: View {
    @State private var coordinator = PreBetCheckInCoordinator()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var stakeFocused: Bool

    // Deep-link to the report section that proves a grounded flag.
    @State private var showingReport = false
    @State private var deepLinkSection: String?

    #if DEBUG
    @State private var showDebugMenu = false
    #endif

    /// DEBUG visual-harness hook: focuses the stake field shortly after
    /// appear so the keyboard + Done row can be screenshot-verified
    /// without simulated taps. No-op in production call sites.
    private let autoFocusStakeForHarness: Bool

    /// DEBUG visual-harness hook: drives the coordinator straight to the
    /// .read result on appear, so the instant-read RESULT state can be
    /// screenshot-captured. No-op in production call sites.
    private let autoSubmitForHarness: Bool

    /// Seeds the coordinator's stake at construction (before StakeField
    /// inits, so the field displays it). Lets a harness show the filled
    /// input + enabled button, or give the local read a stake to read.
    /// Production passes nil, so the coordinator starts at stake 0 exactly
    /// as before - no behavior change.
    init(
        autoFocusStakeForHarness: Bool = false,
        autoSubmitForHarness: Bool = false,
        harnessStake: Decimal? = nil
    ) {
        self.autoFocusStakeForHarness = autoFocusStakeForHarness
        self.autoSubmitForHarness = autoSubmitForHarness
        if let harnessStake {
            let c = PreBetCheckInCoordinator()
            c.stake = harnessStake
            _coordinator = State(initialValue: c)
        }
    }

    var body: some View {
        ZStack {
            canvasGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                Group {
                    switch coordinator.phase {
                    case .input:
                        inputForm
                    case .read(let read, let enriched):
                        readView(read, enriched: enriched)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fullScreenCover(isPresented: $showingReport) {
            if let report = ReportStore.shared.reports.first {
                ReportScrollContainer(report: report, initialSectionId: deepLinkSection)
                    .preferredColorScheme(.dark)
            }
        }
        // The decimal pad has no return key, and ToolbarItem(.keyboard)
        // silently renders NOTHING without a toolbar-hosting context
        // (this sheet has no NavigationStack) - the first version of
        // this fix shipped as a no-op that way. A safeAreaInset row is
        // immune: keyboard avoidance lifts the bottom safe area above
        // the keyboard, so the row rides up with it while focused.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if stakeFocused {
                HStack {
                    Spacer()
                    Button("Done") { stakeFocused = false }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.Color.Brand.yellow)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(DS.Color.V3.surfaceRaised)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            Analytics.signal("prebet.viewed")
            if autoFocusStakeForHarness {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    stakeFocused = true
                }
            }
            if autoSubmitForHarness {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    coordinator.submit()
                }
            }
        }
        #if DEBUG
        .confirmationDialog(
            "Debug time override",
            isPresented: $showDebugMenu,
            titleVisibility: .visible
        ) {
            Button("Real time (clear override)") {
                coordinator.debugNowOverride = nil
            }
            Button("Force midnight (late-night flag)") {
                coordinator.debugNowOverride = Self.todayAt(hour: 0)
            }
            Button("Force noon (clean window)") {
                coordinator.debugNowOverride = Self.todayAt(hour: 12)
            }
            Button("Cancel", role: .cancel) {}
        }
        #endif
    }

    private var canvasGradient: LinearGradient {
        LinearGradient(
            colors: [DS.Color.V3.canvasGradientStart, DS.Color.V3.canvasGradientEnd],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("About to bet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                #if DEBUG
                .onTapGesture(count: 4) { showDebugMenu = true }
                #endif

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(DS.Color.V3.surfaceCard)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    #if DEBUG
    private static func todayAt(hour: Int) -> Date {
        let cal = Calendar.current
        var comp = cal.dateComponents([.year, .month, .day], from: Date())
        comp.hour = hour
        comp.minute = 0
        return cal.date(from: comp) ?? Date()
    }
    #endif

    private static func stakeBucket(_ stake: Decimal) -> String {
        switch stake {
        case ..<25:     return "lt_25"
        case 25..<100:  return "25_100"
        case 100..<500: return "100_500"
        default:        return "500_plus"
        }
    }

    private static func oddsBucket(_ odds: Int) -> String {
        if odds < 0 { return "favorite" }
        if odds < 200 { return "small_dog" }
        return "big_dog"
    }

    // MARK: - Input form

    private var inputForm: some View {
        ScrollView {
            VStack(spacing: 20) {
                FieldRow(label: "Sport") {
                    Menu {
                        ForEach(Sport.allCases, id: \.self) { s in
                            Button(s.displayName) { coordinator.sport = s }
                        }
                    } label: {
                        menuLabel(coordinator.sport.displayName)
                    }
                }

                FieldRow(label: "Bet type") {
                    Menu {
                        ForEach(BetType.allCases, id: \.self) { t in
                            Button(t.displayName) { coordinator.betType = t }
                        }
                    } label: {
                        menuLabel(coordinator.betType.displayName)
                    }
                }

                StakeField(stake: $coordinator.stake, focus: $stakeFocused)

                OddsField(odds: $coordinator.odds)

                Spacer(minLength: 16)

                submitButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private func menuLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DS.Color.V3.textPrimary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var canSubmit: Bool {
        coordinator.stake > 0 && coordinator.odds != 0
    }

    private var submitButton: some View {
        Button {
            Analytics.signal(
                "prebet.submitted",
                parameters: [
                    "sport":        coordinator.sport.rawValue,
                    "stake_bucket": Self.stakeBucket(coordinator.stake),
                    "odds_bucket":  Self.oddsBucket(coordinator.odds),
                    "bet_type":     coordinator.betType.rawValue
                ]
            )
            // Instant: computes the on-device read and swaps the phase
            // synchronously; the server enrichment fires behind it.
            coordinator.submit()
        } label: {
            Text("Check before I bet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(canSubmit ? DS.Color.V3.canvasGradientEnd : DS.Color.V3.textTertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSubmit ? DS.Color.V3.ctaText : DS.Color.V3.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!canSubmit)
    }

    // MARK: - Read (instant hero + grounded flags + neutral CTAs)

    @ViewBuilder
    private func readView(_ read: LocalBehavioralRead, enriched: PreBetCheckInResponse?) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                readHero(read)

                // Server prose enriches the read once it lands. The local
                // read is the product; this is additive and may never arrive.
                if let summary = enriched?.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.custom("Georgia-Italic", size: 16))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                if !read.flags.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(read.flags) { flag in
                            GroundedFlagRow(flag: flag) { tapped in
                                guard let section = tapped.sectionId else { return }
                                deepLinkSection = section
                                showingReport = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                ctaStack(read)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer(minLength: 24)
            }
            .padding(.top, 12)
        }
    }

    private func readHero(_ read: LocalBehavioralRead) -> some View {
        let color = Self.toneColor(read.tone)
        return VStack(spacing: 10) {
            Text(Self.toneLabel(read.tone))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            Text(read.headline)
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .multilineTextAlignment(.center)
            Text(read.subtext)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - CTAs (neutral, record-only positive)

    @ViewBuilder
    private func ctaStack(_ read: LocalBehavioralRead) -> some View {
        VStack(spacing: 10) {
            if read.leadsWithPause {
                ctaButton("Wait 30 minutes", style: .primary, outcome: .waited)
                ctaButton("Log this bet", style: .secondary, outcome: .placedBet)
            } else {
                ctaButton("Log this bet", style: .primary, outcome: .placedBet)
                ctaButton("Wait 30 minutes", style: .secondary, outcome: .waited)
            }
        }
    }

    private enum CTAStyle { case primary, secondary }

    @ViewBuilder
    private func ctaButton(_ title: String, style: CTAStyle, outcome: CheckInOutcome) -> some View {
        Button {
            Analytics.signal(outcome == .waited ? "prebet.waited" : "prebet.placed_bet")
            coordinator.decide(outcome)
            dismiss()
        } label: {
            switch style {
            case .primary:
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.canvasGradientEnd)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DS.Color.Brand.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            case .secondary:
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
                    )
            }
        }
    }

    private static func toneLabel(_ tone: ReadTone) -> String {
        switch tone {
        case .heated:   return "Heated"
        case .elevated: return "Elevated"
        case .normal:   return "Normal"
        case .calm:     return "Calm"
        }
    }

    private static func toneColor(_ tone: ReadTone) -> Color {
        switch tone {
        case .heated:   return DS.Color.V3.Severity.red
        case .elevated: return DS.Color.V3.Severity.orange
        case .normal:   return DS.Color.V3.textSecondary
        case .calm:     return DS.Color.V3.Severity.green
        }
    }
}

// MARK: - FieldRow

private struct FieldRow<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(DS.Color.V3.textTertiary)
            content()
        }
    }
}

// MARK: - StakeField

private struct StakeField: View {
    @Binding var stake: Decimal
    var focus: FocusState<Bool>.Binding
    @State private var text: String

    init(stake: Binding<Decimal>, focus: FocusState<Bool>.Binding) {
        self._stake = stake
        self.focus = focus
        // Seed the displayed text from the initial stake. Production always
        // starts at 0 -> "" (identical to before); a harness-preset stake
        // shows in the field.
        self._text = State(initialValue: stake.wrappedValue > 0 ? "\(stake.wrappedValue)" : "")
    }

    var body: some View {
        FieldRow(label: "Stake") {
            HStack(spacing: 8) {
                Text("$")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.textTertiary)
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    // Focus is owned by PreBetCheckInView, which renders the
                    // Done dismiss row in its bottom safeAreaInset while this
                    // field is focused.
                    .focused(focus)
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .onChange(of: text) { _, new in
                        // Locale-aware: a `.decimalPad` emits the user's
                        // locale separator (comma in much of the world);
                        // Decimal(string:) is US-only and would silently
                        // zero a "12,50" stake. See DecimalStakeParsing.
                        if let d = Decimal.parsingStake(new), d >= 0 {
                            stake = d
                        } else if new.isEmpty {
                            stake = 0
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - OddsField

private struct OddsField: View {
    @Binding var odds: Int
    @State private var magnitudeText: String = "110"
    @State private var isFavorite: Bool = true

    var body: some View {
        FieldRow(label: "Odds (american)") {
            HStack(spacing: 8) {
                Button {
                    isFavorite.toggle()
                    syncOdds()
                } label: {
                    Text(isFavorite ? "−" : "+")
                        .font(.system(size: 20, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(DS.Color.V3.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                TextField("110", text: $magnitudeText)
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(DS.Color.V3.textPrimary)
                    .onChange(of: magnitudeText) { _, _ in syncOdds() }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onAppear { syncOdds() }
        }
    }

    private func syncOdds() {
        let magnitude = Int(magnitudeText) ?? 0
        odds = isFavorite ? -magnitude : magnitude
    }
}

// MARK: - GroundedFlagRow

/// A grounded read flag. When `flag.sectionId` is present the row is
/// tappable and deep-links to the report section that proves it (a
/// chevron signals the affordance); otherwise it renders inert.
private struct GroundedFlagRow: View {
    let flag: GroundedFlag
    let onTap: (GroundedFlag) -> Void

    private var isLinked: Bool { flag.sectionId != nil }

    var body: some View {
        Button {
            onTap(flag)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(severityColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)

                VStack(alignment: .leading, spacing: 4) {
                    Text(flag.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .multilineTextAlignment(.leading)
                    Text(flag.detail)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                if isLinked {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.Color.V3.textTertiary)
                        .padding(.top, 4)
                }
            }
            .padding(14)
            .background(DS.Color.V3.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(!isLinked)
    }

    private var severityColor: Color {
        switch flag.severity {
        case .high:   return DS.Color.V3.Severity.red
        case .medium: return DS.Color.V3.Severity.orange
        case .low:    return DS.Color.V3.Severity.yellow
        case .info:   return DS.Color.V3.Severity.gray
        }
    }
}

#if DEBUG
#Preview("Input") {
    PreBetCheckInView()
        .preferredColorScheme(.dark)
}
#endif
