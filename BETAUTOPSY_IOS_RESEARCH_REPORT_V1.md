# BetAutopsy iOS Native Rebuild: v1 Launch Strategy and Roadmap

*Comprehensive research report. Locked May 10, 2026.*

## TL;DR — The strategic shift

**Redesign for mobile-native. Do not port the 3,384-line web report.**

Every category leader in behavioral self-awareness (Whoop, Oura, Robinhood, Spotify Wrapped, Duolingo) converged on the same patterns: one hero number, card-based progressive disclosure, share-card-as-product, and notifications that deliver value in the body. A web-report port loses on every one of those dimensions. The native rebuild is also the only path that earns the iOS-specific moats (Siri pre-bet check-in, Lock Screen widget, Live Activity, Share Extension) that competitors cannot copy quickly.

Pikkit owns descriptive analytics. Action Network owns picks. Behavioral betting analysis is an empty App Store category. Owning the language is the first-mover prize.

---

## The 5 critical decisions

These are the highest-leverage decisions to lock before next coding session:

1. **Hero metric:** BetIQ Score (recommended) — bidirectional, has clear denominator, leaves room for coaching narrative. Not Discipline (too moralizing), not Days Since Heated Session (anxiety-inducing).
2. **Tab count:** 3 tabs (recommended) — Today / Sessions / Reports. Avatar circle top-right of Today for Settings, Profile, Paywall, Responsible Use.
3. **Report architecture:** Chapter-based (recommended) — 7 to 9 horizontally swipeable chapters. Not a scrollable port of AutopsyReport.tsx.
4. **Geo-restriction:** Hybrid (recommended) — restrict to top 25 legal US states at App Store Connect territory level. Costs nothing, eliminates reviewer-decision risk. Nationwide is defensible but riskier for a new app without Pikkit's track record.
5. **Siri pre-bet check-in in v1:** Yes, logged-moment only (recommended) — ships as App Intent in 4-6 engineer-days. Behavior correlation tied to next CSV upload, not real-time. Promote to v1 marketing differentiator.

---

## 1. Category analysis

### The reference apps and what to steal from each

**Whoop** — Hero metric architecture. Recovery score (0-100, color-banded). One number, one verdict, one color. Notification copy quotes the actual number ("Your HRV is 22% below baseline"). 90%+ year-one retention. Subscription bundles historical trends so canceling forfeits the trend.

*Steal:* Forensic verdict pattern as report cover. "You vs your baseline" framing in every notification. Behavior-impact callouts ("Sunday late-night bets cost you $X expected value"). Long-horizon metrics (Bettor Age, Bankroll Healthspan) that mature at 90+ days.

**Oura** — Consistent 0-100 scoring across multiple dimensions. Staged metric reveals (Resilience unlocks at 14 days; deepest archetype reading at 90 days). Personal-baseline framing.

*Steal:* Personal-baseline framing is the antidote to bettors who hate being compared to pros. Staged reveals lock retention by gating depth behind tenure.

**Robinhood** — Card-based progressive disclosure for financial data. Threshold-based notifications. Animated hero numbers.

*Steal:* Notifications contain enough information that user doesn't need to open the app. Animated count-up on dashboard open via `contentTransition(.numericText())`.

**Spotify Wrapped** — 1080x1920 share cards, swipeable, mixing serious stats with self-deprecating ones. 425M+ shares in 2024. The user shares themselves, not Spotify.

*Steal:* Annual Season Wrapped (September 2026 for NFL opener) as planned marketing campaign. Mixed serious/playful tone. Auto-generated share cards as primary virality unit.

**Duolingo** — 600+ experiments on streaks alone. 7-day streak users 3.6x more likely to retain. Streak Freeze reduced churn 21% among at-risk users.

*Steal:* Streak around self-review (not bet frequency). "Review streak about to break at midnight" notification. Borrow the loss-aversion mechanic, NOT the passive-aggressive tone.

**Strava** — Stats-stickers-over-photos. Local Legend (frequency, not speed). Annual recap. Default private but one-tap sharing.

*Steal:* Democratized recognition. Anonymous cohort comparison ("How you compare to other Heat Chasers") at v2.

**Calm/Headspace** — Notification permission primer that converts at 60-80% vs 20-30% cold-ask floor. Ask after the value moment.

*Steal:* Permission primer after archetype reveal. Realistic target for BetAutopsy: 35-50% prominent opt-in (niche behavioral app).

**Cal AI** — Onboarding quiz first to build sunk-cost commitment. Full paywall after onboarding. 123 paywall experiments across 46 trigger points in 10 months. Hit ~$40M ARR before founders turned 20.

*Steal:* Quiz before paywall pattern. Aggressive paywall experimentation. Multiple trigger points, not one cold paywall. BUT: only paywall after at least one real CSV analysis has run.

### The 10 patterns BetAutopsy should adopt, ranked

1. Single hero score, color-coded, on cover of every report and share card
2. 1080x1920 share cards as primary virality unit
3. Notification permission primer (target 35-50% grant rate for this category)
4. Onboarding quiz before paywall to build sunk-cost commitment
5. Reveal one specific finding from user's actual data before paywall
6. Behavioral streak grounded in process (review days, discipline days), not outcome
7. Card-based progressive disclosure for reports
8. Long-horizon metrics that mature at 30, 60, 90 days
9. AI chat layer grounded in user's own betting history as long-term moat
10. Aggressive paywall experimentation with multiple trigger points

---

## 2. Competitive map

### Pikkit owns descriptive, BetAutopsy owns diagnostic

Pikkit: 4.87 stars, ~19,000 reviews, $39.99/mo Pro or $299.99/year. Auto-syncs 30+ sportsbooks. Recent paywall changes generated negative review wave in 2025. Top complaints: sync bugs, missing books for non-US users, "greedy paywall" sentiment, sportsbook account-flagging concerns.

**What's almost completely absent from Pikkit's negative reviews:** the phrase "tells me I lost money but doesn't tell me why." Pikkit users have no vocabulary for "behavioral analysis" because they've never been shown a product that addresses it. BetAutopsy's marketing job is translating user language ("I keep doing X") into product language ("you have a chase-loss confirmation bias on home favorites in division games after a losing Saturday").

**The Pikkit Apple Review precedent is directly clonable:**
- Infrequent Simulated Gambling content descriptor (not Frequent/Intense)
- 18+ age rating (BetAutopsy uses 17+ which is also valid)
- Native iOS code (no HTML5 wrapper)
- Standard Apple IAP
- "Not a sportsbook, not a picks service" disclaimer in metadata and in-app
- 1-800-GAMBLER placement
- Responsible gaming partnerships referenced

### Action Network is opposite worldview

Action Network: exogenous (better picks/data → improve). BetAutopsy: endogenous (understanding self → improve). Their economic engine requires more bet frequency. BetAutopsy's economic engine requires more self-awareness. Permanent daylight between positioning.

Pricing: $7.99/mo Edge, $19.99/mo Pro, $99.99/year. Strong scoreboard, QuickSlip betslip, Live Activities, BetSync tracker. No behavioral analysis.

### The defensibility moats

**Pre-bet check-in (Siri shortcut, App Intents).** Interrupts the chase loop before the bet exists. Requires historical behavioral baseline to be useful — new entrants can't offer without first building analysis IP.

**Heated session detection.** Algorithmic real-time flag. No competitor has this.

**Archetype IP.** The five named archetypes (Surgeon, Heat Chaser, Parlay Dreamer, Grinder, Gut Bettor) become brandable identity. Once a user has been told they're a Heat Chaser, that label has equity competitors can't clone without looking derivative.

**Behavioral journaling.** Reddit advice for years has been "keep a betting journal." Nobody operationalizes the journal as an app surface. Structured journaling feeds the archetype model and creates defensible user data.

### Positioning sentence

> Pikkit tells you what happened. BetAutopsy tells you why you keep doing it.

Category language to own: behavioral betting analysis, forensic bet review, cognitive bias detection for bettors, bet post-mortem. Reference brands: "Whoop for bettors," "Strava for bettors."

---

## 3. The 7 moments of mobile-native value

A web app cannot deliver any of these. The native rebuild IS the moments.

### Moment 1: Cold open daily glance (the Whoop ritual)

One number animates up. Color-banded green/yellow/red. One verdict word below. Three contributing-input tiles. Total perceived time under one second to verdict. This is the dopamine pulse that earns daily opens without rewarding gambling behavior.

**Features needed for v1:** Today tab, BetIQ Score computation, count-up animation via `contentTransition(.numericText())`, color bands (green 67-100, amber 34-66, red 0-33), three contributing tiles.

### Moment 2: Notification tap from Weekly Autopsy (Monday 9am local)

Time-anchored, ritualized weekly cron. Notification body contains the actual insight, not a tease. Spotify Discover Weekly proves the weekly habit is the single highest-leverage retention engine for analytical products.

**Features needed for v1:** Trigger.dev v1.1 weekly cron, Monday 9am local-time scheduling, insight templating, deep-link routing.

### Moment 3: Pre-bet check-in (killer behavioral intervention)

"Hey Siri, pre-bet check-in with BetAutopsy." Three mood options (calm/hyped/tilted/drinking). One tap. Closes Siri with "Logged. Take a breath." No app launch required. Captures intent at moment of risk.

**Features needed for v1:** App Intent (`PreBetCheckInIntent`), `AppShortcutsProvider` for install-time voice phrases, mood enum, on-device persistence. **Honest scope: 4-6 engineer-days, not 2.** Real-time correlation to bet outcome is v1.1+ (requires real-time bet log).

### Moment 4: Heated session in-progress intervention (v1.1)

Real-time push notification when behavioral signals spike. Body always quotes the data ("Tilt Index just crossed 75. You have placed 3 bets in 9 minutes."). Soft action ("Three deep breaths, then decide"). Always includes "Mute for tonight" action.

**Features needed for v1.1:** real-time signal computation, APNs via Cloudflare Worker, `.timeSensitive` interruption level with Time Sensitive entitlement, mute-action handler, hard frequency cap.

### Moment 5: Archetype reveal share moment (Spotify Wrapped at any moment)

Animated full-screen reveal with swipeable 1080x1920 cards. Big type, color-coded per archetype, one stat per card, share button on every card with `ShareLink`. Success haptic at reveal.

**Features needed for v1:** `ImageRenderer` SwiftUI for on-device 1080x1920 PNG generation, archetype assets, NumberTicker reveal animation, ShareLink with `SharePreview`.

### Moment 6: Daily glance via Lock Screen widget (v1.1)

`accessoryCircular` ring with score, `accessoryRectangular` with score plus verdict word. Duolingo's iOS streak widget lifted daily commitment 60%.

**Features needed for v1.1:** WidgetKit extension, TimelineProvider, App Group for data sharing, two widget families.

### Moment 7: Active session Live Activity (v1.1)

Dynamic Island compact-leading session number, compact-trailing live BetIQ delta. Lock Screen banner with bets placed, time elapsed, heat indicator. Interactive "Pause session" button.

**Features needed for v1.1:** ActivityKit, Live Activity payload under 4 KB, App Intent for pause action, APNs push for updates from CF Worker.

---

## 4. Feature rerank: v1, v1.1, v2

### v1 (ship in 35-50 days): the actual native product

20 features. Ordered by mobile-native value divided by implementation cost.

1. **3-tab shell** (Today / Sessions / Reports). Avatar top-right of Today for Settings.
2. **Hero BetIQ Score** with count-up animation, color bands, verdict word, three tiles.
3. **Chapter-based report navigation.** 7-9 horizontally swipeable chapters. NOT a scroll port.
4. **CSV import via Files share extension and document type.** App Group, `public.comma-separated-values-text` UTI. **Budget 3 engineer-days, not 1** (real-device pain).
5. **Bet DNA Quiz reimagined as cold-launch archetype predictor.** 7 questions before any CSV. Predicted archetype in ~75 seconds. THE activation moment.
6. **Pikkit CSV education card** in onboarding with deep link to App Store.
7. **Grammarly paywall** with blurred dollar amounts, real archetype visible, three plan cards (Annual pre-selected). Post-archetype-reveal placement.
8. **Sample report on cold launch.** Solves the no-CSV activation gap for the 60%+ of users without CSV ready. Critical addition.
9. **Sign in with Apple after archetype reveal**, not before. Frame as "save your archetype."
10. **Notification permission primer after archetype reveal**, with provisional auth on first launch. Target 35-50% prominent opt-in.
11. **Siri pre-bet check-in via App Intent.** 4-6 engineer-days. Logged-moment only in v1.
12. **1080x1920 share card generator** via SwiftUI `ImageRenderer`. ShareLink on archetype reveal and report chapter endings.
13. **Responsible Use screen** in Settings: 1-800-GAMBLER, NCPG link, self-exclusion toggle.
14. **17+ age rating** with honest questionnaire answers. 21+ age gate as onboarding card 2.
15. **Privacy manifest (PrivacyInfo.xcprivacy)** declaring no tracking, purchase history, user content, four required-reason APIs.
16. **App Review notes paragraph** mirroring Pikkit precedent. Demo account with sample CSV, unlocked Pro entitlement.
17. **App Store listing**: subtitle "Forensic bet analysis & tilt," 5-7 screenshots, 15-second App Preview video.
18. **Weekly Autopsy push notification** via Trigger.dev v1.1 cron. Monday 9am local. Value in body.
19. **TelemetryDeck wired** for core funnel: install, quiz complete, archetype revealed, paywall view, purchase, weekly autopsy opened.
20. **RevenueCat with three SKUs**: $4.99 single (consumable), $14.99 monthly (auto-renew), $99.99 annual (auto-renew). Annual pre-selected with "Save $79.88" anchor.

Plus empty states with brand voice throughout.

### v1.1 (8-12 weeks post-launch): the moats

1. **Heated Session Alert push** (real-time, .timeSensitive)
2. **Live Activity for active session** (Dynamic Island + Lock Screen banner)
3. **Lock Screen widget** (accessoryCircular + accessoryRectangular) + home widgets (systemSmall + systemMedium)
4. **HealthKit sleep correlation** (read-only, opt-in). On-device only per Apple guideline 5.1.3(i)
5. **Streak system** (Days Reviewed, not days winning). Streak Freezes earned via Pro
6. **Apple Watch complications** via WidgetKit shared codebase. NO standalone watch app
7. **A/B copy harness for notification copy** (OneSignal or Customer.io)
8. **Apple native win-back offers** (StoreKit 2). 50% off two months for 31-90 day cohort
9. **Pause subscription** (1 or 2 months) as third option in cancellation flow
10. **Season Pass SKU** ($39.99 for 17-week NFL season) as consumable IAP. Stronger than 3-report bundle.
11. **Pertinent negatives and contradictions chapter** (port from web engine)
12. **Bet-by-bet annotations** (disciplined/emotional/chasing/impulsive/neutral) as Sessions tab filter
13. **Screenshot OCR via Vision framework** (for users without Pikkit CSV path)

### v2 (3-6 months post-launch): category-defining

1. **Ask the Analyst** AI chat grounded in user's own betting history. Whoop Coach pattern. Long-term moat.
2. **Long-horizon archetype evolution** (started as Heat Chaser at month 1, now Grinder)
3. **Anonymous cohort comparison.** Strava Local Legend pattern.
4. **Season Wrapped annual moment** (September 2026 NFL opener). Planned marketing campaign.
5. **Apple Watch standalone app**, ONLY if MAU exceeds 50K
6. **Sport-specific deep dives** as report chapters (NFL key numbers, NBA prop overexposure, etc.)
7. **Trigger.dev full migration** replacing Vercel dependency

### Permanent skips (cut from v1, never build)

- Lock Screen widget in v1 — defer to v1.1
- Live Activity in v1 — defer to v1.1
- Heated Session Alert in v1 — defer to v1.1
- Apple Watch app in v1 (and likely v1.1, v2 only if MAU >50K)
- ConfettiSwiftUI, Inferno Metal shaders, sound design
- iPad-optimized layout
- macOS Catalyst
- Animated digit roll (use `contentTransition(.numericText())`)
- Spotify Wrapped Season Recap in v1 (it's a v2 marketing moment)
- Dark mode toggle (app is midnight-themed only)
- Geo-restrict at runtime (use App Store Connect territory only)
- AUTOPSY50/PRODUCTHUNT promo codes (replace with Apple native promotional offers)
- Floating action button (anti-pattern)
- Custom tab bar (use SwiftUI TabView)
- Hamburger drawer
- Splash screen beyond launch
- Lottie animations
- Web view inside app
- Social feed

---

## 5. Mobile-native UX patterns

### Hero metric architecture (Whoop three-layer)

- **Layer 1:** The number. JetBrains Mono 96pt, midnight background, color-banded (green 67-100 "Disciplined," amber 34-66 "Drifting," red 0-33 "Heated"). Animate via `contentTransition(.numericText())` over ~800ms.
- **Layer 2:** Verdict word and trend arrow.
- **Layer 3:** Three contributing-input tiles (chase rate, stake variance, session length deviation). Tap any tile for 7-day sparkline.

Hero metric is **BetIQ Score**. Not Discipline (too moralizing). Not Days Since Heated Session (anxiety-inducing).

### Chapter-based report (replaces AutopsyReport.tsx)

7-9 horizontally swipeable chapters:
1. Your score and verdict
2. Where you bled value (the leaks)
3. When you bet badly (timing patterns)
4. What you bet on (sport/market mix)
5. Stake discipline (variance and chasing)
6. Sleep and session correlation (v1.1)
7. Streaks and milestones
8. Comparable archetype
9. Recommended next 7 days

Each chapter: one hero viz, max three short paragraphs, one "what to do" line. Cap reading time at 20s per chapter. Final chapter: "Share your archetype" with `ShareLink`. 9-dot pagination indicator. Selection haptic on snap.

### Tab bar

3 tabs only: Today / Sessions / Reports. Resist 4th tab until BetAutopsy ships a coaching product.

### Haptic discipline

| Moment | Generator | Style |
|---|---|---|
| Score lands on dashboard open | UIImpact | .rigid |
| Archetype reveal | UINotification | .success |
| 7-day streak milestone | UINotification .success + UIImpact .heavy (180ms later) |
| Chapter swipe | UISelection | default |
| Pull-to-refresh threshold | UIImpact | .medium |
| Share completion | UINotification | .success |
| Heated session warning | UINotification | .warning |
| Paywall reveal | None (reads as manipulative) |
| Settings toggle | None (system handles) |

Always call `prepare()` ahead of time. Never play haptics on cold start. Always pair with visual change.

### Empty states (brand voice)

- No bets: "No bets logged. Upload a CSV or run a Siri check-in to start the autopsy."
- No reports: "Reports unlock at 25 logged bets. You have 8."
- Loading report: "Reading the body. (Compiling 47 metrics.)"
- Empty session: "Quiet day. Sometimes that's the win."
- Error: "Couldn't parse that CSV. Mind sending it to support?"

### Native iOS patterns to adopt

`ShareLink` everywhere. `.refreshable` on Sessions tab. App Intents for Siri. WidgetKit (v1.1). ActivityKit (v1.1). HealthKit read-only opt-in (v1.1). `contentTransition(.numericText())` for score count-up. Document type + share extension for CSV. Symbol Image assets for custom marks. Native paywall sheets, not full-screen modals.

---

## 6. Notification taxonomy

### Cardinal rule

Deliver value in notification body, never tease. Every behavioral signal must be quoted in body with direction and comparison.

### Permission strategy

On first launch: provisional only (`UNAuthorizationOptionProvisional`). No upfront prompt. Notifications deliver quietly to Notification Center.

After archetype reveal + 1-2 quiet notifications: fire custom primer:
> Want a Monday morning autopsy?
> Every Monday at 9am we send one specific insight from your week. Like "You bet 47% more after a loss on Sunday." No spam.
> [Turn on alerts] [Not now]

Target: 35-50% prominent opt-in.

### Frequency caps

Hard cap: 1 notification/day, 4/week. One mandatory non-notification day per week. Heated Session Alert (Tier 1) can override cap (safety-relevant). Per-user adaptive reduction by 50% if 14-day open rate falls below personal baseline. After 2 weeks low engagement: pause non-Tier 1 for 7 days, resume with Weekly Autopsy.

### Interruption levels

- Weekly Autopsy, Streak protection: `.passive`
- Pre-bet check-in reminder, Archetype shift: `.active`
- Heated Session Alert: `.timeSensitive` (request entitlement)
- Never `.critical`
- `relevanceScore`: Heated 1.0, Archetype Shift 0.7, Weekly Autopsy 0.5, Streak 0.3
- Default quiet hours: 11pm-8am local

### Copy library (excerpt)

**Weekly Autopsy (Monday 9am local, .passive)**
- "Last week you placed 23 bets. 17 came after 10pm. Win rate before midnight: 54%. After midnight: 31%."
- "Your discipline score for the week is 62, down 8 points. The drop tracks to four parlays placed during Sunday's Chiefs game."
- "You chased two losses last week. Both came within 18 minutes of a losing bet. Heat Chaser pattern, week 3 in a row."

**Heated Session Alert (v1.1, .timeSensitive)**
- "Tilt Index just crossed 75. You have placed 3 bets in 9 minutes. Three deep breaths, then decide."
- "You are betting 2.4x your usual stake size right now. Pausing to check is not the same as stopping."

Every Heated Session Alert includes "Mute for tonight" UNNotificationAction.

**Streak protection (.passive)**
- "Day 14 of pre-bet check-ins. One tap keeps it alive."
- "Streak: 21 days. Longest in your archetype's top 20%."

Positive framing. Never about not betting (perverse incentive). Always about reviewing behavior.

---

## 7. Monetization architecture

### Conversion expectations (no trial)

RevenueCat 2026 data (115K+ apps): hard-paywall 10.7% download-to-paid Day 35; freemium 2.1-2.2%; top quartile 38.7%. BetAutopsy's Grammarly soft paywall sits at top of freemium.

Realistic blended targets:
- Install → paywall view: 60-80%
- Paywall view → any purchase: 3-6%
- Install → any revenue: 1.5-4% at launch, 3-5%+ healthy
- Mix: 60-70% single / 30-40% subscription at launch
- Single → sub upgrade within 30 days: 15-25% if prompted well
- Annual share of new subs: 30-50% (annual retains 2.5x better)
- Blended ARPU per install at Day 60: $0.40-$1.20

### Why no trial was right

80-90% of trial decisions happen Day 0; 55% of cancellations within 24 hours. Trials front-load decision. $4.99 single functions AS the paid trial. Apple Small Business 15% rate: BetAutopsy nets ~$4.24, ~$12.74, ~$84.99 per SKU.

### Paywall placement

1. **Primary:** post-data-import, post-archetype-reveal. Real archetype name visible. Real bias tags. Dollar amounts blurred ($▓▓▓). Three plan cards, Annual pre-selected with "MOST POPULAR."
2. **Dashboard locked tiles.** Two of six tiles blurred (Bias Heatmap, Action Plan) with "$▓▓▓ locked."
3. **Single → sub upsell.** Post-purchase footer: "Get next week's autopsy automatically. Upgrade and your $4.99 applies."
4. **Win-back paywall.** Apple StoreKit 2 native (v1.1).

### Annual anchor copy (3 variants to A/B)

**A: Loss-prevention**
> Don't lose your insights.
> Annual Pro: $99.99 ($8.33/mo). You save $79.88 vs monthly.

**B: Months-free (recommended primary)**
> Pro for an entire betting year, plus 5 months free.
> $99.99/year ($8.33/mo). vs $179.88 if paid monthly.

**C: Daily cost trivialization**
> Less than $2/week for the discipline that pays for itself.
> $99.99/year. Cancel anytime. Save 44%.

### Single → sub pathway (3 touches over 30 days)

1. **T+0** modal: "Your $4.99 counts toward Pro. Upgrade in next 7 days, first month is $9.99."
2. **T+7** push: "Your bias patterns have shifted. See what changed → Upgrade."
3. **T+21** in-app banner with annual anchor.

Stop pushing after T+30.

### Retention targets

| Metric | Realistic at launch | Stretch |
|---|---|---|
| Install → purchase | 3-5% | 6-8% |
| Single → sub (30 day) | 15-20% | 25%+ |
| Annual share of new subs | 30-40% | 50%+ |
| D1 retention (blended) | 35-45% | |
| D7 retention (blended) | 18-25% | |
| D30 blended | 10-15% | 18-22% |
| D30 paid only | 50-60% | 65%+ |
| D90 paid only | 45-55% | 60%+ |
| Annual sub 12-month retention | 45-55% | 60%+ |

Industry median D30 across consumer apps: 5-7% (Adjust 2026). Casino/Sports Betting D30: 2.8-3.1%. Behavioral analytics with strong execution: 10-18%. BetAutopsy targets are top-quartile-realistic for solo founder.

---

## 8. Onboarding sequence (17 cards, target 75s to archetype reveal)

**Card 1: Hook (12s).** "Most bettors lose. Few know exactly why. BetAutopsy reads your bet history like a forensic accountant."
**Card 2: Age gate (8s).** "Quick check. To continue you must confirm 21 or older."
**Card 3: Show don't tell (15s).** Sample Heat Chaser report animation.
**Card 4: Quiz prelude (8s).** "7 questions, 60 seconds, no CSV needed yet."
**Cards 5-11: Quiz (45-60s).** Single full-screen question per card.
**Card 12: Archetype reveal (10s).** Spotify Wrapped-style full-screen.
**Card 13: Push permission primer (8s).** Custom modal previewing Monday autopsy.
**Card 14: Sign in with Apple (4s).** "Save your archetype."
**Card 15: Pikkit CSV education (15s).** Three paths.
**Card 16: Paywall.** Three plan cards.
**Card 17: First confirmed archetype reveal (post-payment).** Spotify Wrapped real data.

**OR sample report path** (for no-CSV users): cards 1-14, then sample report unlocked, paywall after sample experience.

---

## 9. App Store positioning

### Name and subtitle

**App name:** BetAutopsy (10 chars). Uncontested. Trademark search recommended.
**Subtitle:** Forensic bet analysis & tilt (28 chars).
**Promotional text (170 char):** "Upload your sportsbook CSV. We tell you when you tilt, what you chase, and which sessions cost you. No picks. No sportsbook. Just the autopsy."

### Description first 3 lines

> A bet tracker is just a spreadsheet. BetAutopsy is the autopsy.
> Upload your sportsbook CSV. Get a forensic, week-by-week analysis of every behavioral leak in your betting.
> Not a picks service. Not a sportsbook. Behavioral analysis only.

### Keywords (98 chars)

> tracker,sportsbook,bankroll,tilt,wager,analytics,parlay,nfl,nba,mlb,clv,discipline,journal,picks

Avoid plurals (Apple stems). Avoid words in name/subtitle. Avoid "gambling," "casino," sportsbook brand names.

### Category

**Primary: Sports. Secondary: Lifestyle.** Not Health & Fitness (medical re-eval risk). Not Finance (deceptive interpretation risk).

### Screenshots (5-7, 6.9" iPhone)

1. Hero claim + score. "One number tells you when you're betting badly."
2. The autopsy report. "9-chapter forensic report."
3. Pre-bet Siri check-in. "'Hey Siri, pre-bet check-in.' Stop the tilt before the bet."
4. Archetype reveal card.
5. Lock Screen widget + Dynamic Island composite (v1.1).
6. Sleep correlation chart (v1.1).
7. Privacy + not-a-sportsbook statement.

~90% of users don't scroll past screenshot 3. Order matters.

### App Preview video

15s vertical. In-app footage only. 10-25% conversion lift (realistic for behavioral apps; 35% is game-category average). DIY: QuickTime + CapCut free, or Final Cut Pro $304 one-time. App Preview Video Converter $5 for codec.

### Apple Review compliance

- Age rating: Simulated gambling = None. Gambling references = Yes Mild/Infrequent. Result: 17+ with "Infrequent/Mild Mature/Suggestive Themes."
- **Brazil exclusion required** (April 2025 update — gambling-references apps need Brazilian SPA license).
- **Geo-restriction: hybrid recommended.** Restrict to top 25 legal US states at App Store Connect territory level. Zero cost, eliminates reviewer-decision risk.
- 1-800-GAMBLER: paywall fine print, Settings, onboarding footer, heated session sheet, App Store description.
- Privacy manifest: NSPrivacyTracking false, purchase history, user content, 4 required-reason APIs.
- Review notes paragraph: Pikkit-precedent disclosure. Demo account with sample CSV.

### Localization

v1: English only. Spanish at v1.2 after US retention validated.

---

## 10. Budget allocation ($1-3K Year 1)

### Required (non-negotiable)

| Item | Cost |
|---|---|
| Apple Developer Program | $99/yr |
| Claude Pro | $240/yr |
| Anthropic API (production) | $400-600/yr (TestFlight adds ~$100) |
| Supabase Pro | $0-300/yr (free tier may carry through launch) |
| Domain | $30/yr |
| RevenueCat | $0 (free under $2.5K MTR) |
| TelemetryDeck | $0 (free under 100K signals/mo) |
| Trigger.dev | $0 (free tier) |

**Subtotal: ~$870-1,270**

### Recommended

| Item | Cost |
|---|---|
| App Icon (Fiverr) | $150 |
| App Preview video (DIY) | $5-304 |
| Beta tester gift cards | $100 |
| Screenshot Studio | $30-50 |
| Sentry | $0-312 |
| OneSignal/Customer.io (v1.1) | $0-108 |

**Subtotal: $285-1,024**

### Hidden costs not in original budget

- LLC formation (if not done): $50-500
- Trademark search ("BetAutopsy"): $100-300
- Personal → LLC developer account transition: potentially second $99
- Beta tester payment processing
- Time cost of self-designed icon: 5-15 hours hidden cost

### Realistic Year 1 spend

| Scenario | Total |
|---|---|
| Lean (free tiers maxed) | $1,200-1,500 |
| Mid case | $1,800-2,300 |
| Comfortable | $2,500-3,000 |

**Budget verdict: $1,800-2,500 is the achievable realistic band.** $1-3K window holds. Biggest unknown: Anthropic API consumption at scale.

### Anthropic API cost model warning

Budgeted $400-600 assumes 200-500 reports analyzed via Claude. If BetAutopsy gets 1,000+ paying users in Year 1, each running 5-10 reports = $1,500-3,000+ in API costs alone.

Mitigations:
- Cache analysis results aggressively (same CSV = same report)
- Use Haiku for cheaper sub-analyses
- CF Worker streaming caps cost

---

## 11. Risk register

### Apple Review risk

**Geo-restriction pushback** (medium probability). Mitigation: hybrid approach — App Store Connect territory restriction to 25 legal states. Zero runtime cost.

**Brazil exclusion** required (high probability — April 2025 Apple update).

**Age rating interpretation** (low probability if questionnaire answered honestly).

**Description language match Pikkit precedent verbatim.**

**"Apple rejects gambling-adjacent at all" tail risk (15-25%).** Plan B: pivot to "responsible gambling tools" with mandatory daily limits, NCPG partnership upfront, more aggressive 1-800-GAMBLER.

### Solo founder bandwidth

1. Share extension for CSV: budget 3 engineer-days, not 1
2. Privacy manifest with third-party SDKs: half-day
3. App Intents for Siri: 4-6 engineer-days (not 2)
4. Chapter-based report redesign: 5-8 engineer-days (biggest design lift in v1)
5. App Store submission cycle: 2-3 weeks for review + iteration, not 1

### Vercel backend reliance

- 5min function timeout: confirm largest CSV (~10K bets) fits
- No offline state: add offline banner + retry queue
- Trigger.dev migration: defer to v2

### No-CSV cold-start problem (biggest activation risk)

60%+ of users won't have CSV ready on day 1. Pikkit onboarding takes 1-3 days. Solutions ranked:
1. **Sample report on cold launch** (recommended v1)
2. **Pikkit affiliate link with onboarding sequence** (already planned)
3. **Screenshot OCR via Vision framework** (v1.1, was v2)
4. Manual bet logging (v2+, large build cost)

### Pikkit dependency

Pikkit may move CSV export behind paywall. Mitigation: support direct CSV from DraftKings, FanDuel, BetMGM. Long-term: screenshot OCR via Vision.

### Capacitor lessons applied to native

What killed Capacitor likely: web view performance on 3,384-line report, App Store Review hybrid pushback, share extension impossibility, push UX friction, App Intents impossibility, WidgetKit impossibility, ActivityKit impossibility, HealthKit complexity, no Lock Screen presence. **Native rebuild solves every one.** Highest-risk native features inherited from Capacitor pain: Share Extension, push notifications. Budget extra time on both.

---

## 12. Master plan v5 — the revision from v4

### Five structural changes

1. **Reframe v1 product as native, not port.** Throw away ~60% of AutopsyReport.tsx visual hierarchy.
2. **Promote Bet DNA Quiz to v1 activation funnel.** Without it, upload-first loses 80% of users.
3. **Promote Siri pre-bet check-in to v1** (logged-moment only). 4-6 engineer-days. Marketing differentiator.
4. **Demote Lock Screen widget, Live Activity, Heated Session Alert to v1.1.** Cumulative cost exceeds v1 budget.
5. **Replace AUTOPSY50/PRODUCTHUNT codes with Apple native promotional offers and win-back offers.**

### Revised timeline (5-6x pace doesn't apply to all things)

5-6x pace applies to: coding, design, configuration.
Does NOT apply to: Apple Review wait, TestFlight beta minimum 7 days, privacy manifest debugging, share extension real-device, marketing collateral focused hours.

- **TestFlight (internal):** 14-21 days
- **TestFlight (external, 10 testers):** 21-30 days, run 7 days minimum
- **App Store submission:** Day 28-35
- **App Store live:** Day 50-75 (assumes 1-2 rejection cycles)

**Realistic launch window: 50-75 days.** Stretch: 35 days only if zero rejection cycles.

### Five decision points (next coding session)

1. Hero metric BetIQ Score? **Recommended: Yes**
2. Three tabs or four? **Recommended: Three**
3. Chapter-based report or scroll port? **Recommended: Chapters (7-9)**
4. Geo-restrict at launch? **Recommended: Hybrid (App Store Connect territory, 25 legal states)**
5. Ship Siri pre-bet check-in in v1? **Recommended: Yes, logged-moment only**

---

## 13. Retention engine roadmap

Priority order:
1. Weekly Autopsy notification + cron (v1)
2. Hero BetIQ Score daily glance (v1)
3. Archetype identity reinforcement (v1)
4. Streak system around self-review (v1.1)
5. Lock Screen widget (v1.1)
6. Heated Session Alert (v1.1)
7. HealthKit sleep correlation (v1.1)
8. Ask the Analyst AI chat (v2)
9. Season Wrapped annual moment (v2)

### Churn signals to instrument from day one

- No CSV upload in 7 days = at-risk
- No app open in 14 days = high churn risk; trigger win-back
- No engagement with weekly digest 2 weeks in a row = churn imminent
- Subscription renewal in <30 days + low engagement = pause/discount offer trigger
- 5+ consecutive Weekly Autopsy notifications unopened = pause cadence

### Cohort analysis priorities

1. Paid vs free retention curve
2. Archetype-based retention (do Heat Chasers churn faster than Grinders?)
3. Onboarding completion vs not
4. Notification opt-in vs opt-out
5. Annual vs monthly 12-month retention

---

## 14. Top 10 recommendations (scrutinized version)

1. **Redesign for mobile-native, do not port the web report.** Throw away 60% of AutopsyReport.tsx visual hierarchy. Build 7-9 chapter swipeable report instead.

2. **Promote Bet DNA Quiz to cold-launch activation funnel.** 7 questions, 60s, archetype reveal at 75s. THE activation moment.

3. **Ship Siri pre-bet check-in in v1 (logged-moment only, 4-6 engineer-days).** Behavior correlation tied to next CSV upload, not real-time. Real-time correlation is v1.1+.

4. **Adopt Grammarly paywall with three plan cards, annual pre-selected.** Annual anchor copy: "Pro for an entire betting year, plus 5 months free. $99.99/year vs $179.88 if paid monthly."

5. **Defer Lock Screen widget, Live Activity, Heated Session Alert to v1.1.** Cumulative cost exceeds v1 budget. These are the v1.1 moat.

6. **Use Apple native win-back offers and promotional offers.** Drop AUTOPSY50/PRODUCTHUNT system entirely.

7. **Adopt three tabs (Today / Sessions / Reports), not four.** Avatar top-right of Today for Settings, Profile, Paywall, Responsible Use.

8. **Hybrid geo-restriction: App Store Connect territory to top 25 legal US states.** Costs nothing. Eliminates reviewer risk. Pikkit nationwide is defensible but riskier for new app.

9. **Target Day 30 paid retention 50-60% at launch, 60-70% as stretch.** Annual sub 12-month retention 45-55% realistic, 60%+ stretch.

10. **Budget $1,800-$2,500 for Year 1 outside marketing.** Required core $870-1,270. Recommended $285-1,024. Add hidden costs (LLC, trademark, transition). Anthropic API consumption is biggest unknown.

11. **NEW: Solve the no-CSV cold-start problem in v1.** Sample report on cold launch is critical addition. 60%+ of installs won't have CSV ready day 1.

### Final answer

**Redesign for mobile-native. Do not port the report.** The web product proves the analytical engine works. The native product is a different product with different unit primitives: one hero number, swipeable chapters, share cards, voice intents, ambient widgets, real-time alerts. Pikkit's reviews show that a tracker (even a beloved 4.87-star one) cannot answer "why I keep doing this." BetAutopsy's category-defining bet is not a better report. It is a behavioral product that lives where the bet decision lives.

Ship in 50-75 days, learn for 60, build the v1.1 moat in the following quarter, position for September 2026 NFL kickoff Season Wrapped moment as the marketing event. That is the actual product strategy.

---

*Source of truth for v1 product decisions. Locked May 10, 2026.*
*Supersedes master plan v4. Master plan v5 is THIS document plus the 5 decisions.*
