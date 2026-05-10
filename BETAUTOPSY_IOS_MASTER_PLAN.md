# BetAutopsy iOS rebuild — master plan v4

> **30-day TestFlight target, ~45-day App Store live target.**
> Functional v1 with Tier 1 polish baked in. Tier 2/3 in `POLISH_BACKLOG.md`.
> This file lives at the root of `betautopsy-ios`. Every Claude Code session loads it.
> v4 supersedes v3. v1, v2, v3 archived in `/docs/archive/`.

> **This is the final planning doc. No v5. After this, we build.**

---

## 0. The thesis

The Capacitor build is broken structurally. WebView around Next.js cannot deliver native feel. Native SwiftUI is now solo-buildable with Claude Code (Indragie's Context, twocentstudios's Vinylogue, Franco Torriani's Read It Now). Keep Supabase, Resend, Stripe, the Claude analysis engine, the archetype classifier. Throw away Capacitor, Tailwind, Next.js routing for the app. That's the layer that's broken.

**v1 is functional with Tier 1 polish.** Pikkit didn't launch looking like Pikkit-today. Polish followed users. v4 takes the v3 floor and adds the polish that actually drives conversion or rejection-prevention — not the polish that just looks pretty.

**Honest timeline:**
- ~30 calendar days to TestFlight Beta App Review
- ~45 calendar days to live in App Store (one rejection cycle assumed)
- Faster is possible at the pace you've demonstrated

**Learning curve disclaimer:** if this is your first Swift project, expect Week 1 to feel like going backwards. Real velocity kicks in Week 2. That's ramp, not failure.

---

## 1. Non-negotiables

These cannot be relitigated mid-build. If a Claude Code suggestion conflicts with this list, the suggestion loses.

**Stack**
- Native Swift 6 + SwiftUI on iOS 26 SDK, deployment target iOS 17
- iOS 26 features (Liquid Glass, Symbol Effects v3) gated behind `#available(iOS 26.0, *)`
- Android: defer to month 6+, evaluate Skip framework at that time
- No React Native, Expo, Capacitor, Flutter. Not in v1, not as a hedge.

**Backend**
- Supabase stays as system of record. No migration to Convex, Firebase, or custom Postgres
- Sign in with Apple is the only auth method on iOS
- RevenueCat handles all IAP. Apple Small Business Program enrolled day one
- Cloudflare Workers (Hono) handles Claude streaming. Vercel does not stream Claude
- Trigger.dev handles CSV jobs and notification crons. No long-running serverless functions
- APNs called directly from CF Worker. No OneSignal, Firebase, or Expo Push

**Design (v1: functional with targeted polish)**
- Forensic dark aesthetic at the **token level only** (colors, fonts in `Tokens.swift`)
- All other UI uses SwiftUI defaults colored with brand tokens
- Max 4px border-radius on buttons and chips, 0px on panels
- No shadows. No backdrop-blur. No gradients on surfaces. No glass effects in custom UI
- JetBrains Mono for all numbers. Inter for all body text
- Three brand colors only: midnight `#0D1117`, scalpel teal `#00C9A7`, bleed red `#E8453C`
- Plus neutral surface ramp: `#0D1117 → #161B22 → #1F2630 → #2A3340`
- Plus text grays: primary `#F0F0F0`, secondary `#A0A0A0`, tertiary `#606060`
- 1px top-edge highlights at `#FFFFFF08` for elevation, never shadows
- Reference `Tokens.swift` for every value. Never hardcode hex.
- SF Symbols only for icons. No custom illustrations in v1 (App Icon is the only custom asset).
- **Pow library is allowed for Tier 1 archetype reveal moment. Used sparingly, only at moment of reveal.**

**Brand voice**
- "Sharp friend who happens to be a behavioral psychologist"
- No em dashes in any user-facing copy. Anywhere. Ever. (Internal docs and code comments are fine.)
- "Tilt" is blog/SEO only. Product UI uses "heated session"
- No fabricated statistics. Qualitative language until real data exists
- No sportsbook-specific analysis (noise, not insight)
- Sentence case throughout, no exclamation marks in product UI

**Risk discipline**
- Never let Claude Code touch `.pbxproj` directly. Always add files manually in Xcode
- Always handle Apple's first-name-only-once rule on Sign in with Apple (snippet in section 11)
- Always validate IAP via RevenueCat webhook into Supabase, never trust the client
- Always use provisional notifications first, then ask for full permission after first valuable moment
- Always send notifications in user's local timezone via stored IANA identifier, never UTC
- **Never create nested folder Groups in Xcode unless absolutely necessary (caused a 90-minute mess in v3 build).** Files at top level of BetAutopsy group are fine. Target membership is what matters, not visual organization.

---

## 2. The complete stack

### Frontend
| Layer | Choice | Why |
|---|---|---|
| Language | Swift 6 strict concurrency | Catches actor/Sendable bugs at compile time |
| UI framework | SwiftUI | Only stack where Swift Charts, Symbol Effects are one-line |
| Architecture | `@Observable` (iOS 17+) + `@Environment` for DI | Maps to React mental model; no TCA, no Redux |
| Navigation | `NavigationStack` with type-safe `Route` enum | Native, deep-linkable, no third-party router |
| Persistence | SwiftData, read-only cache only | Cache last 50 reports. Refetch on app foreground. |
| Charts | Swift Charts (native) | Free, sufficient for v1 |
| Animation library | **Pow (EmergeTools, $99 lifetime)** | **Used only for archetype reveal moment in v1** |
| Visual identity | Single `Tokens.swift` in main app | No Swift Package overhead in v1; promote to package in v1.1 |

### Backend
| Layer | Choice | Why |
|---|---|---|
| DB / auth / storage | Supabase Pro ($25/mo) | Already shipping; supabase-swift v2 is first-party, production-ready |
| Auth method | Sign in with Apple only | Sidesteps Guideline 4.8; Supabase Auth issues JWT |
| Streaming proxy | Cloudflare Workers + Hono (free tier) | Vercel kills SSE at 60s; CF has no idle timeout |
| Background jobs | Trigger.dev (free up to ~300 users) | Durable, resumable; handles per-user timezone scheduling |
| Push | APNs JWT signed in CF Worker | No SDK weight, no privacy disclosure surface |
| IAP | RevenueCat (free until $2.5K MTR) | Industry standard; Apple Small Business 15% rate enrolled day one |
| Email | Resend ($20/mo) | Already shipping; client-agnostic |
| Marketing site | Next.js on Vercel ($20/mo) | Untouched; acquisition surface only |
| Error monitoring | TestFlight + Apple MetricKit (free) | Built-in, no SDK; upgrade to Sentry in v1.1 if needed |
| Analytics | TelemetryDeck (free up to 10K signals/day) | Privacy-first iOS-native; replaces in-app GA4/Firebase |

### AI tooling
| Tool | Role | Cost |
|---|---|---|
| Claude in Xcode 26.3 (Sonnet 4.6) | Daily SwiftUI coding | Claude Pro $20/mo |
| Claude Mac app (Opus 4.7) | Hard architecture, debugging mysteries | Same Pro plan |

### Libraries imported in v1
| Library | Use | License |
|---|---|---|
| supabase-swift | DB, auth, storage | Free |
| RevenueCat SDK | IAP | Free until $2.5K MTR |
| TelemetryDeck SDK | Analytics | Free up to 10K signals/day |
| **Pow (EmergeTools)** | **Archetype reveal animations only** | **$99 one-time lifetime** |
| Swift Charts | Native, no import needed | Free |

### Library bans

**Permanently banned:**
- ConfettiSwiftUI (kitsch, conflicts with brand voice)
- shadcn references in any AI prompt (gives generic output)
- Firebase / Crashlytics (privacy manifest disclosure surface, Google data sharing)
- Any first-name-personalization library

**Banned in v1, may evaluate later:**
- Lottie (Rive replaces it; only revisit if Rive fails for a use case)
- Any third-party charting library (Swift Charts is sufficient until proven otherwise)
- Inferno Metal shaders (flashy but App Review red flag)

---

## 3. The keep / reference / throw away matrix

### Keep verbatim — no rework
- Claude analysis engine system prompts (port to Hono Worker as-is)
- Archetype classifier waterfall: **Heat Chaser → Parlay Dreamer → Surgeon → Grinder → Gut Bettor**
  - Surgeon comes before Grinder so high-performers get positive framing
- Bias detection rules and severity thresholds
- DFS source detection (PrizePicks/Underdog parlay handling)
- Supabase schema, all 12 tables, RLS policies
- Stripe products and prices (RevenueCat will sync billing state)
- Resend email templates (7-email drip, Weekend Autopsy, Tuesday digest)
- Blog content + RSS + SEO pillar page (untouched on marketing site)
- Server-side Meta CAPI, server-side TikTok Events API
- Existing geo-gating allowlist (US states with legal online sports betting)
- Pikkit referral link: `https://links.pikkit.com/invite/surf40498`

### Reference, port to native
- Color values: `#0D1117`, `#00C9A7`, `#E8453C` → `Tokens.swift`
- Typography: JetBrains Mono (OFL) + Inter (OFL) → bundled in main app target
- Brand voice rules → `CLAUDE.md`
- Microcopy → `Strings.swift` (ported batch-by-batch as features are built)
- Onboarding email copy (lives in Resend, app triggers via Supabase)
- Paywall copy and pricing framing ("Your biases are costing you $[blurred]")
- Archetype names + descriptions
- CSV parser (existing TypeScript, move invocation context from Vercel API route to Trigger.dev task)

### Migration caveats — read these honestly
- **Stripe coupons (AUTOPSY50, PRODUCTHUNT) do NOT migrate to App Store.** RevenueCat syncs subscription state, not coupons. Recreate as App Store Connect promotional offers post-launch.
- **GA4 in-app does NOT port.** Drop Firebase/GA4 SDK. Use TelemetryDeck for in-app analytics. Server-side GA4 stays on marketing site only.
- **Cookie consent banner has no iOS equivalent.** ATT (App Tracking Transparency) is a different concept entirely. Just don't carry over.
- **CSV parser language doesn't change** — it's already TypeScript. The runtime changes (Vercel function → Trigger.dev task) and the file source changes (multipart upload → Supabase Storage signed URL).

### Throw away entirely
- Every React component
- All Tailwind classes
- Next.js routing/middleware (for the app — marketing site keeps it)
- Capacitor configuration and native shell
- Konsta UI integration plans
- Bottom tab bar implementation (SwiftUI TabView replaces)
- Grammarly-style paywall blur (rebuild simply with `.blur()` in v1, polish in v1.1)
- Living Discipline Score widget (rebuild simply with Swift Charts)
- All page layouts, scroll containers, modals (NavigationStack, .sheet, ScrollView)
- Cookie consent banner
- Client-side Meta Pixel, TikTok Pixel, in-app Firebase/GA4
- Capacitor plugins (replaced by native frameworks)

---

## 4. The plan, day-by-day

**Working assumption:** full-time, ~6 productive hours/day, Claude in Xcode as primary engineer, Claude Mac app as escalation. Total budget: ~30 calendar days to TestFlight, ~45 calendar days to live.

### Day 0: Pre-flight (do BEFORE starting the clock)

These have wait times. Do them the weekend before Day 1.

- [ ] Buy Apple Developer Program ($99/yr) — **24-48 hour activation wait**
- [ ] Enroll in Apple Small Business Program — separate enrollment, also has wait
- [ ] Sign latest Apple Developer Program License Agreement in App Store Connect
- [ ] Confirm Diagnostic Sports LLC matches App Store Connect requirements
- [ ] Verify Mac has Apple Silicon, 50GB+ free disk
- [ ] Apple ID with two-factor enabled
- [ ] Anthropic API account confirmed
- [ ] Subscribe to Claude Pro
- [ ] Confirm Supabase Pro is on
- [ ] **Buy Pow license ($99 one-time)**

**Day 1 cannot start until Apple Developer Program is active. Plan accordingly.**

---

### Week 1: Foundation + brand (Days 1–7)
**Goal:** Branded SwiftUI app authenticates with Supabase, runs on physical iPhone, has analytics + onboarding + custom App Icon.

**Day 1 — installation only**
- [ ] Install Xcode 26.3
- [ ] Sign into Claude in Xcode (Sonnet 4.6 via Agent SDK)
- [ ] Create private repo `betautopsy-ios`
- [ ] Drop master plan + CLAUDE.md + README at root
- [ ] Verify `xcodebuild -version` works
- [ ] Bookmark Apple's App Review Guidelines

**Day 2 — Apple Developer config + Cloudflare**
- [ ] New SwiftUI project, deployment target iOS 17, Swift 6 strict concurrency on
- [ ] Apple Developer portal setup (App ID + SiwA capability + Service ID + .p8 key)
- [ ] Create App Store Connect app record (do not submit), reserve bundle ID
- [ ] `wrangler` CLI setup, deploy hello-world Hono Worker

**Day 3 — Supabase SiwA wiring + Tokens**
- [ ] Configure Sign in with Apple in Supabase dashboard
- [ ] `Tokens.swift` with colors, fonts, spacing
- [ ] Bundle JetBrains Mono + Inter (both OFL)
- [ ] Color/font test view in Preview, verify dark mode
- [ ] BACard, BAButton, BAChromeLabel components

**Days 4–5 — Auth flow + Supabase + onboarding**
- [ ] Add `supabase-swift` via SPM
- [ ] Implement Sign in with Apple → Supabase Auth flow (snippet in section 11)
- [ ] **Critical:** capture name + IANA timezone on first auth, persist immediately
- [ ] Use supabase-swift's built-in Keychain storage
- [ ] **NEW: Native paged onboarding sequence (Tier 1 #2)**
  - 3-card swipeable TabView with `.page` style
  - Card 1: "Find your blind spots"
  - Card 2: "Track behavioral patterns over time"
  - Card 3: "Get your archetype"
  - Final state: Sign in with Apple button
  - Page indicator at bottom
  - First-launch only; persisted via UserDefaults
- [ ] Test cold launch with expired token: silent refresh

**Day 6 — Analytics + streaming proxy**
- [ ] Integrate TelemetryDeck SDK (now, instrument as you build)
- [ ] Wire core events: `app.launched`, `auth.completed`, `auth.failed`, `onboarding.completed`
- [ ] CF Worker `claude-stream` endpoint proxies one streaming Claude call
- [ ] Confirm streaming works on physical device

**Day 7 — App Icon + gate**
- [ ] **NEW: Design + ship App Icon (Tier 1 #6)**
  - 1024x1024 PNG, monogram on midnight surface, scalpel teal accent
  - Forensic motif (magnifying glass, fingerprint, evidence stamp, etc.)
  - DIY in Figma if confident, or $100-300 outsource on Fiverr/99designs
  - Drop into Assets.xcassets, Xcode auto-generates required sizes
- [ ] Gate verification:
  - App opens on physical iPhone
  - SiwA completes, name + timezone persists
  - Onboarding flow on first launch only
  - Real App Icon visible on home screen
  - TelemetryDeck dashboard shows real events
  - Buffer day for inevitable SiwA weirdness

**If Day 7 gate slips:** push everything by 2 days. Foundation is foundation.

---

### Week 2: Core flow + reveal moment (Days 8–14)
**Goal:** End-to-end CSV upload → analysis → native report. Plus the archetype reveal moment that makes the app shareable.

**Days 8–12: Upload + analysis pipeline**
- [ ] Trigger.dev project set up
- [ ] Move CSV parser invocation from Vercel API route to Trigger.dev task
- [ ] Port archetype classifier waterfall
- [ ] Port bias detection rules
- [ ] Trigger.dev `analyze-csv` task: parse → classify → generate Claude analysis → write to Supabase `reports` table
- [ ] iOS: `UIDocumentPickerViewController` integrated via `UIViewControllerRepresentable`
- [ ] Upload file to Supabase Storage with signed URL
- [ ] Pikkit referral path on upload screen (link: `https://links.pikkit.com/invite/surf40498`)
- [ ] Sportsbook export instructions linked
- [ ] **NEW: Custom loading state (Tier 1 #4)**
  - Timer-based text rotation during analysis
  - Sample copy: "EXAMINING BET 47 OF 132" → "DETECTING BIAS PATTERNS" → "GENERATING CASE FILE"
  - JetBrains Mono, subtle pulse animation
  - Polling Supabase reports table every 3 seconds, max 60 seconds
  - Realtime subscription deferred to v1.1
- [ ] TelemetryDeck events: `csv.uploaded`, `analysis.completed`, `analysis.failed`

**Days 13–14: Report screen + archetype reveal**
- [ ] Native report view with NavigationStack
- [ ] Hero number: dollar impact ("$1,847 lost to heated sessions") in JetBrains Mono Bold
- [ ] Three semantic descriptors below: archetype name, heated session count, time period
- [ ] Native Swift Charts bar chart for bias breakdown (4.2 keystone)
- [ ] **NEW: Pow archetype reveal moment (Tier 1 #1)**
  - Add Pow library via SPM
  - On first time viewing report (or "Show My Archetype" tap):
    - Full-screen reveal sheet
    - Archetype name reveals with `.movingParts.glow` + `.scale` + `.boing`
    - Subtitle text fades in below
    - "Continue" button appears after 1.5s
  - 5 archetype variants (Heat Chaser, Parlay Dreamer, Surgeon, Grinder, Gut Bettor)
  - First-time only; subsequent views go straight to report
- [ ] Past reports list with NavigationStack push
- [ ] **NEW: Empty states with personality (Tier 1 #5)**
  - No reports: "No case files yet. Upload a CSV to begin investigation."
  - No bets in CSV: "Empty case file. CSV contained no bets to analyze."
  - Network error: "Connection lost. Pull to retry."
  - All using SF Symbols at large size + chrome label + body copy
- [ ] Error states: short copy in sharp-friend voice
- [ ] TelemetryDeck event: `report.viewed`, `archetype.revealed`

**Day 14 — gate:**
- [ ] User uploads test CSV → sees real autopsy report
- [ ] Hero number renders correctly
- [ ] Archetype reveal moment fires on first view
- [ ] Past reports list works
- [ ] Native chart renders
- [ ] Empty states render correctly when triggered

---

### Week 3: Monetization + notifications + Share Extension (Days 15–21)

**Days 15–17: RevenueCat**
- [ ] RevenueCat SDK integrated
- [ ] Three products configured in App Store Connect:
  - Single report consumable: $9.99
  - Pro monthly: $39.99/mo with 7-day free trial
  - Pro annual: $299.99/yr (no trial)
- [ ] All three in same subscription group
- [ ] Webhook from RevenueCat → Supabase `subscriptions` table
- [ ] Paywall view: monthly with trial as default, annual as "save 4.5 months" upgrade
- [ ] Restore Purchases button mandatory
- [ ] T&Cs and Privacy Policy links mandatory
- [ ] Verify entitlements via webhook, never trust client
- [ ] TelemetryDeck events: `paywall.shown`, `purchase.attempted`, `purchase.completed`, `purchase.failed`

**Days 18–19: APNs + Share Extension**
- [ ] APNs auth key (.p8) from Apple Developer
- [ ] CF Worker `apns-push` endpoint signs JWT, caches 50 min
- [ ] Device token registration on app launch → Supabase `devices` table
- [ ] On `410 BadDeviceToken` from APNs, delete token from DB immediately
- [ ] Provisional notification permission requested at first launch
- [ ] **NEW: Share Extension target (Tier 1 #3)**
  - New Xcode target: Share Extension
  - Activation rule: only `.csv` files (and .xls, .xlsx)
  - Reads CSV from share intent, validates basic format
  - Uploads to Supabase Storage with user's session token
  - Hands off to main app via custom URL scheme deep link
  - Falls back to native picker if user not authenticated
  - Required: Apple's app-extension-safe APIs only (no UIKit-restricted)

**Days 20–21: Two notification types + TestFlight test mode**
- [ ] **Weekly Autopsy notification** — Trigger.dev cron, per-user IANA timezone
  - Fires Monday 9am LOCAL user time
  - Requires ≥7 days of bet data
  - Title: dollar number first ("$387 in heated sessions")
  - Body: ≤110 chars, no emoji
  - `interruption-level: active`, `thread-id: weekly-autopsy`
- [ ] **Heated Session Alert** — post-hoc within 6 hours
  - Never 22:00–08:00 local
  - Never within 4 hours of NFL kickoff Sundays
  - Hard cap: 1 per 7-day rolling window
  - `thread-id: heated-session`
- [ ] **TestFlight debug toggle in Settings** (CRITICAL — remove before submit)
- [ ] Per-thread Settings toggles persist to Supabase `user_preferences`
- [ ] After first report viewed: prompt for full notification permission
- [ ] TelemetryDeck events: `notification.permission_requested`, `notification.permission_granted`, `notification.opened`

---

### Week 4: Compliance + TestFlight prep (Days 22–28)

**Days 22–23: Settings + compliance + outreach prep**
- [ ] Settings screen with:
  - Notification per-thread toggles
  - "Show units instead of dollars" toggle (default off)
  - Account deletion (mandatory)
  - Privacy Policy + T&Cs links
  - 1-800-GAMBLER link
  - Restore Purchases button
  - Debug-only: test notification triggers (hidden in production)
- [ ] Age gate on first launch (17+ check)
- [ ] Geo-restriction check (server-side)
- [ ] **TestFlight outreach prep** (send Day 27):
  - TestFlight invite email for waitlist
  - r/sportsbetting post draft (mod approval if needed)
  - Aim for 20–50 testers

**Day 24 — App Store metadata writing**
- [ ] App Store name: "BetAutopsy" (max 30 chars)
- [ ] Subtitle (max 30 chars): "Behavioral Bet Analysis"
- [ ] Promotional text (max 170 chars): updateable post-launch
- [ ] Description (max 4000 chars): forensic-tone, allowed keywords only, includes Apple non-affiliation disclaimer + 1-800-GAMBLER mention
- [ ] Keywords field: behavioral analysis, self-awareness, cognitive bias, post-mortem, betting journal, betting psychology, habit insights
- [ ] **Banned keywords:** picks, +EV, edge, win more, beat the books, sharp action, line shopping, arbitrage
- [ ] Category: Lifestyle primary, Health & Fitness secondary
- [ ] 17+ rating with Frequent/Intense Simulated Gambling content descriptor
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) — be exhaustive about TelemetryDeck and any other SDK
- [ ] Privacy nutrition labels in App Store Connect — match privacy manifest exactly
- [ ] **NEW: Detailed App Review notes** (rejection prevention #D)
  - Test account credentials (create one specifically for review)
  - Test CSV file (link to a sample)
  - Note: "BetAutopsy is a behavioral analysis tool, not a gambling app. We do not take wagers, show odds, or recommend bets. This positions us closer to Pikkit (id1586567110) which Apple has approved."

**Days 25–26: Screenshots + App Preview video**
- [ ] **NEW: Strategic 5-7 screenshot story (Tier 1 polish A)**
  Take from real iPhone 15 Pro / 6.7":
  1. Hero: report screen with dollar impact + archetype + chart
  2. CSV upload moment with native picker visible
  3. Bias breakdown chart
  4. **Archetype reveal mid-animation** (this is the viral screenshot)
  5. Past reports list (proves repeat-use)
  6. Settings showing 1-800-GAMBLER (reviewers screenshot this themselves)
  7. Paywall (proves IAP)
- [ ] Annotate each with one-line caption overlay in JetBrains Mono (use Screenshot Studio or Picsew on Mac)
- [ ] **App Preview video — DO IT (Tier 1 polish B)**
  - 15-second loop: open app → tap upload → loading state → archetype reveal → see report
  - Record on real iPhone via QuickTime over USB
  - Apple data: increases conversion ~35%

**Day 27: Beta App Review submission + outreach**
- [ ] Submit binary for TestFlight Beta App Review (24–48 hour review)
- [ ] Send waitlist invite email
- [ ] Post in r/sportsbetting (or hold until Beta App Review approves)

**Day 28: External TestFlight goes live**
- [ ] Beta App Review approves (assume Day 28; if rejected, fix and resubmit, +1-2 days)
- [ ] Push to 20–50 external testers
- [ ] Use TestFlight debug toggle to validate notification system
- [ ] Monitor TestFlight crash reports + TelemetryDeck dashboard

---

### Week 5: TestFlight feedback + App Store submit (Days 29–37)

**Days 29–34: Iterate on TestFlight feedback**
- [ ] Need a weekend in this window so users experience Monday Weekly Autopsy
- [ ] Watch for: CSV import failures, auth edge cases, paywall friction, notification permission drop-off, archetype reveal animation issues
- [ ] Critical bug fixes only — resist scope creep
- [ ] Minimum bar before App Store submit:
  - Zero crashes during test sessions
  - At least one tester completed: upload → report → $9.99 purchase
  - At least one tester received Weekly Autopsy notification
  - At least one tester saw archetype reveal moment

**Day 35: Pre-submit cleanup**
- [ ] Remove TestFlight debug toggle from production build
- [ ] Final keyword review
- [ ] Final privacy nutrition label check
- [ ] Submit IAP products in App Store Connect (separate 24–72 hour review track)

**Days 36–37: Submit**
- [ ] Submit binary Tuesday or Wednesday morning Pacific time
- [ ] Avoid WWDC week and iPhone-launch week
- [ ] Update marketing site (betautopsy.com) with App Store badge prepared (don't activate until live)

**Days 38–45: Review + revision**
- [ ] First review: 24-72 hours typical
- [ ] **Rejection on first submission is the median outcome.** Plan for one revision cycle.
- [ ] Common rejection causes:
  - 4.2 (more native features) — Share Extension already in v1, that's the strongest counter. If still hit: explain in resubmission notes.
  - 5.3 (gambling framing) — sharpen behavioral-only positioning
  - 4.8 (auth method) — confirm SiwA is the only option
  - 3.1.1 (IAP not used) — confirm products tied to entitlements
- [ ] Approval expected ~Day 42-45
- [ ] Activate App Store badge on marketing site

---

## 5. Architecture

### Frontend file structure

```
betautopsy-ios/
├── BETAUTOPSY_IOS_MASTER_PLAN.md     # This file. Source of truth.
├── POLISH_BACKLOG.md                  # All Tier 1/2/3 polish + rationale
├── CLAUDE.md                          # Rules every Claude session loads
├── BetAutopsy.xcodeproj/
├── BetAutopsy/                        # Main app target
│   ├── BetAutopsyApp.swift
│   ├── ContentView.swift
│   ├── AppRouter.swift                # NavigationStack Route enum
│   ├── Tokens.swift                   # Colors, fonts, spacing
│   ├── Components.swift               # BACard, BAButton, BAChromeLabel
│   ├── Strings.swift                  # All user-facing copy
│   ├── Onboarding/                    # Paged welcome flow
│   ├── Auth/                          # Sign in with Apple
│   ├── Upload/                        # Document picker + Pikkit referral
│   ├── Reports/                       # Past reports list + detail
│   ├── ArchetypeReveal/               # Pow-driven reveal moment
│   ├── Paywall/                       # RevenueCat-backed
│   ├── Notifications/                 # Permission flow + Settings
│   ├── Settings/                      # Includes 1-800-GAMBLER + debug toggle
│   ├── Networking/                    # CFWorkerClient, SupabaseClient wrapper
│   ├── IAP/                           # RevenueCat wrapper
│   ├── Analytics/                     # TelemetryDeck wrapper
│   ├── Persistence/                   # SwiftData read-only cache
│   ├── Fonts/                         # JetBrains Mono, Inter (7 .ttf files)
│   └── Assets.xcassets                # App Icon goes here
├── ShareExtension/                    # CSV import from Mail/Files/Safari
└── docs/
    ├── archive/
    │   ├── MASTER_PLAN_V1.md
    │   ├── MASTER_PLAN_V2.md
    │   └── MASTER_PLAN_V3.md
    ├── prompts/                       # Ported Claude analysis prompts
    └── reference-screenshots/         # Whoop, Robinhood, Linear (for v1.1+)
```

**Note on file organization:** Avoid nested Group folders inside Xcode unless absolutely necessary. The folder structure above is logical organization — in Xcode, all files at the top of the BetAutopsy group is fine. **Target membership matters, visual hierarchy doesn't.**

### Persistence detail

SwiftData stores last 50 reports as a read-only cache. Refetch strategy:
- On app foreground, refetch full list from Supabase `reports` table
- Compare local count + max(updated_at) to server response
- Polling for new reports during analysis (not Realtime) — see Days 8-12
- Realtime subscription deferred to v1.1

### Backend services
| Service | Endpoint | Purpose |
|---|---|---|
| Supabase | `*.supabase.co` | DB, auth, storage |
| CF Worker `claude-stream` | `*.workers.dev/stream` | SSE proxy to Anthropic |
| CF Worker `apns-push` | `*.workers.dev/push` | APNs JWT signer |
| Trigger.dev | `trigger.dev` | `analyze-csv`, `weekly-autopsy-cron`, `heated-session-detector` |
| RevenueCat → Supabase webhook | RC managed | Subscription state sync |
| Resend | `resend.com` | Email sender |
| Anthropic | `api.anthropic.com` | Claude API |
| TelemetryDeck | `nom.telemetrydeck.com` | iOS-native analytics |
| Marketing site | `betautopsy.com` | Acquisition only |

---

## 6. Notification strategy (the v1 retention loop)

### v1: Two notification types only

**Weekly Autopsy** — Monday 9am local user timezone
- Trigger.dev `schedules.create()` with `timezone: user.iana_timezone` and `deduplicationKey: ${userId}-weekly`
- Requires ≥7 days of bet data; silently suppress otherwise
- Title leads with a number, ≤40 chars, no emoji
- Body ≤110 chars, observational tone, no imperatives
- `thread-id: weekly-autopsy`
- `interruption-level: active`

**Heated Session Alert** — post-hoc within 6 hours of upload
- Never 22:00–08:00 local
- Never within 4 hours of NFL kickoff Sundays
- Hard cap: 1 per 7-day rolling window
- `thread-id: heated-session`

### Copy templates

| Trigger | Title (≤40ch) | Body (≤110ch) |
|---|---|---|
| Weekly Autopsy (loss frame) | `$387 in heated sessions` | `6 sessions last week, average stake 2.3× your baseline. Tap to review.` |
| Weekly Autopsy (low-leak week) | `28 days of disciplined sizing` | `No heated sessions detected since Apr 11. Stake variance down 41%.` |
| Heated Session Alert | `Sunday session flagged` | `8 bets between 11pm and 1am. 2.4× your normal sizing.` |
| First report ready (one-shot) | `Your first case file is ready` | `132 bets analyzed. We found 2 recurring patterns.` |
| Trial closing | `Your trial closes in 2 days` | `Three weekly reports remaining. Continue Pro to keep your case files.` |

**Banned patterns:** first-name in title, exclamation marks, emoji, imperative voice, moral language, urgency cues.

### Permission flow
1. **First launch:** silent provisional with `[.alert, .sound, .badge, .provisional]`
2. **First report viewed:** custom in-app primer modal: "Recaps land Monday morning. No noise otherwise." → system prompt
3. **Denial:** passive in-app banner with "Enable in Settings" deep link

### Per-thread toggle enforcement
- Toggle state writes to Supabase `user_preferences.notification_threads` (jsonb)
- CF Worker checks prefs before sending push (server-side enforcement)
- Default: both threads ON for users who upgrade to full permission

### Anti-patterns to never ship
- Daily push
- Time-sensitive interruption level
- Critical Alerts entitlement
- Emoji in title or body
- Notifications during NFL Sunday afternoons
- First-name personalization

---

## 7. App Store strategy

### Guideline 4.2 — Minimum functionality
v4 minimum viable approval set is now stronger than v3:
- Native CSV import via `UIDocumentPickerViewController` ✓
- **Native paged onboarding flow** ✓ (Tier 1 addition)
- **Share Extension target** ✓ (Tier 1 addition — major 4.2 strength signal)
- At least one native chart (Swift Charts) on report screen ✓
- Sign in with Apple ✓
- Push notifications with content (not silent) ✓
- **Custom App Icon** ✓ (Tier 1 addition)

If first review still rejects on 4.2 (rare with this baseline), add Face ID gate from Tier 2 backlog.

### Guideline 5.3 — Gambling
**Does not directly apply.** BetAutopsy doesn't take wagers, show odds, or recommend picks. Pikkit (id1586567110) is the cleanest precedent.

**Your shield (all in v1):**
- Allowed metadata only
- 17+ rating with gambling content descriptor
- Age gate first launch
- 1-800-GAMBLER link in Settings AND paywall
- Apple non-affiliation disclaimer in description
- Geo-restrict to legal-state jurisdictions
- Diagnostic Sports LLC on developer account
- **Detailed App Review notes citing Pikkit precedent** (Tier 1 polish #D)

### Guideline 3.1.1 — IAP
- Single report: consumable, $9.99
- Pro monthly: auto-renewable, $39.99/mo, 7-day trial
- Pro annual: auto-renewable, $299.99/yr, no trial
- All in same subscription group
- Apple Small Business Program: 15% commission

### Apple Search Ads will not accept you
Apple Ads Policy 4.4.1. Cross ASA off acquisition list.

**Acquisition stays:** Meta server-side CAPI, organic TikTok, SEO, content/blog, ASO, App Store editorial featuring (forensic aesthetic + custom App Icon + archetype reveal moment make this genuinely featurable).

---

## 8. Cost — v1 reality

### Required, day one through launch
| Item | Cost | Status |
|---|---|---|
| Apple Developer Program | $99/yr | Buy Day 0 |
| Claude Pro | $240/yr | Already paying or buy Day 0 |
| Supabase Pro | $300/yr | Flip on Day 0 |
| Resend | $240/yr | Already paying |
| Vercel (marketing only) | $240/yr | Already paying |
| **Pow library** | **$99 one-time** | **Buy Day 0 (Tier 1 addition)** |
| **App Icon design (if outsourced)** | **$100-300 one-time** | **Day 7** |
| **Subtotal v1 required** | **~$1,320-1,520 year 1** | |

### Skip in v1, add when needed
| Item | Cost | Trigger |
|---|---|---|
| Cursor Pro | $240/yr | Skip; Claude in Xcode works |
| Custom display face | $400-800 once | Month 6 post-launch |
| Figma Pro | $180/yr | Month 3 if AI output drifts |
| Rive Pro | $144/yr | September 2026 (Season Wrapped) |
| Trigger.dev paid | $240/yr | After ~300 users |
| TelemetryDeck paid | ~$180/yr | After ~10K signals/day |
| Sentry team plan | $312/yr | Only if MetricKit insufficient |

### Variable
- Claude API: ~$0.50-2 per autopsy with prompt caching
- APNs: free
- CF Workers: free at v1 scale
- RevenueCat: free until $2.5K MTR

**Day-zero minimum to start:** $99 (Apple) + $20 (first month Claude Pro) + $99 (Pow) = **$218**.

---

## 9. CLAUDE.md (every session loads this)

> **Note:** Rules in CLAUDE.md must stay in sync with section 1 of this master plan. If they conflict, the master plan wins.

```markdown
# BetAutopsy iOS — Claude rules

You are an iOS engineer building BetAutopsy, a behavioral betting analysis
app. Read this file in full before any change.

## Reading order on every session
1. This file
2. BETAUTOPSY_IOS_MASTER_PLAN.md sections 1, 3, and the relevant week
3. POLISH_BACKLOG.md if relevant to the task
4. Any /Features/X folder relevant to the current task

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
- @Environment for service injection
- NavigationStack with type-safe Route enum
- Async/await everywhere
- @MainActor on view models

## Design rules
- Max 4px border-radius on buttons/chips, 0px on panels
- No .shadow(), no .background(.ultraThinMaterial), no gradients on surfaces
- iOS 26 Liquid Glass: never .glassEffect() in custom UI
- All numbers use JetBrains Mono with .monospacedDigit()
- All body text uses Inter
- Three brand colors only: midnight, scalpel teal, bleed red
- Plus 4-tier surface ramp + 3-tier text grays from Tokens.swift
- Reference Tokens.swift for every value. Never hardcode hex.
- SF Symbols only for icons. No custom illustrations in v1.
- Pow library only at archetype reveal moment, nowhere else.

## File rules
- NEVER modify .pbxproj
- AVOID nested Group folders in Xcode (caused major mess in v3 build)
- Files at top level of BetAutopsy group is fine
- Target membership matters, visual hierarchy doesn't
- Views over 100 lines must be split into sub-views

## Library rules
- Allowed in v1: supabase-swift, RevenueCat, TelemetryDeck, Pow, Swift Charts
- Permanently banned: ConfettiSwiftUI, Firebase, Crashlytics, shadcn references, Inferno
- Banned in v1: Lottie, third-party charts
- Pow used ONLY at archetype reveal moment
- Never suggest a new dependency without one-line justification
- Don't suggest packages whose latest version was released before iOS 17 SDK

## Auth rules
- Sign in with Apple is the ONLY auth method
- ASAuthorizationAppleIDCredential gives name ONCE on first auth
- Capture name + TimeZone.current.identifier, persist via supabase.auth.update(user:) IMMEDIATELY
- Use supabase-swift's built-in Keychain storage

## IAP rules
- All purchases via RevenueCat
- Never trust client-side Transaction.currentEntitlements
- Verify entitlements via webhook into Supabase, trust DB only

## Notification rules
- Use .provisional first, ask for full permission only after first report viewed
- Never re-prompt; deep-link to Settings if denied
- All notifications scheduled in user's IANA timezone, never UTC
- thread-id on every notification
- interruption-level: active (never time-sensitive)
- No emoji, no exclamation, no first-name in title
- Per-thread toggle state in Supabase user_preferences

## Streaming rules
- All Claude calls go through CF Worker SSE endpoint
- Never call Anthropic from Vercel functions

## Analytics rules
- TelemetryDeck for all in-app events
- Never Firebase, never GA4 in-app
- Fire events for: app.launched, auth.completed, onboarding.completed, csv.uploaded, analysis.completed, archetype.revealed, report.viewed, paywall.shown, purchase.completed, notification.opened, notification.permission_state

## Tasks
When given a task, output:
1. Plan (3-5 bullets)
2. Files to touch
3. Files to create
4. Verification step

If a request conflicts with the master plan, stop and ask.

Then implement. Stop after verification step is named — I'll run it.
```

---

## 10. Failure modes (in order of frequency)

1. **`.pbxproj` corruption** — Mitigation: instruct Claude never to touch it; add files manually
2. **Apple's name-only-once rule** — Mitigation: capture and persist in same Task block
3. **Swift 6 concurrency confusion** — Mitigation: strict concurrency catches at compile time
4. **Client-side IAP entitlement check** — Mitigation: RevenueCat webhook → Supabase, trust DB only
5. **Push permission one-shot** — Mitigation: provisional first, full prompt at first valuable moment
6. **SSE through Vercel** — Mitigation: CF Workers, period
7. **SwiftUI view body type-check timeout** — Mitigation: split views aggressively at 100 lines
8. **Tabs reset on view rebuild** — Mitigation: hoist state to parent
9. **Memory leak from closures in @Observable** — Mitigation: `[weak self]` in Task closures
10. **Image assets in Swift Packages don't render in Previews** — Mitigation: keep Tokens in main app
11. **APNs `410 BadDeviceToken` inflates "delivered" rate** — Mitigation: delete token from DB on 410
12. **Trigger.dev cron timezone confusion** — Mitigation: per-user IANA via `schedules.create()`
13. **IAP review separate track** — Mitigation: submit IAP first
14. **Prompt caching billing surprise** — Mitigation: lock prompt verbatim
15. **AI generates generic shadcn-style UI** — Mitigation: ban shadcn references in CLAUDE.md
16. **TestFlight notification testing impossible** — Mitigation: ship debug "trigger now" buttons
17. **Apple Developer Program activation wait** — Mitigation: do bureaucracy in Day 0
18. **CSV upload tested without analysis pipeline** — Mitigation: Days 8-12 as one sub-project
19. **Nested Group folders in Xcode break the project structure** — Mitigation: keep files at top level of BetAutopsy group; never create deep group hierarchies
20. **Pow animation too aggressive on archetype reveal** — Mitigation: dial back if testers report it (specifically the `.boing` may be too much). Keep `.scale` + `.glow` minimum.

---

## 11. Critical code snippets

### Sign in with Apple — capturing the name + timezone

```swift
func authorizationController(
    controller: ASAuthorizationController,
    didCompleteWithAuthorization authorization: ASAuthorization
) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
        return
    }

    Task {
        do {
            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                return
            }

            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: identityToken)
            )

            var attributes: [String: AnyJSON] = [
                "iana_timezone": .string(TimeZone.current.identifier)
            ]

            if let givenName = credential.fullName?.givenName,
               let familyName = credential.fullName?.familyName {
                attributes["full_name"] = .string("\(givenName) \(familyName)")
            }

            try await supabase.auth.update(
                user: UserAttributes(data: attributes)
            )
        } catch {
            print("Sign in error: \(error)")
        }
    }
}
```

### APNs JWT signing in CF Worker

```typescript
import { SignJWT, importPKCS8 } from "jose";

let cachedToken: { jwt: string; expiry: number } | null = null;

async function getApnsJwt(env: Env): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiry > now + 60) {
    return cachedToken.jwt;
  }

  const key = await importPKCS8(env.APNS_PRIVATE_KEY, "ES256");
  const jwt = await new SignJWT({ iss: env.APNS_TEAM_ID, iat: now })
    .setProtectedHeader({ alg: "ES256", kid: env.APNS_KEY_ID })
    .sign(key);

  cachedToken = { jwt, expiry: now + 50 * 60 };
  return jwt;
}

async function sendPush(deviceToken: string, payload: object, env: Env) {
  const jwt = await getApnsJwt(env);
  const response = await fetch(
    `https://api.push.apple.com/3/device/${deviceToken}`,
    {
      method: "POST",
      headers: {
        "authorization": `bearer ${jwt}`,
        "apns-topic": env.BUNDLE_ID,
        "apns-push-type": "alert",
        "apns-priority": "5",
      },
      body: JSON.stringify(payload),
    }
  );

  if (response.status === 410) {
    await env.DB.exec("DELETE FROM devices WHERE token = ?", deviceToken);
  }
  return response;
}
```

### Trigger.dev per-user timezone scheduling

```typescript
import { schedules, schedule } from "@trigger.dev/sdk/v3";

export const weeklyAutopsyTask = schedules.task({
  id: "weekly-autopsy",
  run: async (payload, { ctx }) => {
    const userId = payload.externalId;
    const user = await getUserFromSupabase(userId);

    if (!hasSevenDaysOfData(user)) return;
    if (!user.notification_threads?.weekly_autopsy) return;
    if (!user.notification_permission_full) return;

    const summary = await generateWeeklySummary(user);

    await sendPushNotification({
      userId,
      title: summary.title,
      body: summary.body,
      threadId: "weekly-autopsy",
      interruptionLevel: "active",
    });
  },
});

export async function registerUserSchedule(userId: string, ianaTimezone: string) {
  await schedules.create({
    task: "weekly-autopsy",
    cron: "0 9 * * 1",
    timezone: ianaTimezone,
    externalId: userId,
    deduplicationKey: `${userId}-weekly`,
  });
}
```

### Pow archetype reveal moment

```swift
import SwiftUI
import Pow

struct ArchetypeRevealView: View {
    let archetype: Archetype
    @State private var phase: RevealPhase = .pre
    let onContinue: () -> Void

    enum RevealPhase {
        case pre, revealing, complete
    }

    var body: some View {
        ZStack {
            BAColor.surface0.ignoresSafeArea()

            VStack(spacing: BASpacing.l) {
                Spacer()

                BAChromeLabel("YOUR ARCHETYPE")
                    .opacity(phase == .pre ? 0 : 1)
                    .animation(.easeIn(duration: 0.4), value: phase)

                Text(archetype.name)
                    .font(BAFont.body(48, weight: .bold))
                    .foregroundStyle(BAColor.scalpelTeal)
                    .changeEffect(
                        .glow(color: BAColor.scalpelTeal),
                        value: phase
                    )
                    .scaleEffect(phase == .pre ? 0.5 : 1.0)
                    .opacity(phase == .pre ? 0 : 1)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: phase)

                Text(archetype.description)
                    .font(BAFont.bodyDefault)
                    .foregroundStyle(BAColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BASpacing.l)
                    .opacity(phase == .complete ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(0.3), value: phase)

                Spacer()

                if phase == .complete {
                    BAButton("Continue", style: .primary, action: onContinue)
                        .padding(.horizontal, BASpacing.m)
                        .padding(.bottom, BASpacing.xxl)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .onAppear {
            // Pre → revealing after 0.3s, revealing → complete after 1.5s total
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                phase = .revealing
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                phase = .complete
            }
        }
    }
}
```

---

## 12. Day 0 / pre-flight checklist

- [ ] Buy Apple Developer Program ($99/yr) — **24-48 hour activation wait**
- [ ] Enroll in Apple Small Business Program
- [ ] Sign latest Apple Developer Program License Agreement
- [ ] Confirm Diagnostic Sports LLC matches App Store Connect requirements
- [ ] Verify Mac has Apple Silicon, 50GB+ free disk
- [ ] Apple ID with two-factor enabled
- [ ] Anthropic API account confirmed
- [ ] Subscribe to Claude Pro
- [ ] Confirm Supabase Pro is on
- [ ] **Buy Pow license ($99 one-time)**
- [ ] Bookmark Apple's App Review Guidelines
- [ ] Bookmark this file

---

## 13. Elevator version

> BetAutopsy iOS rebuild. Native SwiftUI on iOS 26 SDK, deployment target iOS 17. Supabase + Sign in with Apple + RevenueCat + Cloudflare Workers (Hono) for Claude streaming + Trigger.dev for CSV jobs and notification crons. Two notification types: Monday 9am-local Weekly Autopsy + capped post-hoc Heated Session Alert. Forensic dark aesthetic at token level. Native onboarding sequence, custom App Icon, Pow-driven archetype reveal moment, Share Extension for CSV import, custom loading state with rotating analysis copy, branded empty states. Built solo with Claude in Xcode (Sonnet 4.6) + Claude Mac app (Opus 4.7) over ~30 days to TestFlight, ~45 days to live App Store. Apple Small Business Program for 15% IAP commission. Lifestyle primary category. 17+ rating. Diagnostic Sports LLC on the developer account. v1 functional with Tier 1 polish, Tier 2/3 in v1.1+.

---

## 14. Explicitly NOT in v1

- Onboarding behavioral quiz (cut entirely)
- Custom Inferno Metal shader
- Custom haptic vocabulary (Tier 2 has light haptic feedback only)
- Sound design
- Custom illustrations / archetype sigils (use SF Symbols, Pow handles reveal motion)
- Hero dashboard with animated digit roll
- Card flip transitions
- App open animation
- Symbol Effects pass on every screen (Tier 2 has selective Symbol Effects)
- Notification Service Extension (rich push)
- Face ID gate (Tier 2 backlog)
- BAForensicsKit Swift Package
- L-bracket evidence-tag corner card style
- Realtime subscription for report-ready (use polling)
- Android port (Skip framework eval month 6+)
- Apple Watch companion
- iPad-optimized layouts
- visionOS port
- Multi-language localization
- Live Activities
- Custom display face
- Pre-bet tilt check-in
- Discipline Leagues
- CLV tracking
- Season Wrapped (September 2026)
- macOS Catalyst port
- Referral program

If I don't ship v1, none of these matter. If I do, they all become tractable.

---

## 15. v1.1+ roadmap (rough sketch)

Once v1 is live, polish gets data-informed.

**v1.1 (~weeks 4-6 post-launch)**
- Tier 2 polish backlog items (see POLISH_BACKLOG.md)
- Custom empty/loading/error state polish
- Notification Service Extension for rich Weekend Autopsy push
- Face ID gate
- Monthly case-file recap notification
- Realtime subscription replacing polling

**v1.2 (~weeks 8-12)**
- Spotlight indexing of past reports
- App Intents for Siri
- Home Screen widget showing dollar impact
- Streak protection notifications
- Lapsed-user re-engagement at D7/D14/D30
- Notification A/B copy harness

**v1.3+ (months 4-6)**
- Onboarding behavioral quiz (only if data shows opt-in interest)
- BAForensicsKit promoted to Swift Package
- Custom illustrations for archetype sigils
- Daily intentional pulse notification
- Sport-specific notification timing variants

**Future (months 6+)**
- Custom display face for wordmark
- Sound design pass
- Season Wrapped (September 2026)
- Skip framework evaluation for Android
- Apple Watch companion

---

## 16. Stop editing this document. Start building.

This is v4. There is no v5. Every iteration past this point is procrastination dressed as planning.

Edit this file only when you ship a non-negotiable change (e.g. iOS 17 deployment target → 18, RevenueCat replaced with custom, Pow replaced). Do not edit it to redesign the plan.

The plan is good enough. The remaining gap closes by writing code, not editing this file.

**Tier 2 and Tier 3 polish ideas live in `POLISH_BACKLOG.md` — pull from there opportunistically when you finish floor work, not as planning sessions.**

---

*Last updated: Day 1 of build. v4 supersedes v1, v2, v3. Subsequent updates only for non-negotiable changes during build.*
