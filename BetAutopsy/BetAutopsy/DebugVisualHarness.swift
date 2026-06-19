//
//  DebugVisualHarness.swift
//  BetAutopsy
//
//  DEBUG-only launch-argument harness for screenshot-verifying visual
//  fixes in the simulator without auth. Added in the TESTFLIGHT-MIN
//  fix round after two compile-green no-ops shipped (StatusBarScrim
//  v1, keyboard toolbar Done): compile-green is not pixel-proof, and
//  auth blocks walking to the affected screens in a fresh simulator.
//  Keep this - it is reusable for every future visual fix.
//
//  Launch arguments (scheme arguments or `simctl launch <udid>
//  com.diagnosticsports.betautopsy.app <arg>`). NOTE the bundle id:
//  the real id is com.diagnosticsports.betautopsy.app, NOT the
//  com.diagnosticsports.BetAutopsy that CLAUDE.md documents - using
//  the documented one launches whatever stale app owns it on that
//  simulator (this exact mistake burned an hour of this fix round).
//    -ScrimHarness    stub scroll rows, pre-scrolled to the bottom so
//                     text sits in the status-bar collision zone, with
//                     .statusBarScrim() attached (the Reports/Sessions
//                     attachment idiom).
//    -ReaderHarness   the real ReportScrollContainer on MockReport
//                     (scrim under the floating xmark).
//    -CheckInHarness  the real PreBetCheckInView presented as a sheet
//                     with the stake field auto-focused, proving the
//                     decimal-pad Done row.
//

#if DEBUG
import SwiftUI

enum DebugVisualHarness {
    enum Kind: String {
        case scrim = "-ScrimHarness"
        case reader = "-ReaderHarness"
        case checkIn = "-CheckInHarness"
        case chapterRail = "-ChapterRailHarness"
        case coverFull = "-CoverHarness"
        case coverSnapshot = "-CoverSnapshotHarness"
        case reveal = "-RevealHarness"
        case dynTypeFindings = "-DynTypeFindingsHarness"
        case upload = "-UploadHarness"

        // App-state audit (comprehensive screenshot map). Each boots
        // straight to one real production view with stubbed entry data.
        case stateAgeGate = "-StateAgeGate"
        case stateSampleReport = "-StateSampleReport"
        case statePikkit = "-StatePikkit"
        case stateAuth = "-StateAuth"
        case stateQuiz = "-StateQuiz"
        case stateArchetypeReveal = "-StateArchetypeReveal"
        case stateTodayEmpty = "-StateTodayEmpty"
        case stateReportsEmpty = "-StateReportsEmpty"
        case stateReportsPopulated = "-StateReportsPopulated"
        case stateSessions = "-StateSessions"
        case stateUpload = "-StateUpload"
        case stateSnapshotReport = "-StateSnapshotReport"
        case stateFullReport = "-StateFullReport"
        case stateFullReportFindings = "-StateFullReportFindings"
        case statePaywall = "-StatePaywall"
        case stateCheckIn = "-StateCheckIn"
        case stateSettings = "-StateSettings"
        case stateGlossary = "-StateGlossary"
        case statePushPrimer = "-StatePushPrimer"

        // Deep-scroll captures: drive the section via a `-section <id>` arg
        // (one harness, every section), so the audit shows the whole report
        // body top to bottom.
        case stateFullReportSection = "-StateFullReportSection"
        case stateSnapshotSection = "-StateSnapshotSection"

        // The pre-bet check-in payoff: the instant local read RESULT, and
        // the filled input with the enabled (brand-yellow) submit button.
        case stateCheckInResult = "-StateCheckInResult"
        case stateCheckInFilled = "-StateCheckInFilled"
    }

    static var active: Kind? {
        let args = ProcessInfo.processInfo.arguments
        return Kind.allCases.first { args.contains($0.rawValue) }
    }

    /// Value following a launch flag, e.g. argValue("-section") -> "section_findings".
    static func argValue(_ flag: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static func hasArg(_ flag: String) -> Bool {
        ProcessInfo.processInfo.arguments.contains(flag)
    }
}

extension DebugVisualHarness.Kind: CaseIterable {}

struct DebugVisualHarnessRoot: View {
    let kind: DebugVisualHarness.Kind

    // Onboarding views read @Environment(OnboardingCoordinator.self); the
    // app-state harnesses inject this instance. UploadFlowCoordinator backs
    // the upload + reports harnesses.
    private let coordinator = OnboardingCoordinator()
    private let uploadCoordinator = UploadFlowCoordinator()

    init(kind: DebugVisualHarness.Kind) {
        self.kind = kind
        // SectionAction auto-presents the push primer on appear (once per
        // install, gated by this flag). Mark it asked so report captures show
        // the real action content; the dedicated -StatePushPrimer renders the
        // primer directly and is unaffected.
        if kind != .statePushPrimer {
            UserDefaults.standard.set(true, forKey: "betautopsy.push_permission_asked")
        }
        // Seed entry data BEFORE the views init/read it.
        switch kind {
        case .reveal:
            // Clear flags + slow motion so the reveal replays slowly enough
            // to capture a frame sequence.
            DebugReveal.slowMotion = true
            RevealFlags.clear(MockReport.heatedBettor.id)
        case .stateArchetypeReveal:
            // ArchetypeRevealView renders from coordinator.quizResult; compute
            // a default result (empty answers -> the default archetype).
            coordinator.computeArchetype()
        case .stateTodayEmpty, .stateReportsEmpty:
            // New-user empty state: no reports.
            ReportStore.shared.clear()
        case .stateReportsPopulated, .stateSessions,
             .stateCheckInResult, .stateCheckInFilled:
            // The local read computes from ReportStore.shared.reports.first;
            // seed it so the read has time-of-day / loss-pattern data.
            seedReports()
        case .stateFullReport, .stateFullReportFindings, .stateFullReportSection:
            // Clean resolved cover for the audit (no reveal animation): mark
            // the reveal already seen so it renders the resolved state.
            RevealFlags.markMoneyShotSeen(MockReport.heatedBettor.id)
            RevealFlags.markHeroSeen(MockReport.heatedBettor.id)
            // The findings deep-scroll shot passes -expandEvidence so the
            // tap-expand evidence layer is visible without a live tap.
            if DebugVisualHarness.hasArg("-expandEvidence") {
                DebugReveal.forceExpandEvidence = true
            }
        default:
            break
        }
    }

    private func seedReports() {
        ReportStore.shared.clear()
        ReportStore.shared.add(MockReport.heatedBettor)
        ReportStore.shared.add(MockReport.heatedBettorSnapshot)
    }

    var body: some View {
        switch kind {
        case .scrim:
            scrimHarness
        case .reader:
            ReportScrollContainer(report: MockReport.heatedBettor)
        case .checkIn:
            checkInHarness
        case .chapterRail:
            // Full reader with the rail pinned visible so the screenshot
            // captures it deterministically (auto-hide would race the
            // capture). debugKeepRailVisible is DEBUG-only.
            ReportScrollContainer(
                report: MockReport.heatedBettor,
                debugKeepRailVisible: true
            )
        case .coverFull:
            // Cover in situ at the top of the real shell (full report):
            // resolved net, grade, percentile.
            ReportScrollContainer(report: MockReport.heatedBettor)
        case .coverSnapshot:
            // Cover in situ (snapshot): blurred net hook, no grade/percentile.
            ReportScrollContainer(report: MockReport.heatedBettorSnapshot)
        case .reveal:
            // Full report with flags cleared (init) + slow motion: the cover
            // net-dollar money shot plays on launch. Capturable frame
            // sequence (blurred-hold -> mid-resolve -> resolved).
            ReportScrollContainer(report: MockReport.heatedBettor)
        case .dynTypeFindings:
            // Reader deep-linked to the findings section, so a body section
            // can be screenshot at a large content size (set via
            // `simctl ui content_size`) to prove no clipping/overlap.
            ReportScrollContainer(
                report: MockReport.heatedBettor,
                initialSectionId: "section_findings"
            )
        case .upload:
            uploadHarness

        // MARK: - App-state audit
        case .stateAgeGate:
            AgeGateView().environment(coordinator)
        case .stateSampleReport:
            SampleReportPreviewView().environment(coordinator)
        case .statePikkit:
            PikkitEducationView().environment(coordinator)
        case .stateAuth:
            AuthView().environment(coordinator)
        case .stateQuiz:
            BetDNAQuizView().environment(coordinator)
        case .stateArchetypeReveal:
            ArchetypeRevealView().environment(coordinator)
        case .stateTodayEmpty:
            NavigationStack { TodayView() }.environment(coordinator)
        case .stateReportsEmpty, .stateReportsPopulated:
            ReportListView()
                .environment(ReportStore.shared)
                .environment(uploadCoordinator)
        case .stateSessions:
            SessionsTabView().environment(ReportStore.shared)
        case .stateUpload:
            uploadHarness
        case .stateSnapshotReport:
            ReportScrollContainer(report: MockReport.heatedBettorSnapshot)
        case .stateFullReport:
            ReportScrollContainer(report: MockReport.heatedBettor)
        case .stateFullReportFindings:
            ReportScrollContainer(report: MockReport.heatedBettor, initialSectionId: "section_findings")
        case .statePaywall:
            PaywallView(snapshotReportId: MockReport.heatedBettorSnapshot.id)
        case .stateCheckIn:
            checkInHarness
        case .stateCheckInResult:
            // Auto-submit drives the coordinator to the instant local-read
            // RESULT (against the seeded report) on appear.
            PreBetCheckInView(autoSubmitForHarness: true, harnessStake: 120)
                .preferredColorScheme(.dark)
        case .stateCheckInFilled:
            // Filled input: a real stake is pre-set so the field shows it and
            // the "Check before I bet" button is enabled (brand-yellow). No
            // submit, no focus (keyboard down so the button is visible).
            PreBetCheckInView(harnessStake: 120)
                .preferredColorScheme(.dark)
        case .stateSettings:
            SettingsView()
        case .stateGlossary:
            NavigationStack { GlossaryView() }
        case .statePushPrimer:
            PushPermissionView()
        case .stateFullReportSection:
            ReportScrollContainer(
                report: MockReport.heatedBettor,
                initialSectionId: DebugVisualHarness.argValue("-section") ?? "section_verdict",
                debugAnchorBottom: DebugVisualHarness.hasArg("-anchorBottom"),
                debugAnchorCenter: DebugVisualHarness.hasArg("-anchorCenter")
            )
        case .stateSnapshotSection:
            ReportScrollContainer(
                report: MockReport.heatedBettorSnapshot,
                initialSectionId: DebugVisualHarness.argValue("-section") ?? "section_findings",
                debugAnchorBottom: DebugVisualHarness.hasArg("-anchorBottom"),
                debugAnchorCenter: DebugVisualHarness.hasArg("-anchorCenter")
            )
        }
    }

    private var uploadHarness: some View {
        let coordinator = UploadFlowCoordinator()
        coordinator.state = .uploading
        return UploadProgressView(coordinator: coordinator, onCancel: {}, onRetry: {})
    }

    /// Stub rows pre-scrolled to the bottom: the top rows sit in the
    /// status-bar region at launch, so a single screenshot proves the
    /// scrim occupies [0, topInset + 28] in screen coordinates.
    private var scrimHarness: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(0..<60, id: \.self) { i in
                        Text("Stub row \(i). This line must fade out under the clock, not collide with it.")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Color.V3.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
            }
            .defaultScrollAnchor(.bottom)
        }
        .statusBarScrim()
    }

    private var checkInHarness: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()
        }
        .sheet(isPresented: .constant(true)) {
            PreBetCheckInView(autoFocusStakeForHarness: true)
                .preferredColorScheme(.dark)
        }
    }
}
#endif
