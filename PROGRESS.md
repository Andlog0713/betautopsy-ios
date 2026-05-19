# BetAutopsy iOS Progress

## Done this session

### Mega-PR B: iOS rendering of engine depth (2026-05-19)

Squashed merge from `mega-pr-b-ios`. Companion to engine-side
Mega-PR A (squash `0b776dd`, 2026-05-19). Surfaces engine fields
that were on the wire but not rendered.

Codable model expansion:
- `TriggerEvent` struct, `DetectedSession.triggerEvent`
- `AnnotationSignal` struct, 6 new optional fields on `BetAnnotation`
- `StreakInfluence` struct, 3 new optional fields on `AnnotationSummary`
- `TiltSignals` ported to tolerant Codable (PR-15 pattern)
- All additions nil-safe; legacy wire payloads keep decoding clean

Chapter renders:
- Ch 2: `TriggerEventChip` on each `TiltSessionCard` and
  `HeatedSessionPreviewCard` (type-tinted icon + caps label +
  description prose)
- Ch 2: `TiltSignalBreakdownCard` rendering the 6
  `enhanced_tilt.signals` with severity-coded bars
- Ch 3: replaces session-derived `BehavioralImpactRow` block with
  engine-shipped `bet_annotations` as the hero: EMOTIONAL COST
  hero card, 5-segment distribution bar, worst and best annotated
  bet cards with contributing signals, and stake-by-streak card.
  `BehavioralImpactRow` retained as the fallback path for legacy
  reports without `betAnnotations` on the wire.
- Ch 4: NEW WHERE YOU BLEED section above bias card with up to
  5 `strategic_leaks` (ROI badge + sample size + detail + fix);
  bias rows now tap-open a `BiasEvidenceSheet` (Path B: prose +
  evidence-bet-count caption + fix, no per-bet fetch because no
  `/api/bets` endpoint exists and iOS does not hit Supabase
  directly. Adding the endpoint and an in-sheet EVIDENCE BETS
  list is a future PR.)
- Ch 5: `ContradictionCard` renders the first engine contradiction
  above the existing pattern cards

Snapshot mode coverage:
- Ch 3 emotional cost hero replaced with `LockedDollarBar`
- Ch 3 streak-influence dollars replaced with small
  `LockedDollarBar` per column
- Ch 4 strategic leak detail prose collapses to first sentence +
  DOLLAR DAMAGE `LockedDollarBar`
- Ch 4 bias evidence sheet est. cost replaced with `LockedDollarBar`
- Ch 5 contradiction annual cost replaced with `LockedDollarBar`

Out of scope (deferred):
- Filter CTA from `BiasEvidenceSheet` (no bets list view exists; v1.1)
- Multi-contradiction rendering (v1.1)
- `edge_profile` / Ch 6 rebuild (v1.1 locked)
- Ch 7 bootstrap projection (v1.1 locked)
- `/api/bets` endpoint + per-bet sheet rows (future PR)

Files added:
- `Components/V3/TriggerEventChip.swift`
- `Components/V3/TiltSignalBreakdownCard.swift`
- `Components/V3/AnnotationDistributionBar.swift`
- `Components/V3/AnnotatedBetCard.swift`
- `Components/V3/StreakInfluenceCard.swift`
- `Components/V3/StrategicLeakCard.swift`
- `Components/V3/BiasEvidenceSheet.swift`
- `Components/V3/ContradictionCard.swift`
- `PROGRESS.md`

Files modified:
- `ReportModels.swift` (Codable expansion)
- `ChapterYourMindView.swift` (Ch 2 wiring)
- `ChapterYourDisciplineView.swift` (Ch 3 rebuild + legacy fallback)
- `ChapterYourBiasesView.swift` (Ch 4 strategic leaks + sheet)
- `ChapterYourPatternsView.swift` (Ch 5 contradiction)
- `Components/V3/TiltSessionCard.swift` (triggerEvent prop)
- `Components/V3/HeatedSessionPreviewCard.swift` (triggerEvent prop)
- `Components/V3/BiasRow.swift` (onTap + chevron + haptic)
