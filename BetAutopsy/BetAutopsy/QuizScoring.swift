//
//  QuizScoring.swift
//  BetAutopsy
//
//  iOS port of the web quiz-engine for the 7-question Quick Start Quiz.
//  Source of truth: lib/quiz-engine.ts in the web app. iOS ships a subset
//  of the 13 web questions chosen for full archetype coverage. Real
//  archetype assignment comes from uploaded bet data later via the
//  server-side classifier; this quiz is fast onboarding positioning.
//

import SwiftUI

// MARK: - Types

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

enum QuizQuestionStyle {
    case `default`
    case bold
    case slider
}

struct QuizOption: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let scores: [ScoringDimension: Int]
}

struct QuizQuestion: Identifiable {
    let id: String
    let question: String
    let subtext: String?
    let style: QuizQuestionStyle
    let options: [QuizOption]
}

struct ArchetypeResult {
    let name: String
    let color: Color
    let colorHex: String
    let description: String
}

struct QuizResult {
    let archetype: ArchetypeResult
    let emotionEstimate: Int
    let disciplineEstimate: Int
    let grade: String
}

// MARK: - Engine

enum QuizScoring {

    static let questions: [QuizQuestion] = [
        // Q1 — q3: weekly volume
        QuizQuestion(
            id: "q3",
            question: "How many bets do you place in a typical week?",
            subtext: nil,
            style: .default,
            options: [
                QuizOption(label: "1 to 3, only when I see something I love",
                           value: "few",
                           scores: [.volume: 2, .selectivity: 9]),
                QuizOption(label: "5 to 10, a few per day on game days",
                           value: "moderate",
                           scores: [.volume: 5, .selectivity: 5]),
                QuizOption(label: "15 to 25, I bet most games I watch",
                           value: "high",
                           scores: [.volume: 8, .selectivity: 3]),
                QuizOption(label: "30 or more, if there's a line I'm on it",
                           value: "max",
                           scores: [.volume: 10, .selectivity: 1])
            ]
        ),

        // Q2 — q4: heavy favorite
        QuizQuestion(
            id: "q4",
            question: "Your team is a -300 favorite. Do you bet them?",
            subtext: nil,
            style: .default,
            options: [
                QuizOption(label: "Absolutely, they're going to win",
                           value: "yes",
                           scores: [.favLean: 9, .discipline: 3]),
                QuizOption(label: "Only if I think the line is off",
                           value: "value",
                           scores: [.favLean: 4, .discipline: 8]),
                QuizOption(label: "I'd rather take the dog at +250",
                           value: "dog",
                           scores: [.favLean: 1, .discipline: 6]),
                QuizOption(label: "I'd parlay them with something else",
                           value: "parlay",
                           scores: [.favLean: 7, .parlayLean: 7])
            ]
        ),

        // Q3 — q5: bet sizing
        QuizQuestion(
            id: "q5",
            question: "Be honest: do your bet sizes stay consistent?",
            subtext: nil,
            style: .default,
            options: [
                QuizOption(label: "Yes, every bet is basically the same size",
                           value: "flat",
                           scores: [.variance: 1, .discipline: 9, .emotion: 2]),
                QuizOption(label: "Mostly, with occasional bigger plays",
                           value: "mostly",
                           scores: [.variance: 4, .discipline: 6, .emotion: 4]),
                QuizOption(label: "They swing a lot based on how I'm feeling",
                           value: "swing",
                           scores: [.variance: 8, .discipline: 2, .emotion: 8]),
                QuizOption(label: "I go big when I'm confident, small when I'm not",
                           value: "confidence",
                           scores: [.variance: 6, .discipline: 4, .emotion: 6])
            ]
        ),

        // Q4 — q1: chasing
        QuizQuestion(
            id: "q1",
            question: "You just lost 3 bets in a row. What do you do?",
            subtext: nil,
            style: .default,
            options: [
                QuizOption(label: "Take a break and come back tomorrow",
                           value: "break",
                           scores: [.discipline: 9, .chaseTendency: 1, .emotion: 2]),
                QuizOption(label: "Stick to my plan. The next bet is independent",
                           value: "plan",
                           scores: [.discipline: 7, .chaseTendency: 2, .emotion: 3]),
                QuizOption(label: "Bet bigger on the next one to make it back",
                           value: "bigger",
                           scores: [.discipline: 1, .chaseTendency: 9, .emotion: 8, .variance: 8]),
                QuizOption(label: "Throw a parlay together to get even fast",
                           value: "parlay",
                           scores: [.discipline: 2, .chaseTendency: 8, .emotion: 7, .parlayLean: 9])
            ]
        ),

        // Q5 — q7: hot streak
        QuizQuestion(
            id: "q7",
            question: "You hit a big parlay for +800. What's your next move?",
            subtext: nil,
            style: .default,
            options: [
                QuizOption(label: "Withdraw the winnings and reset",
                           value: "withdraw",
                           scores: [.discipline: 9, .emotion: 2]),
                QuizOption(label: "Keep my normal routine. The win doesn't change anything",
                           value: "normal",
                           scores: [.discipline: 8, .emotion: 3]),
                QuizOption(label: "Ride the hot streak, bet bigger for a few days",
                           value: "ride",
                           scores: [.discipline: 2, .emotion: 7, .variance: 7]),
                QuizOption(label: "Roll it into an even bigger parlay",
                           value: "roll",
                           scores: [.discipline: 1, .emotion: 8, .parlayLean: 9, .variance: 9])
            ]
        ),

        // Q6 — q10: motivation
        QuizQuestion(
            id: "q10",
            question: "Why do you actually bet?",
            subtext: "Not what you tell people. What's the real reason.",
            style: .bold,
            options: [
                QuizOption(label: "I genuinely believe I have an edge and can beat the market",
                           value: "edge",
                           scores: [.discipline: 7, .selectivity: 7]),
                QuizOption(label: "It makes watching games 10x better",
                           value: "fun",
                           scores: [.discipline: 4, .emotion: 5, .volume: 5]),
                QuizOption(label: "The rush when you hit. Nothing else compares",
                           value: "rush",
                           scores: [.discipline: 2, .emotion: 9]),
                QuizOption(label: "Honestly, I don't know anymore. It's just what I do",
                           value: "habit",
                           scores: [.discipline: 1, .emotion: 8, .chaseTendency: 5])
            ]
        ),

        // Q7 — q14: loss impact slider
        QuizQuestion(
            id: "q14",
            question: "On a scale of 1 to 10, how much does a loss ruin the rest of your day?",
            subtext: "1 means you forget about it immediately. 10 means it affects everything.",
            style: .slider,
            options: [
                QuizOption(label: "1 to 2",
                           value: "low",
                           scores: [.emotion: 1, .discipline: 8, .chaseTendency: 1]),
                QuizOption(label: "3 to 4",
                           value: "mild",
                           scores: [.emotion: 3, .discipline: 6, .chaseTendency: 3]),
                QuizOption(label: "5 to 6",
                           value: "moderate",
                           scores: [.emotion: 5, .discipline: 4, .chaseTendency: 5]),
                QuizOption(label: "7 to 8",
                           value: "high",
                           scores: [.emotion: 7, .discipline: 2, .chaseTendency: 7]),
                QuizOption(label: "9 to 10",
                           value: "extreme",
                           scores: [.emotion: 9, .discipline: 1, .chaseTendency: 9])
            ]
        )
    ]

    // MARK: - Scoring

    static func computeResult(answers: [String: String]) -> QuizResult {
        let averages = computeAverages(answers: answers)
        let archetype = assignArchetype(averages: averages)
        let emotionEst = computeEmotionEstimate(averages: averages)
        let disciplineEst = computeDisciplineEstimate(averages: averages)
        let grade = computeGrade(
            emotionEstimate: emotionEst,
            disciplineEstimate: disciplineEst,
            averages: averages
        )
        return QuizResult(
            archetype: archetype,
            emotionEstimate: emotionEst,
            disciplineEstimate: disciplineEst,
            grade: grade
        )
    }

    private static func computeAverages(answers: [String: String]) -> [ScoringDimension: Double] {
        var sums: [ScoringDimension: Int] = [:]
        var counts: [ScoringDimension: Int] = [:]

        for (questionId, answerValue) in answers {
            guard let question = questions.first(where: { $0.id == questionId }),
                  let option = question.options.first(where: { $0.value == answerValue })
            else { continue }

            for (dimension, score) in option.scores {
                sums[dimension, default: 0] += score
                counts[dimension, default: 0] += 1
            }
        }

        var averages: [ScoringDimension: Double] = [:]
        for dimension in ScoringDimension.allCases {
            if let count = counts[dimension], count > 0, let sum = sums[dimension] {
                averages[dimension] = Double(sum) / Double(count)
            } else {
                averages[dimension] = 5.0
            }
        }
        return averages
    }

    private static func assignArchetype(averages: [ScoringDimension: Double]) -> ArchetypeResult {
        let e = averages[.emotion]        ?? 5.0
        let p = averages[.parlayLean]     ?? 5.0
        let c = averages[.chaseTendency]  ?? 5.0
        let f = averages[.favLean]        ?? 5.0
        let v = averages[.volume]         ?? 5.0
        let d = averages[.discipline]     ?? 5.0
        let r = averages[.variance]       ?? 5.0
        let s = averages[.selectivity]    ?? 5.0

        if d >= 7.5 && e <= 3.5 && s >= 6 {
            return ArchetypeResult(
                name: "The Natural",
                color: DS.Color.Archetype.natural,
                colorHex: "#5BFFA8",
                description: "Cool, calculated, and data-driven. You treat betting like a business, not a game. Your discipline is your edge. Most bettors would kill for your self-control."
            )
        }
        if d >= 6 && r >= 6 && s >= 5 {
            return ArchetypeResult(
                name: "Sharp Sleeper",
                color: DS.Color.Archetype.sharpSleeper,
                colorHex: "#6B5BFF",
                description: "You've got real instincts and some genuine edges, but your sizing is all over the place. Lock in your stake strategy and you could be dangerous."
            )
        }
        if e >= 6 && c >= 6 && d <= 4 {
            return ArchetypeResult(
                name: "Heated Bettor",
                color: DS.Color.Archetype.heatedBettor,
                colorHex: "#FF5454",
                description: "Your reads aren't bad, but your emotions turn winners into losing weeks. The bets after losses are where your bankroll goes to die."
            )
        }
        if f >= 7 && d >= 4 {
            return ArchetypeResult(
                name: "Chalk Grinder",
                color: DS.Color.Archetype.chalkGrinder,
                colorHex: "#B8944A",
                description: "You play it safe with favorites and that feels smart, but you're paying a tax on every bet. The juice is eating you alive."
            )
        }
        if p >= 7 {
            return ArchetypeResult(
                name: "Parlay Dreamer",
                color: DS.Color.Archetype.parlayDreamer,
                colorHex: "#8B7DFF",
                description: "The big ticket is always calling. Your straight bet game is probably solid. The parlays are where the dream meets reality, and reality usually wins."
            )
        }
        if s >= 7 && v <= 4 {
            return ArchetypeResult(
                name: "Sniper",
                color: DS.Color.Archetype.sniper,
                colorHex: "#60A5FA",
                description: "You pick your spots carefully and don't bet just to bet. Selective and focused. Now it's about sharpening the edge on the shots you do take."
            )
        }
        if v >= 7 && r <= 4 {
            return ArchetypeResult(
                name: "Volume Warrior",
                color: DS.Color.Archetype.volumeWarrior,
                colorHex: "#A78BFA",
                description: "You grind it out with consistent sizing across a lot of bets. The approach is sustainable. The question is whether there are leaks hiding in the volume."
            )
        }
        if r >= 7 && p >= 5 && e >= 5 {
            return ArchetypeResult(
                name: "Degen King",
                color: DS.Color.Archetype.degenKing,
                colorHex: "#FF5454",
                description: "You're here for the ride and you own it. High variance, high energy, high entertainment value. But somewhere in the chaos there might be real edges, if you can find them."
            )
        }
        return ArchetypeResult(
            name: "The Grinder",
            color: DS.Color.Archetype.grinder,
            colorHex: "#A8AABF",
            description: "Steady and consistent without any extreme tendencies. You're not making the big mistakes most bettors make. The question is whether you're leaving edges on the table."
        )
    }

    private static func computeEmotionEstimate(averages: [ScoringDimension: Double]) -> Int {
        let e = averages[.emotion]       ?? 5.0
        let c = averages[.chaseTendency] ?? 5.0
        let r = averages[.variance]      ?? 5.0
        let d = averages[.discipline]    ?? 5.0

        let raw = (e * 7) + (c * 5) + (r * 3) - (d * 4) + 30
        return Int(round(min(100.0, max(0.0, raw))))
    }

    private static func computeDisciplineEstimate(averages: [ScoringDimension: Double]) -> Int {
        let d = averages[.discipline] ?? 5.0
        return Int(round(min(95.0, max(5.0, d * 10))))
    }

    private static func computeGrade(
        emotionEstimate: Int,
        disciplineEstimate: Int,
        averages: [ScoringDimension: Double]
    ) -> String {
        let p = averages[.parlayLean] ?? 5.0
        let raw = Double(100 - emotionEstimate) * 0.4
            + Double(disciplineEstimate) * 0.4
            + (10.0 - p) * 2.0
        let score = Int(round(raw))

        if score >= 80 { return "A" }
        if score >= 65 { return "B" }
        if score >= 50 { return "C" }
        if score >= 35 { return "D" }
        return "F"
    }
}
