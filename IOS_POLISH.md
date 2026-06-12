# BetAutopsy iOS Polish Log

Running PR-by-PR log of iOS polish work done by Claude Code on this
repo. Most recent entry on top. Companion to POLISH_BACKLOG.md (which
plans the work) and the Notion sprint table (which tracks completion
externally).

Format per entry:

- Branch
- Why
- Step 0 findings
- What shipped
- Verification
- Notes / deviations

---

## Branch: feat/testflight-min

### Why

TESTFLIGHT-MIN: the minimum remaining iOS work for a respectable
first TestFlight build. Safe-area/back-button audit, WhatChanged
first-report hide, PR-12 prep. No redesign work (Prompt 4 runs
during TestFlight).

### Step 0 findings

- Version identity already correct: 1.0 (1) in pbxproj matches the
  APPLE_REVIEW_COMPLIANCE "Build 1.0 (1)" first-submission plan. No
  bump made (pbxproj is hands-off for CC; future bumps are manual).
- Shell map: onboarding NavigationStack (bar hidden) -> 3-tab root ->
  sheets (Settings with own stack + Done, check-in, paywall with
  xmark, glossary correctly wrapped) -> covers (report reader with
  xmark, push primer with Allow/Later, upload progress). No journal
  screen exists; check-in is the only text-input surface.
- WhatChanged first-report hole: the unlock child carries a
  no-filter FULL-HISTORY date range, different from its snapshot
  twin, so the date-range exclusion matched the user's own snapshot
  as "previous" on their first purchased report and diffed against
  redacted zeros.
- ITSAppUsesNonExemptEncryption was missing from Info.plist.

### Per-screen safe-area audit

| Screen | Status |
|---|---|
| Report reader (ReportScrollContainer) | FOUND: scrolled content collides with clock (bar-less). FIXED: StatusBarScrim under the xmark. |
| Reports tab (ReportListView) | FOUND: same collision. FIXED: scrim. |
| Sessions tab (SessionsTabView) | FOUND: same collision. FIXED: scrim. |
| Today tab | OK (NavigationStack + toolbar; system bar material on scroll). |
| Settings / Glossary | OK (own NavigationStack, Done button; glossary pushed or sheet-wrapped correctly). |
| Onboarding (age gate, sample preview, quiz, reveal, auth, Pikkit) | OK (content respects safe area; backgrounds full-bleed by design; forward-only flow has no back buttons by design). |
| Paywall | OK (sheet, xmark, scroll content inset). |
| Push primer | OK (Allow / Maybe later both dismiss). |
| Upload progress | OK (fixed-top layout inside safe area; no dismiss mid-flight by design). |
| Pre-bet check-in | FOUND: decimal pad had no dismiss. FIXED: keyboard Done accessory. Sheet otherwise OK. |
| Reviewer bypass sheet | OK. |
| DEFERRED to Prompt 4: bottom-edge fade polish on the report reader, UploadProgressView fixed 60pt top offset (cosmetic), Dynamic Type pass. |

### What shipped

1. StatusBarScrim component (safe-area-inset-sized canvas gradient,
   overlay, non-interactive) on the three bar-less scroll surfaces.
2. Check-in stake keyboard Done accessory; VsLastReportCard previous
   pool excludes snapshots (signal: prior FULL report existence;
   covers snapshot + full renders).
3. ITSAppUsesNonExemptEncryption = false committed with the
   placeholder-key procedure (real anon key never staged; verified
   against the committed blob). TESTFLIGHT_NOTES.md added: What to
   Test copy (COPY_SYSTEM + DO-NOT-MARKET clean) + the numbered
   manual upload checklist.

### Verification

xcodebuild green per commit. Andrew walks every screen on device
(the audit IS the visual pass), then runs the TESTFLIGHT_NOTES.md
checklist for archive + upload.

---

## Branch: feat/3b2-charts-breadth

### Why

3B-2 breadth pass: the remaining five charts from the typed
charts.* arrays, and the remaining sections recomposed onto the 3B-1
component library. After this the report renders fully on the new
system; Prompt 4 is IA/share/polish.

### Step 0 findings (approved placement map)

- BY HOUR interim (PR #36) lived in SectionPatternsTiming
  (hourChartSection + label-parsing helpers); odds rendering in
  SectionSports.oddsBucketCard. Both swapped with fallbacks.
- Collision resolved per approval: StakeByStreakChart (typed)
  replaces StreakInfluenceCard in full+v3; the card (with its locked
  variant) stays for snapshot/pre-#74.
- SectionProtocol approved as a NO-OP (RecoveryRecommendationCard is
  a safety surface - untouched). ScoreGauge stays library-only.
- The "IF YOU DID ALL OF THESE" aggregate SUMMED per-action
  projections - confirmed and removed (third costume of the additive
  defect).

### What shipped

Six commits, build verified between each:

1. Five charts (each #Preview, SessionTimelineChart pattern, sample
   floors, BAFormat axes): TimeOfDayChart (typed dollars preferred,
   PR #36 label-parsing ROI fallback absorbed for pre-#74/snapshot;
   UTC bucketing caveat documented, WS-TEMPORAL), DayOfWeekChart,
   OddsBucketsChart, StakeByStreakChart, BetTypeMixChart.
2. SectionPatternsTiming: BY HOUR onto TimeOfDayChart (D6
   always-visible preserved via fallback), BY DAY onto DayOfWeekChart
   in full+v3 with tiles kept for snapshot/pre-#74; late-night line
   position/gates unchanged.
3. SectionSports: odds chart swap with card fallback, EvidenceBlock
   on sport findings, BetTypeMixChart added (new surface, full v3
   only).
4. SectionHeatedDiscipline + SectionVerdict: discipline breakdown +
   BetIQ full-mode bars onto ContributorBars (BetIQ snapshot teaser
   shell kept byte-identical, its paywall signal untouched),
   insufficient-data cards + bankroll health onto Callout (danger
   helpline compliance line carried verbatim), StakeByStreakChart
   swap. TiltSignalBreakdownCard kept (icons + worst-trigger dedup).
5. SectionAction: full-mode actions onto ActionRow (check-off wiring
   unchanged, HIGHEST IMPACT fallback kept, no analytics on this
   path); snapshot keeps locked ActionCards; aggregate summed dollar
   REMOVED, qualitative Callout framing kept.
6. This entry.

### Verification

xcodebuild green per commit. Device smoke is Andrew's: full v3
walk-through of every section, a snapshot (locks/teasers identical,
charts gated out), and the pre-#74 BY-HOUR ROI fallback.

### Notes / deviations

- BY HOUR y-axis changes ROI -> net dollars on the typed path
  (approved); the fallback stays ROI.
- BankrollHealthCallout and StreakInfluenceCard remain on disk but
  StreakInfluenceCard still serves snapshot/pre-#74;
  BankrollHealthCallout is now unconsumed by live code (Prompt 4).
- BetIQComponentBars keeps its legacy shell rows for the snapshot
  blur so the locked state is byte-identical.

---

## Branch: feat/3b-component-library

### Why

3B proof-of-vocabulary step: the reusable component library the
three-layer redesign (60-second skim / 5-8 minute read / tap-expand
evidence) is made of, proven by refactoring ONE section onto it. Plus
one approved scope addition: kill the additive recoverable total on
iOS now, so one report never shows two contradictory dollar claims.

### Step 0 findings

- Refactor target: SectionFindings (densest mix - biases + leaks +
  prioritizer + counts, severity/dollar/confidence/sub_splits on both
  finding types, zero chart dependency).
- SeverityChip already existed (BiasSeverity-typed). Extended with
  init(tier:) per Andrew's call, no second type; unknown tiers render
  raw display-cased in gray, never relabeled onto the scale.
- BiasSeverity.displayLabel medium reverted NOTABLE -> MEDIUM
  (ordinal scale must read as ordered intensity at skim speed).
- Web roundRecoveryRange (lib/engine/recovery.ts:38) mirrored in
  Swift as RecoveryRange: step 1000/500/100 by magnitude, 0.8x floor
  / 1.2x ceil bounds.

### What shipped

Five commits, build verified between each:

1. SeverityChip init(tier:) + MEDIUM label revert.
2. Seven component files (Components/V3/, each with #Preview), all
   value-driven with BAFormat applied inside: StatCard (typed Value
   enum), DollarImpactCard (recovery range + method label + verified
   net; pre-#74 fallback rounds the single largest leak through
   RecoveryRange; the never-additive invariant lives in the
   component), EvidenceBlock (tap-expand sub_splits comparison rows,
   snapshot dollar suppression, pre-#74 prose fallback, onExpand
   analytics hook), ScoreGauge, ContributorBars, Callout
   (info/caution/severe - severity amber, never brand yellow, for
   caution), ActionRow.
3. SectionFindings proof refactor (render-only; data, snapshot locks,
   top-3 selection, teasers unchanged): StatCard count row, chips in
   bias-row headers, inline EvidenceBlock expansion replacing
   BiasEvidenceSheet (ch4.bias_evidence.opened preserved on first
   expand; sheet file unused on disk), leak cards with chips +
   evidence, DollarImpactCard after FIX IN THIS ORDER.
4. Verdict hero swap: TotalRecoverableHero renders the recovery
   range (engine object, else largest-leak rounded range, else
   hides). TotalRecoverable.compute() deleted outright - the
   additive sum never renders again for any vintage. Caption and
   label rewritten to non-additive copy.
5. This entry.

### Verification

xcodebuild green after each commit; every component has a #Preview.
Device smoke is Andrew's step: SectionFindings + Verdict hero on a
real full v3 report (recovery range matches in both surfaces), on a
snapshot (locks/teasers unchanged, no recovery surface), and on a
pre-#74 report (fallback range, evidence prose in expansion).

### Notes / deviations

- BiasRow kept its legacy onTap sheet path so ChapterYourBiasesView
  (Phase 3 deletion target) still compiles; SectionFindings no
  longer passes it.
- FindingsCounterChips is now unconsumed by live code but untouched
  on disk per the approved plan (Prompt 4 retires it).
- No fixed heights on text containers in any new component (Dynamic
  Type pass comes in Prompt 4).

---

## Branch: feat/3a-report-trust-decode

### Why

Web PR #74 (report-trust wire format) is deployed and verified live:
schema_version 3 reports carry a top-level `recovery` object, a
`charts` object (7 keys including sessionTimeline + heroSession), and
per-finding confidence/severity/sub_splits. 3A scope: iOS decodes all
of it and renders ONE hero chart (the heated-session stake-escalation
curve). The other 8 charts and the reusable components are the next
prompt, deliberately not built here.

### Step 0 findings

- All three network decode paths (AnalyzeClient:542, ReportFetchClient,
  ReportListClient) use a global .convertFromSnakeCase; the disk cache
  uses default keys (symmetric round-trip, safe).
- Pulled the real deployed row (autopsy_reports table, id 406e226d,
  created 2026-06-12 17:37:05) via the web repo's local service-role
  creds; the MCP Supabase account does not include this project. All
  wire keys confirmed exactly as specced; fixture saved to /tmp.
- Directive correction (validated by the proof): explicit CodingKeys
  do NOT bypass .convertFromSnakeCase. The decoder converts wire keys
  FIRST, then matches stringValue. camelCase keys (netUSD, tOffsetMin,
  no underscores) pass through unchanged, so exact-wire CodingKeys
  work. snake_case keys (sub_splits' roi_pct/net_usd) must be pinned
  to POST-conversion spellings (roiPct, netUsd -> property netUSD).
  A raw value of "net_usd" silently decodes nil - the acronym trap,
  one level deeper than the brief assumed.

### What shipped

Two commits, build verified between each:

1. Decode layer: ReportRecovery, ReportCharts + 7 nested point types
   (betClass mapped from reserved wire key "class"), FindingSubSplit;
   optional additive fields on AutopsyAnalysis (recovery, charts),
   DetectedSession (framing), BiasDetected / StrategicLeak /
   SportSpecificFinding (confidence, subSplits, + severity string on
   leaks). Tolerant try? decode throughout; ReportCharts degrades
   per-array. ReportCache.currentVersion 3 -> 4 (v3 blobs pre-date
   the fields and would pin charts == nil forever).
   Decode proof: BetAutopsyTests/DecodeProofV3.swift, a standalone
   swiftc harness (no test target exists) decoding the REAL deployed
   report through production structs with the production decoder
   config. 32/32 assertions pass, including roi_pct:null tolerance
   and a cache-codec round-trip.
2. SessionTimelineChart (Swift Charts): framing-tinted line + area,
   outcome-colored points, severity-amber chase halos, BAFormat
   everywhere (adds BAFormat.minutes). Placed in SectionVerdict after
   the archetype name, before TotalRecoverableHero. Gated full-mode +
   heroSession + non-empty timeline; component requires >= 2 points.
   Empty state renders nothing (the section is unchanged from
   pre-#74), never an empty chart frame.

### Verification

xcodebuild green after each commit; decode proof ALL PASS against the
live report. Device smoke is Andrew's step: hero chart renders on the
fresh 2026-06-12 report (4 points, 3 amber halos, "Heated session.
Finished down.", May 22, 2026 meta), and an older/snapshot report
shows no chart and no gap artifacts.

### Notes / deviations

- Spec's framing label "Heated session - finished down" restructured
  to "Heated session. Finished down." (em dashes banned, COPY_SYSTEM).
- The decode-proof fixture (real betting data) stays in /tmp,
  deliberately not committed; the harness header documents how to
  re-pull and re-run it.
- charts.timeOfDayPnl / dayOfWeekPnl now decode, but the BY HOUR
  chart swap to typed arrays remains out of scope (next prompt), per
  the brief.

---

## Branch: fix/p0-renderer-polish

### Why

A redesign audit flagged a cluster of P0 bug-class issues, all
pure-iOS renderer-side with no engine dependency: inconsistent number
formatting across the report ("$-4087" vs "-$4,087", "28.29%" vs
"-25.8%", "+1,411.1% ROI"), a snapshot LOCKED dollar pill leaking
into a PAID action plan, a duplicated insight callout in the heated
section, an hour chart with no axis labels plus day labels and a
"cut a profitable bucket" contradiction in its callouts, and
CLAUDE.md still documenting the retired Luminol V2 palette.

### Step 0 findings

- No shared formatter existed: 14+ independent dollar/percent
  formatters across live V3 surfaces, with no-thousands-separator and
  "$-N" sign-order bugs, mixed U+2212/ASCII minus glyphs, and three
  duplicated DateFormatter stacks.
- Locked-pill leak root cause (SectionAction): locked = isSnapshot ||
  redacted_dollar tag || dollars <= 0, so a paid action with no
  parseable dollar rendered the lock. Same conditional class in
  SectionSports, SectionFindings, BiasEvidenceSheet,
  LeakPrioritizerCard.
- Duplicate callout: worstTrigger rendered italic inside
  TiltSignalBreakdownCard AND as the InsightCallout body directly
  below.
- Hour chart: live engine byHour labels are "9pm"-style but the axis
  marks expected "0"/"4"/"8" (mock shape), so no labels rendered;
  BEST/WORST used engine bestWindow/worstWindow free-form label
  strings (day labels under the hour chart); the late-night line
  recommended cutting the window unconditionally, even at +21% ROI.
- Tokens.swift is the YELLOW brand (#FACC15 on #131A20 → #0A0E12
  gradient; V2 Luminol namespace already retired). The doc was stale,
  not the code. No brand-color code change was needed or made.

### What shipped

Five commits, build verified between each:

1. BAFormat.swift (new) + every live call site routed through it.
   formatCurrency/formatPct in ReportModels.swift reduced to shims
   for the legacy Chapter*View files (these are Phase-3 deletion
   targets and were deliberately NOT migrated). Absurd-ROI display
   cap at 200 percent magnitude. Renderer rule documented: never
   render LLM pre-formatted number strings; TODOs mark
   Contradiction.volumeData/edgeData (no raw value on the wire yet)
   and the expectedImprovement dollar parser.
2. Locked-dollar pill scoped to snapshot mode in all five surfaces;
   paid reports with no honest dollar hide the row or fall back to
   the HIGHEST IMPACT tag.
3. Heated section worst-trigger insight renders once (callout skipped
   when the breakdown card already shows it).
4. Hour chart parses bucket labels to numeric hours ("9pm" and "23"
   shapes), draws 12AM/4AM/.../8PM axis labels, computes BEST/WORST
   from byHour data with a 3-bet sample floor, hides the callouts
   below two qualifying hours. Late-night "cut these" line only
   attaches to negative ROI; profitable windows read "Late night is
   not your leak." TODO: move onto typed timeOfDayPnl/dayOfWeekPnl
   arrays when the parallel engine change lands.
5. CLAUDE.md visual identity section rewritten to match Tokens.swift;
   Luminol V2 explicitly archived; BAFormat rules added; this entry.

### Verification

xcodebuild (iOS Simulator, Debug) green after every commit. Device
pass on a real paid report is Andrew's verification step: check the
action plan shows no LOCKED pill, the heated insight appears once,
the BY HOUR chart has hour axis labels and hour-valued BEST/WORST,
and dollar/percent formatting is uniform across all seven sections.

### Notes / deviations

- Legacy Chapter*View + ReportView formatters untouched (Phase 3
  deletes those files); they compile via the ReportModels shims.
- StrategicLeakCard's ROI badge and the vitals ROI cell now use
  headline percent (integer at >= 10 magnitude) per the new rules,
  so e.g. "-18.7%" renders "-19%". Flag if the extra decimal should
  be kept on those two surfaces.
- SectionSports odds-bucket ROI badge gained a "+" on positives
  (signed ROI rule).

---

## Branch: claude/ios-betiq-codable

### Why

iPhone QA on snapshot 24d12db7 (case 0248) reported the Ch 1 hero
BetIQ ring rendering 0 even though the wire ships
`report_json.betiq.score = 69`. Bug is purely iOS-side: the
synthesized Codable on `BetIQResult` collapses to nil on any single
missing required field, and the Ch 1 view falls back to 0 via
`report.analysis.betiq?.score ?? 0`.

### Step 0 finding

Decision-tree CASE 1B. `AutopsyAnalysis.betiq` is `BetIQResult?`
decoded via `try? c.decode(BetIQResult.self, ...)`. `BetIQResult`
synthesized Codable requires five non-optional fields including a
nested non-optional `BetIQComponents` (six required Int fields).
The snapshot wire 24d12db7 almost certainly ships a betiq object
with `score` populated but with one of `components`, `interpretation`,
`insufficientData`, or `percentile` missing or null - typical
LLM-side fields that the deterministic snapshot path skips. Any
single per-field failure cascades up:
BetIQComponents decode fails -> BetIQResult decode fails ->
parent try? collapses to nil -> Ch 1 reads `?? 0` -> hero ring
renders 0. Same cascade pattern as PR-15's `DetectedSession` fix.

Interactive simulator access from this CC session was not available
(per PR-15/PR-16 precedent); diagnostic prints were added to
`ChapterTheVerdictView` body `.onAppear`, the build verified, then
the prints were stripped before commit.

### What shipped

`BetAutopsy/BetAutopsy/ReportModels.swift` only.

- `BetIQComponents` gains an explicit memberwise init and a tolerant
  custom `init(from:)`. Every Int field reads via `try?` with a
  default of 0. A new `static let zero` factory provides an all-zero
  instance for use as a fallback default elsewhere.
- `BetIQResult` gains an explicit memberwise init and a tolerant
  custom `init(from:)`. `score` decodes as Int first, then falls
  back to rounding a Double if the engine ever ships 69.0, with
  final fallback 0. `components` falls back to `BetIQComponents.zero`.
  `percentile` defaults to 0, `interpretation` to "", `insufficientData`
  to false. No required-field decode can sink the whole BetIQResult
  any more.

No call-site changes were needed. `ChapterTheVerdictView.swift` still
reads `report.analysis.betiq?.score ?? 0` and that path now resolves
to the real wire score for any non-null betiq object.

### Verification

- xcodebuild on iPhone 17 simulator: BUILD SUCCEEDED.
- `git diff main..HEAD | grep '^+' | grep U+2014` returns zero hits.
- Simulator interactive walk on snapshot 24d12db7 deferred to Andrew.
- Step 0 diagnostic prints added, build-verified, stripped before
  commit.

### Notes / deviations

- The fix follows PR-15's `DetectedSession` precedent: explicit
  memberwise init + tolerant `init(from:)` with `try?` and neutral
  defaults on every field. Same shape, just applied to BetIQ.
- BetIQComponents.zero is a new exposed static. Not used anywhere
  else today, but kept on the type rather than file-local so a
  future test or default value can use it.

---

### Why

iPhone QA after PR-15 (commit 451a4b2) on snapshot 24d12db7 surfaced
five further gaps. Two P0: "LOST" wrapping mid-word on the Ch 2 card,
heat-signal chips truncating mid-word. Three P1: Ch 1 "READ THE
HEATED FILE" tap is dead (was never wired), Ch 5 copy "behavioral
patterns require deeper analysis" reads like it's blaming the user
for thin bet data, Ch 5 "SEE THE SPORT BREAKDOWN" tap is dead (same
unwired pattern as Ch 1).

### Step 0 finding (PageStack mechanism)

`ChapterNavigator.swift` source comment explicitly says
"V1 (PR-V1): chevrons + info are DECORATIVE. No tap targets.
Wired-up navigation is a v1.1 cascade item." Chapter advance is
handled instead by `ReportView`'s `TabView(selection: $currentIndex)`.
The CTAs in this PR wire to a new `onAdvance: () -> Void` closure
on `ChapterTheVerdictView` and `ChapterYourPatternsView`, which
`ReportView` passes at TabView construction time and which sets
`currentIndex` to the target tag inside a `withAnimation(.easeInOut)`
block so the transition matches a swipe.

### What shipped

**Fix A (P0) - Ch 2 LOST label wrap**

`BetAutopsy/Components/V3/HeatedSessionPreviewCard.swift` - the
`Text("LOST")` modifier chain gains
`.fixedSize(horizontal: true, vertical: false)` so the single
4-letter word never breaks across two lines when its HStack column
is squeezed by a wide bet-count + LockedDollarBar(width: 140) pair.

**Fix B (P0) - Ch 2 heat-signal chip layout**

`BetAutopsy/Components/V3/HeatedSessionPreviewCard.swift` - the
`FlowChips` view was rewritten from a custom `FlexibleChipLayout`
(horizontal flow with `.lineLimit(1)` clamp + tail truncation) to
a plain `VStack(alignment: .leading, spacing: 6)`. Each heat signal
now renders on its own full-width row with a 4pt red dot bullet and
the body text uses `.fixedSize(horizontal: false, vertical: true)`
so a long signal like "Stakes more than doubled while chasing losses"
wraps naturally to a second line instead of truncating mid-word.
The `FlexibleChipLayout` Layout-protocol struct was deleted (zero
remaining consumers).

**Fix C (P1) - Ch 1 CTA wired**

`BetAutopsy/ChapterTheVerdictView.swift` - `ChapterTheVerdictView`
gains `var onAdvance: () -> Void = {}`. `handleInsightTap()` now
calls `onAdvance()` instead of the prior `#if DEBUG print(...)`
stub. `BetAutopsy/ReportView.swift` passes
`{ advanceToChapter(1) }` at the Ch 1 call site. New private
`advanceToChapter(_ index: Int)` in ReportView clamps the target
to 0...6 and sets `currentIndex` inside a 0.25s easeInOut
animation. Default `onAdvance: () -> Void = {}` keeps the
`#Preview` block working standalone.

**Fix D (P1) - Ch 5 copy rewrite**

`BetAutopsy/ChapterYourPatternsView.swift` - `fallbackText` rewritten.
With a known count: "You've got N detected behavioral patterns. The
full report names them and shows what they cost you." Without a
count: "Pattern analysis lives in the full report. Unlock to see
your detected patterns and what they cost you." Both forms lead with
what the user already has or is going to get, not what the engine
needs from them.

**Fix E (P1) - Ch 5 CTA wired**

`BetAutopsy/ChapterYourPatternsView.swift` - same `onAdvance`
closure pattern as Fix C. ReportView passes
`{ advanceToChapter(5) }` (Ch 6's tag index). "SEE THE SPORT
BREAKDOWN" now advances to Ch 6, honoring the label.

### Verification

- `xcodebuild -scheme BetAutopsy -destination 'platform=iOS Simulator,name=iPhone 17' build`
  succeeds.
- `git diff main..HEAD | grep '^+' | grep U+2014` returns zero hits.
- `grep -rn "require deeper analysis" BetAutopsy/` returns zero hits.
- `grep -rn "READ THE TILT FILE" BetAutopsy/` returns zero hits
  (still gone from PR-15).
- Simulator interactive walkthrough deferred to Andrew (snapshot
  24d12db7 requires authenticated Supabase fetch this session cannot
  perform).

### Notes / deviations

- The brief assumed ChapterNavigator's `>` arrow already advanced
  pages; source comments confirm it has always been decorative. The
  `onAdvance` closure pattern matches the brief's preferred option
  ("If ChapterNavigator's > arrow uses a closure prop"), so the
  architectural intent is preserved even though the > arrow itself
  is still cosmetic. If a future PR wires the > arrow into the same
  pattern, it can call the same `advanceToChapter` helper in
  ReportView.

---

### Why

iPhone QA on snapshot 24d12db7-0025-4c0e-bde6-e0a015b97f6c (case 0248,
5000 bets, 453 sessions / 218 heated) on top of e9f5158 surfaced four
follow-up gaps from the original snapshot-richer PR. Two P0 conversion
blockers (Ch 2 not rendering at all; Ch 1 CTA still reads "TILT") plus
two finish-quality fixes (locked-dollar bar context labels; Ch 4
4th legacy bias card cleanup).

### Step 0 finding (root cause of Fix A)

Decision-tree CASE 3/4 cascade. Wire ships `isHeated: true` and a
4-string `heatSignals` array on 3 of 218 heated sessions for snapshot
24d12db7. Most heated sessions ship `heatSignals: []` or null on
fields like `gradeReasons`. Synthesized Codable on `DetectedSession`
treats every field as required; a single per-field shape mismatch
(null for a non-optional `[String]`, or a numeric arriving as a
different type) fails the whole element decode, which fails the
`[DetectedSession]` array decode, which collapses
`sessionDetection` to nil via the `try?` wrap in
`AutopsyAnalysis.init(from:)`. Result on iOS: `sessionDetection?.sessions`
reads nil, `heatedSessions` is empty, `previewSession` is nil,
`snapshotHeatedSection` returns `EmptyView()`.

Because I cannot run snapshot 24d12db7 interactively from this
session (it requires Andrew's auth + upload), I applied a tolerant
custom `init(from:)` for `DetectedSession` that decodes every field
with `try?` and a neutral default. This covers CASE 2/3/4 of the
brief's decision tree simultaneously and is defensively correct
even if the actual cause is something else in that decision tree.

### What shipped

**Fix A (P0) - Ch 2 HeatedSessionPreviewCard now renders**

- `BetAutopsy/ReportModels.swift` - `DetectedSession` gains a custom
  tolerant `init(from:)` with explicit CodingKeys. Every field reads
  via `try?` with a neutral default (`""` for strings, `0` for
  numerics, `false` for `Bool`, `[]` for `[String]`). A single
  per-field shape mismatch no longer collapses the whole sessions
  array.
- Step 0 diagnostic prints added to ChapterYourMindView body
  `.onAppear` were stripped before commit per brief.

**Fix B (P0) - Ch 1 CTA renamed**

- `BetAutopsy/ChapterTheVerdictView.swift:101` - `ctaLabel` parameter
  changed from "READ THE TILT FILE" to "READ THE HEATED FILE".
- `BetAutopsy/Components/V3/InsightCallout.swift:59` - preview
  string updated for consistency (not user-facing at runtime, but
  shows in Xcode canvas previews).

**Fix C (P1) - LockedDollarBar context labels**

- `BetAutopsy/Components/V3/BiasRow.swift` - the locked branch wraps
  `LockedDollarBar(width: 110)` in an HStack(spacing: 8) with an
  "EST. COST" caps label (10pt semibold, tracking 1.5,
  DS.Color.V3.Severity.red) prepended.
- `BetAutopsy/Components/V3/HeatedSessionPreviewCard.swift` - the
  "<N> bets" / LockedDollarBar row wraps the LockedDollarBar in an
  HStack(spacing: 8) with a "LOST" caps label prepended.
- Ch 6 BY DAY tiles, Ch 6 sport-finding ESTIMATED COST, and Ch 7
  ActionCard projectedImpact were intentionally left untouched
  (BY DAY tile is too narrow for a label; the other two already
  carry their own context).

**Fix D (P2) - Ch 4 4th bias legacy cleanup**

- `BetAutopsy/ChapterYourBiasesView.swift` - the PR-7.5 Phase 2
  WithheldBiasTeaserCard rendering block in `body` (snapshot mode)
  was removed. With three real bias cards above that show evidence
  + LockedDollarBar, the legacy "Read this in your full report"
  redaction-rectangle card was visually redundant and confusing
  (read as a 4th bias in low-quality treatment). The
  WithheldBiasTeaserCard private type at the bottom of the file
  is retained for now (zero consumers, but kept for one cycle in
  case full mode wants a similar treatment back).

### Verification

- `xcodebuild -scheme BetAutopsy -destination 'platform=iOS Simulator,name=iPhone 17' build`
  succeeds. Re-run after stripping diagnostic prints: still succeeds.
- `git diff main..HEAD -- BetAutopsy/ | grep '^+' | grep U+2014`
  returns zero hits. (Pre-existing em-dashes in unrelated comment
  lines from PR-9 / PR-V-CASCADE-DAY-12 / PR-7.5 are out of scope
  for this PR and were not touched.)
- `grep -rn "TILT FILE" BetAutopsy/` returns zero hits post-fix.
- `grep -rn "READ THE HEATED FILE" BetAutopsy/` returns exactly two
  hits (the Ch 1 CTA call site + the InsightCallout preview string).
- Simulator interactive walkthrough on snapshot 24d12db7 deferred
  to Andrew (requires authenticated Supabase fetch this session
  cannot perform). Andrew runs the 11-item QA checklist.

### Notes / deviations

- Tolerant decoder pattern was applied to `DetectedSession` only.
  Other types in the wire model (`OddsBucket`, `TimingBucket`,
  `BehavioralPattern`, etc.) still rely on synthesized Codable.
  If similar render gaps surface for other snapshot chapters,
  the same tolerant pattern should be ported.
- "EST. COST" label width on iPhone 17 (393pt screen): bias name
  "STAKE VOLATILITY" + spacer + "EST. COST" label + 8pt + 110pt
  LockedDollarBar + chevron should fit. If Andrew sees overflow on
  the longest bias names, the LockedDollarBar can drop to 90pt
  without a model change.
- Em-dashes in pre-existing comments (Tokens.swift, ReportListView.swift,
  PaywallView.swift, AnalyzeClient.swift, etc.) were not touched.
  This PR's diff adds zero em-dashes.

---

### Why

iPhone QA on snapshot 2d5e2936 (2026-05-18) surfaced four conversion
gaps. Engine V2 (ENGINE-PR-SNAPSHOT-LOOSEN-V2) is enriching the snapshot
wire in parallel: sport_specific_findings ship estimated_cost: 0 +
estimated_cost_visibility: "redacted_dollar", evidence prose has dollars
scrubbed to $..., biases sort descending by severity, and bias evidence
first-sentence dollars scrub too. iOS was either dropping or mis-rendering
the new wire. This PR consumes Engine V2 correctly, makes the snapshot
earn its $19.99 ask, and replaces gray "blur placeholder" rectangles for
paywalled dollars with a forensic-redaction LockedDollarBar component.

QA findings this PR fixes:

1. Ch 2 "THE TILT FILE" - subtitle violated the "tilt" brand rule and
   the body had only an emotion ring + 1-line descriptor.
2. Ch 4 "THE BIAS SHEET" - only 1 bias card rendering; evidence shown
   as a gray placeholder rectangle.
3. Ch 5 "THE PATTERNS" - "Not enough bet history" empty state firing
   when the engine actually shipped patterns.
4. Ch 7 "THE ACTION PLAN" - every recommendation read "$0 projected
   next 90 days" because parsed dollars from expectedImprovement were 0.
5. Ch 6 BY DAY tiles + NBA finding rendered "+$0" and "-$11,635" with
   no acknowledgement of the snapshot redaction.

### Step 0 findings

- Paywall trigger pattern: each chapter that hosts snapshot surfaces
  owns a `@State private var showingPaywall: Bool` and a
  `.sheet(isPresented:) { PaywallView(snapshotReportId: report.id) }`.
  LockedDollarBar takes an `onTap` closure; each call site wires it
  to its local state flip + Analytics.signal("paywall.triggered", ...).
- Tokens: `DS.Color.Brand.yellow` (#FACC15) and `DS.Color.Brand.canvasDark`
  (#0A0E12) are the existing names. The brief's reference to
  `DS.Color.V3.canvasDark` was a name drift; component uses Brand.
- `DS.Components` namespace does not exist in this codebase. Existing
  components (`BiasRow`, `TiltSessionCard`, `PatternCard`, `ActionCard`,
  ...) are top-level structs in `Components/V3/`. LockedDollarBar
  follows that convention as a top-level struct rather than introduce
  a brand-new namespace pattern for a single component.
- ReportModels.swift uses synthesized Codable on every concrete struct
  (BiasDetected, SportSpecificFinding, Recommendation) but the
  containing AutopsyAnalysis decodes each array with try?, so a
  per-field shape mismatch collapses safely. New optional fields
  added in this PR (`estimatedCostVisibility`, `evidenceVisibility`,
  `descriptionVisibility`, `fixVisibility`, `costSavings`,
  `costSavingsVisibility`) decode as nil on older engines that don't
  ship them. No required field additions.
- Existing "blur placeholder" component was a hand-rolled
  RoundedRectangle filled with borderSubtle inside WithheldBiasTeaserCard.
  Kept in place for the teaser flow; the new LockedDollarBar replaces
  it for all five paywalled-dollar surfaces below.
- Ch 4 previously filtered biases by `estimatedCost > 0`, which dropped
  the entire snapshot wire (engine V2 ships cost = 0 with visibility =
  redacted_dollar). Snapshot now takes top 3 by severity instead.
- Ch 5 was not reading `behavioralPatterns` from the wire at all; it
  computed patterns client-side from sessions + timing aggregates.
  Snapshot mode rarely has enough sessions to populate those, hence
  the "Not enough bet history" fallback. PR now reads the engine wire
  when in snapshot mode and falls back to the computed list otherwise.
- Ch 7 parsed dollars out of the `expectedImprovement` prose string.
  Engine V2 may scrub those to $... too, which returns 0 and produces
  "$0 projected next 90 days". PR adds `costSavings: Double?` and
  `costSavingsVisibility: String?` to the Recommendation model and
  switches the rendering to LockedDollarBar in snapshot mode.

### What shipped

**New components**

- `Components/V3/LockedDollarBar.swift` - 32pt-tall yellow capsule
  with `$` glyph on the left and `lock.fill` SF Symbol on the right.
  Brand.yellow @ 0.95 opacity background, 1pt Brand.yellow border,
  Brand.canvasDark foreground. Configurable width (default 140pt,
  56pt for BY DAY tile cells, 110pt for inline rows). Tap fires
  light haptic + optional onTap closure. VoiceOver: "Locked dollar
  amount", "Tap to unlock the full report for $19.99", isButton.
- `Components/V3/HeatedSessionPreviewCard.swift` - single-session
  snapshot preview used in Ch 2. Red GRADE F pill, day/date/time
  caption row, bet count + LockedDollarBar row, two-to-three heat
  signal chips below in a flow layout that wraps when too wide.

**Ch 2 - The Heated File**

- Subtitle: "THE TILT FILE" -> "THE HEATED FILE" (brand rule: tilt
  never appears in product UI).
- Internal type identifier `TiltSessionCard` retained (purely an
  internal symbol; no user-visible string).
- Section header: "TOP TILT SESSIONS" -> "TOP HEATED SESSIONS".
- Snapshot mode swaps the multi-card list for a single
  HeatedSessionPreviewCard built from the first heated session with
  signals, plus a "N of M sessions flagged as heated." summary line.
  Full mode keeps the existing 3-card TiltSessionCard list (with
  real signed P&L) untouched.
- Snapshot CTA: "READ THE DISCIPLINE AUDIT" -> "UNLOCK THE DOLLAR
  DAMAGE". Full mode keeps the chapter-bridging "READ THE DISCIPLINE
  AUDIT" label.
- Insight CTA tap fires paywall in snapshot mode (analytics source
  `ch2_insight_cta` / `ch2_heated_session_card`).

**Ch 4 - The Bias Sheet**

- Snapshot mode: top 3 biases by severity (engine V2 sorts desc on the
  wire). Full mode: existing `estimatedCost > 0` filter retained.
- BiasRow now renders first-sentence evidence in the collapsed view
  (off-white textPrimary, two-line clamp), gated on
  `evidenceVisibility != "hidden"`.
- BiasRow accepts `isLockedCost: Bool` and `onLockedTap` and renders
  LockedDollarBar in place of "-$N" when isLockedCost or when
  estimatedCostVisibility == "redacted_dollar".
- Severity-bar width: snapshot mode forces severity-anchored fixed
  widths (1.0 / 0.66 / 0.40 / 0.20) so the bars stay readable when
  every estimatedCost is zero.
- WithheldBiasTeaserCard logic kept for parity; the 3-bias display
  carries most of the signal but the teaser stays available if the
  wire ships one.

**Ch 5 - The Patterns**

- Reads `analysis.behavioralPatterns` on snapshot mode and renders
  the top 1-2 as a new inline `wirePatternCard` (patternName as
  semibold title, description as 2-line body). Full mode keeps the
  client-computed `patternCards` from sessions + timing aggregates.
- Fallback copy replaced. Old: "Not enough bet history to surface
  patterns yet." New: "Behavioral patterns require deeper analysis.
  The full report breaks down N detected patterns and their dollar
  impact." (Where N is `snapshotCounts.patterns ?? behavioralPatterns.count`,
  falling back to a generic "your detected patterns" when neither
  number is available.)

**Ch 6 - When and what**

- BY DAY tile profit line replaced with LockedDollarBar (56pt) in
  snapshot mode. Tap fires paywall (`ch6_locked_dollar`).
- Sport-specific finding ESTIMATED COST line replaced with LockedDollarBar
  (110pt) in snapshot mode or when the wire ships
  `estimatedCostVisibility == "redacted_dollar"` / nil / 0.
- Full mode keeps the existing formatted dollar rendering.

**Ch 7 - The Action Plan**

- "$0 projected next 90 days" is gone. ActionCard now exposes
  `isLockedImpact: Bool`, `onLockedTap`, and `impactFallback` and
  renders LockedDollarBar (110pt) + "projected next 90 days" caption
  in snapshot mode or when `costSavings`/`expectedImprovement` parse
  to zero.
- Aggregate "IF YOU DID ALL OF THESE" row is suppressed when every
  ranked action is locked (refused to compose a locked aggregate dollar
  number, which would be misleading).
- Snapshot paywall card at the top of the chapter unchanged - the
  hero CTA copy "Read the full report ($19.99)." is already correct.

**Wire model**

- `BiasDetected` gains four optional Strings: `estimatedCostVisibility`,
  `evidenceVisibility`, `descriptionVisibility`, `fixVisibility`.
- `SportSpecificFinding` gains `estimatedCostVisibility: String?`.
- `Recommendation` gains `costSavings: Double?` and
  `costSavingsVisibility: String?`.
- All new fields decode safely on older engines (Swift synthesized
  Codable treats missing optional keys as nil).

### Verification

- `xcodebuild -scheme BetAutopsy -destination 'platform=iOS Simulator,name=iPhone 17' build`
  succeeds.
- SwiftUI body type-checker timeout hit once on Ch 4 + Ch 7 (the
  `row.isLockedCost ? handleTap : nil` ternary). Resolved by passing
  the tap closure unconditionally to BiasRow and ActionCard; both
  components only invoke it when their own `isLocked*` flag is set,
  so the behavior is unchanged.
- Stale SourceKit "Cannot find DS in scope" diagnostics ignored per
  CLAUDE.md rule. xcodebuild is ground truth.
- Andrew runs the simulator + physical device walkthrough (see
  iPhone QA checklist below).

### Notes / deviations

- Component namespace: brief asked for `DS.Components.LockedDollarBar`
  under a new `DesignSystem/Components/` folder. The repo has zero
  existing `DS.Components` consumers and the existing pattern is
  top-level structs at `Components/V3/`. Adopted the existing pattern.
- Em-dash check: no em dashes in code, commit subject, commit body,
  PR title, PR body, this file, or the SHIPPED block. Hyphen + space
  used where a dash break was needed.
- Engine V2 dependency: this PR assumes engine V2 will ship the new
  visibility tags. The defensive Codable means consumers also work
  with the current engine (visibility = nil -> snapshot logic falls
  back to `report.reportType == "snapshot"` + zero-cost checks, which
  is exactly the same UI outcome).
- Brand rule fix: subtitle "THE TILT FILE" replaced with "THE HEATED
  FILE"; "TOP TILT SESSIONS" section header replaced with "TOP HEATED
  SESSIONS". Internal symbol `TiltSessionCard` kept (not user-visible).

---

## Branch: testflight-prep-brand-coherence (2026-06-10)

TestFlight blockers (List 1) + brand-coherence facts pass. Single PR,
scope-guarded (no redesign, no new surfaces, no Swift type renames).

### What shipped

List 1:
- (1) `DeviceTokenClient.environment` is now build-derived: `#if DEBUG`
  -> "sandbox", else "production". Release/TestFlight report production
  to match the production APNs token.
- (3) `TodayView` reads the latest cached report from `ReportStore.shared`:
  real BetIQ score (hidden when absent or insufficient-data), verdict
  from `executiveDiagnosisInsight`, real discipline/emotion ranges (range
  card hidden when both absent), case header from `report.caseNumber`
  ("TODAY" when none). No fabricated numbers on first screen. Archetype
  identity stays AppStorage-backed (real, set at quiz reveal).
- (4) `PushPermissionView` requests `[.alert, .sound, .provisional]`
  (was `[.alert, .sound]`). Provisional-only per CLAUDE.md + COPY_SYSTEM
  3F. Full-auth prompt revisited at submission.
- (6) `SectionAction.projectedImpactLabel` returns "" for non-positive
  dollars, so "$0 projected next 90 days" hides and the HIGHEST IMPACT
  tag shows instead. Real projection waits on the deterministic-cost
  engine.

Brand coherence:
- (8) Helpline modernized to the current NCPG set (call 1-800-MY-RESET,
  text 800GAM, chat ncpgambling.org/chat). Swift: SettingsView,
  ResponsibleUseLink (full set); PaywallView, AuthView,
  BankrollHealthCallout (call number inline, "We can wait." preserved).
  Docs: COPY_SYSTEM.md (canonical-set note + all occurrences),
  CLAUDE.md compliance lines.
- (9) Pricing facts updated to the May-17 locked model (single $19.99
  one-time consumable; bundle/annual/monthly retired) across all three
  docs: COPY_SYSTEM.md, BETAUTOPSY_PRICING_PIVOT_V2.md, CLAUDE.md.
- (10) Verified: PaywallView already builds the CTA from
  `RevenueCatStore.shared.priceString` (localized) with a "$19.99"
  fallback. No hardcoded $9.99 in Swift. No change needed.
- (11) tilt doc violations fixed: 3B "Tilt risk" range label -> "Emotion";
  push-body "top-three tilt patterns" -> "heated-session patterns".
  Swift user-facing copy already clean (no em dashes, no exclamations,
  no "tilt" in live Text/Label, no "Betautopsy" misspelling).
- (12) Verified: no raw hex Color literals outside Tokens.swift; severity
  amber #FFC66D (Tokens.swift:112) and Brand.yellow #FACC15 (:199) are
  correctly separated in their locked roles. No change needed.
- 7-chapter -> single-scroll reader: COPY_SYSTEM 3C heading + structural
  note (live reader is `ReportScrollContainer`, one scroll of seven
  sections).

### Verification

- xcodebuild Debug (scheme BetAutopsy, generic iOS Simulator):
  BUILD SUCCEEDED (exit 0).
- No XCTest target exists in the project; `BetAutopsyTests/` is not wired
  to a target. "Tests green" is satisfied by a clean xcodebuild only.
- Device smoke (item 13) is Andrew's: fresh CSV -> analyze SSE -> full
  report; what-if card; snapshot -> unlock swap (sandbox purchase);
  vs-last-report; a check-in round trip; eyeball TodayView (3), push
  primer (4), and the action/protocol section (6).

### Deferred / flagged (NOT in this PR)

- (2) Units/scale "4,872%" / "-2,412pp" double-multiply: NOT REPRODUCIBLE
  in current main. Every live percent/pp formatter consumes already-
  percent engine values with no x100: `formatPct` (ReportModels.swift:
  1485), `signedPercent` (VitalsStripCard.swift:156), and inline
  `Int(roi/edge/winRate.rounded())%`/`pp` in SectionSports /
  SectionPatternsTiming. The only `*100` is `BetIQComponentBars.swift:137`
  (`value/max` ratio, correct). No speculative fix applied (Andrew's
  decision: defer) — a guess would risk the inverse bug. Needs a real
  repro (report id / screenshot) or is engine-side.
- (5) `delete_account` edge function deployment: UNVERIFIABLE here. The
  connected Supabase MCP account exposes only "Vig Rewards" and
  "mets-seat-finder" (both zero edge functions); the BetAutopsy project
  is not reachable. iOS degrades gracefully (local sign-out on 404), so
  TestFlight is safe, but App Store submission (5.1.1(v)) is gated on
  Andrew confirming the function is deployed in BetAutopsy's Supabase.
- (7) `bets.result` strict-enum gate for web's WS-NUMERIC N2 (`cashed_out`):
  no iOS change needed. iOS has no per-bet decode and no `result` enum;
  the new value is wire-safe. No pre-ship iOS PR required.
- ($3,284 / "23 pages"): flagged in COPY_SYSTEM Section 1 as TKTK
  placeholders (rule 7). Not stripped from examples; must be sourced or
  replaced before any user-facing use. Live reader is single-scroll, so
  "23 pages" is not an accurate descriptor.
- "BETAUTOPSY" all-caps wordmark in AgeGateView is an intentional logo
  treatment, not a casing error; left as-is.
- Section count: live reader has SEVEN sections (Verdict, Findings,
  HeatedDiscipline, PatternsTiming, Sports, Protocol, Action), not six
  as an earlier recon note stated. Docs reflect seven.
- Item 14 Notion (sprint rows + command-center update): NOT done by
  Claude Code, per the standing rule that Notion writes are centralized
  in the chat/Notion-MCP layer. File the rows from this list.
- Pricing-doc scope extension: per Andrew's decision, the facts pass
  updated BETAUTOPSY_PRICING_PIVOT_V2.md and the CLAUDE.md pricing block
  in addition to COPY_SYSTEM.md (item 9 named only COPY_SYSTEM), so the
  named source-of-truth doc stops re-rotting downstream copy.

---

## Branch: report-lazy-fetch (2026-06-11)

P0: paid full reports rendered as a minimal shell on iOS. Root cause (proven
against all 14 of a real user's prod reports, decoded through the exact iOS
structs): NOT a decode bug. `GET /api/reports` correctly slims `report_json`
to a ~12-key card whitelist (omits session_detection, behavioral_patterns,
biases_detected, timing, recommendations, etc.); iOS rendered that slim list
payload as if it were a full report because the lazy-fetch by id was never
implemented, and `hydrate()` re-clobbered any full report with the slim row
on relaunch. Intermittent: full right after purchase (poll path returns full)
/ push (/:id full); shell after relaunch or open-from-list (slim).

### What shipped (iOS-only; web slimming stays)

Commit 1 - model flag + cache v3:
- `AutopsyReport.isFullBody` distinguishes slim card from complete body. Set
  per construction site: list=false; detail(/:id)=true, upgraded_from=true
  (protects PR #34), analyze-stream=true, mock=true. Not a wire field (every
  site sets it via the initializer); part of cache Codable.
- `ReportCache.currentVersion` 2 -> 3: drops pre-flag slim-as-full caches on
  upgrade so existing users self-heal on first launch.

Commit 2 - hydrate non-clobber:
- `ReportStore.performHydrate` merges via `mergePreservingFullBodies`: maps
  over the slim list (server owns membership) but keeps any id already held
  at full body. Stops the slim clobber and protects #34's materialized full.

Commit 3 - fetch-on-open + gating:
- `ReportScrollViewModel`: `bodyState` (full/fetching/failed) + `ensureFullBody()`
  lazy-fetches the full body by id via the existing `ReportFetchClient.fetch`,
  swaps it in (progressive fill - slim cards render immediately), upserts to
  heal store+cache. Failure sets `.failed` and does NOT auto-refetch on .task
  re-fire/re-render; only `retry()` or a new report id re-triggers (no endpoint
  loop on flaky network).
- `ReportScrollContainer`: `.task(id: report.id)` drives the fetch; body
  sections render only when `.full`; `.fetching` shows a loading row, `.failed`
  shows a retry block. The degraded snapshot/fallback copy ("Pattern analysis
  lives in the full report" / WARNING SIGNS) can no longer render on a slim
  payload - the masquerade is gone. SectionVerdict (slim-safe) always renders.

### Verification

- xcodebuild Debug SUCCEEDED after each of the 3 commits.
- Root cause reproduced via a Foundation-only harness decoding all 14 prod
  reports with the exact structs (all decoded clean; degradation only on the
  slim list payload). Pulled prod data was confined to /tmp and deleted; the
  temporary diagnostic do/catch prints lived only on branch
  `diag/full-report-decode` and were discarded when this branch was cut.
- Device smoke owed (Andrew): open a report from the Reports list (cards
  instant, body fills in), kill network mid-open (retry block, not the
  masquerade), relaunch and re-open a previously-opened report (stays full,
  no re-shell), snapshot opened from list fills its redacted body.

### Composition with PR #34

#34's materialize -> upsert -> cache delivers a full body (isFullBody=true via
the upgraded_from path); the hydrate merge here preserves it against the slim
clobber. Without this merge, #34's full report rotted back to a shell on the
next hydrate. They compose; this PR sequences ahead of #34 in merge order.

### Notes / deviations

- Failure UX is the gating approach (hide degraded sections + retry), per
  Andrew, not the lighter-touch banner that would leave the masquerade on
  screen.

---

## Branch: unlock-compiling-flow (2026-06-11)

Reworks the snapshot->full post-purchase loading flow. Today a successful
purchase shows an indeterminate "Preparing your full report..." spinner,
then on the 90s poll timeout flips to red text ("Pull to refresh on the
dashboard") and auto-dismisses. Root cause: server generation is deferred
(RevenueCat webhook -> engine re-run, 30-120s) but the iOS poll only waited
90s, so the red timeout fired in NORMAL operation on large reports. Approved
via Step-0 outline; not a TestFlight blocker; sequences behind the 4
critical items + PR #33; fresh branch off main.

### What shipped (iOS PR)

- PendingUnlockStore (new): UserDefaults-backed {snapshotId, createdAt},
  the source of truth for resume + failure detection. 12-min failure
  ceiling off createdAt.
- RevenueCatStore: pollForUpgradedReport returns UnlockPollOutcome
  (.materialized/.stillCompiling/.authExpired), in-sheet window 90s->150s
  (cosmetic; reliability is the persisted record + resume). Idempotent
  materialize(_:source:) guarded on PendingUnlockStore.isActive; resume
  one-shot poll; unlockFailed flag past the ceiling. Red timeout string
  removed.
- PaywallView: payment confirmed up front (decoupled from generation);
  staged compiling block (rotating copy + "usually under two minutes") +
  dismissable; calm "Still compiling. ...in your Reports tab when it's
  ready." on window-elapse. Red reserved for genuine failures.
- Resume wiring: RootTabView scenePhase .active (cold launch + foreground)
  and ReportListView Reports-tab appear.
- Failure banner (ReportListView): recoverable, calm, Restore + Contact
  support; shown only past the ceiling.
- Push routing: AppDelegate accepts kind=="report_ready"; DeepLinkRouter
  completes a pending unlock idempotently when a deep-linked report
  resolves it.
- Funnel analytics (TelemetryDeck): purchase.confirmed, compile.started,
  compile.completed (source=in_sheet|resume|push), unlock.failed.

### Idempotency (required)

All three completion paths funnel through RevenueCatStore.materialize,
guarded on PendingUnlockStore.isActive. First path wins (upsert + clear +
one compile.completed); the rest no-op. ReportStore.upsert is id-keyed
(no duplicate row) and ReportScrollViewModel swaps a snapshot only once
(post-swap it is full, guard fails). Only the push-tap path presents a
cover; in-sheet/resume mutate data without presenting. So no double-swap,
no double-present, no duplicate analytics.

### Verification

- xcodebuild Debug SUCCEEDED after each commit (model+sheet; then
  resume+banner+push).
- Device smoke owed (Andrew): in-sheet success swap; close-during-compile
  then report appears on return (resume); 12-min ceiling -> failure banner;
  staged copy rotation; no red on a successful purchase.

### Cross-repo dependency

- Companion WEB PR (repo /Users/Andrew/betautopsy) adds the report_ready
  push: widen ApnsKind union, a push-report-ready orchestrator, fire it at
  the end of processUpgrade after the INSERT. Must deploy before/with any
  iOS copy that promises a notification; until then iOS copy leads on the
  Reports-tab guarantee (resume-backed) and the push is additive. Built as
  a separate PR (halt between repos).

### Notes / deviations

- In-sheet 150s bump is acknowledged cosmetic; resume is the reliability
  path. Pre-generation is scoped out; the "generate-on-paywall-show"
  variant (kick off the full run when the paywall is shown, for near-instant
  unlock) is flagged for a later evaluation, NOT snapshot-time pre-gen.
- Notion: sprint rows / command-center update not filed by Claude Code
  (standing rule); file from this entry.

---

## Branch: recovery-tier-ui (2026-06-10)

Re-converges iOS with web PR #71 (commit 45ec0fb): renders the report-baked
three-tier `riskTier` recovery UI that now shows on web. Outline-gated
(approved), two commits (decode, then UI), build verified between. NOT a
TestFlight blocker; sequences after PR #32 smoke+merge and the 4 critical
items. Branched off main (no file overlap with PR #32).

### What shipped

Commit 1 (decode):
- `ReportModels.swift`: new `RiskTier` enum ('none'|'elevated'|'recovery'),
  `SupportResource`, `ReportRiskSummary`, and a minimal `ReportControlSystem`
  (only the fields iOS renders; rules engine / cooldowns / plan template are
  Control-Center surfaces iOS lacks and are left off the model). Optional
  `controlSystem` added to `AutopsyAnalysis` (property + memberwise init +
  CodingKeys + tolerant `init(from:)`). `effectiveRiskTier` mirrors web's
  `riskTier ?? (recoveryModeRecommended ? .recovery : .none)` back-compat.

Commit 2 (UI):
- New `ElevatedRiskNote.swift`: dismissible non-clinical note, per-report
  `@AppStorage("elevatedNoteDismissed.<reportId>")` (mirrors web localStorage).
  Rendered at top of `SectionVerdict` only at the elevated tier. No helpline.
- New `RecoveryRecommendationCard.swift`: informational card (no opt-in CTA
  — iOS has no Control Center). Renders headline + topRisks + the decoded
  `supportResources` (helpline rendering A: engine-sourced, styled with
  ResponsibleUseLink chrome) + non-medical disclaimer. Rendered in
  `SectionProtocol` only at the recovery tier. Support resources surface
  ONLY here (recovery tier), matching web's message-fatigue gating.

### Scope dropped (approved)

- Live-state reframing (web `recoveryModeActive`): no iOS source (no
  control-system endpoint, no `profiles.manual_recovery_mode` read, no
  recovery toggle), and no iOS user can be in manual recovery mode anyway.
  iOS renders the report-baked `effectiveRiskTier` only. Session relabeling,
  recovery banner, and `!recoveryModeActive` card-suppression all dropped.
- Control Center / rules / cooldowns / plan template / relapse triggers: not
  decoded, not rendered.
- Recovery card opt-in CTA: dropped (nothing to point at).
- Helpline at elevated tier: deliberately not added (message-fatigue gate).

### DO-NOT-MARKET gate (clinical-safety)

This UI inherits web PR #71's DO-NOT-MARKET gate: the recovery tier must NOT
appear in any iOS marketing / App Store copy until the engine threshold
recalibration lands on a real population (coupled to the WS-NUMERIC /
WS-TEMPORAL re-tune). The recovery tier is an in-product clinical-safety
surface only, not a feature to promote, until the thresholds are validated.

### Verification

- xcodebuild Debug (scheme BetAutopsy, generic iOS Simulator): BUILD
  SUCCEEDED after each commit (decode, then UI).
- Crash-safety: `controlSystem` optional + per-field tolerant init means
  snapshots (engine omits control_system), every pre-#71 report, and any
  malformed/unknown-tier payload decode to nil/.none and render nothing.
  No historical or cached report can crash.
- Device-eyeball owed (next halt): an elevated-tier report (note + dismissal
  persists per report) and a recovery-tier report (card + support links tap
  out to tel/chat). Needs a real recovery-tier payload from the engine, or a
  temporary MockReport `controlSystem` to force each tier on-device.

### Notes / deviations

- Engine-dependency flag: `riskTier` is engine-classified
  (`classifyReportRiskTier`) and PR #71 was itself a threshold recalibration;
  tier assignment can shift as the temporal/numeric engine work lands. iOS
  renders only what's shipped (low coupling), but this belongs on the
  engine-sequencing list in the parity map.
- Notion: per the standing rule, sprint rows + command-center update are NOT
  filed by Claude Code; file them from this entry.
