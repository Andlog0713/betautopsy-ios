//
//  ReportView.swift
//  BetAutopsy
//
//  Full-screen report reader. Top bar with case number + chapter counter
//  + dismiss, paged TabView of 7 chapters, animated page indicator.
//  Phase 1 fills all 7 pages with ChapterPlaceholder; later phases swap
//  in real chapter views.
//

import SwiftUI

struct ReportView: View {
    let report: AutopsyReport

    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex = 0

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                ZStack(alignment: .bottom) {
                    TabView(selection: $currentIndex) {
                        ChapterTheVerdictView(report: report).tag(0)
                        ChapterYourMindView(report: report).tag(1)
                        ChapterPlaceholder(label: "CHAPTER 3").tag(2)
                        ChapterPlaceholder(label: "CHAPTER 4").tag(3)
                        ChapterPlaceholder(label: "CHAPTER 5").tag(4)
                        ChapterPlaceholder(label: "CHAPTER 6").tag(5)
                        ChapterPlaceholder(label: "CHAPTER 7").tag(6)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    pageIndicator
                        .padding(.bottom, DS.Spacing.lg)
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Text("CASE \(report.caseNumber) · CHAPTER \(currentIndex + 1) OF 7")
                .font(.custom("JetBrainsMono-Regular", size: 10))
                .tracking(10 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
            Spacer()
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.Color.Text.tertiary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.top, DS.Spacing.xs)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                Capsule()
                    .fill(i == currentIndex
                          ? DS.Color.Accent.luminol
                          : DS.Color.Text.tertiary.opacity(0.4))
                    .frame(width: i == currentIndex ? 14 : 4, height: 4)
                    .animation(.easeOut(duration: 0.2), value: currentIndex)
            }
        }
    }
}

struct ChapterPlaceholder: View {
    let label: String

    var body: some View {
        ZStack {
            DS.Color.Surface.canvas.ignoresSafeArea()
            Text(label)
                .font(.custom("JetBrainsMono-Regular", size: 14))
                .tracking(14 * 0.15)
                .foregroundStyle(DS.Color.Text.tertiary)
        }
    }
}
