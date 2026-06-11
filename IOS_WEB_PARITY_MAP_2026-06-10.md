# BetAutopsy iOS ↔ Web Parity Map

**Date:** 2026-06-10
**Type:** Read-only recon. No code, no commits, no Notion writes.
**Scope:** Map every web product user journey to its iOS status, flag engine-dependency risk, and produce three scoping lists (TestFlight-minimum, full-parity, engine-sequencing).
**Repos:** iOS `/Users/Andrew/betautopsy-ios` (SwiftUI, sources under `BetAutopsy/BetAutopsy/`) · Web `/Users/Andrew/betautopsy` (Next.js App Router).

---

## TL;DR (findings first)

1. **iOS is fully native SwiftUI end to end — no WebView, no thin web-port anywhere.** It is a thin native *client* over the same Vercel engine the web uses (`api.betautopsy.com`). The report reader, onboarding, quiz, paywall, check-in are all real native surfaces.
2. **The report-viewing journey is at near-parity** and is the strongest part of the app. iOS renders essentially all engine report depth (BetIQ + 6 components, heated sessions, behavioral impacts/annotations, what-ifs, vs-last-report, leaks, contradictions, tilt signals).
3. **Three whole web journeys are entirely or mostly absent on iOS:** the **Control System** (rules/cooldowns/recovery mode — *missing*), **enforcement-aware Check-in** (iOS consumes the *old v1 advisory shape*, ignores `actionGate`/`ruleViolations`/`cooldown`), and **Ask Your Autopsy** conversational Q&A (*missing*).
4. **The Today/dashboard tab is mock data** (hardcoded BetIQ "87", "$2,847" verdict) — not real aggregated PnL. The Sessions tab is real but non-interactive. There is no individual-bets feed. Ingest is **CSV-only** (web has CSV + paste + screenshot).
5. **Engine sequencing is the real constraint.** Two web workstreams (WS-TEMPORAL, WS-NUMERIC) will recompute timing, late-night, ROI/win-rate, cash-out P&L, deterministic bias costs, and bump `schema_version` 2→3. Most are additive-safe for iOS Codable, but **two iOS-side items must land before web ships** (see R3 §3). Building net-new iOS parity against current engine output risks rework.
6. **One hard cross-repo gate already exists:** if any iOS enum decodes `bets.result` strictly, iOS needs a one-case PR (`cashed_out`) *before* web ships WS-NUMERIC PR-N2. iOS currently decodes report `result` leniently, but this must be verified.

---

# R0 — Orientation: the iOS app as it exists today

## Entry point & lifecycle
- `BetAutopsyApp.swift:8` — `@main`. Static `sessionPrewarm` Task kicks a Supabase JWT refresh at app init before any view appears (`:20`). Runs a one-shot V2→V3 archetype-string migration (`:40`), starts Sentry, Analytics. Cold-start hooks: Apple credential-state check, RevenueCat login-if-authenticated (`:79-84`).
- Onboarding is a `fullScreenCover` over the root, gated by `@AppStorage("onboardingComplete")` (`:86`, `:94`).

## Navigation model
- `RootTabView.swift:23` — `TabView` with **3 tabs: Today / Sessions / Reports** (yellow active tint). No custom tab bar (per CLAUDE.md rule).
- Report deep-links open via `fullScreenCover(item:)` on `DeepLinkRouter.presentingReport` (`RootTabView.swift:46`) → `ReportScrollContainer`.
- Cache-first hydrate keyed on `appleUserID` (`RootTabView.swift:63`) — swaps cached reports synchronously, then network-refreshes in background.
- Onboarding flow: `OnboardingCoordinator` ordered phases `ageGate → sampleReportPreview → betDNAQuiz → archetypeReveal → signIn → pikkitEducation → complete` (`BetAutopsyApp.swift:116`). Sign-in happens **after** quiz + reveal ("earn-the-ask").

## Every screen / view (one line each)
**Onboarding:** `AgeGateView` (18+ gate) · `SampleReportPreviewView` (static demo card) · `BetDNAQuizView` (7-question quiz) · `ArchetypeRevealView` (animated reveal) · `AuthView` (Sign in with Apple) · `PikkitEducationView` (external Pikkit invite).
**Root tabs:** `TodayView` (hub + "About to bet" CTA; **mock data**) · `SessionsTabView` (read-only sessions list) · `ReportListView` (report history + Upload CSV entry).
**Report reader:** `ReportScrollContainer` (single-scroll, 6 sections) driven by `ReportScrollViewModel`; sections under `Components/V3/Sections/*`; ~40 cards under `Components/V3/*`.
**Upload/analysis:** `CSVPickerView` (UIDocumentPicker) · `UploadFlowCoordinator` (state machine) · `UploadProgressView` (SSE spinner).
**Paywall/IAP:** `PaywallView` · `RevenueCatStore`.
**Check-in:** `PreBetCheckInView` + `PreBetCheckInCoordinator` + `PreBetCheckInClient` + `PreBetCheckInModels`.
**Settings/support:** `SettingsView` · `GlossaryView` · `PushPermissionView`.
**Dead/deprecated:** `ReportView.swift` (marked DEPRECATED, REBUILD-PHASE-2) + all 7 `Chapter*View.swift` + `ChapterNavigator.swift` — referenced only by their own previews. The live reader is `ReportScrollContainer` exclusively.
**Debug:** `DebugAPITestView`, `ReportDecodeDebug`, `MockReport`.

## SwiftUI / Swift patterns in use
- `@Observable` (not `ObservableObject`) on stores/coordinators; `@Environment` injection for `OnboardingCoordinator`, `UploadFlowCoordinator`, `ReportStore`. Swift 6 strict concurrency, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. Swift Charts for timing/PnL charts. Single-scroll reader (no pager).

## Networking layer
- Base host **`https://api.betautopsy.com`** (`APIConfig.swift:19`) — targets `api.` directly to preserve the Bearer across the apex→www 308 redirect (URLSession strips Authorization cross-host).
- Bearer = live Supabase JWT via `APIConfig.bearerToken` (`APIConfig.swift:75`), auto-refreshed by supabase-swift. Not the old Info.plist placeholder.
- **Endpoints iOS actually calls:**
  - `POST /api/analyze` — **real SSE streaming** via `URLSession.bytes(for:)` with `httpBody` set on a multipart request (`AnalyzeClient.swift:379`); parses `metrics`/`report_started`/`complete`/`error`; 401 refresh-retry-once; 300s timeout.
  - `GET /api/reports` — list (`ReportListClient.swift`).
  - `GET /api/reports/:id` — single report (`ReportFetchClient.swift`, deep-link target).
  - `GET /api/reports?upgraded_from=:id` — post-purchase unlock poll (`RevenueCatStore.swift`, every 3s up to 90s).
  - `POST /api/check-in` + `POST /api/check-in/outcome` (`PreBetCheckInClient.swift`).
  - `POST /api/device-tokens` (`DeviceTokenClient.swift`), `POST /api/action-checkoffs` (`ActionCheckoffClient.swift`).

## How it decodes AutopsyAnalysis
- `AutopsyAnalysis` top-level struct at `ReportModels.swift:1227`. Decodes with **`convertFromSnakeCase`** at every site (not camelCase wire). `schema_version` IS decoded (`schemaVersion: Int?`) but is **informational only — there is no version-branching**.
- Resilience pattern: every struct has a hand-written tolerant `init(from:)` wrapping each field in `try?` with neutral defaults, so a single null/mistyped field degrades locally instead of collapsing the parent. Handles mixed snake/camel v2 reality, `overall_grade: null`, the dual `executive_diagnosis`/`executiveDiagnosis` collision, and `_snapshot*` leading-underscore keys.
- Key nested types confirmed present: `BetIQResult{score, components: BetIQComponents(6), percentile, interpretation, insufficientData}` (`:361`), `EnhancedTiltResult{score, signals: TiltSignals(6), riskLevel, worstTrigger, percentile}` (`:458`), `SessionDetectionResult` (`:754`), `WhatIfScenario{label, actual, hypothetical, deltaDollars}` (`:1184`), `WhatChanged{previousReportDate, daysSincePrevious, archetypeChange?, betIQDelta?, topImpactDeltas?}` (`:1152`).
- **Persistence:** disk-backed cache-first `ReportStore` + `ReportCache` actor (PR #29). v2 decode contract retained (PR #30, #31 fixed `overall_grade:null` collapse + the `-$-8,840` double-negative).

---

# R1 — The parity map

For each journey: **iOS status** · **iOS file(s)** · **same engine/API contract?** · **native vs web-port feel**. Engine-dependency flags carry a ⚠️.

### (a) Auth — **EXISTS (native)**
- **Files:** `AuthView.swift`, `Services/AppleSignInCoordinator.swift`, `Services/AuthState.swift`, `Services/AccountDeletionService.swift`, `Services/SupabaseService.swift`.
- **Sign up / sign in:** unified — **Sign in with Apple ONLY** (`AuthView.swift:157`); first Apple auth is sign-up. Nonce SHA256, Supabase `signInWithIdToken`, captures `fullName`+`email`+`TimeZone.current.identifier` once (`AppleSignInCoordinator.swift:137`).
- **Sign out:** `AuthState.signOut()` (`AuthState.swift:60`) — Supabase + RC logout + push/checkoff clear + `ReportStore.clear()` + UserDefaults wipe.
- **Account deletion:** `AccountDeletionService.swift` — best-effort `delete_account` edge function then local sign-out regardless (edge function may not be deployed; failure swallowed at `:42`). Satisfies Apple 5.1.1(v).
- **Contract:** same Supabase auth backend. **Divergence by design:** web uses email/password + Google OAuth; iOS uses Apple-only. Apple Sign-In does **not** exist on web. Account-deletion endpoint differs (iOS edge fn vs web `POST /api/account/delete`).
- **Feel:** fully native.

### (b) Upload / ingest — **PARTIAL (CSV-only)**
- **Files:** `CSVPickerView.swift` (UIDocumentPicker scoped to `.commaSeparatedText`), `UploadFlowCoordinator.swift`, `UploadProgressView.swift`.
- **Web has 4 ingest paths:** Pikkit CSV, raw CSV, **paste parser**, **screenshot/OCR parser** (`app/(dashboard)/upload/page.tsx`, `/api/parse-paste`, `/api/parse-screenshot`). **iOS has only CSV.** Repo-wide grep found zero paste/screenshot/PhotosPicker/pasteboard ingest.
- **Contract:** iOS posts the file to `POST /api/analyze` multipart with hardcoded `report_type = "snapshot"` (`UploadFlowCoordinator.swift:48`). Web also has a separate `POST /api/upload` import step; iOS folds upload into analyze.
- **Feel:** native file picker. The missing paste/screenshot paths are the gap.

### (c) Analysis — **EXISTS (native, real SSE)**
- **Files:** `AnalyzeClient.swift`, `AnalyzeError.swift`, `UploadProgressView.swift`.
- **SSE:** real streaming (`AnalyzeClient.swift:379`), parses `metrics`/`report_started`/`complete`/`error`, handles both `event:`-prefixed and bare-envelope forms, 401 refresh-retry, 300s timeout. Endpoint `POST api.betautopsy.com/api/analyze`.
- ⚠️ **Engine dependency:** consumes the full analyze SSE `complete` payload (the whole `AutopsyAnalysis`). Every WS-TEMPORAL/WS-NUMERIC output change flows through here.
- **Feel:** native, but the *loading UX is shallow* — a `ProgressView()` spinner; `.metrics` only flips a label ("Analyzing your bets…" → "Reading your patterns…"), no live numeric metrics. Web shows richer SSE progress.

### (d) Report — **EXISTS (native, comprehensive, near-parity)**
- **Files:** `ReportScrollContainer.swift` (6 sections), `ReportScrollViewModel.swift`, `Components/V3/Sections/*`, ~40 cards in `Components/V3/*`.
- **Section order:** Verdict → Findings → HeatedDiscipline → PatternsTiming → Sports → Protocol → Action (snapshot CTA blocks interleaved). Web is a single 199KB monolith (`components/AutopsyReport.tsx`) with 5 chapters; iOS is more decomposed — *iOS is arguably the cleaner architecture here*.
- **Surfaces present:** archetype + vitals (`VitalsStripCard`), BetIQ ring (`HeroRingView`) + 6 component bars (`BetIQComponentBars`), total recoverable (`TotalRecoverableHero`), vs-last-report (`VsLastReportCard`), what-ifs (`WhatIfCard`), damages (`DamagesCard`), biases (`BiasRow` + `BiasEvidenceSheet`), leaks (`StrategicLeakCard`/`LeakPrioritizerCard`), heated sessions (`HeatedSessionPreviewCard`/`TiltSessionCard`), tilt signals (`TiltSignalBreakdownCard`), behavioral impacts/annotations (`BehavioralImpactRow`/`AnnotatedBetCard`/`AnnotationDistributionBar`/`StreakInfluenceCard`), patterns (`PatternCard`), contradictions (`ContradictionCard`), timing charts (Swift Charts), recommendations + checkoffs (`ActionCard`).
- **Gaps vs web report:** **"Ask Your Autopsy" (conversational Q&A) is MISSING** (web `POST /api/ask-report`, Claude Haiku). The in-report **"Adopt Rule / Start Cooldown"** control actions (web `ReportControlSystem`) are absent. `edge_profile`/Ch-6 and Ch-7 bootstrap projection deferred (v1.1).
- ⚠️ **Engine dependency (heavy):** reads `betiq.{score,components,timing}`, `session_detection.{heatedSessionCount,heatedSessionPercent,sessions}`, `timing_analysis`, `biases_detected[].estimated_cost`, `what_if_scenarios`, `summary.roi_percent`, archetype. **All of these are recomputed by the incoming engine work** (see R3 §3).
- **Feel:** fully native, the standout journey.

### (e) Snapshot / paywall / IAP — **EXISTS (native)**
- **Files:** `PaywallView.swift`, `Services/RevenueCatStore.swift`, `Components/V3/LockedDollarBar.swift`, `Components/V3/TotalRecoverableHero.swift`.
- **Snapshot detection:** `report.reportType == "snapshot"` (`ReportScrollContainer.swift:29`) threaded into every section; field-level redaction via `*Visibility == "redacted_dollar"` tags + `_snapshotTeaser`/`_snapshotCounts` side-channel (engine-produced).
- **Unlock:** `RevenueCatStore` sets `pending_report_unlock_id` attribute → `Purchases.purchase(package:)` → polls `GET /api/reports?upgraded_from=X` every 3s/90s for the webhook-materialized full child row. Restore Purchases present (`PaywallView.swift:196`). Entitlements verified server-side via `POST /api/webhooks/revenuecat` (DB is source of truth).
- **Contract divergence:** iOS unlock = RevenueCat (webhook only processes `INITIAL_PURCHASE`+`NON_RENEWING_PURCHASE`); web unlock = Stripe (`/api/checkout`, `/api/webhook`). Both converge on `autopsy_reports` rows. **Web pricing flag is OFF** (`PRICING_ENABLED=false`), so web snapshots currently render full — iOS is the only surface actually exercising the paywall.
- ⚠️ **Engine dependency:** redaction depends on engine `*_visibility` tags and `estimated_cost`. WS-NUMERIC N7 makes `estimated_cost` deterministic — this *improves* snapshot blur honesty but changes the dollar values shown post-unlock.
- **Feel:** native, matches the Grammarly-style spec.

### (f) WhatChanged / longitudinal — **EXISTS (native, first-report-hide done)**
- **Files:** `Components/V3/VsLastReportCard.swift`, wired in `SectionVerdict.swift:112` with first-report hide at `SectionVerdict.swift:94` (renders only when a prior report exists).
- **Contract:** consumes the engine-computed `whatChanged` object (`ReportModels.swift:1152`); backend emits explicit `null` on first report, omits key when no qualifying deltas. In-place snapshot→full swap via `upgradedFromSnapshotId` matched against `ReportStore.reportsChanged` Combine subject.
- **Gaps vs web:** web also has client-side `compareReports` (`lib/report-comparison.ts`) + a separate **upload-vs-upload compare page** (Pro-only A/B). iOS has neither the richer comparison nor upload-compare.
- ⚠️ **Engine dependency (critical for schema bump):** `whatChanged` carries `betIQDelta` and `topImpactDeltas` (cost deltas). The **schema_version 2→3 boundary requires iOS to tolerate `methodology_changed: true` and suppressed numeric deltas** while still showing archetype-name + bias presence deltas (see R3 §3). This is the single most important reader-side engine flag.
- **Feel:** native.

### (g) Pre-bet check-in — **EXISTS but OLD v1 SHAPE (not enforcement-aware) — CRITICAL GAP**
- **Files:** `PreBetCheckIn/PreBetCheckInClient.swift`, `PreBetCheckInModels.swift`, `PreBetCheckInView.swift`, `PreBetCheckInCoordinator.swift`. Endpoint `POST /api/check-in` (+ `/outcome`).
- **iOS request (`PreBetCheckInModels.swift:63`):** `{ sport, stake: Decimal, odds: Int, betType, placedAt: Date, localHour: Int }`. ✅ already sends `localHour` (the timezone seam WS-TEMPORAL unifies on).
- **iOS response (`PreBetCheckInModels.swift:119`):** `{ checkInId, betQualityScore: Int, flags:[{id,severity,title,detail}], recommendation: place_anyway|wait_thirty|place_bet, summary }`.
- **This is the legacy v1 advisory shape.** It does **not decode** any of the enforcement-aware fields the server now returns: `actionGate` (`clear|reflection_required|blocked`), `ruleViolations[]`, `cooldown`, `recentRiskContext[]`, `planContext`, `reflectionPrompts[]`, `overrideRequired`. (All are additive/optional server-side per `types/index.ts:1294`, so iOS doesn't break — it just ignores them.)
- **Behavioral consequence:** in `PreBetCheckInView.swift:354` the user can always tap "Place anyway" with zero friction. There is no blocking, no reflection gate, no cooldown enforcement. The web product can return `blocked`/`reflection_required` and force `wait_thirty`; iOS silently downgrades all of it to advisory.
- ⚠️ **Engine dependency:** the check-in scorer reads `timing_analysis.late_night_stats` (rebased by WS-TEMPORAL) and `biases_detected[Post-Loss Escalation]` (renamed to "rapid-fire escalation" by WS-TEMPORAL). Late-night flags will change prevalence; the post-loss flag changes name.
- **Feel:** native sheet, but functionally a generation behind the web contract.

### (h) Control system — **MISSING entirely**
- No control center, rules engine, cooldowns, recovery mode, action gates, rule violations, or self-exclusion UI exists anywhere on iOS. Grep confirms "cooldown"/"recovery" appear only as advisory *copy* in `MockReport.swift:44/147`, `BiasRow.swift:220`, `BiasEvidenceSheet.swift:148` — never as enforced features.
- **Web has a full Control Center:** `GET|POST /api/control-system`, `components/control/ControlPageClient.tsx` + `ControlSystemPanel.tsx`; tables `control_plans`/`control_rules`/`cooldowns`/`risk_events`/`pre_bet_checkins`; 10 rule types, 3 severities, soft/hard enforcement, recovery-mode levels (watch/elevated/recovery), engine-suggested rules, manual 24h cooldown, manual recovery toggle. The report itself can adopt rules / start cooldowns.
- This is the **largest single missing journey.** It also underpins enforcement-aware check-in (g) and recovery-mode tone app-wide.

### (i) Dashboard — **PARTIAL (mock data)**
- **File:** `TodayView.swift`. Today tab hub. Shows **hardcoded** BetIQ "87", verdict "Your impatience cost you $2,847 since November", static discipline/emotion ranges. Pulls only `userArchetype` from `@AppStorage`. Real function is the "About to bet" CTA → check-in, plus a Settings gear.
- **Web dashboard** (`app/(dashboard)/dashboard/page.tsx`): real net P&L, total bets/wagered, avg stake, win rate, ROI, emotion score, grade, discipline, `ProgressChart`, streak, `ControlSystemPanel`, milestones, recovery-mode banner, priority nudge, quick actions. Backed by `dashboard_stats` RPC.
- ⚠️ **Engine dependency:** a real iOS dashboard would read `summary.roi_percent`/`win_rate` (both recomputed by WS-NUMERIC) and emotion/discipline/BetIQ (BetIQ moves indirectly). No iOS `dashboard_stats` equivalent endpoint is wired.
- **Feel:** native shell, fake data — currently a demo, not a dashboard.

### (j) Bets feed — **PARTIAL (sessions, not bets)**
- **File:** `SessionsTabView.swift`. Read-only sessions list aggregated from `analysis.sessionDetection?.sessions` across all reports (deduped, newest-first): date/day/grade, start/end/duration, bet count, signed P/L, heat signals. **Tap does nothing** ("detailed session view parked for v1.1", `:12`).
- **No individual-bets feed.** Web `app/(dashboard)/bets/page.tsx` is a full filterable/sortable bets table with CRUD, manual entry, bulk delete. iOS has no `/api/bets` endpoint and does not hit Supabase directly (noted in `IOS_POLISH`/PROGRESS: the `BiasEvidenceSheet` per-bet list was deferred for exactly this reason).
- ⚠️ **Engine dependency:** session grades/heat signals rebase under WS-TEMPORAL (the −5 "after 11pm" deduction re-bases; date-only rows excluded → session counts drop).
- **Feel:** native list, non-interactive.

### (k) Settings — **EXISTS (native)**
- **File:** `SettingsView.swift`. Sign out; Delete account (→ confirm → `AccountDeletionService`); Privacy Policy + Terms links; 1-800-GAMBLER (`tel:`) + ncpgambling.org; Behavioral Patterns Glossary (`GlossaryView`); version/build + disclaimers.
- **Gaps vs web settings:** no bankroll setting, no subscription management UI, no email-preference toggles, no data export, no notification toggles. Web `settings/page.tsx` has all of these.
- **Feel:** native, minimal.

### (l) Retention (push + email) — **PARTIAL (push only; email is backend-side)**
- **Files:** `PushPermissionView.swift`, `Services/DeviceTokenClient.swift`, `Services/PushTokenStore.swift`, `Services/DeepLinkRouter.swift`, `Services/BetAutopsyAppDelegate.swift`.
- **Push:** primer modal after first report viewed (one-time, never re-prompts); APNs registration; tap routing only for `kind == "heated_session"` → `ReportFetchClient.fetch(id)` → fullScreenCover. Token upsert `POST /api/device-tokens` (env hardcoded `"sandbox"`). Web heated-push send path (`lib/push-heated*.ts`) fires from analyze via `waitUntil`.
- ⚠️ **Spec deviation:** `PushPermissionView` requests **full** `[.alert,.sound]` authorization, but CLAUDE.md mandates **provisional only** (`UNAuthorizationOptionProvisional`) for v1. Flag for review.
- **Email:** entirely backend (web crons: weekly digest, weekend autopsy, 7-email onboarding drip, welcome). No iOS surface — correct (email is server-driven), but iOS has no in-app email-preference control.
- **Feel:** native push plumbing; thin.

---

# R2 — Gaps and surprises

## Web journeys missing or partial on iOS (the real "match web" scope)
| Journey | iOS status | Note |
|---|---|---|
| Control System (rules/cooldowns/recovery) | **MISSING** | Largest gap; underpins enforcement check-in + recovery tone |
| Enforcement-aware check-in | **PARTIAL** | Consumes old v1 shape; ignores `actionGate`/`ruleViolations`/`cooldown`/`reflectionPrompts` |
| Ask Your Autopsy (Q&A) | **MISSING** | Web `POST /api/ask-report` (Claude Haiku), paid-only |
| Paste ingest | **MISSING** | Web `/api/parse-paste` |
| Screenshot/OCR ingest | **MISSING** | Web `/api/parse-screenshot` |
| Real dashboard (PnL/stats) | **PARTIAL** | `TodayView` is mock data; no `dashboard_stats` equivalent |
| Individual bets feed + CRUD | **MISSING** | Web `bets/page.tsx`; no iOS `/api/bets` |
| Upload-vs-upload compare (Pro) | **MISSING** | Web `uploads/compare` |
| Uploads history (rename/re-analyze) | **MISSING** | Web `uploads/page.tsx` |
| In-report Adopt-Rule / Start-Cooldown | **MISSING** | Web `ReportControlSystem` |
| Settings: bankroll / subscription mgmt / email prefs / export | **MISSING** | Web `settings/page.tsx` |
| Richer SSE progress UX | **PARTIAL** | iOS shows spinner + label flip only |
| In-app email preferences | **MISSING** | Backend-only on both, but web exposes a toggle |

## Drift the other direction (iOS has, web lacks)
- **Sign in with Apple** — iOS-only; web is email/password + Google OAuth. (Both legitimate; not a bug, but a real divergence.)
- **BetDNA quiz + archetype reveal as onboarding** — iOS runs the quiz pre-auth as an "earn-the-ask" onboarding; web has the quiz as a standalone lead-gen page (`/quiz`), not in the auth flow.
- **Section-decomposed report architecture** — iOS reader is cleanly split into 6 sections + ~40 cards; web is a single 199KB monolith. iOS is the better-factored side here.
- **Disk-backed cache-first ReportStore** — instant cold-launch report render (PR #29); a native-only capability.

## Endpoint / API-base health
- iOS base `https://api.betautopsy.com` is **correct and current** (intentionally `api.` to preserve Bearer across redirect). No stale base found.
- iOS hits 8 endpoints (R0); all exist on web. **No iOS call points at a removed endpoint.**
- **`device-tokens` env is hardcoded `"sandbox"`** (`DeviceTokenClient.swift`) — must flip to production for TestFlight/prod APNs.
- **Check-in is the one endpoint whose contract has grown** under iOS: iOS decodes the v1 subset of a now-richer response (not broken, but incomplete).

## State of the 4 known v1 items
1. **Render audit (safe-area / back-button):** `IOS_POLISH.md` shows a multi-branch polish log (PageStack mechanism, root-cause fixes) — render work has been actively done. No open safe-area/back-button defect was found in this read-only pass, but a device smoke pass on the live report path is still owed (memory: What-If device smoke deferred).
2. **Snapshot-loosen:** This is the **web-side LOOSEN (sufficiency-floor) workstream** — engine-side, *not yet landed*, and it **blocks WS-TEMPORAL**. iOS reads `insufficient_data` flags today; the reader-side `insufficient_data` fixes are explicitly deferred to LOOSEN. Not an iOS-only item.
3. **WhatChanged first-report hide:** ✅ **DONE** — `SectionVerdict.swift:94` renders `VsLastReportCard` only when a prior report exists.
4. **TestFlight-prep:** Not complete. Open items: device-tokens env → production; provisional-push spec deviation; `account_deletion` edge function deploy status unverified; the mock `TodayView` data; the iOS units/scale display bug (below).

## Surprises worth flagging
- **iOS units/scale display bug** (from web PROGRESS.md `:1004-1019`): native iOS double-multiplies an already-`0..100` value, producing "4,872%" / "-2,412pp". Fix lives in the iOS repo, independent of engine work. **Verify and fix before TestFlight.**
- **iOS Ch-7 "$0 projected next 90 days"** is hardcoded copy (web PROGRESS `:708`). Once WS-NUMERIC N7 ships deterministic per-bias costs, this can be computed for real or should be hidden.
- **`TodayView` mock data** will read as broken/dishonest to a real user (hardcoded "$2,847") — higher-priority than its "demo polish" status suggests.

---

# R3 — Three lists (no effort estimates)

## List 1 — Minimum to a TestFlight-able build (focused report + check-in path)
What is actually broken/incomplete on the core flow a first user hits:
1. **Flip `DeviceTokenClient` APNs env** from hardcoded `"sandbox"` to production (or environment-derived).
2. **Fix the iOS units/scale display bug** ("4,872%" / "-2,412pp" double-multiply of a 0..100 value).
3. **Replace `TodayView` mock data** with real values (or hide the fake numbers) — hardcoded BetIQ "87" and "$2,847" verdict cannot ship.
4. **Resolve the provisional-push spec deviation** — `PushPermissionView` requests full auth; decide provisional-only per CLAUDE.md or get explicit sign-off.
5. **Verify `account_deletion` edge function is deployed** (App Review 5.1.1(v) requires real deletion, not just local sign-out).
6. **Device smoke the live report + check-in path** end-to-end on a real device with a fresh full-report upload (What-If card, snapshot→unlock swap, vs-last-report).
7. **Hide or fix the hardcoded "$0 projected next 90 days"** Ch-7 copy.
8. **Confirm `bets.result` is decoded leniently** (String, not a strict enum) so the incoming `cashed_out` value won't break decode — see §3 below.

*Note: TestFlight does NOT require the engine workstreams. Per web PROGRESS, temporal/numeric gates App Store submission, not TestFlight; LOOSEN is the iOS critical path that lands first.*

## List 2 — Full "match web natively" scope (every R2 gap to reach journey parity)
- **Control System** (the big one): control center UI, rules list + adopt-suggested + author-custom, manual cooldown, recovery-mode toggle/banner; consume `GET|POST /api/control-system`.
- **Enforcement-aware check-in**: decode + render `actionGate`/`ruleViolations`/`cooldown`/`reflectionPrompts`/`overrideRequired`; implement the `blocked`/`reflection_required` gates and override-with-reason flow (write `/outcome` override path).
- **Ask Your Autopsy**: conversational Q&A surface against `POST /api/ask-report` (paid-only, rate-limited).
- **Ingest parity**: paste parser + screenshot/OCR ingest (`/api/parse-paste`, `/api/parse-screenshot`).
- **Real dashboard**: wire a `dashboard_stats` equivalent for live PnL/win-rate/ROI/grade on `TodayView`.
- **Bets feed**: individual-bets list (requires a `/api/bets` endpoint — not yet present) + optional CRUD/manual entry.
- **Uploads history**: list, rename, re-analyze, multi-select; upload-vs-upload compare (Pro).
- **In-report control actions**: Adopt-Rule / Start-Cooldown buttons (`ReportControlSystem`).
- **Settings parity**: bankroll, subscription management, email-preference toggles, data export.
- **Richer analysis progress UX**: surface live SSE `metrics` instead of a static spinner.
- **Report depth tail**: `edge_profile`/Ch-6 and Ch-7 projection (currently v1.1-deferred).

## List 3 — Engine-dependency flags (sequence iOS parity AFTER the engine settles)
Every iOS surface that will need to change when WS-TEMPORAL / WS-NUMERIC land. **Both workstreams bump `schema_version` 2→3.**

**Hard cross-repo gates (must do BEFORE web ships):**
- ⚠️ **`cashed_out` result value (WS-NUMERIC N2):** web widens `bets.result` to include `cashed_out`. Additive on the wire, but **if any Swift enum decodes `result` strictly, iOS needs a one-case PR before web ships N2.** Verify iOS decodes `result` as `String`. (Tracked web Notion `37b5964c-daf2-81ba-b790`.)
- ⚠️ **schema_version 2→3 annotation (both workstreams):** the iOS WhatChanged / `SectionVerdict` surface must tolerate `methodology_changed: true` and **suppressed numeric deltas** (betIQDelta, emotion, discipline, estimated_cost) across the version boundary, while still showing archetype-name + bias presence/absence deltas. Caption copy: *"Scoring methodology updated since your last report — score deltas resume next report."* iOS reader change must land **before/with** the first value-changing engine PR.

**Output fields iOS renders that get recomputed (expect value shifts, plan visual/copy review):**
- ⚠️ **Late-night biases** (`Late-Night Betting`, `Sustained Late-Night Concentration`): large prevalence drop. Reports currently showing these on iOS won't reproduce them. Affects `SectionPatternsTiming`, `TiltSessionCard`/`HeatedSessionPreviewCard` trigger chips, and the **check-in late-night flag**.
- ⚠️ **`timing_analysis.by_hour`**: recomputed (excludes `date_only` rows); new `time_bearing_bet_count`, `timezone_basis`. iOS timing charts in `SectionPatternsTiming`.
- ⚠️ **Session grades / `session_detection`**: −5 "after 11pm" deduction re-bases → sessions regrade → different top heated sessions; `date_only` rows excluded → session counts drop. Affects `SessionsTabView`, heated cards, `_snapshot_teaser.sessionGrades/heatedSessionCount`.
- ⚠️ **Post-loss → "rapid-fire escalation" rename**: bias name + session heat-signal descriptors change. Affects bias rows, tilt signals, and the check-in post-loss flag.
- ⚠️ **`summary.roi_percent`** (resolved-set denominator) and **`win_rate`** (pushes removed): values change. Affects `VitalsStripCard`, any future dashboard.
- ⚠️ **Cash-out P&L** (`result: cashed_out` first-class): P&L totals shift; excluded from win-rate/calibration. Historical cash-outs unrecoverable.
- ⚠️ **`biases_detected[].estimated_cost` becomes deterministic (N7):** dollar values shown in `DamagesCard`/`LeakPrioritizerCard`/`BiasEvidenceSheet`/`LockedDollarBar` change; makes snapshot blur honest and WhatChanged cost-deltas meaningful. Unblocks real Ch-7 projection.
- ⚠️ **`betiq.score` + `timing` component**: move indirectly via win-rate/ROI input changes and timing re-base. Affects `HeroRingView`/`BetIQComponentBars`.
- ⚠️ **`what_if_scenarios`** (odds=0/non-finite guards; `excluded_bet_count`): re-check the `WhatIfCard` scenario-3 dual-guard after the numeric PR (web watch-item).
- ⚠️ **New additive per-bet fields** (`timestamp_quality`, `settled_at`, `time_bearing_bet_count`, `timezone_basis`, `excluded_bet_count`): all optional, iOS Codable ignores safely — but are available to surface if desired.
- ⚠️ **Check-in scorer inputs** rebase (late_night_stats, post-loss bias) — even without adopting enforcement fields, the existing iOS check-in flags will change behavior when the engine lands.

**Sequencing recommendation:** land List-1 (TestFlight) now — it is engine-independent except the one `cashed_out` decode check. Hold List-2 control-system + dashboard + bets work until LOOSEN → TEMPORAL → NUMERIC settle, since those surfaces read exactly the fields being recomputed. The two hard gates (cashed_out decode, schema_version annotation) are the only iOS changes that must be coordinated *with* the engine timeline rather than after it.

---

*Sources: iOS `/Users/Andrew/betautopsy-ios` (read-only); Web `/Users/Andrew/betautopsy` incl. `ENGINE_HARDENING_OUTLINES_2026-06-10.md`, `types/index.ts`, `PROGRESS.md`, `app/api/*`, `components/AutopsyReport.tsx`, `lib/control-system.ts`, `lib/check-in-scorer.ts`. No files modified.*
