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

## Branch: claude/ios-snapshot-richer

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
