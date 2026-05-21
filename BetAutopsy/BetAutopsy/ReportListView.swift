//
//  ReportListView.swift
//  BetAutopsy
//
//  Reports tab. Reads AutopsyReport instances from ReportStore (falling
//  back to the Tilter mock when empty), provides the CSV upload
//  entry point, and routes upload state into a progress cover and the
//  final ReportView.
//
//  Three modal layers, mutually exclusive in practice:
//    - .sheet for CSVPickerView (file picker)
//    - .fullScreenCover (isPresented) for UploadProgressView (active flow)
//    - .fullScreenCover (item) for ReportView (opened report)
//

import SwiftUI

struct ReportListView: View {
    @Environment(ReportStore.self) private var store
    @Environment(UploadFlowCoordinator.self) private var coordinator

    @State private var showingPicker = false
    @State private var presentedReport: AutopsyReport?
    @State private var checkoffStore = ActionCheckoffStore.shared

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerRow
                        .padding(.top, DS.Spacing.md)

                    Text("Your behavioral diagnostics")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .padding(.top, DS.Spacing.xs)

                    content
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.xl)
            }
            .refreshable {
                await store.hydrate()
            }
        }
        .sheet(isPresented: $showingPicker) {
            CSVPickerView(
                onPicked: { url in
                    showingPicker = false
                    handlePickedFile(url)
                },
                onCancelled: { showingPicker = false }
            )
        }
        .fullScreenCover(isPresented: progressVisibleBinding) {
            UploadProgressView(
                coordinator: coordinator,
                onCancel: { coordinator.cancel() },
                onRetry: { coordinator.cancel(); showingPicker = true }
            )
        }
        .fullScreenCover(item: $presentedReport) { report in
            ReportScrollContainer(report: report)
        }
        .onChange(of: coordinatorStateKey) { _, _ in
            handleStateChange()
        }
        .task(id: store.reports.first?.id) {
            if let mostRecentId = store.reports.first?.id {
                await checkoffStore.load(reportId: mostRecentId)
            }
        }
        .onChange(of: AuthState.shared.isAuthenticated) { _, isAuth in
            if isAuth, let mostRecentId = store.reports.first?.id {
                Task { await checkoffStore.load(reportId: mostRecentId) }
            }
        }
    }

    // MARK: - Content state machine

    /// Drives loading / error / empty / populated off the hydration state.
    /// While reports exist, the list always shows (pull-to-refresh keeps
    /// the last-known list visible and renders its own spinner).
    @ViewBuilder
    private var content: some View {
        if store.reports.isEmpty {
            if store.isHydrating {
                loadingState
            } else if store.hydrationError != nil {
                errorState
            } else {
                emptyState
            }
        } else {
            reportsList
        }
    }

    private var loadingState: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .tint(DS.Color.V3.textTertiary)
            Text("Loading your reports.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.V3.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DS.Spacing.xxl)
    }

    private var emptyState: some View {
        emptyStateUploadButton
            .padding(.top, DS.Spacing.xl)
    }

    private var errorState: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("Couldn't load reports.")
                .font(.system(size: 15))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: { Task { await store.hydrate() } }) {
                Text("Try again")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(DS.Color.V3.ctaText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DS.Spacing.xxl)
    }

    private var reportsList: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: DS.Spacing.md) {
                ForEach(Array(store.reports.enumerated()), id: \.element.id) { idx, report in
                    Button {
                        presentedReport = report
                    } label: {
                        reportCard(report, showProgressRing: idx == 0)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, DS.Spacing.xl)

            Text("More reports unlock after each weekly upload.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, DS.Spacing.xl)
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("AUTOPSY REPORTS")
                .font(.system(size: 10, weight: .regular).monospacedDigit())
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.V3.textTertiary)

            Spacer()

            if !store.reports.isEmpty {
                Button(action: { showingPicker = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DS.Color.V3.ctaText)
                        .frame(width: 32, height: 32)
                }
            }
        }
    }

    // MARK: - Empty-state upload pill

    private var emptyStateUploadButton: some View {
        Button(action: { showingPicker = true }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.doc")
                    .font(.system(size: 16, weight: .semibold))
                Text("Upload CSV")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(DS.Color.V3.primaryFillText)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(DS.Color.V3.primaryFill)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    // MARK: - Report card

    /// Card title: "{archetype} · {shortDate}". Falls back to the date
    /// alone when the archetype is absent, and to "Report" when neither
    /// the archetype nor a parseable date is available (Step 5).
    private func cardTitle(for report: AutopsyReport) -> String {
        let archetype = report.analysis.bettingArchetype?.name
        let date = Self.shortDate(from: report.createdAt)
        switch (archetype, date) {
        case let (.some(name), .some(day)): return "\(name) \u{00B7} \(day)"
        case let (.some(name), .none):      return name
        case let (.none, .some(day)):       return day
        case (.none, .none):                return "Report"
        }
    }

    /// Parses an ISO-8601 createdAt string and formats it as "MMM d"
    /// (e.g. "May 20"). Returns nil when the string can't be parsed, so
    /// cardTitle can fall back cleanly. No shared Date extension exists in
    /// the project yet; this local helper avoids adding one for a single
    /// call site.
    private static let cardDatePlain = ISO8601DateFormatter()
    private static let cardDateFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private static let cardDateOutput: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale.current
        f.setLocalizedDateFormatFromTemplate("MMMd")
        return f
    }()
    private static func shortDate(from raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        // Supabase createdAt may or may not carry fractional seconds; try
        // both ISO-8601 variants before giving up.
        let date = cardDatePlain.date(from: trimmed)
            ?? cardDateFractional.date(from: trimmed)
        guard let date else { return nil }
        return cardDateOutput.string(from: date)
    }

    private func reportCard(_ report: AutopsyReport, showProgressRing: Bool) -> some View {
        let ringTotal = min(6, report.analysis.recommendations.count)
        let renderRing = showProgressRing && ringTotal > 0
        // total_profit is a redacted dollar in snapshot mode (b775e8e);
        // rendering it inline would leak "$0". Swap for the established
        // label + LockedDollarBar locked-dollar treatment.
        let totalProfitRedacted = report.reportType == "snapshot"
            || report.analysis.summary.totalProfitVisibility == "redacted_dollar"
        return VStack(alignment: .leading, spacing: 0) {
            // REBUILD-PHASE-1 Step 5: status markers only. The case number
            // moved to a secondary line under the archetype+date title; this
            // row collapses to zero height when empty (full report w/ ring).
            HStack(spacing: 8) {
                if report.reportType == "snapshot" {
                    LabelChip(text: "FREE SNAPSHOT",
                              color: DS.Color.V3.Severity.gray)
                }

                Spacer()

                if !renderRing {
                    Text("TAP TO READ")
                        .font(.system(size: 10, weight: .regular).monospacedDigit())
                        .tracking(10 * 0.15)
                        .foregroundStyle(DS.Color.V3.ctaText)
                }
            }

            // Primary: "{archetype} · {shortDate}", or just the date when
            // the archetype is absent, or "Report" when neither resolves.
            Text(cardTitle(for: report))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .padding(.top, DS.Spacing.sm)

            // Secondary: case number, subdued.
            Text("Case \(report.caseNumber)")
                .font(.system(size: 12, weight: .regular).monospacedDigit())
                .tracking(10 * 0.12)
                .foregroundStyle(DS.Color.V3.textTertiary)
                .padding(.top, 3)

            Text("\(report.betCountAnalyzed.pluralized("bet", "bets")) analyzed")
                .font(.system(size: 13, weight: .regular).monospacedDigit())
                .monospacedDigit()
                .foregroundStyle(DS.Color.V3.textSecondary)
                .padding(.top, 2)

            if totalProfitRedacted {
                HStack(spacing: 8) {
                    Text("NET P/L")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundStyle(DS.Color.V3.textTertiary)
                    LockedDollarBar(width: 110)
                }
                .padding(.top, DS.Spacing.md)
            } else {
                Text("Your impatience cost you \(formatCurrency(abs(report.analysis.summary.totalProfit))) since November.")
                    .font(.system(size: 14, weight: .regular).italic())
                    .foregroundStyle(DS.Color.V3.textSecondary)
                    .lineSpacing(3)
                    .multilineTextAlignment(.leading)
                    .padding(.top, DS.Spacing.md)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.md)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
        )
        .overlay(alignment: .topTrailing) {
            if renderRing {
                ProgressRing(
                    completed: checkoffStore.completedCount(forReportId: report.id),
                    total: ringTotal
                )
                .padding(.top, 10)
                .padding(.trailing, 12)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
    }

    // MARK: - Upload flow plumbing

    /// CSV bytes must be read synchronously here so the picker's
    /// security-scoped resource is still active. The async upload then
    /// works on the in-memory Data, no longer touching the URL.
    private func handlePickedFile(_ url: URL) {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            #if DEBUG
            print("ReportListView: failed to read picked CSV (\(error))")
            #endif
            return
        }
        coordinator.startUpload(
            csvData: data,
            filename: url.lastPathComponent,
            reportType: "snapshot"
        )
    }

    private var progressVisibleBinding: Binding<Bool> {
        Binding(
            get: {
                switch coordinator.state {
                case .uploading, .streaming, .failed: return true
                default: return false
                }
            },
            set: { _ in }
        )
    }

    /// String key for .onChange - UploadFlowCoordinator.State isn't
    /// Equatable so we use a discriminator.
    private var coordinatorStateKey: String {
        switch coordinator.state {
        case .idle:              return "idle"
        case .picking:           return "picking"
        case .uploading:         return "uploading"
        case .streaming(let m):  return "streaming-\(m)"
        case .succeeded(let r):  return "succeeded-\(r.id)"
        case .failed:            return "failed"
        }
    }

    private func handleStateChange() {
        if case .succeeded(let report) = coordinator.state {
            store.add(report)
            presentedReport = report
            coordinator.dismiss()
        }
    }
}
