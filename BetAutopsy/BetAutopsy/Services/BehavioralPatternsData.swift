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
            id: "category-concentration-leak",
            name: "Category Concentration Leak",
            definition: "Allocating a large share of total volume to a single sport, league, or bet type while neglecting others. Heavy concentration means your overall results swing with that one category's variance, and a cold stretch there shows up as a much bigger drawdown than a diversified book would produce.",
            example: "78% of your weekly bets are NBA player props. When NBA props go cold for two weeks, your bankroll takes the full hit."
        ),
        GlossaryEntry(
            id: "high-pick-addiction",
            name: "High-Pick Addiction",
            definition: "In DFS pick'em pools, leaning heavily on 5-pick and 6-pick entries instead of 2-pick or 3-pick entries. Bigger payouts pull you toward more picks, but the probability of going perfect drops sharply with each added leg and the ROI math usually turns negative.",
            example: "65% of your DFS entries are 5 or 6 picks. Your 5-6 pick entries are at minus 18% ROI; your 2-3 pick entries are at plus 4%."
        ),
        GlossaryEntry(
            id: "power-play-preference",
            name: "Power Play Preference",
            definition: "In DFS pick'em pools, choosing Power Play (all picks must hit) over Flex Play (some picks can miss). Power Play prints bigger when it cashes but cashes far less often. For most bettors, Flex Play returns a better long-run ROI on the same pick set.",
            example: "Your Power entries are at minus 22% ROI; your Flex entries on the same picks would have returned plus 6%."
        ),
        GlossaryEntry(
            id: "multiplier-chasing",
            name: "Multiplier Chasing",
            definition: "After a loss, adding more picks to your next DFS entry to chase the bigger multiplier payout. The post-loss entry takes on more variance just when discipline matters most. Average pick count rises after losses and falls after wins, the opposite of what a steady strategy looks like.",
            example: "Your average pick count after a loss is 5.2. After a win, it drops to 3.4."
        ),
        GlossaryEntry(
            id: "player-concentration-bias",
            name: "Player Concentration Bias",
            definition: "Including the same player across many DFS entries or parlays in the same slate. A single player's bad night cascades through all of them at once. Diversifying across players reduces correlated risk, but loyalty to a favorite player overrides the math.",
            example: "One player appears in 11 of your 14 DFS entries this week. He goes under, and all 11 entries lose at once."
        ),
        GlossaryEntry(
            id: "sunk-cost-fallacy",
            name: "Sunk Cost Fallacy",
            definition: "Continuing to bet on a team, player, or system because of money already lost on it, not because the next bet has positive expected value. The previous losses are gone whether you bet again or not.",
            example: "You're down $600 on a specific team this season. You bet them again at a price you wouldn't normally take, hoping to make some back."
        )
    ]
}
