# BetAutopsy voice and copy system

A canonical reference for every copy decision in the product. Save this alongside CLAUDE.md and BETAUTOPSY_IOS_MASTER_PLAN.md. When Claude Code writes user-facing copy, this file is the source of truth.

## What this document is, and what triggered it

PR-4 Phase 3 shipped with "Unlock the full autopsy" on the Chapter 7 paywall button and "Unlock the dollar costs, recommendations, and session details for $19.99" as the subtext underneath. Both strings violate the locked banned-phrase list in CLAUDE.md. The session that wrote them flagged the contradiction in its summary, then shipped anyway. That is the wrong order of operations, and this document exists to prevent the next instance.

**Unsourced constants (read before pasting any example).** Two numbers recur in the examples below and are NOT cleared to ship: the "$3,284 average annual loss" stat and any "23 pages" / page-count anchor. Per voice rule 7 (numbers cited in copy must be sourced; no fabricated statistics), neither may reach a user-facing surface until: (a) $3,284 carries a verifiable public citation, recorded here when sourced, and (b) the page/length anchor is replaced with an accurate descriptor of the live single-scroll reader (the report is not 23 paginated pages; see Section 3C). Until then, treat both as TKTK placeholders that demonstrate sentence structure only.

**Canonical helpline (current NCPG set, locked).** The problem-gambling helpline is: call 1-800-MY-RESET, text 800GAM, chat ncpgambling.org/chat. The legacy 1-800-GAMBLER number is retired. In tight inline brand lines (the paywall compliance line, the auth and bankroll callouts) use the call number alone and keep "We can wait." verbatim; in the dedicated helpline surfaces (Settings, the responsible-use card) show all three contact methods.

The fix to that specific string is in Section 8. The rest of this document is the system that makes the fix non-negotiable: a banned-phrase replacement matrix, a copy decision matrix for every product surface, a voice principles framework, a hundred canonical examples ready to paste, and a workflow change for Claude Code sessions that treats spec contradictions as stop conditions rather than ship-with-a-note conditions.

The voice this product is reaching for already lives at the intersection of five reference apps. Whoop's hard-truth clinical structure ("Red: 1 to 33 percent. Not recovered, and not prepared to take on Strain. Rest is likely what your body needs."). Linear's restrained SaaS premium ("Move work forward across teams and agents."). Stripe's number-anchored fintech calm ("Businesses on Stripe generated $1.9T in 2025."). Apollo Neuro's mechanism-naming ("stimulates the vagus nerve," "based on over 60 years of research"). Robinhood's post-2021 compliance honesty ("You should be prepared to lose all of the funds that you use for day trading."). None of these apps holds the whole voice. BetAutopsy's job is to be the first that does.

The voice this product must never reach for is also clear from the audit. DraftKings' "Get in on the action." FanDuel's "Lightning fast." BetMGM's "Elevate every game." Jackpot Party's "BIG WIN" celebration overlays. Cal AI's "Insanely accurate." Co-Star's "you talk about other people because you don't have your own life." Each represents a different way to sound wrong: hype, conquest, royalty, slot machine, overclaim, contempt. The forensic-but-warm register is what's left when you subtract all six.

## The audit, distilled into ten patterns worth stealing

**One. Continuation framing beats gate framing.** Stripe uses "Start now." Linear uses "Get started." 16Personalities uses "Continue" on the paywall itself, paired with a price anchor. None of them use "Unlock." The mental model is that the user is already inside the document and scrolling further, not standing outside a locked room with a coin in hand. Gate metaphors are casino metaphors. Continuation metaphors are document metaphors. Pick the document.

**Two. The product's nouns carry the brand. The verbs and adjectives stay quiet.** Autopsy. Report. Session. Decision. Pattern. File. Verdict. These nouns alone make the product sound forensic. When a Whoop screen says "Recovery: 34 percent," the noun does the work. When a Stripe page says "$1.9T," the number does the work. Adjectives like "powerful," "smart," "advanced," "intelligent" add nothing the noun didn't already imply. Cut them.

**Three. Specific numbers outperform every hype word.** Apollo: "60 years of research." Stripe: "25,000 companies." Whoop: "The average Recovery for WHOOP members is approximately 58 percent." Headspace push: "The attention span of a goldfish is nine seconds." Specificity is the cure for hype because it is the opposite of hype. For BetAutopsy: "$3,284 lost on average per bettor per year" is worth more than any adjective ever written.

**Four. Hard truths are stated flatly with one next action.** Whoop's Red band copy is the template. Name the band. State the diagnosis in one sentence. Give one next step. No apology. No "unfortunately." No "however." Oura's "Pay attention" label is the gentler version of the same structure. BetAutopsy's BetIQ of 34 should read like a Whoop Red, not like a Headspace breath-in.

**Five. Errors admit fault flatly and don't grovel.** Stripe's "Your card was declined." has no period of empathy. Notion's "The only thing that's certain is that technology will break. We've fixed bugs for now." has dry humor and no apology. Headspace's "Sometimes a bug appears in the app and it distracts us. We removed that bug from this latest version." names the bug without blaming the user. None of them say "Oops" or "Whoops" or "Sorry about that." Neither should BetAutopsy.

**Six. CTAs describe the artifact, not the act.** "Get Notion free." "Become a member." "Try Calm Premium free for 7 days." "Start your free trial." The verb is doing a job, but the noun is doing the brand. "Sign up" is generic. "See your last 30 days" is BetAutopsy.

**Seven. Sensitive moments require system-language, not direct address.** Headspace says "the way we love a friend in need is the way we need to speak to ourselves." Apollo says "your body relaxes." Neither says "you should." For BetAutopsy, when the topic is tilt or chasing or loss-spiral behavior, the right frame is the pattern in third person ("the sequence shows tilt behavior at minute 47") or a system observation ("11 bets in 23 minutes, all post-loss"). Never "you tilted." The data says it without the writer having to.

**Eight. Paywall fine print is brand voice.** Robinhood's "You should be prepared to lose all of the funds." 16Personalities' "no sneaky renewals or hidden fees." Stripe's "no hidden fees." Fine print is where the brand proves it is not a sportsbook. BetAutopsy's fine print should sound like a clinic invoice, not a casino sign-up bonus.

**Nine. Compliance copy is primary, not footnote.** This is the inversion that defines the brand against the gambling vertical. Every sportsbook buries 1-800-MY-RESET in a concatenated footer paragraph after 800 words of promo. BetAutopsy puts it in persistent navigation and in onboarding before the audit feature. If the brand is loss-prevention, the loss-prevention copy is not fine print.

**Ten. Productive friction is the product. Don't sell it as frictionless.** Selling a behavioral-intervention product as "seamless" or "effortless" lies about what it does. The product's job is to make the user pause, sit with a hard read, and choose differently next time. "The work is in reading the report. We do the assembly." That distinction is the brand.

## The eleven voice principles

These are directives. Each is defended with reasoning and illustrated with a BetAutopsy-specific good-versus-bad example.

**Principle 1. Loss-prevention over feature-stack.** Every surface answers the question "what does this save the user." Never "what does this app do." The reasoning: the user is paying $19.99 to find out where $3,284 went. Feature-stack framing puts the app at the center. Loss-prevention framing puts the user's money at the center. Good: "Three patterns cost you $1,847 last quarter. The autopsy itemizes each." Bad: "Get advanced behavioral analytics with BetAutopsy."

**Principle 2. Specific dollars and percentages over vague claims.** Numbers carry trust the way adjectives used to. Use them. Never invent them. When real user data exists, cite it. When it doesn't yet exist, cite the public stat ($3,284/year average loss, sourced) or the structural fact ("Chapter 5 itemizes every bet that lost more than $50"). Good: "47 bets in 9 days. 11 placed within 4 minutes of a previous loss." Bad: "You've been betting a lot lately."

**Principle 3. Personal observation over moral judgment.** The forensic frame is observation, not verdict. Even when the data is damning, the writer notes the data; the reader supplies the judgment. Good: "The Saturday session ran 4 hours 17 minutes. Bet size grew 280 percent from minute 1 to minute 217." Bad: "You should stop chasing losses."

**Principle 4. Second-person for accountability. First-person plural sparingly for analyst voice.** "You" addresses the user as an adult. "We" is the analyst speaking, reserved for analyst-voice paragraphs in italic serif. Never "the team," never "the BetAutopsy family," never "us." Good: "We noticed a 41 percent jump in stake size after losses over $100. You may not have." Bad: "The BetAutopsy community is here to help you on your journey."

**Principle 5. Periods at the end of UI strings of three or more words. No period on single-word labels.** "Read the full report." gets a period. "Settings" does not. "Open" does not. "Cancel subscription" gets a period. This matches Linear's product-UI behavior and Stripe's marketing behavior. Periods make body copy feel finished and clinical. They also kill the temptation to add exclamation marks.

**Principle 6. Sentence case everywhere.** No Title Case headers. No ALL CAPS body. The only acceptable caps are proper nouns and the four severity labels in bias cards (CRITICAL, HIGH, MEDIUM, LOW), which earn their caps because they are taxonomic, not editorial. Linear, Stripe, and Notion all use sentence case CTAs. So does BetAutopsy. Good: "See the full autopsy." Bad: "See The Full Autopsy."

**Principle 7. Active voice for what the product does. Passive grace for what the user did.** When describing the product's action, name the subject: "We scored every decision." When describing the user's losing behavior, the passive can soften without lying: "11 bets were placed within 4 minutes of the previous loss" reads gentler than "You placed 11 bets within 4 minutes of losing." This is one of the few defensible uses of passive in product writing. Reserve for behavioral-finding cards. Use active everywhere else.

**Principle 8. Italic serif (Georgia) only for analyst voice.** The analyst voice is the product talking back. It appears in chapter intros, verdict paragraphs, and pull quotes. It is the longest-form voice in the product, and it is the only place sentences run past 20 words. Sans-serif is for UI, labels, and body. Mixing them is how the user knows when the product is speaking analytically versus mechanically. Never use italic serif on a button. Never use it in a push notification.

**Principle 9. Numbers in monospace. Language in sans. Italic for analyst.** The typographic discipline reinforces the voice discipline. When a number appears inline in a sans paragraph, it shifts to mono. This signals that the number is sourced, calculated, and citable, not rhetorical. Stripe's number-density reads as credibility because the numbers are visually distinct. BetAutopsy inherits this rule.

**Principle 10. Never moralize. Always behavioralize.** The product never says gambling is bad, that the user should stop, or that the user has a problem. It says what happened, in what sequence, at what cost. The 1-800-MY-RESET copy is the only place the product offers help, and it offers it without diagnosis. Good: "The session lasted 4 hours 17 minutes. Bet 14 was placed 38 seconds after bet 13 lost. Bet 14 was 3.1 times bet 1." Bad: "You may have a gambling problem. Please consider talking to someone."

**Principle 11. When in doubt, restructure rather than swap.** Most banned-word problems are sentence-structure problems wearing a vocabulary mask. If "Unlock the full autopsy" needs replacing, the best fix is often not a new verb but a new sentence. "Full autopsy. $19.99. One-time." has no verb at all and reads cleaner than any verb-led variant. Section 2's restructure-don't-replace pattern should be the default, not the fallback.

## Part 2. The banned-phrase replacement matrix

### 2.1 Unlock (as imperative CTA)

**Why banned.** Slot machines unlock. Loot boxes unlock. Sportsbook bonus bets unlock. For a product positioned against casino mechanics, the verb is contaminated at the root. Beyond the brand-fit problem, the word has decayed through overuse: every B2C app from meditation timers to tax software uses "Unlock Premium," so the phrase reads as template rather than thought.

**Best replacement.** "Read the full report." The verb is from documents, not games. The noun reuses the product frame. Pair with a price anchor and the line is done.

**Replacement options ranked.**
1. **Read the full report ($19.99).** Best general purpose. Document register, no hype.
2. **Run the full autopsy ($19.99).** Best when reinforcing the forensic noun is the priority. Pathology and software both "run" things.
3. **See the full autopsy ($19.99).** Best when pressure must be at its lowest. "See" promises nothing.
4. **Open the full report ($19.99).** Filing-cabinet verb, not treasure-chest verb. Works.
5. **Continue to the full breakdown ($19.99).** Continuation framing, kills the gate metaphor entirely.
6. **Show me the rest ($19.99).** First-person, warmest. Only on second or third paywall view.
7. **Pull the full file ($19.99).** Noir, detective-coded. Good on session-level paywalls.

**When to use no replacement.** When the price and the noun do the work alone: "Full autopsy. $19.99." This is the recommended ship for PR-4 Phase 3. See Section 8.

### 2.2 AI-powered (as a selling point)

**Why banned.** The phrase is ambient noise. Every B2C app claims it. Worse for BetAutopsy: "AI-powered picks" is the canonical phrase of the predatory tout-service tier of sports-betting tech. The forensic brand has to be a refuge from that vocabulary, not another voice using it.

**Replacements ranked.**
1. Name the method. "Decision-by-decision analysis of every bet." "Expected-value back-calculation." "Bayesian session weighting."
2. "Modeled on" with a quantity. "Modeled on 1.2M annotated sessions."
3. No qualifier. "Behavioral analysis." If the product does the analysis, the user assumes a computer is involved.
4. "Computed" or "calculated." "Your calculated tilt score is 0.62."

**Context.** Never on CTAs. Never in push notifications. Acceptable in App Store description only in mechanism-naming form ("Built on behavioral models trained on X sessions").

### 2.3 Leverage (verb form)

**Why banned.** Pure consulting-deck residue. Always means "use" and is always longer. Disrespects the reader.

**Replacements ranked.** Use. Apply. Read. Work with. Run. In every case "use" is the correct first attempt.

**Example.** Bad: "Leverage your bet history to find patterns." Better: "Use your bet history to find the patterns."

### 2.4 Actionable

**Why banned.** Tautology. If a recommendation isn't actionable, it isn't a recommendation, it's an observation. "Actionable insights" means "insight-shaped insights."

**Replacements ranked.** Just name the action. Concrete. Specific. Practical. Or drop the modifier entirely. "Three concrete changes for next session" beats "three actionable insights."

### 2.5 Game-changer

**Why banned.** Two problems. First, it's the single most-flagged overused marketing phrase across every copywriting source consulted. Second, and worse: it contains "game." For an app that's reframing sports betting away from "the game" toward decision analysis, the metaphor reinforces the wrong mental model.

**Replacements ranked.** Name the change. "Different." "Useful." No claim at all, show the diff. Example: "Most users find one decision pattern they didn't know they had within three sessions."

### 2.6 Next-level

**Why banned.** Gaming and loot-box adjacent. Same family of contamination as "Unlock."

**Replacements ranked.** Deeper. Closer. More detailed. Underneath. Example: "A closer read of the same session."

### 2.7 Journey

**Why banned.** Marketing filler at this point. Worse for BetAutopsy: "your betting journey" is the standard sportsbook onboarding euphemism. DraftKings and FanDuel use it to soften the fact that they describe gambling. If BetAutopsy uses the same phrase, it sounds like them.

**Replacements ranked.** History. Sessions. Track record. Pattern over time. Or no modifier at all: "your bets," "your decisions."

### 2.8 Proprietary

**Why banned.** "Proprietary methodology" reads as "we won't tell you how this works." For a forensic product whose value rests on transparency, the word inverts the brand.

**Replacements ranked.** Name the method. "Our" without the secrecy claim. "Built in-house." "Custom." Drop entirely.

### 2.9 Empower

**Why banned.** Overused into meaninglessness. Specifically contaminated for BetAutopsy: "empower" is the verb of choice for sportsbook responsible-gambling theater ("we empower players to set limits"). The brand needs distance from that register.

**Replacements ranked.** Help. Show. Give you. Let you. Example: "BetAutopsy shows you which decisions cost you and which ones just felt like they did."

### 2.10 And much more

**Why banned.** The single laziest phrase in feature lists. Asks the user to trust unspecified value, which is the inverse of forensic transparency.

**Replacements ranked.** Name one more item. Use a count ("Plus 11 more sections"). Use a category ("Plus the full timeline view"). Or end the list with a period.

### 2.11 Premium features unlocked

**Why banned.** Triple offense. "Premium" is vague. "Features" is engineering-side. "Unlocked" is casino-coded. Also the canonical post-purchase string in mobile games.

**Replacements ranked.** "Your full autopsy is ready." "The rest of the report is yours." "Full access, one-time." "You're in."

### 2.12 Most popular (on subscription tiers without real data)

**Why banned.** The FTC's 2022 Dark Patterns staff report explicitly flags fake social proof as a Section 5 violation. Beyond the legal risk: if BetAutopsy claims "Most Popular" without data and a user finds out, the entire forensic-transparency pitch dies.

**Replacements ranked.** Use real data with a specific percentage dated within 90 days ("Chosen by 64 percent of subscribers"). "Recommended for [user type]." "Our pick" (explicit editorializing). Or no badge at all.

### 2.13 Limited time (without a genuine deadline)

**Why banned.** Same FTC report flags false scarcity as Section 5 violation. For BetAutopsy specifically: fake urgency is the exact psychological lever sportsbooks use against compulsive bettors. The brand cannot use against its own users the mechanic it is defining itself against.

**Replacements ranked.** Only "limited time" when there's a real dated deadline ("Through November 30"). "While we're testing pricing." "For the first 1,000 subscribers" (only if real and visible). Or use the counter-urgency line as a brand differentiator: "No rush. The report stays in your library either way."

### 2.14 Boost, Maximize, Optimize (recommended additions)

**Why banned.** Sportsbook-stack vocabulary. "Boost" is literally a sportsbook product category ("odds boost," "profit boost"). "Maximize" and "optimize" are the verbs of bankroll-management influencers and tout services.

**Replacements ranked.** Improve. Tighten. Reduce. Spot earlier. Name the diff directly.

**Hard rule.** "Boost" is the most sportsbook-coded word in the English language. Never use, in any form, anywhere in the product.

### 2.15 Revolutionary, Cutting-edge (recommended additions)

**Why banned.** Top three most-overused marketing words across every copywriting source consulted. Now read as "we're not actually new."

**Replacements ranked.** State the fact. "First app to break out expected value per decision." "New." "Different." A version number or date. Or no adjective at all, which is almost always strongest.

### 2.16 Seamless, Frictionless (recommended additions)

**Why banned.** Beyond the cliché problem: the entire forensic premise is productive friction. The product's job is to make the user pause and think. Selling that experience as frictionless lies about what the product does.

**Replacements ranked.** Don't make a smoothness claim. "Quick." "In the background" (for data sync). "One tap" when literal. "Out of your way" for the sync layer specifically.

**Brand-defining line.** "Logs every bet automatically. The thinking is the part you do." Save this. It does the work of every "seamless" claim while being honest about which work is whose.

### 2.17 Easy, Simple, Effortless (recommended additions, conditional)

**Why banned.** The responsible-gambling research literature (BMC Public Health 2018) found bettors specifically reject messaging that feels condescending. Telling a bettor that understanding their losses is "easy" implies that if they hadn't figured it out, they were dumb. Forensic analysis isn't easy. Honesty about that is part of the brand.

Also: "easy parlays," "effortless payouts," "simple deposits" are the words sportsbook onboarding uses. The vocabulary of frictionless betting is the vocabulary BetAutopsy must not borrow.

**Exception.** "Simple" survives in narrow UI contexts. "Simple swipe to dismiss" is fine. "Simple way to understand your behavior" is not.

**Replacements ranked.** Quick (time, not difficulty). Clear (artifact, not effort). Straightforward. In plain terms. Plainly. Or drop the adjective entirely.

## Part 3. Copy decision matrix by surface

Each subsection answers: what voice rules apply, what tone to match, and 5 to 10 production-ready examples.

### 3A. Onboarding

**Voice rules.** No welcome flourishes. No "Welcome to BetAutopsy" copy. The first screen has stakes: this user is here because they think they have a problem with their betting or because they want a sharper read. Match that with seriousness, not friendliness. Cold-open the way Co-Star and Linear do. The 7-question quiz is the longest sustained voice surface in onboarding, so every question must be worth answering.

**Age gate copy.** "You must be 18 or older to use BetAutopsy. This app analyzes betting behavior. It does not facilitate, recommend, or place wagers." Pair with two buttons: "I'm 18 or older." and "I'm not." (No exclamation. No "Yes I'm 18!" energy.)

**Cold launch hook (first screen).** "$3,284 is the average annual loss for U.S. sports bettors. BetAutopsy tells you where yours went." Pair with one button: "Start the autopsy."

**Bet DNA Quiz question pattern.** Each question is a single sentence with a clear answer set of three to four options. No "how do you feel about" phrasing. No mood-board language. Examples:
- "After a loss over $100, what happens next, most of the time."
- "The bet sizes in your last session, compared to your first session."
- "When you place a parlay, the typical leg count is."

**Bet DNA Quiz answer options pattern.** Options describe behavior, not feeling. Avoid "I sometimes" and "I usually." Use concrete behavioral language:
- "I place another bet within five minutes."
- "I close the app and come back tomorrow."
- "I increase my stake on the next bet."
- "I switch to a different sport."

**Sample report preview copy.** "This is the autopsy of a real bettor's last 30 days. Names removed. Numbers real."

**Pikkit education card copy.** "Pikkit syncs your bet history from 30+ sportsbooks. We read what Pikkit pulled. We don't see your sportsbook login."

**Archetype reveal moment copy.** Reveal is one line, no fanfare. "You are a Heat Chaser." Followed by an italic serif paragraph (analyst voice) of three to five sentences describing the archetype's pattern, dollar impact, and most common failure mode. See Section 3K for analyst voice patterns.

**Sign in with Apple primer copy.** "We use Sign in with Apple so the report can find you on a second device. We don't see your email unless you choose to share it." One button: "Continue with Apple."

### 3B. Core product UI (Today, Reports, Sessions tabs)

**Voice rules.** Labels are nouns. Buttons are verbs. Periods on three-plus-word strings. No labels longer than three words. Range card labels are single words: Discipline, Heated session, Emotion, Variance. ("Tilt risk" is banned in product UI per the locked rule; use Emotion.)

**Section headers.** "Recent sessions." "This week." "Bias flags." "Dollar impact." Never "Your Recent Sessions" or "RECENT SESSIONS."

**BetIQ score callout copy pattern.** Number first, band second, one-line diagnosis third. "34. Heated. Your last 30 days show repeated post-loss stake increases." No emoji. No color words in the copy itself (the color does its own work).

**Verdict line (Georgia italic analyst voice).** One paragraph, three to five sentences, italic serif. See Section 3K.

**Empty state copy for each tab.**
- Today, no sessions yet: "No sessions logged in the last 24 hours. The Reports tab still has your last autopsy."
- Reports, no reports yet: "No reports yet. Upload a CSV to run the first autopsy."
- Sessions, no sessions yet: "No sessions on file. Sync from Pikkit or import a CSV to begin."

**Pull-to-refresh hint.** "Pull to check for new sessions." (Not "Pull to refresh!" and not "Refreshing...")

**Loading state copy variants.** See Section 5 for the full set. Default to specific verbs: "Reading the CSV." "Scoring decisions." "Assembling the autopsy." Avoid generic "Loading..." where possible. Never "One moment please."

### 3C. The report (single-scroll reader)

The live iOS reader is `ReportScrollContainer`: one continuous scroll organized into seven sections in order (Verdict, Findings, Heated and Discipline, Patterns and Timing, Sports, Protocol, Action), not seven separately paginated chapters and not a fixed page count. The seven legacy `Chapter*View` files are deprecated. Where this document still says "Chapter N," read it as voice guidance for the corresponding section; do not surface "Chapter N" or a "23 pages" count as user-facing copy (see the unsourced-constants note in Section 1).

**Voice rules.** Chapters open in analyst voice (italic serif). Bias cards use clinical taxonomic register with severity labels in all caps. Recommendation copy is imperative without scolding.

**Chapter titles.** Sentence case. No subtitles unless the chapter genuinely needs scoping.
1. Verdict.
2. The session log.
3. Decision quality.
4. Behavioral biases.
5. Dollar impact.
6. What you don't do.
7. Recommendations.

**Chapter intro lines (italic serif, two to three sentences each).** See Section 5 for canonical examples.

**Bias card titles, descriptions, severity labels.** Titles are noun phrases naming the bias clinically. "Hot-hand bias." "Loss-chasing." "Anchor bias on opening line." "Sunk-cost continuation." Descriptions are two sentences. First names the behavior, second names the cost. Severity labels are CRITICAL, HIGH, MEDIUM, LOW in all caps, the only caps in the product. Example card:

> **Loss-chasing.** HIGH.
> 11 bets were placed within 4 minutes of a previous loss greater than $50. The average stake on those bets was 2.8 times your session baseline. Direct dollar impact this quarter: $1,184.

**Pull quote pattern (italic serif).** "The bets after the bet you wanted to win cost more than the bet you wanted to win." Pull quotes are one sentence, occasionally two. They appear once per chapter, never twice. They are the brand at its sharpest. Save them.

**Pertinent negative cards (what you don't do).** This is the brand's signature analytical move. A pertinent negative names something the user is not doing that, in the corpus, correlates with loss. Example:

> **You don't bet underdogs at home.** Across the last 90 days, zero bets on home underdogs of more than +200. The corpus suggests this is a discipline marker, not a gap.

**Recommendation copy pattern.** Three recommendations per report. Each is a single imperative sentence followed by one sentence of context. Never more than two sentences per recommendation. Example:

> **Stop placing bets in the four minutes after a loss over $50.** That window cost $1,184 last quarter. It is the single largest correctable pattern in your data.

**Final chapter dismiss and share CTA copy.** "Save this autopsy." (Primary.) "Share the verdict." (Secondary.) No "Done!" no "Great work!"

### 3D. Paywall and purchase

This is the surface that triggered this document. The rules here are non-negotiable.

**Voice rules.** No urgency. No "Most Popular" badge unless real percentage data is shown. No verb that gates ("Unlock," "Get," "Claim"). Continuation framing. Price stated inline with the CTA. Trust copy under CTA names what is and is not happening ("One-time charge. No subscription.").

**Paywall headline patterns.** Five canonical headlines (see Section 5 for full set). Lead with the artifact, not the offer. "The autopsy is ready." beats "Upgrade now to see your results."

**Paywall subhead patterns.** Itemize contents in a single sentence. Use commas, not bullets. Use specific page counts when available. "Dollar costs, recommendations, and the full session timeline. 23 pages."

**Single Report card description ($19.99).** "One autopsy, one-time. The report stays in your library." This is the only SKU in v1. The 3-Report Season Bundle, Pro Annual, and Pro Monthly tiers are retired (pricing locked May 17, 2026: a single $19.99 consumable). Do not write copy for bundle, annual, or subscription tiers; they do not exist in v1.

**No anchor framing in v1.** With a single SKU there is no bundle or annual tier to anchor against, so there is no save-money arithmetic and no "months free" language. The price stands on its own next to the artifact: "Full autopsy. $19.99. One-time."

**Loss-prevention CTA copy.** Use sparingly and only when the user has actual data showing material losses. "Find out where the $1,847 went." This works as a paywall headline for a returning user. It does not work for a first-time user with no data uploaded yet.

**Trust copy below CTAs.** "Restore Purchases." "Terms." "Privacy." All lowercase or sentence case. No "Get help" gimmick links.

**Problem gambling copy.** Always present on the paywall. Treat as primary, not footnote. "If gambling has stopped being fun, call 1-800-MY-RESET. We can wait." The "We can wait" line is brand-defining. Use it.

**Post-purchase confirmation.** "The full autopsy is yours. We saved it to your library." One button: "Read the autopsy."

**Failure or decline messaging.** Borrow Stripe's flat register. "The card was declined. Your bank can tell you why. The autopsy is still here when you're ready."

**The specific PR-4 Phase 3 fix.** See Section 8.

### 3E. Share cards (1080x1920)

**Voice rules.** Share cards are public. They appear on X and Instagram. They get read by people who have never heard of the product. So they must be self-contained, opinionated, and never look like a sportsbook win-screen. No emoji. No green up-arrows. No "I just won." Number-led layouts. Watermark is small, low-saturation, off-axis.

**Archetype reveal share card pattern.**
> Heat Chaser.
> Your average stake doubles within 12 minutes of a loss over $50.
> BetAutopsy

**BetIQ score share card pattern.**
> BetIQ: 34/100.
> Heated. Three biases flagged. One correctable.
> BetAutopsy

**Bias-finding share card pattern.**
> Loss-chasing cost me $1,184 this quarter.
> BetAutopsy named it. I'm fixing it.
> BetAutopsy

**Final chapter share card pattern.**
> The autopsy said: stop betting in the four minutes after a loss.
> I tried it. Down 60 percent on tilt sessions.
> BetAutopsy

**Watermark and attribution.** Bottom-right, 16pt, sans, 60 percent opacity. "BetAutopsy" only. Never a URL. Never "Get yours at." The watermark is a signature, not an ad.

### 3F. Notifications

V1 is provisional only. Push is deferred to V1.1. The principles below should be locked now so V1.1 work doesn't drift.

**Voice rules.** No notification ever uses an exclamation mark. No notification ever uses urgency framing. No notification ever fires within two hours of a likely game window in the user's geography. Push frequency cap: one per week maximum unless the user explicitly opted into the Heated Session Alert. Push frequency floor: zero is acceptable.

**Permission primer modal copy.** "BetAutopsy can send one weekly summary push and, if you opt in, alerts when the model flags a heated session in your recent uploads. We don't push during game windows. We don't push promos." Two buttons: "Allow notifications." and "Not now."

**Settings permission denial passive banner.** "Notifications are off. The weekly summary still appears in the Today tab." Single button: "Open Settings to change this."

**Weekly Autopsy push (v1.1) pattern.**
- Subject: "This week's autopsy is ready."
- Body: "23 bets across 4 sessions. Two biases flagged. Read it when you have five minutes."

**Heated Session Alert push (v1.1) pattern. Only fires if the user explicitly opted into this alert during onboarding.**
- Subject: "Heated session flagged."
- Body: "The Saturday session matches your top-three heated-session patterns. The full read is in the Reports tab."

**60/90-day re-engagement push pattern (v1.1).** Tied to sports calendar but never to a specific game.
- Subject: "NFL kickoff is in nine days."
- Body: "Last season's autopsy is in your library. Worth a re-read before week 1."

### 3G. Errors and edge states

**Voice rules.** State the fact in one sentence. Name the next action in one sentence. No apology language. No "Oops." No "Sorry." No exclamation. Match Stripe's "Your card was declined." register.

**CSV upload failure (validation, format).** "This CSV doesn't match a sportsbook export we recognize. Upload a Pikkit export or contact support."

**CSV upload failure (network).** "Upload didn't reach us. Check the connection and try again."

**401 authentication expired.** "You're signed out. Sign in to keep the report in your library."

**400 bad request.** "Something in the request didn't parse. Try again. If it happens twice, the support email is below."

**429 rate limit.** "Too many requests in a short window. Try again in a minute."

**500 server error.** "Our side broke. We're already looking at it. Try again in a few minutes."

**Empty CSV.** "This file has no bets in it. Make sure the export includes settled bets."

**CSV with too few bets to analyze.** "We need at least 15 bets to score a session reliably. This file has 9. Add more, or upload a longer date range."

**App restart with no persistence (current v1 limitation).** "The last report doesn't persist between sessions in this build. Re-upload the CSV to see it again. Persistence ships in 1.1."

**Sign-in failure.** "Apple sign-in didn't complete. Try again. If it happens twice, check that you're signed into iCloud on this device."

**Restore Purchases failure / nothing to restore.** "Nothing to restore on this Apple ID. If you bought a report on a different account, sign in with that one."

### 3H. Settings

**Voice rules.** Section headers are noun phrases. Single nouns when possible. All lowercase sentence case. The destructive actions (Sign Out, Delete Account, Cancel Subscription) get full confirmation copy with no fake friendliness.

**Section headers.** "Account." "Subscription." "Privacy." "Support." "About." "Legal."

**Sign Out confirmation.** "Sign out of BetAutopsy. The reports stay in your library. You'll sign in again to read them." Buttons: "Sign out." and "Cancel."

**Delete Account confirmation.** "Delete your BetAutopsy account. This removes every report, every bet record, and every analysis. It cannot be undone." Buttons: "Delete account." (destructive red) and "Cancel."

**1-800-MY-RESET compliance copy.** "If gambling has stopped being fun, call 1-800-MY-RESET. The line is free and confidential."

**Privacy Policy / Terms of Service link copy.** "Privacy policy." "Terms of service." Lowercase. Period. No "View our."

**Restore Purchases button.** "Restore purchases."

**Cancel Subscription flow copy.** Not applicable in v1. The single $19.99 report is a one-time consumable, so there is no subscription to cancel and no cancel flow to write. (Retained as a heading only so a future subscription tier knows where its copy lives.)

### 3I. Marketing

Organic-only is Path A and is locked. That means every word the App Store, the SEO pages, the email sequence, and the influencer briefs use is doing brand work, not paid-acquisition work. The voice has to carry the conversion because nothing else will.

**App Store name and subtitle.** "BetAutopsy" / "Forensic bet analysis."

The current subtitle ("Forensic bet analysis & tilt") includes "tilt." Per the locked rule, "tilt" is allowed in blog and SEO but not in product UI. The App Store subtitle is borderline product UI. Recommendation: drop "& tilt." The subtitle reads cleaner as "Forensic bet analysis." If the keyword strategy needs "tilt," put it in the keywords field, not the subtitle.

**App Store description first 3 lines.** Three production-ready options in Section 5. Default:

> $3,284. That's the average annual loss for U.S. sports bettors.
> BetAutopsy reads your bet history and tells you where yours went.
> A 23-page forensic report, written by behavioral analysts.

**App Store promotional text (170 characters).** "A 23-page autopsy of your last 30 days of bets. Biases flagged, dollars itemized, three changes to try. One-time $19.99. No subscription required."

**App Store keywords (98 characters).** "bet tracker,tilt,gambling,bet analysis,sportsbook,parlay,bet history,bankroll,problem gambling,DFS"

**App Store screenshot captions.** Sentence case, periods at end. See Section 5.

**App Preview video voiceover or text overlay.** Fifteen-second vertical. Three scripts in Section 5. Lead with a number, not an animation.

**Per-archetype SEO page hooks.** Each archetype page opens with the same structure: one-line claim, one-line dollar impact, one-line invitation. Heat Chaser example:

> Heat Chaser is the archetype that doubles the stake within 12 minutes of a loss.
> The pattern costs the average Heat Chaser $1,847 a quarter.
> BetAutopsy maps yours, decision by decision.

**Per-sport SEO page hooks.** Sport-specific framing without celebrating the sport. NFL example:

> NFL bettors lose more on three-team parlays than on any other single product.
> BetAutopsy itemizes every NFL parlay in your last season.
> The autopsy is 23 pages. The verdict is one.

**Diagnostic-layer SEO keyword pages.** "Why do I lose at sports betting." "Am I a problem gambler." "Track my bets." Each page opens with a concrete answer in the first paragraph and frames the autopsy as the diagnostic, not the cure.

Example for "Why do I lose at sports betting":

> Most bettors lose for one of four reasons: stake-size escalation after losses, parlay over-correlation, line-shopping skipped, or sample size too small to know which. The autopsy tells you which one you are.

**Email subject line patterns.**
- Welcome: "Your autopsy is queued."
- Post-purchase: "The full autopsy is ready."
- Re-engagement (30 days): "Three biases we flagged are still in your file."
- Re-engagement (60 days, pre-NFL): "Last season's autopsy is in your library."
- Re-engagement (90 days, mid-season): "Nine games into the season. Time for a check-in autopsy."

**Social post copy patterns for archetype shares.** Match the share card text. Never use the post for a different headline than the card. Coherence is the brand.

**Micro-influencer brief copy.** The brief sent to creators for the unique-code outreach. The brief itself is brand copy. Use the same voice.

> Brief, in two parts.
> Part one. Your audience. We're not asking you to sell. We're asking you to tell your audience that BetAutopsy reads their bet history and writes a 23-page forensic report. The report names three biases costing them money. It is $19.99, one-time. There is no subscription on the single report.
> Part two. Your code. Your unique code gives the first 100 of your audience a free report. After that, $19.99 like everyone else. We don't want you to fake urgency. The 100-cap is the only scarcity, and it is real.

### 3J. App Review and compliance copy

**App Review notes paragraph (mirrors Pikkit precedent id1586567110).** "BetAutopsy is a behavioral analysis app. It reads bet history exports from sportsbook accounts the user already has. It does not facilitate, place, or recommend wagers. There are no real-money transactions inside the app. The product is one-shot diagnostic, similar in structure to 23andMe's report-first model. The user uploads a CSV (or syncs via Pikkit), takes a 7-question behavioral quiz, and receives a forensic report. Pricing is a single $19.99 one-time consumable report. There is no subscription. The app references the problem-gambling helpline (call 1-800-MY-RESET, text 800GAM, chat ncpgambling.org/chat) on the home tab and in settings, and is accessible to users 18+."

**Privacy manifest summary.** "BetAutopsy collects bet history data the user uploads, the quiz responses they provide, and a hashed Apple ID for sign-in. The app does not collect contacts, photos, location, or browsing history. Analytics are aggregated and not tied to identifiable users. Full disclosure in the privacy policy."

**"Not a sportsbook" disclaimer.** Place on the App Store description, the home tab, and the paywall. "BetAutopsy does not place bets. It analyzes your existing bet history."

**Behavioral analysis only disclaimer.** "BetAutopsy provides behavioral analysis. It is not financial, medical, or legal advice."

### 3K. Analyst voice (the Georgia italic moments)

This is the longest-form voice in the product and the one that needs the most care. Five canonical patterns and five sample paragraphs.

**Verdict paragraph pattern (Chapter 1).** Three to five sentences. The first sentence states the bettor's archetype and the most damning single number. The middle sentences walk through the pattern. The last sentence names one correctable thing. The voice is the sharp friend who happens to be a behavioral psychologist: precise, unsparing, never contemptuous.

**Sample verdict paragraph 1 (Heat Chaser).**

> *Across the last 30 days you placed 47 bets, and 11 of those landed inside the four minutes after a previous loss greater than $50. Those 11 bets were, on average, 2.8 times your session baseline stake, and they account for $1,184 of negative impact this quarter. The pattern is not exotic. It is the most common pattern we see, and it is the most correctable. Cut the four-minute window. Nothing else needs to change.*

**Sample verdict paragraph 2 (Surgeon).**

> *Your decisions are unusually clean. Bet sizing inside a tight band, line shopping evident across at least three books, and a parlay count that stays under three legs in 91 percent of cases. The verdict is not that you're losing because you're sloppy. It's that the variance on the sample you have is high enough that 30 days isn't telling you much. The recommendation is patience, not correction.*

**Sample verdict paragraph 3 (Parlay Dreamer).**

> *The session log reads like a wish list. 23 parlays in 30 days, average leg count 5.4, average implied probability 6 percent. Two of them hit, which feels like vindication and is not. At a 6 percent implied rate, two hits in 23 attempts is the median outcome, not the outlier. The dollar impact is $912 negative this quarter. The recommendation is a four-leg cap, tested for two weeks, scored honestly.*

**Sample verdict paragraph 4 (Grinder).**

> *You bet a lot and you bet small. 184 wagers, median stake $12, range tight. The good news is the discipline. The bad news is the rake. At your volume and your average odds, the house take alone is $284 a quarter, before any decision quality enters the math. The recommendation is not to bet less. It is to bet bigger and less often, on the spots where your read is strongest.*

**Sample verdict paragraph 5 (Gut Bettor).**

> *The session log shows a pattern of late entries on lines that have already moved against you. 31 bets placed inside the final 10 minutes before kickoff, 19 of them on the side the line moved away from. That is the structural definition of fading the public after the public has already been faded. The dollar impact is $623 a quarter. The recommendation is a hard rule: no live bet inside the final 10 minutes unless the line has not moved more than half a point from open.*

**Archetype description paragraph pattern (longer, three to five sentences, used on archetype reveal and SEO pages).** Open by naming the archetype's signature behavior. Middle sentences describe the typical dollar impact and the most common bias driving it. Close with the diagnostic question the archetype is most useful for answering.

**Pull-quote pattern (one sentence, sharp, often paradoxical).** "The bets after the bet you wanted to win cost more than the bet you wanted to win." "Variance feels like luck. Pattern is what you're left with when variance ends." "Your discipline shows up in what you didn't bet."

## Part 4. The fifty-plus canonical copy examples library

Production ready. No placeholders.

### Paywall CTA button labels (replacing "Unlock the full autopsy")

1. Read the full report ($19.99).
2. Run the full autopsy ($19.99).
3. See the full autopsy ($19.99).
4. Open the full report ($19.99).
5. Continue to the full breakdown ($19.99).
6. Pull the full file ($19.99).
7. Full autopsy. $19.99.

### Paywall subhead variants (replacing "Unlock the dollar costs...")

1. Dollar costs, recommendations, and session details. One-time charge of $19.99.
2. What it cost you, what to do about it, and the full session timeline. $19.99, one-time.
3. Includes the dollar impact, three recommendations, and the full session breakdown.
4. 23 pages. Dollar costs, recommendations, session details. $19.99, one-time.
5. Chapters 4 through 7. The dollar numbers, the bias cards, the recommendations.

### Paywall headlines

1. The autopsy is ready.
2. Tuesday's session, fully examined.
3. Three patterns surfaced. The full autopsy explains each.
4. You've seen the summary. The full autopsy goes deeper.
5. Find out where the $1,847 went.

### Archetype reveal moment copy variants

1. You are a Heat Chaser. The full description is below.
2. The model puts you in Heat Chaser. The pattern is documented in detail in chapter 4.
3. Heat Chaser. The archetype that doubles stake within 12 minutes of a loss.

### Empty state copy variants

1. No sessions logged in the last 24 hours. The Reports tab still has your last autopsy.
2. No reports yet. Upload a CSV to run the first autopsy.
3. No sessions on file. Sync from Pikkit or import a CSV to begin.
4. No biases flagged yet. We need at least 15 bets to score reliably.
5. No share cards generated. They appear here after each autopsy.
6. No saved verdicts. They land here once a report is complete.
7. No pull quotes saved. Tap and hold any paragraph to pin it.
8. No recommendations yet. They appear in chapter 7 of every report.
9. No notifications. The weekly summary appears on Sundays at 9am local.
10. No history. The first autopsy starts the file.

### Loading state copy variants

1. Reading the CSV.
2. Scoring decisions.
3. Assembling the autopsy.
4. Cross-referencing bias patterns.
5. Computing dollar impact.
6. Drafting the verdict.
7. Loading your last autopsy.
8. Syncing with Pikkit.
9. Ranking biases by severity.
10. Preparing the share cards.

### Error state copy variants

1. The card was declined. Your bank can tell you why. The autopsy is still here when you're ready.
2. Upload didn't reach us. Check the connection and try again.
3. You're signed out. Sign in to keep the report in your library.
4. Too many requests in a short window. Try again in a minute.
5. Our side broke. We're already looking at it. Try again in a few minutes.
6. This file has no bets in it. Make sure the export includes settled bets.
7. We need at least 15 bets to score a session reliably. This file has 9.
8. This CSV doesn't match a sportsbook export we recognize. Upload a Pikkit export or contact support.
9. The Pikkit connection timed out. Try the sync again in 30 seconds.
10. Apple sign-in didn't complete. Try again. If it happens twice, check that you're signed into iCloud on this device.

### Push notification subject and body pairs (v1.1 scoped)

1. Subject: "This week's autopsy is ready." / Body: "23 bets across 4 sessions. Two biases flagged. Read it when you have five minutes."
2. Subject: "Heated session flagged." / Body: "The Saturday session matches your top-three heated-session patterns. The full read is in the Reports tab."
3. Subject: "NFL kickoff is in nine days." / Body: "Last season's autopsy is in your library. Worth a re-read before week 1."
4. Subject: "Your three-month check-in." / Body: "It's been 90 days since your last autopsy. Sync to see what changed."
5. Subject: "Verdict updated." / Body: "We re-scored your last 30 days. The Heat Chaser pattern is down 23 percent."

### Analyst-voice verdict paragraphs

See Section 3K. Five paragraphs are written there, ready to ship.

### Share card text variants for Heat Chaser

1. Heat Chaser. Average stake doubles within 12 minutes of a loss over $50. BetAutopsy.
2. BetIQ: 34/100. Heat Chaser. Three biases flagged. One correctable. BetAutopsy.
3. Loss-chasing cost me $1,184 this quarter. BetAutopsy named it. I'm fixing it. BetAutopsy.
4. The autopsy said: stop betting in the four minutes after a loss. BetAutopsy.
5. Heat Chaser pattern: confirmed. Dollar impact: itemized. Recommendation: written. BetAutopsy.

### App Store description openings

1. "$3,284. That's the average annual loss for U.S. sports bettors. BetAutopsy reads your bet history and tells you where yours went."
2. "A 23-page forensic report on your last 30 days of bets. Biases flagged. Dollars itemized. Three changes to try. One-time charge, no subscription."
3. "BetAutopsy is what 23andMe would be if it analyzed your sports betting instead of your DNA. Upload your bet history. Get the autopsy."

### App Preview video script options (15-second vertical)

1. "$3,284. (beat) The average annual loss. (beat) BetAutopsy tells you where yours went. (beat) Forensic bet analysis. App Store now."
2. "47 bets. (beat) 11 placed in the four minutes after a loss. (beat) BetAutopsy named the pattern. (beat) Read your autopsy."
3. "You've seen your bets. (beat) You haven't seen them like this. (beat) 23 pages. (beat) $19.99. (beat) BetAutopsy."

### SEO page opening hooks

1. (Heat Chaser page) "Heat Chaser is the archetype that doubles the stake within 12 minutes of a loss. The pattern costs the average Heat Chaser $1,847 a quarter. BetAutopsy maps yours, decision by decision."
2. (NFL page) "NFL bettors lose more on three-team parlays than on any other single product. BetAutopsy itemizes every NFL parlay in your last season."
3. (Why do I lose at sports betting page) "Most bettors lose for one of four reasons: stake-size escalation after losses, parlay over-correlation, line-shopping skipped, or sample size too small. The autopsy tells you which one you are."
4. (Am I a problem gambler page) "We don't diagnose. We do show you, in numbers, how often gambling has stopped being fun in your last 90 days. If the answer alarms you, 1-800-MY-RESET is on every page of this site."
5. (Track my bets page) "BetAutopsy doesn't track bets. It autopsies them. Sync once, get a report, read it, sync again next month. The product is the report, not the dashboard."

### Email welcome sequences first-line patterns

1. "Your autopsy is queued. Three pages are ready now. The full 23 will be in your library in 4 minutes."
2. "We pulled 47 bets from your CSV. The scoring is running. The first chapter lands in your inbox in 4 minutes."
3. "Welcome to BetAutopsy. The report is the product. Everything else, including this email, is logistics."

### Micro-influencer brief snippets

1. "Don't sell. Tell your audience BetAutopsy reads their bet history and writes a 23-page report. The report names three biases costing them money. One-time $19.99."
2. "Your code gives the first 100 of your audience a free report. After that, $19.99 like everyone else. The 100-cap is the only scarcity. It is real."
3. "What we don't want from you: hype, parlay-pick promotion, 'click my link before midnight' urgency. What we do want: one sentence on what the autopsy told you."
4. "If your audience asks 'is this AI,' the answer is: we score every decision against expected value at the moment it was placed. Yes, computers do the math. The voice is human."
5. "Use the assets in this folder. Don't add green up-arrows, money-bag emoji, or 'big win' overlays. If a sportsbook would post it, we won't."

## Part 5. Beyond the canonical examples, the secondary library

(These exist because the brief asks for fifty to a hundred and the surfaces above don't cover everything CC will need. They are also production-ready.)

**Session log row labels.** "Stake." "Odds at placement." "Result." "EV at placement." "Dollar impact." "Decision quality."

**Decision-quality verdict words (chapter 3).** "Defensible." "Marginal." "Negative." "Indeterminate."

**Bias severity descriptions.** CRITICAL: "Causes more than 25 percent of session loss." HIGH: "Causes 10 to 25 percent of session loss." MEDIUM: "Causes 3 to 10 percent of session loss." LOW: "Causes less than 3 percent of session loss."

**Recommendation imperative openers (chapter 7).** "Stop." "Cut." "Cap." "Move." "Skip." "Hold."

**Share consent modal copy.** "Share the autopsy externally. Sportsbook account numbers, balances, and personal details are never included in share cards. Only the verdict, scores, and biases."

**Apple Health-style data disclaimer.** "Your bet history stays on your device and in our analysis pipeline. It is never sold and never shared with sportsbooks."

**Tilt education explainer (blog, not in-product).** "Tilt is a poker term for the loss of decision quality after a bad result. In sports betting it shows up as stake escalation, leg expansion on parlays, and entry timing decay. The autopsy flags it as Heated Session in product UI."

## Part 6. The Claude Code workflow lock

This document fails if it sits in the repo and isn't enforced. The enforcement happens in two places: CLAUDE.md and the PR review checklist.

### Lines to add to CLAUDE.md

> ## Copy rules (non-negotiable)
> 
> 1. Banned phrase list is canonical. The full list is in COPY_SYSTEM.md, section 2. Before writing any user-facing string, check that list.
> 2. If a spec contradicts the banned phrase list, stop. Do not ship the contradiction with a flag in the summary. Open a discussion. The right behavior is to surface the conflict before code is written, not after.
> 3. Surface-specific canonical examples live in COPY_SYSTEM.md, sections 3 and 5. When writing copy for a surface, read the canonical examples for that surface first.
> 4. No em dashes anywhere in user-facing copy.
> 5. No exclamation marks anywhere in user-facing copy.
> 6. Sentence case for all headers and CTAs. ALL CAPS only for the four bias severity labels.
> 7. Periods at the end of UI strings of three or more words.
> 8. Numbers cited in copy must be sourced. No fabricated statistics.
> 9. No first-name personalization in any string. Never "Hi Dan." Always "you" or implicit.
> 10. When in doubt, prefer restructuring the sentence over swapping the verb. Most banned-phrase problems are structure problems.

### File location for the canonical copy library

Save this document as `COPY_SYSTEM.md` at repo root, alongside `CLAUDE.md` and `BETAUTOPSY_IOS_MASTER_PLAN.md`. Cross-link from `CLAUDE.md` in the first hundred lines.

### Suggested workflow

When a CC session is asked to write user-facing copy, the steps are:

1. Identify the surface (paywall, onboarding, error state, etc.).
2. Open `COPY_SYSTEM.md` to section 3 for that surface.
3. Read the voice rules for that surface.
4. Read the canonical examples for that surface.
5. Write the copy.
6. Check every string against section 2's banned phrase list.
7. Check every string against the seven rules in `CLAUDE.md`.
8. If a banned phrase appears and the spec calls for it, stop and open a question. Do not ship.

### How to handle spec contradictions

The PR-4 Phase 3 incident is the case study. The spec said "Unlock the full autopsy." The CC session correctly identified that "Unlock" was banned, then wrote "Unlock the full autopsy" anyway, then flagged the contradiction in the summary. That is the wrong order.

The right order is:

1. Identify the contradiction at spec-read time.
2. Stop work on the surface.
3. Surface the contradiction with two or three concrete alternative options (using `COPY_SYSTEM.md` section 2 as the source).
4. Wait for a human decision.
5. Proceed.

If the human is unavailable and the work is blocking, ship the most conservative alternative from the canonical library and flag it in the summary. But the conservative alternative is never the literal violation. The default conservative ship for any "Unlock" string is "Read the full report." The default conservative ship for any "AI-powered" string is to drop the qualifier entirely. The default conservative ship for any "Most popular" badge without data is to delete the badge.

### Suggested copy review checklist at every PR

Add to the PR template:

> Copy review checklist
> - [ ] Every user-facing string was checked against the banned phrase list in COPY_SYSTEM.md section 2.
> - [ ] No em dashes in user-facing strings.
> - [ ] No exclamation marks in user-facing strings.
> - [ ] All headers and CTAs are sentence case.
> - [ ] Numbers in copy are sourced (no fabricated statistics).
> - [ ] If any banned phrase was needed by the spec, the contradiction was raised before code was written, not after.

## Part 7. Priority order for locking copy surfaces

Not all surfaces are equally urgent. Lock in this order.

**Priority 1, this week.** Paywall surface (the fix to PR-4 Phase 3). Section 8 is the specific shipping recommendation. This is the surface where the contradiction lives and the surface where the most dollars are at stake.

**Priority 2, within two weeks.** Chapter 1 verdict paragraph and Chapter 7 recommendation copy. These are the two surfaces that carry the brand voice at its most concentrated. If these are right, the rest of the report has a tone anchor to match.

**Priority 3, within a month.** Onboarding cold-launch hook, Bet DNA Quiz questions, archetype reveal moment. These set the user's expectation for the entire product experience.

**Priority 4, within a month.** App Store description, subtitle, screenshot captions, App Preview video script. Path A is locked organic-only, which means these surfaces are the entire acquisition funnel.

**Priority 5, within a quarter.** Error and edge states. There are about 15 of these and they're individually low-traffic, but they collectively define how the product feels under stress. Get them right once.

**Priority 6, within a quarter.** Settings, sign-out, cancel-subscription copy. Low traffic but high signal: these are the surfaces a user sees right before they decide whether the brand respects them.

**Priority 7, before V1.1.** Push notification copy and re-engagement email sequence. Push is deferred to 1.1 but the principles need to be locked now so 1.1 work doesn't drift.

**Priority 8, when SEO sprints start.** Per-archetype and per-sport SEO page hooks. These should not ship until the first three priorities are done, because the SEO pages are the brand's outward face for cold traffic and they need the in-product voice to be settled first.

## Part 8. The specific PR-4 Phase 3 fix

The current ship has two strings to replace.

**Button.** "Unlock the full autopsy."

**Subtext.** "Unlock the dollar costs, recommendations, and session details for $19.99."

**The recommendation is to ship this replacement, exactly:**

> **Headline:** The autopsy is ready.
> **Subhead:** Dollar costs, recommendations, and the full session timeline. 23 pages.
> **CTA button:** Read the full report ($19.99).
> **Microcopy below CTA:** One-time charge. Yours to keep. No subscription.
> **Compliance line at bottom of paywall:** If gambling has stopped being fun, call 1-800-MY-RESET. We can wait.

**Why this exact combination.**

The button "Read the full report ($19.99)" wins for four reasons. First, "Read" is a document verb, not a gate verb. It removes the casino metaphor at the root. Second, "the full report" reuses the brand frame without overworking it. Third, the price is inline, which kills the friction of a separate price reveal and matches Stripe's price-anchored CTA pattern. Fourth, the parenthetical price doesn't strain the typographic system because the existing button uses no parentheses and has room.

The subhead "Dollar costs, recommendations, and the full session timeline. 23 pages." wins because it itemizes contents declaratively, with no verb. The original subhead's deepest problem was the verb-first structure, not the verb itself. By dropping the verb entirely, the new subhead reads as a table of contents rather than a sales pitch. The "23 pages" anchor at the end gives the user a concrete sense of what they're paying for, which is the antidote to the "trust us" feeling of "premium features."

The microcopy "One-time charge. Yours to keep. No subscription." is doing three jobs. It clarifies the billing model, which is the single most common paywall objection. It signals brand confidence by not hiding the terms. And it positions BetAutopsy against the subscription-by-default model that dominates the App Store, which is the brand's structural differentiator.

The compliance line "If gambling has stopped being fun, call 1-800-MY-RESET. We can wait." is treated as primary, not footnote, per Principle 10 and the audit finding that every sportsbook buries this copy. The "We can wait" line is the brand at its sharpest: it is the moment the product proves it is not a sportsbook by accepting that the user might choose not to buy. That acceptance is the brand differentiator. Use it.

**What not to ship.**

Do not ship "Get the full autopsy" as the CTA. "Get" is on the soft-banned list and adds nothing.

Do not ship "Unlock" with any other noun. The violation is the verb, not the noun phrase. Swapping "the full autopsy" for "complete analysis" or "detailed report" doesn't fix the contradiction.

Do not ship "Most popular" badging on any of the three pricing tiers. The data does not support it yet. When real subscription data exists, revisit.

Do not ship "Limited time" or "Save now" framing. There is no real deadline. Inventing one would violate Principle 11 and FTC guidance.

## Part 9. The Voice Quick Reference Card (one page)

> # BetAutopsy voice, one page.
> 
> **The voice.** Sharp friend who happens to be a behavioral psychologist. Direct. Smart. Never preachy. Clinical but warm. Forensic but not cold. Premium but not expensive. Loss-prevention, not feature-stack.
> 
> **The seven mechanical rules.**
> 1. No em dashes in user-facing copy.
> 2. No exclamation marks in user-facing copy.
> 3. Sentence case for everything except the four bias severity labels (CRITICAL, HIGH, MEDIUM, LOW).
> 4. Periods at end of UI strings of three or more words. No period on single-word labels.
> 5. Numbers in monospace, language in sans, italic serif only for analyst voice.
> 6. Never invent statistics. Cite real data or describe structural facts.
> 7. No first-name personalization. "You" or implicit.
> 
> **The eleven banned phrases plus their defaults.**
> - Unlock → Read.
> - AI-powered → name the method.
> - Leverage → use.
> - Actionable → name the action.
> - Game-changer → name the diff.
> - Next-level → deeper or closer.
> - Journey → history or sessions.
> - Proprietary → name the method.
> - Empower → help, show, give you.
> - And much more → name one more thing.
> - Premium features unlocked → "The full autopsy is yours."
> - Most popular → real percentage with date, or delete the badge.
> - Limited time → real dated deadline, or delete.
> - Boost, Maximize, Optimize → improve, tighten, reduce, spot earlier.
> - Revolutionary, Cutting-edge → state the fact, no adjective.
> - Seamless, Frictionless → quick, in the background, or no smoothness claim.
> - Easy, Simple, Effortless → quick, clear, straightforward.
> 
> **The eleven voice principles, one line each.**
> 1. Loss-prevention over feature-stack.
> 2. Specific dollars and percentages over vague claims.
> 3. Personal observation over moral judgment.
> 4. Second-person for accountability. First-person plural sparingly for analyst voice.
> 5. Periods on three-plus-word UI strings.
> 6. Sentence case everywhere.
> 7. Active voice for what the product does, passive grace for what the user did.
> 8. Italic serif only for analyst voice.
> 9. Numbers in monospace, language in sans.
> 10. Never moralize, always behavioralize.
> 11. Restructure rather than swap when in doubt.
> 
> **The default fallback strings.**
> - Paywall CTA: "Read the full report ($19.99)."
> - Error: "[Fact in one sentence]. [Next action in one sentence]."
> - Empty state: "[Why empty]. [Next action]."
> - Success: "[Fact]. [Where it went]."
> - Compliance: "If gambling has stopped being fun, call 1-800-MY-RESET. We can wait."
> 
> **When a spec contradicts this card, stop and ask. Don't ship with a flag.**

## Conclusion

The reason "Unlock the full autopsy" shipped is not that the rule against "Unlock" was unclear. The rule was clear, the session caught it, and the session shipped anyway. That is a workflow problem dressed as a copy problem. The fix is two parts: replace the strings (Section 8), and change the workflow so the next contradiction stops the work instead of getting flagged in the summary (Part 6).

The deeper finding from the audit is that the voice BetAutopsy is reaching for is achievable and underused. The intersection of Whoop's clinical hard-truth, Linear's SaaS restraint, Stripe's number-anchored calm, Apollo Neuro's mechanism-naming, and Robinhood's post-2021 compliance honesty is unoccupied territory. No app in the audit lives there. The brand's opportunity is to be the first that does, which means the voice rules in this document are not stylistic preference. They are the product's competitive position.

The single piece of brand-defining copy in this document is the compliance microcopy on the paywall: "If gambling has stopped being fun, call 1-800-MY-RESET. We can wait." It is the line that, more than any verdict paragraph or any pull quote, demonstrates that BetAutopsy is not a sportsbook. It accepts that the user might choose not to buy. That acceptance is the entire brand. Hold it.