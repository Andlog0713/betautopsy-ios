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

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerRow
                        .padding(.top, DS.Spacing.md)

                    Text("Your behavioral diagnostics")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(DS.Color.Text.primary)
                        .padding(.top, DS.Spacing.xs)

                    if store.showMockPlaceholder {
                        emptyStateUploadButton
                            .padding(.top, DS.Spacing.xl)
                    }

                    VStack(spacing: DS.Spacing.md) {
                        ForEach(store.displayedReports) { report in
                            Button {
                                presentedReport = report
                            } label: {
                                reportCard(report)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, store.showMockPlaceholder
                                   ? DS.Spacing.xl : DS.Spacing.xl)

                    Text("More reports unlock after each weekly upload.")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Color.Text.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, DS.Spacing.xl)
                }
                .padding(.horizontal, DS.Spacing.md)
                .padding(.bottom, DS.Spacing.xl)
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
            ReportView(report: report)
        }
        .onChange(of: coordinatorStateKey) { _, _ in
            handleStateChange()
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("AUTOPSY REPORTS")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)

            Spacer()

            if !store.reports.isEmpty {
                Button(action: { showingPicker = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(DS.Color.Accent.luminolSoft)
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
            .foregroundStyle(DS.Color.Text.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(DS.Color.Accent.luminol)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
        }
    }

    // MARK: - Report card

    private func reportCard(_ report: AutopsyReport) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("CASE \(report.caseNumber)")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Text.tertiary)

                if report.reportType == "snapshot" {
                    LabelChip(text: "FREE SNAPSHOT",
                              color: DS.Color.Accent.luminolSoft)
                }

                Spacer()

                Text("TAP TO READ")
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(10 * 0.15)
                    .foregroundStyle(DS.Color.Accent.luminolSoft)
            }

            Text(report.analysis.bettingArchetype?.name ?? "Report")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(DS.Color.Text.primary)
                .padding(.top, DS.Spacing.sm)

            Text("\(report.betCountAnalyzed) bets analyzed")
                .font(.custom("JetBrainsMono-Regular", size: 13))
                .monospacedDigit()
                .foregroundStyle(DS.Color.Text.secondary)
                .padding(.top, 2)

            Text("Your impatience cost you \(formatCurrency(abs(report.analysis.summary.totalProfit))) since November.")
                .font(.custom("Georgia-Italic", size: 14))
                .foregroundStyle(DS.Color.Text.secondary)
                .lineSpacing(3)
                .multilineTextAlignment(.leading)
                .padding(.top, DS.Spacing.md)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.md)
        .background(DS.Color.Surface.card)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Color.Border.subtle, lineWidth: DS.Stroke.hairline)
        )
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

    /// String key for .onChange — UploadFlowCoordinator.State isn't
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
