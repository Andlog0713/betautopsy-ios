//
//  AnnotatedBetCard.swift
//  BetAutopsy
//
//  Renders a single BetAnnotation as a worst- or best-decision card on
//  Ch 3. Surfaces classification chip + optional session grade chip +
//  primary reason + top 2 contributing signals + confidence.
//
//  No dollar values inside the card body, so the same render works in
//  full and snapshot mode without redaction.
//

import SwiftUI

struct AnnotatedBetCard: View {
    enum Role {
        case worst, best

        var title: String {
            switch self {
            case .worst: return "WORST DECISION"
            case .best:  return "BEST DECISION"
            }
        }

        var tint: Color {
            switch self {
            case .worst: return DS.Color.V3.Severity.red
            case .best:  return DS.Color.V3.Severity.green
            }
        }
    }

    let role: Role
    let annotation: BetAnnotation

    private var topSignals: [AnnotationSignal] {
        guard let signals = annotation.signals else { return [] }
        // Blocker #7: the engine sometimes emits a top signal whose
        // description is verbatim the primaryReason, so it renders as the
        // card title and again as the first bullet. Drop the duplicate.
        let reason = annotation.primaryReason
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return Array(
            signals
                .sorted { $0.weight > $1.weight }
                .filter {
                    $0.description.trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased() != reason
                }
                .prefix(2)
        )
    }

    private var gradeColor: Color {
        guard let raw = annotation.sessionGrade?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased(),
              !raw.isEmpty else {
            return DS.Color.V3.textTertiary
        }
        switch raw {
        case "F": return DS.Color.V3.Severity.red
        case "D": return DS.Color.V3.Severity.orange
        case "C": return DS.Color.V3.Severity.yellow
        case "A": return DS.Color.V3.Severity.green
        default:  return DS.Color.V3.textSecondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(role.title)
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.4)
                .foregroundStyle(role.tint)

            HStack(spacing: 8) {
                classificationChip
                if let grade = annotation.sessionGrade?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased(),
                   !grade.isEmpty {
                    gradeChip(grade)
                }
            }

            Text(annotation.primaryReason)
                .font(DS.Font.V3.bodyRegular)
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !topSignals.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(topSignals) { signal in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(role.tint.opacity(0.7))
                                .frame(width: 4, height: 4)
                                .padding(.top, 6)
                            Text(signal.description)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(DS.Color.V3.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            Text("CONFIDENCE \(BAFormat.percent(annotation.confidence, headline: true))")
                .font(DS.Font.V3.rowCapsLabel)
                .tracking(1.0)
                .foregroundStyle(DS.Color.V3.textTertiary)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: DS.Stroke.hairline)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private var classificationChip: some View {
        let color = annotation.classification.color
        return Text(annotation.classification.label)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous)
                    .fill(color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous)
                            .stroke(color, lineWidth: DS.Stroke.hairline)
                    )
            )
    }

    private func gradeChip(_ grade: String) -> some View {
        Text("GRADE \(grade)")
            .font(.system(size: 10, weight: .bold))
            .tracking(1.2)
            .foregroundStyle(gradeColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.chip, style: .continuous)
                    .stroke(gradeColor, lineWidth: DS.Stroke.hairline)
            )
    }

    private var accessibilityDescription: String {
        var parts: [String] = [
            role.title,
            annotation.classification.label
        ]
        if let grade = annotation.sessionGrade {
            parts.append("Session grade \(grade)")
        }
        parts.append(annotation.primaryReason)
        parts.append("Confidence \(Int(annotation.confidence.rounded())) percent")
        return parts.joined(separator: ". ") + "."
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        AnnotatedBetCard(
            role: .worst,
            annotation: BetAnnotation(
                betIndex: 4422,
                classification: .chasing,
                confidence: 92,
                primaryReason: "Placed 11 minutes after a $420 NFL loss settled. Stake was 3.1x your session median.",
                sessionGrade: "F",
                isInHeatedSession: true,
                betId: "b_4422",
                signals: [
                    AnnotationSignal(name: "post_loss_recency", weight: 86, category: "emotional",
                                     description: "Recency to prior loss was 11 minutes, top quartile of your chase window."),
                    AnnotationSignal(name: "stake_vs_median", weight: 72, category: "impulsive",
                                     description: "Stake was 3.1x your session median.")
                ],
                sessionId: "s_0247",
                currentStreak: -4,
                stakeVsMedian: 3.1,
                timeSinceLastBet: 660
            )
        )
        AnnotatedBetCard(
            role: .best,
            annotation: BetAnnotation(
                betIndex: 3812,
                classification: .disciplined,
                confidence: 88,
                primaryReason: "Flat-staked NBA player prop in a researched window. No prior loss within 6 hours.",
                sessionGrade: "A",
                isInHeatedSession: false,
                betId: "b_3812",
                signals: [
                    AnnotationSignal(name: "flat_sizing", weight: 78, category: "disciplined",
                                     description: "Stake equal to your session median."),
                    AnnotationSignal(name: "no_recent_loss", weight: 64, category: "disciplined",
                                     description: "No prior settled loss within the last 6 hours.")
                ],
                sessionId: "s_0156",
                currentStreak: 1,
                stakeVsMedian: 1.0,
                timeSinceLastBet: 21600
            )
        )
    }
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
