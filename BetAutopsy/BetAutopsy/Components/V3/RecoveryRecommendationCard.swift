//
//  RecoveryRecommendationCard.swift
//  BetAutopsy
//
//  Recovery-tier card (web RecoveryRecommendationCard + SUPPORT block, PR
//  #71). Shown in SectionProtocol when the report-baked riskTier is
//  'recovery'. Informational only: iOS has no Control Center to opt into, so
//  there is no opt-in CTA. The support resources (helpline / chat / crisis
//  line) render ONLY here, never at the elevated tier, matching web's
//  message-fatigue gating. Helpline content comes straight from the
//  engine-supplied supportResources (single source of truth), styled with
//  ResponsibleUseLink's chrome.
//

import SwiftUI

struct RecoveryRecommendationCard: View {
    let controlSystem: ReportControlSystem

    private var leadText: String {
        if let headline = controlSystem.headline, !headline.isEmpty {
            return headline
        }
        return "This stretch shows sustained high-risk patterns. Support is here if you want it."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(leadText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.Color.V3.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(controlSystem.topRisks) { risk in
                VStack(alignment: .leading, spacing: 4) {
                    Text(risk.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Color.V3.textPrimary)
                    Text(risk.detail)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !controlSystem.supportResources.isEmpty {
                Text("SUPPORT")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.6)
                    .foregroundStyle(DS.Color.V3.textTertiary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(controlSystem.supportResources) { resource in
                        resourceRow(resource)
                    }
                }
            }

            Text("BetAutopsy is not a medical or mental health service. Consult a professional for treatment.")
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.V3.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func resourceRow(_ resource: SupportResource) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let href = resource.href, let url = URL(string: href) {
                Link(destination: url) {
                    Text(resource.label)
                        .font(DS.Font.V3.captionLabel)
                        .foregroundStyle(DS.Color.Brand.yellow)
                        .multilineTextAlignment(.leading)
                }
            } else {
                Text(resource.label)
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.Brand.yellow)
            }

            Text(resource.value)
                .font(.system(size: 12))
                .foregroundStyle(DS.Color.V3.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
#Preview {
    RecoveryRecommendationCard(controlSystem: ReportControlSystem(
        riskTier: .recovery,
        recoveryModeRecommended: true,
        headline: "This stretch shows sustained high-risk patterns. Support is here if you want it.",
        topRisks: [
            ReportRiskSummary(
                title: "Stake escalation after losses",
                detail: "Stakes grew across losing sessions in the last 30 days.",
                evidence: ""
            )
        ],
        supportResources: [
            SupportResource(
                label: "National Problem Gambling Helpline",
                value: "Call or text 1-800-MY-RESET. Free and confidential, 24/7.",
                href: "tel:18006973738"
            ),
            SupportResource(
                label: "Problem gambling chat",
                value: "Start a confidential live chat through the National Council on Problem Gambling.",
                href: "https://www.ncpgambling.org/chat/"
            )
        ]
    ))
    .padding(16)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(DS.Color.V3.canvasGradientEnd)
    .preferredColorScheme(.dark)
}
#endif
