//
//  PushPermissionView.swift
//  BetAutopsy
//
//  Full-screen permission prompt presented exactly once per device,
//  on Chapter 7 onAppear, gated by the UserDefaults flag
//  "betautopsy.push_permission_asked". V3-styled per V12 onboarding
//  cascade rhythm.
//
//  Both Allow and Maybe Later set the asked flag so the prompt never
//  re-surfaces. iOS Settings is the only re-entry. Allow path calls
//  UNUserNotificationCenter.requestAuthorization then
//  UIApplication.registerForRemoteNotifications on the main thread
//  if granted. Denial is silent — Sentry breadcrumb only, no nag.
//

import SwiftUI
import UserNotifications
import UIKit
import Sentry

struct PushPermissionView: View {
    @Environment(\.dismiss) private var dismiss

    private static let askedKey = "betautopsy.push_permission_asked"

    var body: some View {
        ZStack {
            DS.Color.V3.canvasGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 120)

                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    Text("GET THE AUTOPSY")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(10 * 0.18)
                        .foregroundStyle(DS.Color.V3.textTertiary)

                    Text("Get the autopsy when it matters.")
                        .font(.system(size: 24, weight: .bold))
                        .tracking(-24 * 0.015)
                        .foregroundStyle(DS.Color.V3.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("We'll send a notification when we detect a heated session in your latest report. Quiet by default. No marketing, no spam.")
                        .font(DS.Font.V3.bodyRegular)
                        .foregroundStyle(DS.Color.V3.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.lg)

                Spacer()

                VStack(spacing: DS.Spacing.md) {
                    Button(action: handleAllowTap) {
                        Text("Allow Notifications")
                            .font(DS.Font.V3.buttonLabel)
                            .foregroundStyle(DS.Color.V3.primaryFillText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(DS.Color.V3.primaryFill)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
                    }

                    Button(action: handleMaybeLaterTap) {
                        Text("Maybe later")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Color.V3.textTertiary)
                            .frame(height: 44)
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xxl)
            }
        }
    }

    // MARK: - Actions

    private func handleAllowTap() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        ) { granted, error in
            if let error = error {
                let crumb = Breadcrumb(level: .error, category: "push")
                crumb.message = "requestAuthorization error: \(error.localizedDescription)"
                SentrySDK.addBreadcrumb(crumb)
            }

            if granted {
                let crumb = Breadcrumb(level: .info, category: "push")
                crumb.message = "Push permission granted"
                SentrySDK.addBreadcrumb(crumb)

                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                let crumb = Breadcrumb(level: .info, category: "push")
                crumb.message = "Push permission denied"
                SentrySDK.addBreadcrumb(crumb)
            }

            DispatchQueue.main.async {
                markAskedAndDismiss()
            }
        }
    }

    private func handleMaybeLaterTap() {
        let crumb = Breadcrumb(level: .info, category: "push")
        crumb.message = "Push permission deferred (maybe later)"
        SentrySDK.addBreadcrumb(crumb)

        markAskedAndDismiss()
    }

    private func markAskedAndDismiss() {
        UserDefaults.standard.set(true, forKey: Self.askedKey)
        dismiss()
    }
}

#Preview {
    PushPermissionView()
        .preferredColorScheme(.dark)
}
