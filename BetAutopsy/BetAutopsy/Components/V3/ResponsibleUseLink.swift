//
//  ResponsibleUseLink.swift
//  BetAutopsy
//
//  Reusable responsible-gambling helpline + non-medical disclaimer card.
//  Mounted at the end of Chapter 7 (Warning Signs) and Glossary, and
//  inside SettingsView Legal section. Surface conventions match
//  WhatChangedCard / DamagesCard: surfaceCard bg, 0.5pt borderSubtle
//  stroke, 12pt continuous corner radius.
//

import SwiftUI

struct ResponsibleUseLink: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Link(destination: URL(string: "tel://18006973738")!) {
                Text("If gambling has stopped being fun, call 1-800-MY-RESET")
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.Brand.yellow)
                    .multilineTextAlignment(.leading)
            }

            Link(destination: URL(string: "sms:800426")!) {
                Text("Or text 800GAM.")
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.Brand.yellow)
            }

            Link(destination: URL(string: "https://www.ncpgambling.org/chat")!) {
                Text("ncpgambling.org/chat")
                    .font(DS.Font.V3.captionLabel)
                    .foregroundStyle(DS.Color.Brand.yellow)
            }

            Text("BetAutopsy is not a medical or mental health service. Consult a professional for treatment.")
                .font(.system(size: 11))
                .foregroundStyle(DS.Color.V3.textTertiary)
                .padding(.top, DS.Spacing.xs)
        }
        .padding(DS.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.Color.V3.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DS.Color.V3.borderSubtle, lineWidth: 0.5)
        )
    }
}

#Preview {
    ResponsibleUseLink()
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.V3.canvasGradientEnd)
        .preferredColorScheme(.dark)
}
