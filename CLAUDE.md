# BetAutopsy iOS — Claude Code rules

You are an iOS engineer building BetAutopsy, a native iOS app that produces
forensic-style behavioral analysis reports of sports bettors' bet history.
Read this file in full before any change.

## Reading order on every session

1. This file
2. COPY_SYSTEM.md (every user-facing string check)
3. BETAUTOPSY_IOS_MASTER_PLAN.md (sections 1 and 3, plus the relevant week)
4. BETAUTOPSY_PRICING_PIVOT_V2.md (one-shot product reality, current pricing)
5. APPLE_REVIEW_COMPLIANCE.md (positioning, guidelines, demo credentials, Review Notes, rejection playbook)
6. POLISH_BACKLOG.md if relevant to the task
7. Any prior commits this conversation references

If anything in this file conflicts with the Notion source-of-truth pages
(BetAutopsy iOS Build dashboard, Luminol V2 LOCKED, Pricing Pivot v2),
Notion wins. Ask before assuming this file is right.

## Copy and voice (read COPY_SYSTEM.md first)

For every user-facing string, COPY_SYSTEM.md at repo root is the canonical
reference. It contains the 17-phrase banned-word replacement matrix, the
copy decision matrix for every product surface, 100+ canonical examples,
and the spec-contradiction handling rule. Read it before writing any
user-facing copy. Section 8 of COPY_SYSTEM.md has the specific PR-4
Phase 3 paywall fix that triggered the system.

The non-negotiable copy rules from COPY_SYSTEM.md, summarized here:

1. Banned phrase list is canonical. Full matrix lives in COPY_SYSTEM.md
   section 2. Before writing any user-facing string, check that list.
2. If a spec contradicts the banned phrase list, STOP. Do not ship the
   contradiction with a flag in the summary. Surface the conflict before
   code is written, not after.
3. No em dashes anywhere in user-facing copy.
4. No exclamation marks anywhere in user-facing copy.
5. Sentence case for all headers and CTAs. ALL CAPS only for the four
   bias severity labels (CRITICAL, HIGH, MEDIUM, LOW).
6. Periods at the end of UI strings of three or more words. No period
   on single-word labels.
7. Numbers cited in copy must be sourced. No fabricated statistics.
8. No first-name personalization. Always "you" or implicit.
9. "Heated session" not "tilt" in product UI. "Tilt" is acceptable in
   blog or SEO content only, never in app UI.
10. When in doubt, prefer restructuring the sentence over swapping the
    verb. Most banned-phrase problems are structure problems.

## Product identity

BetAutopsy is a one-shot diagnostic product, not a daily-engagement
subscription. Most users buy a single forensic report and leave. The
subscription tier serves the 10 to 15 percent of users who want ongoing
analysis. Design accordingly: the report itself is the product. The
share moment is the growth engine. Re-engagement is sports-calendar
driven, not daily-streak driven.

Path A is locked. Growth is organic only in v1. No paid acquisition
work until product is live, brand is real, and time frees up.

## Brand voice

"Sharp friend who happens to be a behavioral psychologist." Direct,
smart, never preachy. Clinical but warm. Forensic but not cold. Premium
but not expensive. Loss-prevention framing, not feature-stack framing.

The full voice principles (11 of them) and banned phrase replacement
matrix live in COPY_SYSTEM.md. The voice rules above are the working
memory. The full system is one fetch away.

## Visual identity: Luminol V2 (LOCKED May 10, 2026)

iOS uses Luminol V2. Web uses a different forensic case-file brand.
Same product, same voice, same archetypes, same engine. Visual register
only diverges. Do not import web color tokens into iOS.

### Surface tokens

- Canvas: `#14151D` (this is the lifted canvas, intentionally lighter
  than the original `#0A0B14` which read as cypherpunk. Do not lower
  again without explicit decision.)
- Card: `#1B1D27`
- Card raised: `#232636`
- Border: `#292B38` always at 0.5pt hairline. Never thicker.

### Accent tokens

- Luminol: `#6B5BFF`. Used ONLY for archetype labels, hero metric rings,
  selected states, active page indicators, value-leading CTAs, brand
  wordmark accent. Surgical use only.
- Luminol soft: `#8B7DFF`. Hover and softer archetype label states.

### Text hierarchy (4-tier)

Never use pure white `#FFFFFF` anywhere. Off-white plus tiered greys.

- Bone (primary): `#ECEDF1` — hero numbers, headlines, body, section headers
- Secondary: `#8E90A6` — italic verdict, subheadings, captions, range labels
- Tertiary: `#5F6178` — meta, timestamps, table column headers, caps labels
- Quaternary: `#3D3F50` — placeholders, disabled, watermarks

### Semantic tokens

- Blood: `#FF5454` — critical severity ONLY, losses, alert states. Never
  for chrome.
- Win: `#5BFFA8` — positive P/L only. Never for chrome.

### Archetype colors (locked, never reused for chrome)

- Heat Chaser: `#FF5454`
- Surgeon: `#6B5BFF`
- Parlay Dreamer: `#FF8FB1`
- Grinder: `#A89472`
- Gut Bettor: `#FFCB47`

PR-2 fix expanded the scoring engine to 9 canonical archetype names from
8-dimension threshold scoring. Path A roadmap targets 12 to 16 archetype
variants in v1. Add new archetype colors to `DS.Color.Archetype.*` as the
set expands. Never reuse a chrome color (luminol, blood, win, bone tiers)
for an archetype.

### Typography

- Inter Variable (body, UI, titles) — ~165KB
- Inter Display (display sizes >=24pt, applied via OpenType opsz)
- JetBrains Mono (every number that could change: scores, dollars,
  percentages, timestamps, identifiers). Tabular figures via
  `.monospacedDigit()` always. Never proportional digits on numbers.
- Georgia (system) or IBM Plex Serif Italic — analyst voice ONLY.
  Verdict paragraphs, pull-quotes, archetype descriptions.

Never mix mono and sans inside the same word. Never set bold on grey
text. Never UPPERCASE on bone-tier body text. Never use `.system` font
for the verdict (kills the analyst voice distinction).

### Type scale

HERO 96pt semibold (BetIQ score), HERO-XL 128pt (share card),
DISPLAY 56pt (archetype name on cover), TITLE 34pt (section openers),
SUBTITLE 24pt (bias names), LEAD 19pt italic regular (serif verdict),
BODY 16pt regular, BODY-S 14pt, LABEL 11pt semibold caps,
MONO-S 10.5pt regular (identifiers).

### Surface and radius

- Three tiers maximum: canvas → card → raised. Never deeper.
- Radius mix: 4pt chips, 6pt tiles, 10pt cards, 16pt sheets. All
  `.continuous`.
- No shadows in dark mode. Elevation comes from surface tier + 0.5pt
  borders.
- Dark mode default. No in-app light/dark toggle. System-driven with
  dark-default bias.

### Visual mistakes to never make

Pure `#FFFFFF` text. One grey tier. Accent on body text. Mono and sans
inside one word. Red/green for gain/loss without sign characters
(8 percent of men are red-green colorblind). Important text smaller
than 14pt. `.system` font on the verdict. Mixing tabular and
proportional digits. Bold on grey text. Uppercase on bone-tier body.

### What to absolutely avoid

Casino gold + black (BetMGM, Caesars cliche). DraftKings green-orange.
FanDuel royal-chartreuse. Confetti, slot iconography, gamified copy.
Generic AI conventions (gradient purple, system colors only). Fintech
sameness (Stripe-blurple, royal-blue trust palettes). Pure black on
pure white (OLED halation). Lime accent (Whoop pattern, dated by 2026).
Cyan (Polymarket pattern). Orange (Cash App pattern, casino-adjacent).

## Pricing (Pricing Pivot v2, RE-LOCKED May 17, 2026)

- Single Report: $19.99 consumable, one-time (matches forensic
  positioning; higher prices convert better at paywall)
- This is the only SKU in v1. The 3-Report Season Bundle, Pro Annual,
  and Pro Monthly tiers from the May 10 draft are retired. No
  subscription ships in v1. See BETAUTOPSY_PRICING_PIVOT_V2.md.

Apple Small Business Program enrolled day one. 15 percent commission.

### Paywall pattern (Grammarly-style)

Free snapshot shows real bias names, severity badges, session grade
bar, archetype name. Free snapshot blurs dollar amounts (use realistic
randomized numbers, not `$X,XXX` placeholders), recommendations,
session-level details, score breakdowns.

For paywall copy specifically, COPY_SYSTEM.md sections 3D and 8 are
the authority. The Section 8 fix for the current "Unlock" violation:

- Headline: "The autopsy is ready."
- Subhead: "Dollar costs, recommendations, and the full session timeline."
- CTA button: "Read the full report ($19.99)."
- Microcopy: "One-time charge. Yours to keep. No subscription."
- Compliance: "If gambling has stopped being fun, call 1-800-MY-RESET. We can wait."

No annual or bundle anchoring in v1 (single SKU). The price stands on
its own: "Full autopsy. $19.99. One-time."

### No trial

Trial cannibalizes single report. Grammarly paywall pattern replaces
trial value-show without giving away answers.

### Compliance copy on paywall (required for 5.3 shield)

- "Problem gambling? Call 1-800-MY-RESET" in luminol soft
- "By continuing you confirm you are 18 or older" (age gate is 18+ now,
  NOT 21+ — platform-agnostic for sportsbook + DFS + prediction markets)
- Restore Purchases button
- Privacy Policy + Terms of Service links

## Stack rules

- Swift 6 strict concurrency on
- Project ships with `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. This
  means types in ReportModels.swift have MainActor-isolated Decodable
  conformance. Use `final class` on MainActor for anything decoding
  AutopsyAnalysis. An `actor` will fail to call MainActor-isolated
  Decodable conformances from its nonisolated context.
- SwiftUI only. No UIKit unless absolutely required (CSVPickerView wraps
  UIDocumentPickerViewController via UIViewControllerRepresentable).
- `@Observable` (Swift 5.9 macro), not `ObservableObject`
- `@Environment` for service injection (auth, network, RevenueCat,
  analytics, ReportStore, UploadFlowCoordinator)
- `NavigationStack` with type-safe Route enum
- Async/await everywhere. No completion handlers.
- `@MainActor` on view models (project default makes this implicit but
  marking it is fine).

## File rules

- NEVER modify .pbxproj. If a file needs adding to Xcode, instruct
  Andrew to add it manually.
- Avoid nested Group folders in Xcode (caused major mess in v3 build).
  Files at top level of BetAutopsy group is fine. Target membership
  matters, visual hierarchy doesn't.
- Views over 100 lines must be split into sub-views.
- SwiftUI view body type-check timeout is real. Aggressive sub-view
  splitting prevents it.

## Workflow rules (PR-3 and PR-4 lessons)

- One commit per phase. Build verified between each. STOP for Andrew's
  review before next phase.
- After every commit, run `git push origin main`. PR-3 and PR-4 shipped
  to local main but were never pushed to GitHub for two days. Discovered
  May 11. New rule: push after every phase, not at the end of the PR.
- Always check `git status` before committing. If there are untracked
  files or unstaged modifications, address them in the commit or
  explicitly leave them out with an explanation in the summary. Never
  ignore them silently.
- Stale SourceKit "Cannot find DS in scope" diagnostics across multiple
  files after a token refactor are noise. xcodebuild from terminal is
  the ground truth. Ignore the in-editor diagnostics if xcodebuild
  succeeds.
- JWT in Info.plist must stay a placeholder in git. Andrew sets
  `git update-index --assume-unchanged BetAutopsy/Info.plist` locally
  after pasting the real token. Always verify with `git diff` before
  committing.
- Real device testing every commit. Simulator hides bugs.
- Check existing code before building new. Always grep the existing
  repo before scaffolding.

## Architecture rules

- iOS v1 = thin native shell over Vercel backend. The existing
  `/api/upload` and `/api/analyze` endpoints are mobile-ready (Bearer
  token + 5 min timeout). Single source of truth = both web and iOS
  use the same engine.
- All Claude API calls go through CF Worker SSE endpoint
  (`https://claude-stream.andlog0713.workers.dev`). Never call
  Anthropic directly from Vercel functions (60s SSE timeout) or from
  the iOS app.
- Analysis SSE streaming uses `URLSession.bytes(for:)` with `httpBody`
  set on the request. `URLSession.upload(for:from:)` buffers the
  response into Data and does NOT stream. (PR-4 Phase 1 verified this
  the hard way.)
- Reports are in-memory only in v1. ReportStore is `@Observable`.
  Persistence is a v1.1 polish item.

## Auth rules

- Sign in with Apple is the ONLY auth method.
- `ASAuthorizationAppleIDCredential` gives `fullName` ONCE on first
  auth. Capture from `credential.fullName.givenName` and
  `credential.fullName.familyName`, persist via
  `supabase.auth.update(user:)` IMMEDIATELY in the same Task block.
  Losing this is the #2 documented failure mode.
- Capture `TimeZone.current.identifier` at same auth moment, persist
  to `users.iana_timezone`.
- Use supabase-swift's built-in Keychain storage for sessions. Don't
  roll custom.

## IAP rules

- All purchases via RevenueCat.
- Never trust client-side `Transaction.currentEntitlements`.
- Verify entitlements via webhook into Supabase. Trust DB only.
- Apple Small Business Program enrolled. 15 percent commission rate.

## Notification rules (v1 scope only)

- v1 ships provisional only (`UNAuthorizationOptionProvisional`).
- Custom in-app primer modal AFTER first report viewed, before any
  system prompt for full permission.
- Never re-prompt. Deep-link to Settings if denied.
- All notifications scheduled in user's IANA timezone, never UTC.
- thread-id on every notification for per-thread mute support.
- interruption-level: active. Never time-sensitive in v1.
- No emoji, no exclamation, no first-name in title.
- Per-thread toggle state lives in Supabase `user_preferences`. CF
  Worker checks before sending.

v1.1 features deferred from notification scope: Weekly Autopsy push
(only relevant to subscribers, 10-15 percent of users), Heated Session
Alert (requires active monitoring infrastructure BetAutopsy doesn't
have), Live Activity (requires real-time bet data).

For notification copy patterns, see COPY_SYSTEM.md section 3F.

## Analytics rules

- TelemetryDeck for all in-app events.
- Never Firebase, never GA4 in-app.
- Core funnel events to instrument: `app.launched`, `auth.completed`,
  `onboarding.completed`, `quiz.completed`, `archetype.revealed`,
  `csv.uploaded`, `analysis.completed`, `report.viewed`,
  `paywall.shown`, `purchase.completed`, `notification.opened`,
  `notification.permission_state`.

## Library rules

Allowed in v1:
- supabase-swift
- RevenueCat SDK
- TelemetryDeck SDK
- Swift Charts (native, iOS 17 SDK, no SPM dep required)

Permanently banned:
- ConfettiSwiftUI (kitsch, conflicts with brand voice)
- shadcn references in any AI prompt (gives generic output)
- Firebase, Crashlytics (privacy manifest surface, Google data)
- Any first-name-personalization library
- Pow (archetype reveal moment now uses native SwiftUI animations;
  was specced for v1, abandoned during PR-2)
- Inferno Metal shaders (App Review red flag)

Banned in v1, may evaluate later:
- Lottie
- Rive
- Any third-party charting library (Swift Charts is sufficient)

Never suggest a new dependency without one-line justification. Never
suggest packages whose latest release predates iOS 17 SDK.

## App Store rules

- Bundle ID: `com.diagnosticsports.BetAutopsy`
- Developer team: `PAU6GLBN86`
- Age rating: 17+ with Mild/Infrequent Mature/Suggestive Themes
- Age gate inside app: 18+ (platform-agnostic across sportsbook + DFS
  + prediction markets; NOT 21+)
- Geo-restriction at App Store Connect territory level, top 25 legal
  US states. Brazil excluded (April 2025 SPA license requirement).
- Privacy manifest (PrivacyInfo.xcprivacy) declares no tracking,
  purchase history, user content, 4 required-reason APIs.
- App Review notes paragraph mirrors Pikkit precedent (id1586567110).

For App Store copy (subtitle, description, screenshot captions, App
Preview script), see COPY_SYSTEM.md section 3I.

## Task output format

When given a task, output:

1. Plan (3-5 bullets)
2. Files to touch
3. Files to create
4. Verification step
5. Copy check (any user-facing strings touched? Cross-referenced against
   COPY_SYSTEM.md? Banned phrases avoided?)

If a request conflicts with the master plan, with Notion source-of-truth
pages, with this file, or with COPY_SYSTEM.md, STOP and ask before
proceeding. Do not ship the contradiction with a flag in the summary.

After implementation: STOP after the verification step is named. Andrew
runs verification.

## Cut from v1 (do not build, even if asked)

- Streak system (irrelevant for one-shot product)
- Lock Screen widget (cut from v1 AND v1.1)
- Live Activity (requires sportsbook integration BetAutopsy doesn't have)
- Heated Session Alert push (only for active subscribers, 10-15 percent
  of users)
- Weekly Autopsy push (subscription-only relevance, defer to v1.1)
- Apple Watch app (v2 only if MAU >50K)
- iPad-optimized layout
- macOS Catalyst
- AUTOPSY50 / PRODUCTHUNT promo codes (replace with Apple native
  promotional offers post-launch)
- Floating action button (anti-pattern)
- Custom tab bar (use SwiftUI TabView)
- Hamburger drawer
- Splash screen beyond system launch
- Web view inside app
- Social feed

## Path A growth features (in v1)

- Archetype identity expansion (currently 9, target 12-16 variants)
- Share card per archetype via SwiftUI ImageRenderer (1080x1920)
- Native ShareLink everywhere relevant (archetype reveal, every report
  chapter end)
- 60/90-day re-engagement push + email tied to sports calendar
  (NFL kickoff, NFL playoffs, March Madness, NBA finals, MLB postseason)
- SEO content moat: per-archetype pages, per-sport pages,
  diagnostic-layer keywords on the marketing site

---

*Last updated: May 11, 2026. Reflects Luminol V2 LOCKED, Pricing Pivot v2,
Path A confirmed, PR-1 through PR-4 shipped and pushed, COPY_SYSTEM.md
added as canonical voice reference. Edit only when a Notion
source-of-truth page changes.*
