# BetAutopsy iOS rebuild — master plan v3

> **30-day TestFlight target, ~45-day App Store live target.**
> Functional v1, polish in v1.1+.
> This file lives at the root of `betautopsy-ios`. Every Claude Code session loads it.
> v3 supersedes v2. v1 and v2 archived in `/docs/archive/`.

> **This is the final planning doc. No v4. After this, we build.**

---

## 0. The thesis

The Capacitor build is broken structurally. WebView around Next.js cannot deliver native feel. Native SwiftUI is now solo-buildable with Claude Code (Indragie's Context, twocentstudios's Vinylogue, Franco Torriani's Read It Now). Keep Supabase, Resend, Stripe, the Claude analysis engine, the archetype classifier. Throw away Capacitor, Tailwind, Next.js routing for the app. That's the layer that's broken.

**v1 is not pretty. v1 is functional, native, and ahead of any Capacitor build.** Pikkit didn't launch looking like Pikkit-today. Polish followed users. Not the other way around.

**Honest timeline:**
- ~30 calendar days to TestFlight Beta App Review
- ~45 calendar days to live in App Store (one rejection cycle assumed)
- Faster is possible. This is the realistic budget.

**Learning curve disclaimer:** if this is your first Swift project, expect Week 1 to feel like going backwards. Real velocity kicks in Week 2. That's ramp, not failure. The benchmarks (Indragie, twocentstudios, Torriani) are all experienced iOS devs. You're not. Budget for that.

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

**Design (v1: functional, not premium)**
- Forensic dark aesthetic at the **token level only** (colors, fonts in `Tokens.swift`)
- All other UI uses SwiftUI defaults colored with brand tokens
- Max 4px border-radius on buttons and chips, 0px on panels
- No shadows. No backdrop-blur. No gradients on surfaces. No glass effects in custom UI
- JetBrains Mono for all numbers. Inter for all body text
- Three brand colors only: midnight `#0D1117`, scalpel teal `#00C9A7`, bleed red `#E8453C`
- Plus neutral surface ramp: `#0D1117 → #161B22 → #1F2630 → #2A3340`
- Plus text grays: primary `#F0F0F0`, secondary `#A0A0A0`, tertiary `#606060`
- 1px top-edge highlights at `#FFFFFF08` for elevation, never shadows
- Reference `Tokens.swift` for every value. Never hardcode hex. SF Symbols only — no custom illustrations in v1.

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

---

## 2. The complete stack

### Frontend
| Layer | Choice | Why |
|---|---|---|
| Language | Swift 6 strict concurrency | Catches actor/Sendable bugs at compile time |
| UI framework | SwiftUI | Only stack where Swift Charts, Symbol Effects are one-line |
| Architecture | `@Observable` (iOS 17+) + `@Environment` for DI | Maps to React mental model; no TCA, no Redux |
| Navigation | `NavigationStack` with type-safe `Route` enum | Native, deep-linkable, no third-party router |
| Persistence | SwiftData, read-only cache only | Cache last 50 reports. Refetch on app foreground. (See section 5 detail.) |
| Charts | Swift Charts (native) | Free, sufficient for v1 |
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
| Claude Code CLI | Primary engineer | Claude Pro $20/mo |
| Claude in Xcode 26.3 | SwiftUI Preview iteration | Same Pro plan |
| Cursor + Sweetpad + xcode-build-server | Editor + build system | Optional, $20/mo (skip for v1) |

### Libraries imported in v1 (the only ones)
| Library | Use | License |
|---|---|---|
| supabase-swift | DB, auth, storage | Free |
| RevenueCat SDK | IAP | Free until $2.5K MTR |
| TelemetryDeck SDK | Analytics | Free up to 10K signals/day |
| Swift Charts | Native, no import needed | Free |

### Libraries deferred to v1.1+
| Library | Trigger to add |
|---|---|
| Pow (Movingparts/EmergeTools) | When archetype reveal sequence ships |
| Inferno | When CSV ingestion gets a custom shader |
| Rive Pro | September 2026 (Season Wrapped) |
| Sentry | If MetricKit + TestFlight insufficient |

### Library bans

**Permanently banned:**
- ConfettiSwiftUI (kitsch, conflicts with brand voice)
- shadcn references in any AI prompt (gives generic output)
- Firebase / Crashlytics (privacy manifest disclosure surface, Google data sharing)
- Any first-name-personalization library

**Banned in v1, may evaluate later:**
- Lottie (Rive replaces it; only revisit if Rive fails for a use case)
- Any third-party charting library (Swift Charts is sufficient until proven otherwise)

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
- Existing geo-gating allowlist (US states with legal online sports betting: NJ, NY, PA, MI, IL, OH, AZ, etc.)
- Pikkit referral link: `https://links.pikkit.com/invite/surf40498`

### Reference, port to native
- Color values: `#0D1117`, `#00C9A7`, `#E8453C` → `Tokens.swift`
- Typography: JetBrains Mono (OFL) + Inter (OFL) → bundled in main app target. Both licenses permit redistribution as of 2026.
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

**Working assumption:** full-time, ~6 productive hours/day, Claude Code as primary engineer. Total budget: ~30 calendar days to TestFlight, ~45 calendar days to live.

### Day 0: Pre-flight (do BEFORE starting the clock)

These have wait times. Do them the weekend before Day 1, or whenever you decide to commit. None of them require Xcode or Swift.

- [ ] Buy Apple Developer Program ($99/yr) — **24-48 hour activation wait**
- [ ] Enroll in Apple Small Business Program — separate enrollment, also has wait
- [ ] Sign latest Apple Developer Program License Agreement in App Store Connect
- [ ] Confirm Diagnostic Sports LLC matches App Store Connect requirements (legal name, EIN, address)
- [ ] Verify Mac has Apple Silicon, 50GB+ free disk
- [ ] Apple ID with two-factor auth enabled
- [ ] Anthropic API account confirmed (separate from Claude Pro — Pro is for *you* using Claude Code as a developer; API is for Claude calls your *app* makes in production)
- [ ] Subscribe to Claude Pro if not already
- [ ] Confirm Supabase Pro is on (or flip the switch — backups required)

**Day 1 cannot start until Apple Developer Program is active. Plan accordingly.**

---

### Week 1: Foundation (Days 1–7)
**Goal:** Empty branded SwiftUI app authenticates with Supabase, runs on physical iPhone, and has analytics wired.

**Day 1 — installation only**
- [ ] Install Xcode 26.3 (60-90 minute download)
- [ ] Install Claude Code CLI
- [ ] Create new private repo `betautopsy-ios`
- [ ] Drop this file at root as `BETAUTOPSY_IOS_MASTER_PLAN.md`
- [ ] Create `CLAUDE.md` (see section 9)
- [ ] Verify `xcodebuild -version` works
- [ ] Bookmark Apple's App Review Guidelines page

**Day 2 — Apple Developer config + Cloudflare**
- [ ] New SwiftUI project, deployment target iOS 17, Swift 6 strict concurrency on
- [ ] Apple Developer portal setup:
  - Create App ID with Sign in with Apple capability
  - Create Service ID for SiwA
  - Generate Sign in with Apple key (.p8) — store secrets in 1Password or similar
- [ ] Create App Store Connect app record (do not submit), reserve bundle ID
- [ ] Set up `wrangler` for Cloudflare Workers
- [ ] Deploy hello-world Hono Worker

**Day 3 — Supabase SiwA wiring + Tokens**
- [ ] Configure Sign in with Apple in Supabase dashboard (upload .p8 key, set redirect URLs)
- [ ] Create `Tokens.swift` with colors, fonts, spacing
- [ ] Bundle JetBrains Mono + Inter fonts in app target (both OFL, no licensing concerns)
- [ ] Build manual color/font test view in Preview, verify both light and dark mode
- [ ] One reusable card style with simple rect borders (skip L-bracket evidence-tag for v1, defer to v1.1)
- [ ] One reusable button style with 4px radius

**Days 4–5 — Auth flow end-to-end**
- [ ] Add `supabase-swift` via SPM
- [ ] Implement Sign in with Apple → Supabase Auth flow (snippet in section 11)
- [ ] **Critical:** capture name from `ASAuthorizationAppleIDCredential` on first auth, persist via `supabase.auth.update(user:)` immediately
- [ ] **Also capture timezone:** read `TimeZone.current.identifier` and persist to Supabase `users.iana_timezone` column. Update on app foreground if changed (user moved).
- [ ] Store session in Keychain via supabase-swift's built-in Keychain storage (don't roll custom)
- [ ] Single screen reads authenticated user's display name from Supabase
- [ ] Test cold launch with expired token: silent refresh + authenticated state restoration

**Day 6 — Analytics + streaming proxy**
- [ ] Integrate TelemetryDeck SDK (now, not later — instrument as you build)
- [ ] Wire core events: `app.launched`, `auth.completed`, `auth.failed`
- [ ] CF Worker `claude-stream` endpoint proxies one streaming Claude call
- [ ] Confirm streaming works end-to-end on physical device with debug view

**Day 7 — gate**
- [ ] App opens on physical iPhone
- [ ] Sign in with Apple completes, name persists in Supabase across cold launches
- [ ] Timezone captured correctly
- [ ] Test API call hits CF Worker, streams Claude response into a debug view
- [ ] TelemetryDeck dashboard shows real events from device
- [ ] Buffer day for inevitable Sign in with Apple weirdness

**If Day 7 gate slips:** push everything by 2 days. Foundation is foundation. No shortcuts.

---

### Week 2: Core flow (Days 8–14)
**Goal:** End-to-end CSV upload → analysis → native report.

**This week is intentionally not split day-by-day for the upload-and-analysis chain.** They're coupled — you can't validate one without the other. Treat Days 8-12 as one sub-project with the gate at Day 12.

**Days 8–12: Upload + analysis pipeline**
- [ ] Trigger.dev project set up
- [ ] Move CSV parser invocation from Vercel API route to Trigger.dev task
  - Same TypeScript code, different runtime
  - Read file from Supabase Storage signed URL instead of multipart upload
- [ ] Port archetype classifier waterfall (Heat Chaser → Parlay Dreamer → Surgeon → Grinder → Gut Bettor)
- [ ] Port bias detection rules
- [ ] Trigger.dev `analyze-csv` task: parse → classify → generate Claude analysis → write to Supabase `reports` table
- [ ] iOS: `UIDocumentPickerViewController` integrated via `UIViewControllerRepresentable`
- [ ] Upload file to Supabase Storage with signed URL
- [ ] Pikkit referral path on upload screen (use exact link: `https://links.pikkit.com/invite/surf40498`)
- [ ] Sportsbook export instructions linked from same screen (DraftKings, FanDuel, Pikkit, manual entry note)
- [ ] **Polling for report ready** (not Realtime — defer subscription complexity to v1.1):
  - Poll Supabase `reports` table every 3 seconds, max 60 seconds
  - On found → navigate to report
  - On timeout → "Still working, check back in a moment" with manual refresh
- [ ] TelemetryDeck events: `csv.uploaded`, `analysis.completed`, `analysis.failed`

**Days 13–14: Report screen**
- [ ] Native report view with NavigationStack
- [ ] Hero number: **dollar impact** ("$1,847 lost to heated sessions") in JetBrains Mono Bold
  - **Not a /100 score.** This contradicts shipped product brand decisions.
- [ ] Three semantic descriptors below: archetype name, heated session count, time period
- [ ] Native Swift Charts chart: bias breakdown bar chart
  - **This is your Guideline 4.2 keystone — at least one native chart screen, never WebView**
- [ ] Past reports list with NavigationStack push
- [ ] Empty states: default SwiftUI, no custom personality (defer to v1.1)
- [ ] Loading states: default SwiftUI ProgressView (defer custom skeletons to v1.1)
- [ ] Error states: short copy in sharp-friend voice ("Something jammed. Pull to retry.")
- [ ] TelemetryDeck event: `report.viewed`

**Day 14 — gate:**
- [ ] User uploads test CSV → sees real autopsy report
- [ ] Hero number renders correctly (dollar amount, not /100 score)
- [ ] Past reports list works
- [ ] Native chart renders on report
- [ ] No /100 scores visible anywhere

---

### Week 3: Monetization + notifications (Days 15–21)

**Days 15–17: RevenueCat**
- [ ] RevenueCat SDK integrated
- [ ] Three products configured in App Store Connect:
  - Single report consumable: $9.99
  - Pro monthly: $39.99/mo with 7-day free trial
  - Pro annual: $299.99/yr (no trial)
- [ ] All three in same subscription group (allows upgrade/downgrade per Guideline 3.1.2)
- [ ] Webhook from RevenueCat → Supabase `subscriptions` table
- [ ] Paywall view: monthly with trial as default, annual as "save 4.5 months" upgrade
- [ ] Restore Purchases button mandatory
- [ ] T&Cs and Privacy Policy links mandatory
- [ ] Verify entitlements via webhook into DB, never trust client-side `Transaction.currentEntitlements`
- [ ] TelemetryDeck events: `paywall.shown`, `purchase.attempted`, `purchase.completed`, `purchase.failed`

**Days 18–19: APNs setup**
- [ ] APNs auth key (.p8) from Apple Developer
- [ ] CF Worker `apns-push` endpoint signs JWT, caches 50 min (snippet in section 11)
- [ ] Device token registration on app launch → Supabase `devices` table
- [ ] On `410 BadDeviceToken` from APNs, delete token from DB immediately
- [ ] Provisional notification permission requested at first launch (silent, no system prompt)

**Days 20–21: Two notification types + TestFlight test mode**
- [ ] **Weekly Autopsy notification** (snippet in section 11)
  - Trigger.dev `schedules.create()` per user with their stored IANA timezone
  - Fires every Monday 9am LOCAL user time
  - Requires ≥7 days of bet data; silently suppress otherwise
  - Title: dollar number first ("$387 in heated sessions")
  - Body: ≤110 chars, specific data, no emoji, no exclamation marks
  - `interruption-level: active` (never time-sensitive)
  - `thread-id: weekly-autopsy` (per-thread mute support)
- [ ] **Heated Session Alert** — post-hoc within 6 hours of detecting flagged session
  - Never between 22:00–08:00 local
  - Never within 4 hours of NFL kickoff Sundays
  - Hard cap: max 1 per 7-day rolling window per user
  - Bundle additional detections into next Weekly Autopsy
  - `thread-id: heated-session`
- [ ] **TestFlight debug toggle in Settings** (CRITICAL — remove before App Store submit):
  - "Trigger Weekly Autopsy now" button
  - "Trigger Heated Session Alert now" button
  - These let you validate the notification system during TestFlight when users don't yet have ≥7 days of data
  - Wrap in `#if DEBUG` or feature flag, hide for production build
- [ ] Per-thread Settings toggles persist to Supabase `user_preferences` table
  - CF Worker checks prefs before sending push (server-side enforcement, not client-side suppression)
  - Default: both threads ON for users with full permission
- [ ] After user views first report: prompt for full notification permission ("first valuable moment" pattern)
- [ ] TelemetryDeck events: `notification.permission_requested`, `notification.permission_granted`, `notification.permission_denied`, `notification.opened`

---

### Week 4: Compliance + TestFlight prep (Days 22–28)

**Days 22–23: Settings + compliance + outreach prep**
- [ ] Settings screen with:
  - Notification per-thread toggles (writes to `user_preferences`)
  - "Show units instead of dollars" toggle (default off)
  - Account deletion (mandatory per App Store)
  - Privacy Policy + T&Cs links
  - 1-800-GAMBLER link (Guideline 5.3 shield)
  - Restore Purchases button (mandatory)
  - Debug-only: "Trigger test notification" buttons (hidden in production)
- [ ] Age gate on first launch (17+ check)
- [ ] Geo-restriction check (server-side); show "BetAutopsy isn't available in your region yet" for unsupported jurisdictions
- [ ] **TestFlight outreach prep** (do this Days 22–23, send Day 27):
  - Write TestFlight invite email for waitlist
  - Draft r/sportsbetting post (check subreddit rules, mod approval if needed)
  - Aim for 20–50 testers ready to invite

**Day 24 — App Store metadata writing**
- [ ] App Store name: "BetAutopsy" (or test variants up to 30 chars)
- [ ] Subtitle (max 30 chars): "Behavioral Bet Analysis" or test variants
- [ ] Promotional text (max 170 chars): updateable post-launch without resubmit
- [ ] Description (max 4000 chars): forensic-tone, allowed keywords only, includes Apple non-affiliation disclaimer and 1-800-GAMBLER mention
- [ ] Keywords field: behavioral analysis, self-awareness, cognitive bias, post-mortem, betting journal, betting psychology, habit insights
- [ ] **Banned keywords:** picks, +EV, edge, win more, beat the books, sharp action, line shopping, arbitrage
- [ ] Category: Lifestyle primary, Health & Fitness secondary
- [ ] 17+ rating with Frequent/Intense Simulated Gambling content descriptor
- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`)
- [ ] Privacy nutrition labels in App Store Connect

**Days 25–26: Screenshots + optional video**
- [ ] Three App Store screenshots from real device (iPhone 15 Pro / 6.7"):
  1. Forensic report hero (dollar impact + archetype + chart)
  2. CSV upload moment (`UIDocumentPickerViewController`)
  3. Bias breakdown native chart
- [ ] **App Preview video is OPTIONAL.** App Store accepts screenshots-only.
  - If shipping the video: 15-30 seconds, portrait, recorded on real iPhone via QuickTime over USB, exported per Apple's format requirements
  - If skipping: prioritize TestFlight prep instead

**Day 27: Beta App Review submission + outreach**
- [ ] Submit binary for TestFlight Beta App Review (24–48 hour review)
- [ ] Send waitlist invite email
- [ ] Post in r/sportsbetting (or hold until Beta App Review approves)

**Day 28: External TestFlight goes live**
- [ ] Beta App Review approves (assume Day 28; if rejected, fix and resubmit, +1-2 days)
- [ ] Push to 20–50 external testers
- [ ] Use TestFlight debug toggle to validate notification system works for testers
- [ ] Monitor TestFlight crash reports + TelemetryDeck dashboard

---

### Week 5: TestFlight feedback + App Store submit (Days 29–37)

**Days 29–34: Iterate on TestFlight feedback**
- [ ] Need a weekend in this window so users can experience the Monday Weekly Autopsy
- [ ] Watch for: CSV import failures (4.2 keystone), auth edge cases, paywall friction, notification permission flow drop-off
- [ ] Critical bug fixes only — resist scope creep
- [ ] Minimum bar before App Store submit:
  - Zero crashes during test sessions in TestFlight
  - At least one tester completed: upload → report → $9.99 purchase end-to-end
  - At least one tester received a Weekly Autopsy notification (via debug toggle if needed)

**Day 35: Pre-submit cleanup**
- [ ] Remove TestFlight debug toggle from production build (verify with build flag check)
- [ ] Final review of allowed/banned keywords in metadata
- [ ] Final privacy nutrition label check
- [ ] Submit IAP products in App Store Connect (separate 24–72 hour review track)

**Day 36–37: Submit**
- [ ] Submit binary Tuesday or Wednesday morning Pacific time
- [ ] Avoid WWDC week and iPhone-launch week
- [ ] Update marketing site (betautopsy.com) with App Store badge prepared (don't activate until live)

**Days 38–45: Review + revision (the honest reality)**
- [ ] First review: 24-72 hours typical
- [ ] **Rejection on first submission is the median outcome.** Plan for one revision cycle.
- [ ] Common rejection causes for this app type:
  - 4.2 (more native features needed) — add Share Extension or App Intents from v1.1 list as needed
  - 5.3 (gambling framing) — sharpen behavioral-only positioning
  - 4.8 (auth method) — confirm SiwA is properly the *only* option, no email/password fallback
  - 3.1.1 (IAP not used for digital content) — confirm consumable + subscription products tied to entitlements
- [ ] Approval expected ~Day 42-45
- [ ] Activate App Store badge on marketing site

---

## 5. Architecture

### Frontend file structure
```
betautopsy-ios/
├── BETAUTOPSY_IOS_MASTER_PLAN.md     # This file. Source of truth.
├── CLAUDE.md                          # Rules every Claude session loads
├── BetAutopsy.xcodeproj/
├── BetAutopsy/                        # Main app target
│   ├── App/
│   │   ├── BetAutopsyApp.swift        # @main, root view
│   │   └── AppRouter.swift            # NavigationStack Route enum
│   ├── Features/
│   │   ├── Auth/                      # Sign in with Apple
│   │   ├── Upload/                    # Document picker + Pikkit referral
│   │   ├── Reports/                   # Past reports list + detail
│   │   ├── Paywall/                   # RevenueCat-backed
│   │   ├── Notifications/             # Permission flow + Settings
│   │   └── Settings/                  # Includes 1-800-GAMBLER + debug toggle
│   ├── Core/
│   │   ├── Tokens.swift               # Colors, fonts, spacing
│   │   ├── Strings.swift              # All user-facing copy
│   │   ├── Networking/                # CFWorkerClient, SupabaseClient wrapper
│   │   ├── Auth/                      # SignInWithApple
│   │   ├── IAP/                       # RevenueCat wrapper
│   │   ├── Analytics/                 # TelemetryDeck wrapper
│   │   └── Persistence/               # SwiftData read-only cache
│   ├── Resources/
│   │   ├── Fonts/                     # JetBrains Mono, Inter
│   │   └── Assets.xcassets
│   └── Tests/                         # ViewInspector tests (light coverage v1)
└── docs/
    ├── archive/
    │   ├── MASTER_PLAN_V1.md          # The 90-day premium plan
    │   └── MASTER_PLAN_V2.md          # The 30-day v2
    ├── prompts/                       # Ported Claude analysis prompts
    └── reference-screenshots/         # Whoop, Robinhood, Linear (for v1.1+)
```

**v1 has no separate extension targets.** Share Extension, Widget, Notification Service Extension are all v1.1+. Push notifications use plain text payload, no rich media.

### Persistence detail

SwiftData stores last 50 reports as a read-only cache. Refetch strategy:
- On app foreground, refetch full list from Supabase `reports` table
- Compare local count + max(updated_at) to server response; refresh local if different
- Polling for new reports during analysis (not Realtime) — see Days 8-12
- Realtime subscription deferred to v1.1 (handles offline/reconnect/missed-event complexity)

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
- Requires ≥7 days of bet data; silently suppress if not yet
- Title leads with a number, ≤40 chars, no emoji
- Body ≤110 chars, observational tone, no imperatives
- `thread-id: weekly-autopsy`
- `interruption-level: active` (not time-sensitive)

**Heated Session Alert** — post-hoc within 6 hours of upload detecting flagged session
- Never 22:00–08:00 local
- Never within 4 hours of NFL kickoff Sundays
- Hard cap: 1 per 7-day rolling window
- Bundle additional detections into next Weekly Autopsy
- `thread-id: heated-session`

### Copy templates

| Trigger | Title (≤40ch) | Body (≤110ch) |
|---|---|---|
| Weekly Autopsy (loss frame) | `$387 in heated sessions` | `6 sessions last week, average stake 2.3× your baseline. Tap to review.` |
| Weekly Autopsy (low-leak week) | `28 days of disciplined sizing` | `No heated sessions detected since Apr 11. Stake variance down 41%.` |
| Heated Session Alert | `Sunday session flagged` | `8 bets between 11pm and 1am. 2.4× your normal sizing.` |
| Bias detection (rare; bundle when possible) | `Recency bias in your last 7 bets` | `5 of 7 followed a win. Win rate dropped to 31%.` |
| First report ready (one-shot) | `Your first case file is ready` | `132 bets analyzed. We found 2 recurring patterns.` |
| Trial closing | `Your trial closes in 2 days` | `Three weekly reports remaining. Continue Pro to keep your case files.` |

**Banned patterns:** first-name in title, exclamation marks, emoji, imperative voice ("don't bet"), moral language ("you should have"), urgency cues.

### Permission flow
1. **First launch:** silent provisional with `[.alert, .sound, .badge, .provisional]`. No dialog.
2. **First report viewed:** custom in-app primer modal: "Recaps land Monday morning. No noise otherwise." → system prompt.
3. **Denial:** passive in-app banner with "Enable in Settings" deep link via `UIApplication.openSettingsURLString`. No nag.

### Permission state tracking
- Fire TelemetryDeck event `notification.permission_state` on every app launch with current state
- Compute permission survival as % of users with `.authorized` on Day 1 still at `.authorized` on Day 30

### Per-thread toggle enforcement
- Toggle state writes to Supabase `user_preferences.notification_threads` (jsonb)
- CF Worker checks prefs before sending push (server-side enforcement, never client-side suppression)
- Default: both threads ON for users who upgrade to full permission

### Anti-patterns to never ship
- Daily push (trains users to mute, hurts a behavioral-data app)
- Time-sensitive interruption level (Apple HIG forbids for marketing)
- Critical Alerts entitlement (Apple won't grant to gambling-adjacent apps)
- Emoji in title or body (Headspace data: 70% of users dislike)
- Notifications during active betting hours (NFL Sunday afternoons)
- Personalization with first name (reads like casino email)

### v1.1+ notification roadmap
- **v1.1 (week 4–6 post-launch):** monthly case-file recap, RevenueCat trial/billing webhook-driven sends, first-report welcome notification
- **v1.2 (week 8–12):** streak protection nudges, lapsed-user re-engagement at D7/D14/D30, A/B copy harness
- **v1.3+:** daily intentional pulse (requires live betslip integration), sport-specific timing variants, quick-action buttons, Notification Service Extension for rich charts

### Measurement
- **North star:** 30-day notification permission survival rate (target ≥92%)
- Direct open rate (target floor 5%, aspiration 12-16%)
- Provisional → full upgrade rate (target 40-60% within 14 days)
- Mute-per-thread rate (kill any thread hitting 5%/month)
- **Most important:** does the notified cohort have higher 30-day report-generation than control?

---

## 7. App Store strategy

### Guideline 4.2 — Minimum functionality
Apple has rejected push-notifications-only Capacitor wrappers. You need meaningful native interaction.

**v1 minimum viable approval set:**
- Native CSV import via `UIDocumentPickerViewController` ✓
- At least one native chart (Swift Charts) on the report screen ✓
- Sign in with Apple ✓
- Native paged navigation (NavigationStack) ✓
- Push notifications with content (not silent) ✓

**Held in reserve for first-rejection counterargument:**
- Share Extension target
- Face ID gate
- Spotlight indexing
- App Intents / Siri
- Home Screen widget

If first review rejects on 4.2, add the lightest of these (Share Extension is easiest) and resubmit.

### Guideline 5.3 — Gambling
**Does not directly apply.** BetAutopsy doesn't take wagers, show odds, or recommend picks. Pikkit (id1586567110) is the cleanest precedent — same posture, approved.

**The trap:** the "illegal gambling aid" clause in 5.3.4. If you position as helping users *win more bets*, you edge into gambling aid.

**Your shield (all in v1):**
- Allowed metadata only (behavioral, self-awareness, cognitive bias)
- 17+ rating with gambling content descriptor
- Age gate first launch
- 1-800-GAMBLER link in Settings AND paywall
- Apple non-affiliation disclaimer in description
- Geo-restrict to legal-state jurisdictions (server-side allowlist; reuses existing config)
- Diagnostic Sports LLC on developer account

### Guideline 3.1.1 — IAP
- Single report: consumable, $9.99
- Pro monthly: auto-renewable, $39.99/mo, 7-day trial
- Pro annual: auto-renewable, $299.99/yr, no trial
- All in same subscription group (Guideline 3.1.2)
- Apple Small Business Program: 15% commission
- Reader-app exception does NOT apply

### Bonus: Apple Search Ads will not accept you
Apple Ads Policy 4.4.1 prohibits "services that offer statistical analysis for the purposes of gambling." Doesn't affect App Store approval but cross ASA off acquisition list.

**Acquisition stays:** Meta server-side CAPI, organic TikTok, SEO, content/blog, ASO, App Store editorial featuring (forensic aesthetic is genuinely featurable — submit via App Store Connect Marketing Tools).

---

## 8. Cost — v1 reality

### Required, day one through launch
| Item | Cost | Status |
|---|---|---|
| Apple Developer Program | $99/yr | Buy Day 0 |
| Claude Pro | $240/yr | Already paying or buy Day 0 |
| Supabase Pro | $300/yr | Flip on Day 0 (backups required) |
| Resend | $240/yr | Already paying |
| Vercel (marketing only) | $240/yr | Already paying |
| **Subtotal v1 required** | **~$1,120/yr** | |

### Skip in v1, add when needed
| Item | Cost | Trigger |
|---|---|---|
| Pow license | $99 one-time | When archetype reveal sequence ships in v1.1 |
| Cursor Pro | $240/yr | Skip; Claude Code CLI works |
| Custom display face | $400-800 once | Month 6 post-launch |
| Figma Pro | $180/yr | Month 3 if AI output drifts |
| Rive Pro | $144/yr | September 2026 (Season Wrapped) |
| Trigger.dev paid | $240/yr | After ~300 users (5K monthly tasks limit) |
| TelemetryDeck paid | ~$180/yr | After ~10K signals/day |
| Sentry team plan | $312/yr | Only if MetricKit + TestFlight insufficient |

### Variable
- Claude API: ~$0.50-2 per autopsy with prompt caching
- APNs: free
- CF Workers: free at v1 scale
- RevenueCat: free until $2.5K MTR, then 1% of tracked revenue

### Ongoing business costs (already in your stack, listed for completeness)
- Domains: betautopsy.com, mysharpscore.com
- Diagnostic Sports LLC NY annual filings
- Trademark search/filing (optional): $300-500 self-filed

**Day-zero minimum to start:** $99 (Apple) + $20 (first month Claude Pro) = **$119**.

### Hardware
- Mac with Apple Silicon required for Xcode 26. M-series Mac mini base $599 if needed.
- iPhone for testing (you have one).
- Borrow old iPhone (SE, X) for small/old screen testing.

---

## 9. CLAUDE.md (every session loads this)

> **Note:** Rules in CLAUDE.md must stay in sync with section 1 of this master plan. If they conflict, the master plan wins.

```markdown
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
```

---

## 10. Failure modes (in order of frequency)

1. **`.pbxproj` corruption** — Claude Code edits the project file, Xcode breaks. Mitigation: instruct Claude to never touch it; add files manually in Xcode.
2. **Apple's name-only-once rule** — User's name missing on second launch. Mitigation: capture from `ASAuthorizationAppleIDCredential` on first auth, persist immediately via `supabase.auth.update(user:)`.
3. **Swift 6 concurrency confusion** — Where Claude most often gets lost (`@MainActor`, actors, `Sendable`). Mitigation: load concurrency-expert agent skill, run strict concurrency mode to catch at compile time.
4. **Client-side IAP entitlement check** — Spoofable. Mitigation: RevenueCat webhook → Supabase, trust DB only.
5. **Push permission one-shot** — User taps Don't Allow, you can never re-prompt. Mitigation: provisional first, full prompt only after first valuable moment.
6. **SSE through Vercel** — Breaks at 60 seconds. Mitigation: CF Workers, period.
7. **SwiftUI view body type-check timeout** — "unable to type-check this expression in reasonable time." Mitigation: split views aggressively at 100 lines.
8. **Tabs reset on view rebuild** — `@State` placement gotcha in TabView. Mitigation: hoist state to parent, pass down via `@Binding`.
9. **Memory leak from closures capturing self in @Observable** — common in async network calls. Mitigation: `[weak self]` in Task closures, audit periodically.
10. **Image assets in Swift Packages don't render in Xcode Previews** — bites if you split design tokens into a package early. Mitigation: keep `Tokens.swift` in main app target for v1.
11. **APNs `410 BadDeviceToken` inflates "delivered" rate** — stale tokens fail silently. Mitigation: delete tokens from DB on 410 immediately.
12. **Trigger.dev cron timezone confusion** — naive UTC scheduling sends Weekly Autopsy at 4am for users in some zones. Mitigation: schedule per-user with IANA timezone via `schedules.create()` (snippet in section 11).
13. **IAP review separate track** — Submit IAP first or launch slips. Mitigation: submit IAP day one of launch prep.
14. **Prompt caching billing surprise** — Cache invalidates on single-character system prompt changes. Mitigation: lock prompt verbatim, dynamic data after cache breakpoint.
15. **AI generates generic shadcn-style UI** — Mitigation: ban shadcn references in CLAUDE.md, drop reference screenshots in initial prompts, require all UI to reference Tokens.swift.
16. **TestFlight notification testing impossible without debug toggle** — testers can't accumulate 7 days of data in 2-3 day TestFlight window. Mitigation: ship debug "trigger now" buttons in Settings, hide for production via build flag.
17. **Apple Developer Program activation wait kills Day 1** — 24-48 hour activation. Mitigation: do all bureaucracy in Day 0 (pre-flight section).
18. **CSV upload tested without analysis pipeline** — building upload Days 8-9 with analysis Days 10-12 means upload tested against stub for 4 days. Mitigation: treat Days 8-12 as one sub-project, validate end-to-end.

---

## 11. Critical code snippets

### Sign in with Apple — capturing the name + timezone (failure modes #2 + supporting #12)

```swift
// In your ASAuthorizationControllerDelegate
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

            // Sign in to Supabase
            try await supabase.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: identityToken)
            )

            // CRITICAL: Apple sends the name ONCE on first auth.
            // Capture and persist it now, or it's gone forever.
            // Verify exact API shape against supabase-swift v2 docs at build time.
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

### APNs JWT signing in CF Worker (failure mode #11)

```typescript
// CF Worker pseudocode
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

  cachedToken = { jwt, expiry: now + 50 * 60 }; // 50 min cache
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

  // CRITICAL: stale tokens silently inflate "delivered" rate.
  if (response.status === 410) {
    await env.DB.exec(
      "DELETE FROM devices WHERE token = ?",
      deviceToken
    );
  }
  return response;
}
```

### Trigger.dev per-user timezone scheduling (failure mode #12)

```typescript
// In your Trigger.dev project, in tasks/weekly-autopsy.ts
import { schedules, schedule } from "@trigger.dev/sdk/v3";

export const weeklyAutopsyTask = schedules.task({
  id: "weekly-autopsy",
  run: async (payload, { ctx }) => {
    const userId = payload.externalId;
    const user = await getUserFromSupabase(userId);

    // Server-side check before send
    if (!hasSevenDaysOfData(user)) return;
    if (!user.notification_threads?.weekly_autopsy) return;
    if (!user.notification_permission_full) return;

    const summary = await generateWeeklySummary(user);

    await sendPushNotification({
      userId,
      title: summary.title,        // e.g. "$387 in heated sessions"
      body: summary.body,          // ≤110 chars
      threadId: "weekly-autopsy",
      interruptionLevel: "active",
    });
  },
});

// On user signup, register their schedule
export async function registerUserSchedule(userId: string, ianaTimezone: string) {
  await schedules.create({
    task: "weekly-autopsy",
    cron: "0 9 * * 1",                        // Mondays 9am
    timezone: ianaTimezone,                    // e.g. "America/New_York"
    externalId: userId,                        // links schedule to user
    deduplicationKey: `${userId}-weekly`,      // prevents duplicate schedules
  });
}

// On timezone change (user moved), update schedule
export async function updateUserSchedule(userId: string, newTimezone: string) {
  // Trigger.dev's schedules.create with same deduplicationKey replaces existing
  await schedules.create({
    task: "weekly-autopsy",
    cron: "0 9 * * 1",
    timezone: newTimezone,
    externalId: userId,
    deduplicationKey: `${userId}-weekly`,
  });
}
```

---

## 12. Day 0 / pre-flight checklist

These have wait times. Do them BEFORE Day 1 — ideally the weekend before.

- [ ] Buy Apple Developer Program ($99/yr) — **24-48 hour activation wait**
- [ ] Enroll in Apple Small Business Program
- [ ] Sign latest Apple Developer Program License Agreement in App Store Connect
- [ ] Confirm Diagnostic Sports LLC matches App Store Connect requirements (legal name, EIN, address)
- [ ] Verify Mac has Apple Silicon, 50GB+ free disk
- [ ] Apple ID with two-factor enabled
- [ ] Anthropic API account confirmed (separate from Claude Pro)
- [ ] Subscribe to Claude Pro
- [ ] Confirm Supabase Pro is on (or flip the switch)
- [ ] Bookmark Apple's App Review Guidelines page
- [ ] Bookmark this file

When the Apple Developer Program shows "active," Day 1 starts.

---

## 13. Elevator version

> BetAutopsy iOS rebuild. Native SwiftUI on iOS 26 SDK, deployment target iOS 17. Supabase + Sign in with Apple + RevenueCat + Cloudflare Workers (Hono) for Claude streaming + Trigger.dev for CSV jobs and notification crons. Two notification types: Monday 9am-local Weekly Autopsy + capped post-hoc Heated Session Alert. Forensic dark aesthetic at token level, system-default polish elsewhere. Built solo with Claude Code over ~30 days to TestFlight, ~45 days to live App Store. Apple Small Business Program for 15% IAP commission. Lifestyle primary category. 17+ rating. Diagnostic Sports LLC on the developer account. v1 functional, v1.1+ premium polish.

---

## 14. Explicitly NOT in v1

- Onboarding quiz (cut entirely)
- Archetype reveal sequence (just show on report screen)
- Pow animations (defer to v1.1)
- Custom Inferno Metal shader (defer)
- Custom haptic vocabulary (use default UIKit haptics)
- Sound design (cut entirely)
- Custom illustrations / archetype sigils (use SF Symbols)
- Hero dashboard with animated digit roll (default text fine)
- Card flip transitions (default sheet presentation)
- App open animation (default launch screen)
- Symbol Effects pass
- Empty states with personality (default fine)
- Share Extension target
- App Intents / Siri integration
- Spotlight indexing
- Home Screen widget
- Notification Service Extension (rich push)
- Face ID gate (Sign in with Apple is the gate)
- BAForensicsKit Swift Package (single Tokens.swift in main app)
- L-bracket evidence-tag corner card style (defer to v1.1)
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
- App Preview video (optional, screenshots-only is acceptable)

If I don't ship v1, none of these matter. If I do, they all become tractable.

---

## 15. v1.1+ roadmap (rough sketch)

Once v1 is live, polish gets data-informed.

**v1.1 (~weeks 4-6 post-launch)**
- Add Pow library, ship archetype reveal sequence on report screen
- Custom empty/loading/error states with personality
- L-bracket evidence-tag corner card style
- Notification Service Extension for rich Weekend Autopsy push
- Face ID gate for "your sensitive forensic data"
- Share Extension for CSV import from Mail/Files/Safari
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
- Onboarding quiz (Cal AI pattern, behaviorally validated)
- BAForensicsKit promoted to Swift Package
- Custom illustrations for archetype sigils
- Daily intentional pulse notification (requires live betslip integration)
- Sport-specific notification timing variants

**Future (months 6+)**
- Custom display face for wordmark
- Sound design pass
- Season Wrapped (September 2026)
- Skip framework evaluation for Android
- Apple Watch companion

---

## 16. Stop editing this document. Start building.

This is v3. There is no v4. Every iteration past this point is procrastination dressed as planning.

**Tomorrow:** complete Day 0 pre-flight if not already done.
**Day after:** Day 1 of Week 1.

Edit this file only when you ship a non-negotiable change (e.g. iOS 17 deployment target → 18, RevenueCat replaced with custom). Do not edit it to redesign the plan.

The plan is good enough. The remaining gap closes by writing code, not editing this file.

---

*Last updated: Day 0. v3 is the final planning version. Subsequent updates only for non-negotiable changes during build.*
