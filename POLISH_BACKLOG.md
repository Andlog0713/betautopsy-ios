# BetAutopsy iOS — Polish Backlog

> Companion to `BETAUTOPSY_IOS_MASTER_PLAN.md`.
> **Tier 1 items are baked into the master plan v4 day-by-day schedule.** They ship in v1.
> **Tier 2 items are pulled in opportunistically during v1 build if time allows, otherwise v1.1.**
> **Tier 3 items are intentionally skipped, with reasoning. Don't add these without strong evidence.**
> **Rejection prevention items are non-negotiable for App Store approval.**

---

## How to use this file

1. **You finish a master plan day's work ahead of estimate.** Pull a Tier 2 item.
2. **You're considering adding a polish feature mid-build.** Check Tier 3 first to confirm it's not on the skip list.
3. **You're prepping App Store submission.** Run the rejection prevention checklist.
4. **You're planning v1.1.** Tier 2 + selective Tier 3 items become the v1.1 scope.

**Never use this file as an excuse to delay shipping v1.** Floor first, polish second.

---

## Tier 1: Baked into master plan v4

These ship in v1. They drive conversion or prevent rejection. ROI is high enough that they're not optional.

### 1. Pow library + archetype reveal moment
**Master plan day:** Days 13-14
**Effort:** 4-6 hours
**Cost:** $99 one-time Pow license

**Why it ships in v1:**
The single biggest "wow" moment in the app. Users uploading their CSV and seeing "You are: The Heat Chaser" with a Pow-driven reveal is the moment that gets screenshotted and shared. Free organic distribution.

**Implementation notes:**
- Five archetypes × one reveal animation each
- Use `.movingParts.glow` + `.scale` + spring animation
- First-view-only on report screen; subsequent views skip the reveal
- Track via TelemetryDeck event `archetype.revealed`

**What could go wrong:**
- Pow's `.boing` effect can be over the top — dial back to `.scale + .glow` if testers complain
- Animation framerate drops on older devices (iPhone X-era) — test on physical hardware

---

### 2. Native onboarding paged sequence
**Master plan day:** Days 4-5
**Effort:** 3-4 hours

**Why it ships in v1:**
Apple wants to see "native paged onboarding" for 4.2 approval. Without it, you ship straight to auth which reads as a thin wrapper. Onboarding also primes the user on the value proposition before asking for SiwA, increasing auth completion rate.

**Implementation notes:**
- SwiftUI `TabView` with `.page` style
- Three custom card layouts with chrome label + headline + body copy
- Page indicator at bottom
- "Continue" CTA on each card, "Sign in with Apple" replaces it on last card
- First-launch only; persisted via UserDefaults `hasCompletedOnboarding`

**Card content:**
1. **"Find your blind spots"** — body: "Upload your bet history. We analyze patterns you can't see."
2. **"Track behavioral patterns"** — body: "Heated sessions, recency bias, parlay drift. Specific findings, not generic advice."
3. **"Get your archetype"** — body: "One of five behavioral profiles. Updates as your patterns evolve."

---

### 3. Share Extension target
**Master plan day:** Days 18-19
**Effort:** 4-6 hours

**Why it ships in v1:**
Two reasons. Major 4.2 strength signal (Apple loves Share Extensions because they prove deep iOS integration). Real user value — users tap "Share" on a CSV in Mail/Files/Safari → "BetAutopsy" appears as an option → CSV uploads. Reduces friction on the Pikkit referral flow.

**Implementation notes:**
- New target in Xcode (Share Extension type)
- Activation rule: `.csv`, `.xls`, `.xlsx` UTIs only
- Reads CSV from share intent
- Validates basic format (columns present, non-empty)
- Uploads to Supabase Storage with user's session token (read from Keychain via App Group)
- Hands off to main app via custom URL scheme deep link
- If user not authenticated: opens main app via deep link to auth, queues file for after sign-in

**Required setup:**
- App Group entitlement for sharing Keychain access between main app and extension
- Share Extension Info.plist activation rules

**What could go wrong:**
- Apple is strict about Share Extension memory limits (120MB). Don't load the entire CSV into memory — stream to Supabase Storage
- App Extension UIKit restrictions — no `UIApplication.shared.open()`, etc.

---

### 4. Custom loading state for analysis
**Master plan day:** Days 8-12
**Effort:** 2-3 hours

**Why it ships in v1:**
Real Claude analysis takes 20-60 seconds. Default `ProgressView` makes it feel broken. Branded copy makes wait time feel intentional.

**Implementation notes:**
- Timer-based text rotation, every 3-4 seconds
- Sample copy rotation (cycle through):
  - "PARSING BET HISTORY"
  - "DETECTING BIAS PATTERNS"
  - "EXAMINING SESSION TIMING"
  - "GENERATING CASE FILE"
  - "FINALIZING ANALYSIS"
- JetBrains Mono Medium, BAColor.textPrimary
- Subtle pulse animation on text (opacity 1.0 → 0.6 → 1.0 over 2s)
- Optional: small chrome label "ANALYSIS IN PROGRESS" pinned above

---

### 5. Empty states with personality
**Master plan day:** Days 13-14
**Effort:** 2-3 hours

**Why it ships in v1:**
Default empty state ("No reports yet") feels generic. Forensic empty state feels like *your* app. Cheap personality boost.

**Implementation notes:**
Three empty states needed:

**No reports yet:**
- SF Symbol: `doc.text.magnifyingglass` (large, scalpelTeal)
- Chrome label: "NO CASE FILES"
- Body: "Upload a CSV to begin investigation."
- CTA: "Upload bet history" button

**No bets in CSV:**
- SF Symbol: `exclamationmark.triangle` (large, bleedRed)
- Chrome label: "EMPTY CASE FILE"
- Body: "We couldn't find any bets in this file. Check the format and try again."
- CTA: "Upload another CSV" button

**Network error:**
- SF Symbol: `wifi.slash` (large, textTertiary)
- Chrome label: "CONNECTION LOST"
- Body: "Pull to retry."
- (No button — pull-to-refresh handles it)

---

### 6. App Icon
**Master plan day:** Day 7
**Effort:** 3-5 hours
**Cost:** $0 (DIY in Figma) or $100-300 (outsourced)

**Why it ships in v1:**
Default Xcode app icon = dead giveaway you didn't try. Real BetAutopsy icon = legitimacy signal on home screen.

**Direction:**
- Background: midnight `#0D1117`
- Mark: monogram (BA letters interlocked) OR forensic motif (stylized magnifying glass, fingerprint, evidence stamp)
- Accent: scalpel teal `#00C9A7`
- Typography (if monogram): JetBrains Mono Bold
- 1024x1024 PNG, drop into Assets.xcassets, Xcode auto-generates required sizes

**DIY path:**
- Open Figma, 1024x1024 frame
- Midnight background, layout monogram or motif, export PNG

**Outsource path:**
- Fiverr: search "iOS app icon design" — $50-150 typical
- 99designs: contest format, $200-400, multiple options
- Send brief: "Forensic case-file aesthetic, midnight (#0D1117) background, scalpel teal (#00C9A7) accent. App is behavioral analysis for sports betting. Avoid sportsbook clichés (no dice, no cards, no sportsbook logos)."

---

## Tier 2: Pull in opportunistically

These don't ship by default but are easy wins if you finish floor work ahead of schedule. Otherwise they go in v1.1.

### 7. Symbol Effects pass on key screens
**Effort:** 2-3 hours

**Why useful:**
SF Symbols have built-in iOS 17+ animations. Subtle pulse on heated session indicator, draw-on animation when bias chips appear — these read as "premium iOS app" without being gimmicky.

**Implementation:**
- `.symbolEffect(.pulse, options: .repeating)` on heated session indicator
- `.symbolEffect(.bounce, value: trigger)` on bias detection icons (one-shot when scrolling them into view)
- `.contentTransition(.symbolEffect(.replace))` when status changes

**When to add:** If you finish Day 14 in 4 hours instead of 8.

---

### 8. Native chart polish on report screen
**Effort:** 3-4 hours

**Why useful:**
Default Swift Charts styling is fine but generic. Brand-color bars, custom axis labels in JetBrains Mono, animated bar growth on first appearance.

**Implementation:**
- `.chartXAxis { AxisMarks(values: .automatic) { value in AxisValueLabel().font(BAFont.chrome) } }`
- `.chartYAxis { ... same pattern ... }`
- `.foregroundStyle(by: .value("Bias", item.severity))` with custom color scale
- `.transition(.scale)` on bars for first-render animation

**When to add:** Day 13-14 if hero number + reveal moment came together fast.

---

### 9. Pull-to-refresh on report list
**Effort:** 1 hour

**Why useful:**
iOS users expect it. Without it the list feels static. With it the list feels alive.

**Implementation:**
```swift
.refreshable {
    await viewModel.refresh()
}
```
On the ScrollView containing the report list. One modifier.

**When to add:** Anytime. Always do this. Genuinely 1 hour of work.

---

### 10. Haptic feedback on key moments
**Effort:** 1-2 hours

**Why useful:**
Successful CSV upload, successful purchase, archetype reveal — these moments deserve haptic confirmation. Premium iOS apps have it; absence feels off.

**Implementation:**
Built-in `UIImpactFeedbackGenerator` and `UINotificationFeedbackGenerator`:

- `.medium` impact on CSV upload start
- `.success` notification on analysis complete
- `.medium` impact on archetype reveal start
- `.success` on purchase complete
- `.warning` on auth failure

Wrap in `@MainActor` helper:
```swift
@MainActor
enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
    static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}
```

**When to add:** Day 17-18 polish pass after IAP wired.

---

### 11. Face ID gate
**Effort:** 2-3 hours

**Why useful:**
Strong 4.2 signal. Real user value (protect financial behavioral data). Master plan v3 had this in v1.1 backlog but it's actually quick to add.

**Implementation:**
- `LocalAuthentication` framework
- On app foreground if backgrounded >30 seconds, show Face ID prompt
- Fallback to passcode if Face ID unavailable
- Setting toggle to disable (Settings → "Require Face ID to open")
- Default: ON if device has biometric, OFF otherwise

**When to add:** Day 22-23 with Settings screen, or v1.1 if time-constrained.

---

### 12. Settings polish
**Effort:** 1-2 hours

**Why useful:**
Master plan settings screen is functional but minimal. Section headers, grouped layout, brand-consistent styling.

**Implementation:**
- Group settings into sections: Notifications, Display, Privacy & Safety, Account
- Each section has a chrome label header
- Native `.formStyle(.grouped)` with custom row backgrounds (BAColor.surface1)
- App version + build number at bottom (BAColor.textTertiary)

---

## Tier 3: Skip these (with reasoning)

Don't add these without strong evidence they pay back. Listed so future-you doesn't waste cycles re-evaluating.

### Custom display face for wordmark
**Why skip:** $400-800 cost, ~10 hours integration, doesn't move conversion needle pre-launch. Inter is a strong default. Custom typography is a v2 differentiation lever, not a v1 must-have.

### Custom Inferno Metal shader
**Why skip:** Flashy but App Review red flag (non-essential GPU usage on a financial app). Performance risk on older devices. Even if it works, what does it accomplish? Aesthetic novelty doesn't drive retention.

### Sound design
**Why skip:** Most users have phones on silent. Sound effects on a behavioral analysis app feel out of register — this is forensic, not gamified. The "satisfying chime" pattern works for Duolingo, not for "your $1,847 leak."

### Animated digit roll on dashboard
**Why skip:** Looks cool but bait for attention. Counterproductive in forensic context where you want the user to *think about the number*, not watch it count up. The number IS the point.

### Apple Watch companion
**Why skip:** Separate review track, separate complexity, no real use case for a behavioral analysis app on the watch. What would you check? Heated session count? Skip until v1.5+ at earliest.

### iPad layout
**Why skip:** You already declared iPhone-only on Day 2. Reversing course means re-doing every screen layout, retesting, additional 4.2 review surface. Not worth it for v1.

### Live Activities
**Why skip:** Requires backend work to push live state. Big undertaking for marginal gain pre-launch. What live activity? "Your heated session is in progress"? That's punitive, not helpful.

### Onboarding behavioral quiz
**Why skip:** Cal AI's onboarding quiz pattern works for body-image categories. For behavioral self-awareness in betting, an upfront quiz reads as judgmental and intrusive. The data-driven analysis IS the feature — let the CSV do the talking. Revisit only if user research shows opt-in interest.

### Notification Service Extension (rich push)
**Why skip:** Rich notifications with charts is cool but Apple's Notification Service Extension has memory limits, async constraints, and is a known source of crashes. Plain text notifications with strong copy work fine for v1. Add in v1.1 if the analytics show notification CTR is too low and you suspect rich content would help.

### App Intents / Siri integration
**Why skip:** What would users ask Siri? "Hey Siri, did I have heated sessions this week?" — too narrow a use case for the integration cost. v1.2 if usage data shows demand.

### Spotlight indexing
**Why skip:** Past reports in Spotlight is nice but takes ~4 hours and the discoverability gain is marginal pre-launch. Easy add in v1.1 once there's enough data to index.

### Home Screen widget
**Why skip:** Widgets are great but the design work alone is 6+ hours. What does the widget show? Latest dollar impact? That's a reminder of loss every time the user looks at home screen — possibly counterproductive for a behavioral self-awareness app. v1.2 with proper UX research.

### BAForensicsKit Swift Package
**Why skip:** Premature abstraction. v1 has one app target — the package overhead (separate Tokens.swift availability in Previews, build complexity) costs more than it saves. Promote to a package only if/when you build a second app target (Watch, widget, share extension growth).

### Multi-language localization
**Why skip:** US-only launch (gambling regulations). No Spanish, Portuguese, etc. needed for v1. Adds significant translation cost and review surface. v1.5+ when you expand to international markets.

### Custom illustrations / archetype sigils
**Why skip:** Tier 1 has Pow handling the reveal motion. Custom illustrations would be 5 archetype sigils × 4-6 hours design = 20-30 hours of work. SF Symbols + Pow animations achieve 80% of the perceived premium-ness for 5% of the cost. v1.2 if the data shows users care about archetype identity.

### Pre-bet tilt check-in
**Why skip:** Requires live betslip integration which doesn't exist. Multi-month engineering effort. v1.5+.

### Discipline Leagues / social features
**Why skip:** Behavioral self-awareness is private. Adding social comparison gamifies what should be reflective. Wrong category mistake.

### CLV (Closing Line Value) tracking
**Why skip:** Niche feature for advanced bettors. BetAutopsy is positioned as behavioral, not analytical. Adding CLV positions you closer to OddsJam/Action Network territory which is the wrong category. Skip permanently.

### Season Wrapped (September 2026)
**Why skip in v1:** This is a major v1.1+ feature with big animation, share-card design, multi-week build. Listed in master plan section 15 as future scope.

### macOS Catalyst port
**Why skip:** Forensic UI is mobile-native. Touching it on Mac doesn't add value — desktop bettors use the web app at betautopsy.com. v2.0+ if at all.

### Referral program
**Why skip:** Acquisition mechanism, not product. Best built after PMF and pricing are stable. v1.1+ at earliest.

---

## Rejection prevention checklist

These are NON-NEGOTIABLE for App Store approval. Run this before submitting.

### A. App Store screenshot strategy
**Status in master plan:** Days 25-26
**Why critical:** First impression in App Store. Conversion driver.

**The 5-7 screenshot story:**
1. Hero: report screen with dollar impact + archetype + chart
2. CSV upload moment with native picker visible (proves native iOS, not WebView — 4.2 evidence)
3. Bias breakdown chart (proves Swift Charts use)
4. Archetype reveal mid-animation (the viral screenshot)
5. Past reports list (proves repeat-use product)
6. Settings showing 1-800-GAMBLER link (5.3 evidence, reviewers screenshot this themselves)
7. Paywall (proves IAP implementation)

**Annotation:** one-line caption overlay in JetBrains Mono per screenshot. Use Screenshot Studio or Picsew on Mac.

### B. App Preview video
**Status in master plan:** Days 25-26 (optional in v3, REQUIRED in v4)
**Why critical:** Apple data shows 35% conversion lift. Worth the 2-3 hour effort.

**Format:**
- 15-30 seconds
- Portrait orientation
- Recorded on real iPhone via QuickTime over USB
- 1290x2796 (iPhone 15 Pro Max)
- Story: open app → tap upload → loading state → archetype reveal → see report

### C. Privacy nutrition labels exhaustively filled
**Status in master plan:** Day 24
**Why critical:** Apple checks these against actual code. Mismatch = instant rejection.

**Be honest about:**
- TelemetryDeck collects: anonymous device ID for unique session counting (privacy-first, but not zero data)
- Supabase collects: email (Sign in with Apple), bet history (uploaded by user), archetype (computed)
- RevenueCat collects: anonymized purchase events
- No third-party advertising SDKs
- No data sold or shared

### D. Detailed App Review notes
**Status in master plan:** Day 24
**Why critical:** This single document massively reduces 5.3 rejection risk.

**Include:**
- Test account credentials (create a specific account for review)
- Test CSV file (link to a sample with realistic data)
- Note: "BetAutopsy is a behavioral analysis tool, not a gambling app. We do not take wagers, show odds, or recommend bets. We analyze user-uploaded historical data for behavioral patterns and cognitive biases. This positions us closer to Pikkit (id1586567110) which Apple has approved than to gambling aids."
- Note: "1-800-GAMBLER link is in Settings AND on the paywall (verifiable in screenshot 6 and visible during purchase flow)."
- Note: "Geo-restricted to US states with legal online sports betting at the server level. International users see 'BetAutopsy isn't available in your region yet.'"

### E. TestFlight feedback iteration
**Status in master plan:** Days 28-34
**Why critical:** Real users find issues simulator hides.

**Don't skip:** 3-5 real users, 5-7 days minimum (need a Monday for Weekly Autopsy). Common issues:
- Sign in with Apple breaking on iCloud-paused accounts
- Push notifications double-firing or not firing
- CSV parser edge cases (empty cells, weird date formats, BOM characters)
- Paywall display issues on different device sizes
- Onboarding skipped on iPad simulators (but you're iPhone-only, so verify on iPhone)

### F. Privacy manifest (PrivacyInfo.xcprivacy)
**Status in master plan:** Day 24
**Why critical:** Required as of iOS 17. Apple checks this matches actual SDK behavior.

**Must declare for each third-party SDK:**
- supabase-swift: NSPrivacyAccessedAPICategoryUserDefaults (likely), file timestamp APIs
- RevenueCat: NSPrivacyAccessedAPICategoryFileTimestamp, NSPrivacyAccessedAPICategorySystemBootTime
- TelemetryDeck: check their privacy manifest, copy declared usage
- Pow: minimal — UI animations only

Ship `PrivacyInfo.xcprivacy` at the app root.

### G. Bundle ID + capabilities lock
**Status in master plan:** Day 7+ ongoing
**Why critical:** Bundle ID `com.diagnosticsports.BetAutopsy` must match across:
- Xcode project
- App Store Connect record
- Supabase Auth redirect URL
- RevenueCat product configuration
- APNs auth key + Apple Developer Service ID

Mismatch in any one of these = silent failure. Verify at every checkpoint.

---

## Summary of ROI ranking

If you can only do five Tier 1 items: **Tier 1 #1 (Pow reveal), #2 (onboarding), #3 (Share Extension), #6 (App Icon), and rejection prevention #D (App Review notes)** are the highest-leverage.

Everything else can wait, including pull-to-refresh and haptics. But none of it should be skipped permanently — it just doesn't have to ship Day 30.

---

*Last updated: Day 1 of build. Sync with master plan v4.*
