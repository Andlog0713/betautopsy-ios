# Archetype Mapping Review (May 13 2026)

Discovery for PR-V11 (backend archetype taxonomy rename).
Read-only review — no source code edits. Repo HEAD at `6090ee8`.

---

## Current state — V2 archetype logic

### The 8 dimensions (QuizScoring.swift:16-25)

```swift
enum ScoringDimension: String, Hashable, CaseIterable {
    case emotion
    case parlayLean    = "parlay_lean"
    case chaseTendency = "chase_tendency"
    case favLean       = "fav_lean"
    case volume
    case discipline
    case variance
    case selectivity
}
```

| Dim | Short | What it measures (per question contributions) |
|-----|-------|-----------------------------------------------|
| emotion        | `e` | How feelings drive sizing and chasing. High = volatile, reactive. |
| parlayLean     | `p` | Reach for the big ticket. High = stacks legs even after losses. |
| chaseTendency  | `c` | Behavior after a streak of losses. High = doubles down to recover. |
| favLean        | `f` | Pull toward heavy chalk lines. High = takes -300 with no edge analysis. |
| volume         | `v` | Weekly bet count band. High = 30+ per week, bets every game watched. |
| discipline     | `d` | Plan adherence, flat sizing, breaks. High = treats betting as a system. |
| variance       | `r` | Stake-size variability. High = sizes swing with mood / confidence. |
| selectivity    | `s` | Bet only on edges vs bet for action. High = waits for spots. |

Each dimension is averaged across whatever questions touched it (default 5.0 when no question scored it). Range 0-10.

### V2 archetype emission (QuizScoring.swift:271-351)

The `assignArchetype(averages:)` function uses a first-match ladder. **Order matters** — earlier thresholds win.

| Order | V2 Name (string literal) | Threshold combo | Color token |
|-------|--------------------------|-----------------|-------------|
| 1 | **The Natural** | `d ≥ 7.5 && e ≤ 3.5 && s ≥ 6` | `Archetype.natural` (`#5BFFA8`) |
| 2 | **Sharp Sleeper** | `d ≥ 6 && r ≥ 6 && s ≥ 5` | `Archetype.sharpSleeper` (`#6B5BFF`) |
| 3 | **Heated Bettor** | `e ≥ 6 && c ≥ 6 && d ≤ 4` | `Archetype.heatedBettor` (`#FF5454`) |
| 4 | **Chalk Grinder** | `f ≥ 7 && d ≥ 4` | `Archetype.chalkGrinder` (`#B8944A`) |
| 5 | **Parlay Dreamer** | `p ≥ 7` | `Archetype.parlayDreamer` (`#8B7DFF`) |
| 6 | **Sniper** | `s ≥ 7 && v ≤ 4` | `Archetype.sniper` (`#60A5FA`) |
| 7 | **Volume Warrior** | `v ≥ 7 && r ≤ 4` | `Archetype.volumeWarrior` (`#A78BFA`) |
| 8 | **Degen King** | `r ≥ 7 && p ≥ 5 && e ≥ 5` | `Archetype.degenKing` (`#FF5454`) |
| 9 (fallback) | **The Grinder** | (default, no match) | `Archetype.grinder` (`#A8AABF`) |

Note: V2 fallback "The Grinder" **conflicts** with V3's intended "The Grinder" semantics (high-volume / decent discipline). Rename collision must be resolved in PR-V11.

### Production flow

```
BetDNAQuizView.swift:23
    .questions = QuizScoring.questions           // 7 questions, locally
        ↓ user answers
OnboardingCoordinator.swift:59
    quizResult = QuizScoring.computeResult(answers:)
        ↓
QuizScoring.computeResult()
    computeAverages(answers:)                    // raw [String:String] → [Dim:Double]
    assignArchetype(averages:)                   // ← THE RENAME TARGET
    computeEmotionEstimate / Discipline / Grade
        ↓
ArchetypeResult { name: String, color, colorHex, description }
        ↓ persisted to coordinator + @AppStorage("userArchetype")
ArchetypeRevealView renders by name + color
```

Post-CSV upload, the **server-side classifier** (Vercel `/api/analyze`) emits its own `bettingArchetype.name` on the analysis payload. That's a separate code path the quiz scorer doesn't touch. Both paths today produce V2 names.

---

## Where V2 names are referenced

### String literal sites (must change in PR-V11)

| File | Line(s) | Context |
|------|---------|---------|
| `QuizScoring.swift` | 283, 291, 299, 307, 315, 323, 331, 339, 346 | `ArchetypeResult.name` field for each 9 archetypes |
| `ReportModels.swift` | 453-460 | `BettingArchetypeData.color` switch on name |
| `MockReport.swift` | 303 | `BettingArchetypeData.name` for heatedBettor mock |
| `MockReport.swift` | 306 | `quizArchetype: "Heated Bettor"` |

### Comment-only references (cosmetic, may update with the strings)

| File | Line | Context |
|------|------|---------|
| `MockReport.swift` | 5 | File header doc |
| `ReportListView.swift` | 6 | File header doc |
| `ReportStore.swift` | 18 | Doc comment |
| `Analytics.swift` | 10 | Stale example references "Heat Chaser" (already V3-ish; not in QuizScoring) |

### Dynamic consumers (no rename needed, just consume new strings)

These read archetype.name dynamically and don't hardcode V2 strings — they will pick up V3 names automatically once the producers change:

- `ArchetypeRevealView.swift:47,59,65,76-78` — renders `result.archetype.name`, `.color`, `.description`
- `TodayView.swift:13,20,89-91` — reads `@AppStorage("userArchetype")` String
- `ChapterTheVerdictView.swift` — renders `archetypeName` from `report.analysis.bettingArchetype?.name`
- `ChapterYourDisciplineView.swift:15-16,138` — uses `bettingArchetype?.color`

### Mock fixture status

- `MockReport.heatedBettor` is the Swift identifier and **stays** (file naming, comments, etc).
- The fixture's emitted `bettingArchetype.name` ("Heated Bettor") and `quizArchetype` string ("Heated Bettor") become **"The Tilter"** in PR-V11 (per mapping below).
- Mock numerical content (BetIQ 23, emotion 88, discipline 17) is consistent with The Tilter profile, so no behavioral data needs to change.

---

## Proposed mapping (V2 → V3)

### (a) DIRECT RENAME — same threshold, new name

| V2 | V3 | Threshold (unchanged) | Notes |
|----|----|-----------------------|-------|
| **Heated Bettor** | **The Tilter** | `e ≥ 6 && c ≥ 6 && d ≤ 4` | V3 framing: "episodic blowups, high emotion, low session discipline." Direct semantic match. Mock fixture renames here. |
| **Parlay Dreamer** | **The Lottery Bettor** | `p ≥ 7` | V3 framing: "high parlay lean, low single-bet vol, low avg odds." The quiz can only enforce parlay lean; backend classifier refines the avg-odds and single-bet-vol nuance. |
| **Volume Warrior** | **The Grinder** (V3 sense) | `v ≥ 7 && r ≤ 4` | V3 framing: "high volume, decent discipline, modest CLV." Quiz proxy = volume + low variance. Note: this rename **collides** with V2's fallback name. Resolve by renaming the V2 fallback to something disambiguating (see ORPHANED below). |

### (b) NEEDS NEW THRESHOLDS — V2 maps to V3 but tuning required

| V2 | V3 | What changes | Confidence |
|----|----|--------------|------------|
| **The Natural** | **The Sharp** | V3 is **outcome-defined** ("positive CLV across material sample"). Quiz cannot measure CLV. Quiz threshold should stay `d ≥ 7.5 && e ≤ 3.5 && s ≥ 6` as a *proxy*, but the backend classifier needs separate CLV-based logic on the analyze path. | MEDIUM. Quiz heuristic is a reasonable pre-CSV approximation. |
| **Sniper** | partial **The Sharp** | Both are "low volume + high selectivity." V3 Sharp also requires positive CLV. Quiz can't confirm CLV, so emit "The Sharp" cautiously OR introduce a quiz-only "Aspiring Sharp" subtype. Recommend: collapse Sniper into Sharp's quiz proxy, with `s ≥ 7 && v ≤ 4 && d ≥ 5` (added discipline floor). | MEDIUM. |
| **Degen King** | **The Action Junkie** | V3 framing: "high vol no edge, broad sport spread, low discipline." V2 Degen King has `r ≥ 7 && p ≥ 5 && e ≥ 5` (no volume floor). Add `v ≥ 6` to require the "high vol" signal; drop the parlayLean requirement (V3 Action Junkie isn't specifically parlay-leaning). New threshold: `v ≥ 6 && r ≥ 6 && d ≤ 4`. | MEDIUM. |

### (c) ORPHANED — retire, no clean V3 equivalent

| V2 | Recommendation |
|----|----------------|
| **Sharp Sleeper** | Retire. "Good instincts + sizing chaos" doesn't map to any V3 archetype cleanly. Profile is part-Sharp, part-Action Junkie. Without this branch, those bettors fall through to other thresholds or the fallback. Acceptable loss — V3 prioritizes 9 clean profiles over 9 mixed ones. |
| **Chalk Grinder** | Retire. "Favorite-leaning + average discipline" isn't a V3 profile. The V3 9 don't include a chalk-bias archetype. Recommend routing these users to the V3 fallback or The Lottery Bettor (since betting heavy favorites IS a low-EV pattern similar to parlays). |
| **The Grinder** (V2 fallback name) | Rename the fallback. V3's "The Grinder" is taken by the high-volume archetype. The unmatched/methodical fallback should become something neutral: candidates **"The Methodical"**, **"Unclassified"**, or **"The Balanced Bettor"**. The fallback color (`grinder` = `#A8AABF`) can keep its token name internally or rename to `methodical`/`balanced`. |

---

## V3 archetypes without a V2 equivalent

Four of the V3 9 don't have a V2 predecessor. Each needs brand-new logic.

### 1. The Chaser (loss-chasing, post-loss escalation) — QUIZ-FEASIBLE

- **Drivers:** `chaseTendency` (primary), `emotion` (secondary), `variance` (tertiary).
- **Proposed threshold:** `c ≥ 7 && (e ≥ 5 || r ≥ 6)` — chase-dominant. Distinct from The Tilter (e ≥ 6 && c ≥ 6 && d ≤ 4) by chase being the *standalone* driver, not part of an emotion + low-discipline combo. The Tilter is the broader emotional pattern; Chaser is the narrow post-loss-escalation pattern.
- **Order matters:** Place ABOVE The Tilter in the ladder so chase-dominant profiles route to Chaser even when emotion is also elevated. Otherwise Tilter swallows Chaser.
- **Confidence:** HIGH. The `chase_tendency` dimension exists, has strong question signal (Q4 "lost 3 bets" + Q7 sliders), and the boundary with Tilter is defensible.

### 2. The Reformed Degen (improving trend, prior tilt, recent discipline) — BACKEND-ONLY

- **Drivers:** longitudinal — first-half-of-window emotion/chase signals vs second-half discipline signals.
- **Why quiz can't do this:** Quiz captures *current* self-report. No way to detect "you used to be tilty but the last 30 days look disciplined" from a 7-question survey.
- **Confidence:** LOW from quiz. **HIGH from backend** (analyze path can window the bet timeline).
- **PR-V11 action:** No quiz threshold added. Document as backend-only.

### 3. The Bonus Hunter (low organic vol, high bonus activity) — BACKEND-ONLY

- **Drivers:** ratio of bonus/promo-tagged bets to organic bets.
- **Why quiz can't do this:** Quiz has no question about bonus exploitation. Could add one ("How often do you only play to clear a promo?") but signal would be noisy.
- **Confidence:** LOW from quiz. HIGH from backend if CSV includes bonus markers.
- **PR-V11 action:** No quiz threshold added. Document as backend-only.

### 4. The Steamer (late-line after sharp moves, low CLV from chasing) — BACKEND-ONLY

- **Drivers:** time-of-bet relative to line movement, average CLV.
- **Why quiz can't do this:** Quiz can't measure line timing or CLV.
- **Confidence:** LOW from quiz. HIGH from backend.
- **PR-V11 action:** No quiz threshold added. Document as backend-only.

**Summary of quiz-emittable V3 archetypes (PR-V11 ladder, in order):**

1. The Chaser           (`c ≥ 7 && (e ≥ 5 || r ≥ 6)`)
2. The Tilter           (`e ≥ 6 && c ≥ 6 && d ≤ 4`)
3. The Sharp            (`d ≥ 7.5 && e ≤ 3.5 && s ≥ 6`)
4. The Lottery Bettor   (`p ≥ 7`)
5. The Action Junkie    (`v ≥ 6 && r ≥ 6 && d ≤ 4`)
6. The Grinder (V3)     (`v ≥ 7 && r ≤ 4`)
7. fallback             (e.g. "The Methodical")

That's 6 emittable + 1 fallback. The other 3 V3 archetypes (Reformed Degen, Bonus Hunter, Steamer) are exclusive to the backend classifier.

---

## Recommendations for PR-V11

### Files to edit

| File | Changes |
|------|---------|
| `BetAutopsy/BetAutopsy/QuizScoring.swift` | Rewrite `assignArchetype(averages:)` with the 6-archetype + fallback ladder above. Update each archetype's `description` to V3 voice. ~60 lines changed. |
| `BetAutopsy/BetAutopsy/ReportModels.swift` | Update `BettingArchetypeData.color` switch (lines 451-463) with new V3 name → color mapping. ~12 lines. |
| `BetAutopsy/BetAutopsy/Tokens.swift` | Add new V3 archetype color tokens in `DS.Color.Archetype` (or repurpose). Keep V2 names during cascade per the V2/V3 coexistence rule. ~10 lines added. |
| `BetAutopsy/BetAutopsy/MockReport.swift` | Update lines 303 and 306: `name: "The Tilter"`, `quizArchetype: "The Tilter"`. ~2 lines. |
| `BetAutopsy/BetAutopsy/Analytics.swift` | Update stale comment example at line 10 ("Heat Chaser" → "The Tilter"). ~1 line. |
| Comments in `MockReport.swift:5`, `ReportListView.swift:6`, `ReportStore.swift:18` | Optional cosmetic: replace "Heated Bettor" comment references with "The Tilter." ~3 lines. |

### Estimated complexity

**MEDIUM.** ~90 net lines across 5 files. No new components, no view rewrites. Risk is concentrated in threshold tuning for The Chaser and the reordering of the ladder (Chaser must precede Tilter or the new branch is dead code).

### Risks & unknowns surfaced

1. **Threshold tuning without bet-data validation.** The Chaser threshold `c ≥ 7 && (e ≥ 5 || r ≥ 6)` is a first guess. No way to validate against real quiz-taker distribution until quiz analytics show how the new 6-way split lands. Watch the `archetype.revealed` Telemetry signal post-ship.

2. **The Sharp Sleeper / Chalk Grinder retirement creates routing voids.** Previous Sharp Sleeper bettors (`d ≥ 6 && r ≥ 6 && s ≥ 5`) will mostly fall to The Sharp threshold (`d ≥ 7.5 && e ≤ 3.5 && s ≥ 6`) if their discipline is high enough, else the fallback. Bettors who hit Chalk Grinder (`f ≥ 7 && d ≥ 4`) lose a home entirely — they'll mostly hit the fallback. Acceptable but worth noting.

3. **Quiz ≠ backend classifier divergence.** The quiz emits archetype name from self-report; the backend `/api/analyze` emits archetype name from CSV-derived behavior. After CSV upload, the user's archetype string can **change** (e.g. quiz said "The Lottery Bettor," CSV says "The Tilter"). The current UX doesn't surface this transition. Out of scope for PR-V11, flag for product review.

4. **Fallback rename ripple.** Renaming the V2 "The Grinder" fallback (to e.g. "The Methodical") affects:
   - `Archetype.grinder` color token (consider rename to `methodical`)
   - `BettingArchetypeData.color` default case (line 461)
   - Any user currently with `@AppStorage("userArchetype") == "The Grinder"` — they'll display the old name with the new (V3) "Grinder" color until they re-take the quiz. **Migration path:** on app launch, if `userArchetype == "The Grinder"` AND fallback profile (no other match), set it to the new fallback name. Out of strict scope but worth a 5-line shim.

5. **V3 archetype colors need design input.** The V2 color tokens (`#5BFFA8` for Natural, etc.) were chosen with V2 names in mind. V3 archetype color assignments aren't locked in the Notion spec. Recommend pinging design for The Chaser, The Sharp, The Lottery Bettor, The Action Junkie, The Tilter, The Grinder color decisions before PR-V11 ships.
