//
//  BehavioralPatternsData.swift
//  BetAutopsy
//
//  Source of truth for the in-app Behavioral Patterns glossary
//  (GlossaryView). Entries are sourced from the web engine bias
//  detectors in lib/autopsy-engine.ts (Day 11 Engine Phase B) and
//  the curated explainer set in lib/bias-explainers.ts.
//
//  Names of the first 6 entries match the engine's emit string
//  verbatim so the glossary entry the user reads matches the bias
//  name they see in their generated report. Entries 7-12 are
//  classic cognitive biases that don't have their own engine
//  detector but show up across the behavioral_patterns array.
//
//  App Review use: Guideline 4.2 thin-app defense per
//  APPLE_REVIEW_COMPLIANCE.md §13.
//

import Foundation

struct GlossaryEntry: Identifiable {
    let id: String
    let name: String
    let definition: String
    let example: String
}

enum BehavioralPatterns {
    static let all: [GlossaryEntry] = [
        GlossaryEntry(
            id: "post-loss-escalation",
            name: "Post-Loss Escalation",
            definition: "Increasing stake size after a loss to try to recover quickly. Loss aversion makes losing feel twice as intense as an equivalent win, so your brain reaches for a bigger bet to undo the pain.",
            example: "After a $50 loss, your next stake jumps to $200. Your typical bet is $40."
        ),
        GlossaryEntry(
            id: "heavy-parlay-tendency",
            name: "Heavy Parlay Tendency",
            definition: "Allocating a high percentage of volume to parlays. Each added leg multiplies the sportsbook's margin, so parlay ROI is typically much worse than straight-bet ROI for the same bettor.",
            example: "Parlays make up 40% of your weekly bets. Your straight-bet ROI is positive, your parlay ROI is significantly negative."
        ),
        GlossaryEntry(
            id: "stake-volatility",
            name: "Stake Volatility",
            definition: "Wide swings in bet size from one wager to the next, with no consistent unit. Often reflects emotional state leaking into the decision: confidence or desperation driving the amount instead of analysis.",
            example: "Your bets in one week range from $10 to $300 with no system. A 2x stake on a so-called lock loses, and the damage doubles."
        ),
        GlossaryEntry(
            id: "favorite-heavy-lean",
            name: "Favorite-Heavy Lean",
            definition: "Betting on favorites disproportionately, paying premium juice on shorter odds. Favorites feel safer but require a higher win rate to break even. Winning 60% of bets priced at minus 200 still loses money over time.",
            example: "75% of your bets are on favorites at minus 150 or shorter. Your underdog plays have a higher ROI but you place far fewer of them."
        ),
        GlossaryEntry(
            id: "late-night-betting",
            name: "Late-Night Betting",
            definition: "Bets placed after 10pm tend to underperform daytime bets. Less research, more impulse, and cognitive fatigue all push toward worse decisions. Late-night wagers are often reactive rather than planned.",
            example: "Your post-11pm bets show a 12-point ROI gap versus your daytime bets, on similar bet types."
        ),
        GlossaryEntry(
            id: "emotional-session-pattern",
            name: "Emotional Session Pattern",
            definition: "A cluster of bets placed in quick succession during a state of heightened emotion: after a big loss, during a downswing, or while watching a live game. These sessions typically show worse decision quality than your baseline.",
            example: "Six bets placed in 25 minutes after a $400 loss. Average stake on those bets is 1.8x your usual size."
        ),
        GlossaryEntry(
            id: "hot-hand-fallacy",
            name: "Hot Hand Fallacy",
            definition: "Believing a recent run of wins means you're due for more wins, or that a hot streak will continue beyond what randomness supports. Outcomes of independent bets don't carry forward like that.",
            example: "After three winning bets, your next stake is double your usual size because you feel hot."
        ),
        GlossaryEntry(
            id: "recency-bias",
            name: "Recency Bias",
            definition: "Overweighting the most recent results when sizing or selecting your next bet. A team's last game gets more weight than its full sample. Your last bet's outcome gets more weight than your average outcome.",
            example: "A team blows out an opponent on Sunday. You bet them on Wednesday at a shorter line because that game is still front-of-mind."
        ),
        GlossaryEntry(
            id: "confirmation-bias",
            name: "Confirmation Bias",
            definition: "Seeking out information that supports a bet you've already decided to make, and discounting information that contradicts it. The research happens after the conviction, not before.",
            example: "You're set on the over. You read the matchup preview, focus on the pace-up angle, and skim past the defensive-rating note that argues for the under."
        ),
        GlossaryEntry(
            id: "sunk-cost-fallacy",
            name: "Sunk Cost Fallacy",
            definition: "Continuing to bet on a team, player, or system because of money already lost on it, not because the next bet has positive expected value. The previous losses are gone whether you bet again or not.",
            example: "You're down $600 on a specific team this season. You bet them again at a price you wouldn't normally take, hoping to make some back."
        ),
        GlossaryEntry(
            id: "gamblers-fallacy",
            name: "Gambler's Fallacy",
            definition: "Believing that after a string of one outcome, the opposite outcome is more likely. Independent events don't balance out within a small sample. The coin doesn't owe you tails.",
            example: "Five unders in a row hit on the same total range. You bet the over on the sixth because it's due."
        ),
        GlossaryEntry(
            id: "anchoring",
            name: "Anchoring",
            definition: "Letting the first number you see, usually the opening line, set your reference point for the whole market. Subsequent line movement is judged against that anchor instead of evaluated fresh.",
            example: "The opening line is minus 3. By kickoff the line is minus 6. You take minus 6 anyway because you anchored on the value at minus 3 days earlier."
        )
    ]
}
