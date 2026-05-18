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
