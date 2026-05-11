//
//  OnboardingCoordinator.swift
//  BetAutopsy
//
//  Drives the first-run flow: age gate → sample → quiz → Pikkit → reveal.
//  Quiz answers are scored via QuizScoring; result is persisted to
//  UserDefaults so TodayView (a separate view tree) can read it after the
//  onboarding sheet dismisses.
//

import Foundation

@Observable
final class OnboardingCoordinator {
    enum Step: Hashable {
        case ageGate
        case sampleReportPreview
        case betDNAQuiz
        case pikkitEducation
        case archetypeReveal
        case complete
    }

    var step: Step = .ageGate

    private(set) var answers: [String: String] = [:]
    private(set) var quizResult: QuizResult? = nil

    // MARK: - Step transitions

    func advance() {
        switch step {
        case .ageGate:             step = .sampleReportPreview
        case .sampleReportPreview: step = .betDNAQuiz
        case .betDNAQuiz:          step = .pikkitEducation
        case .pikkitEducation:     step = .archetypeReveal
        case .archetypeReveal:     step = .complete
        case .complete:            break
        }
    }

    func back() {
        switch step {
        case .ageGate, .complete:  break
        case .sampleReportPreview: step = .ageGate
        case .betDNAQuiz:          step = .sampleReportPreview
        case .pikkitEducation:     step = .betDNAQuiz
        case .archetypeReveal:     step = .pikkitEducation
        }
    }

    // MARK: - Quiz state

    func recordAnswer(questionId: String, value: String) {
        answers[questionId] = value
    }

    func computeArchetype() {
        quizResult = QuizScoring.computeResult(answers: answers)
    }

    /// Skip-from-sample-preview path. Leaves quizResult nil so completion
    /// won't synthesize an archetype.
    func skipQuiz() {
        step = .pikkitEducation
    }

    // MARK: - Completion

    func completeOnboarding() {
        let defaults = UserDefaults.standard
        if let result = quizResult {
            defaults.set(result.archetype.name,        forKey: Keys.userArchetype)
            defaults.set(result.archetype.description, forKey: Keys.userArchetypeDescription)
            defaults.set(result.archetype.colorHex,    forKey: Keys.userArchetypeColorHex)
            defaults.set(result.emotionEstimate,       forKey: Keys.userEmotionScore)
            defaults.set(result.disciplineEstimate,    forKey: Keys.userDisciplineScore)
            defaults.set(result.grade,                 forKey: Keys.userGrade)
        }
        // No quiz: leave user* keys absent so TodayView can detect the
        // "assessment not taken yet" state.
        defaults.set(Keys.currentSchemaVersion, forKey: Keys.quizSchemaVersion)
        defaults.set(true,                       forKey: Keys.onboardingComplete)

        step = .complete
    }

    /// Completion path from Pikkit when there's no quiz result to reveal.
    /// Same effect as completeOnboarding(); the wrapper is for caller clarity.
    func completeOnboardingSkippingReveal() {
        completeOnboarding()
    }

    func reset() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: Keys.onboardingComplete)
        defaults.removeObject(forKey: Keys.userArchetype)
        defaults.removeObject(forKey: Keys.userArchetypeDescription)
        defaults.removeObject(forKey: Keys.userArchetypeColorHex)
        defaults.removeObject(forKey: Keys.userEmotionScore)
        defaults.removeObject(forKey: Keys.userDisciplineScore)
        defaults.removeObject(forKey: Keys.userGrade)
        defaults.removeObject(forKey: Keys.quizSchemaVersion)

        answers = [:]
        quizResult = nil
        step = .ageGate
    }

    // MARK: - Persistence keys

    enum Keys {
        static let onboardingComplete         = "onboardingComplete"
        static let userArchetype              = "userArchetype"
        static let userArchetypeDescription   = "userArchetypeDescription"
        static let userArchetypeColorHex      = "userArchetypeColorHex"
        static let userEmotionScore           = "userEmotionScore"
        static let userDisciplineScore        = "userDisciplineScore"
        static let userGrade                  = "userGrade"
        static let quizSchemaVersion          = "quizSchemaVersion"
        static let currentSchemaVersion       = 2
    }
}
