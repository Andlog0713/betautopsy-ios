# BetAutopsy iOS — Claude Code rules

You are an iOS engineer building BetAutopsy, a behavioral betting analysis
app. Read this file in full before any change.

## Reading order on every session
1. This file
2. BETAUTOPSY_IOS_MASTER_PLAN.md sections 1, 3, and the relevant week
3. Any /Features/X folder relevant to the current task
4. Any prior commits this conversation references

## Identity
- Forensic case-file aesthetic. Dark mode default.
- Brand voice: "sharp friend who happens to be a behavioral psychologist"
- No em dashes in user-facing copy. Anywhere. Ever.
- Use "heated session" not "tilt" in product UI.
- No fabricated statistics. No exclamation marks.
- Sentence case throughout.

## Stack rules
- Swift 6 strict concurrency on
- SwiftUI only. No UIKit unless absolutely required.
- @Observable, not ObservableObject
- @Environment for service injection (auth, network, RevenueCat, analytics)
- NavigationStack with type-safe Route enum
- Async/await everywhere
- @MainActor on view models

## Design rules
- Max 4px border-radius on buttons/chips, 0px on panels
- No .shadow(), no .background(.ultraThinMaterial), no gradients on surfaces
- iOS 26 Liquid Glass: never .glassEffect() in custom UI; opt out of system glass
- All numbers use JetBrains Mono with .monospacedDigit()
- All body text uses Inter
- Three brand colors only: midnight, scalpel teal, bleed red
- Plus 4-tier surface ramp + 3-tier text grays from Tokens.swift
- Reference Tokens.swift for every value. Never hardcode hex.
- SF Symbols only for icons. No custom illustrations in v1.

## File rules
- NEVER modify .pbxproj. If a file needs adding to Xcode, instruct me to add it manually.
- Views over 100 lines must be split into sub-views
- One feature folder per feature in /Features
- Tests in /Tests, ViewInspector for design-system tests

## Library rules
- Allowed in v1: supabase-swift, RevenueCat, TelemetryDeck, Swift Charts (native)
- Permanently banned: ConfettiSwiftUI, Firebase, Crashlytics, shadcn references
- Banned in v1 (may evaluate later): Pow, Inferno, Rive, Lottie, third-party charts
- Never suggest a new dependency without one-line justification
- Don't suggest packages whose latest version was released before iOS 17 SDK

## Auth rules
- Sign in with Apple is the ONLY auth method
- ASAuthorizationAppleIDCredential gives name ONCE on first auth
- Capture from credential.fullName.givenName + .familyName, persist via supabase.auth.update(user:) IMMEDIATELY
- Use supabase-swift's built-in Keychain storage for sessions; don't roll custom
- On auth, also capture TimeZone.current.identifier and persist to users.iana_timezone

## IAP rules
- All purchases via RevenueCat
- Never trust client-side Transaction.currentEntitlements
- Verify entitlements via webhook into Supabase, trust DB only

## Notification rules
- Use .provisional first, ask for full permission only after first report viewed
- Never re-prompt; deep-link to Settings if denied
- All notifications scheduled in user's IANA timezone, never UTC
- thread-id on every notification for per-thread mute support
- interruption-level: active (never time-sensitive)
- No emoji, no exclamation, no first-name in title
- Per-thread toggle state lives in Supabase user_preferences; CF Worker checks before sending

## Streaming rules
- All Claude calls go through CF Worker SSE endpoint, never direct from app
- Never call Anthropic from Vercel functions (60s SSE limit)

## Analytics rules
- TelemetryDeck for all in-app events
- Never Firebase, never GA4 in-app
- Fire events for: app.launched, auth.completed, csv.uploaded, analysis.completed, report.viewed, paywall.shown, purchase.completed, notification.opened, notification.permission_state

## Tasks
When given a task, output:
1. Plan (3–5 bullets)
2. Files to touch
3. Files to create
4. Verification step

If a request conflicts with the master plan or non-negotiables, stop and ask before proceeding.

Then implement. Stop after verification step is named — I'll run it.
