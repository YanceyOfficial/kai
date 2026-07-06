import Foundation
import SwiftData
import KaiCore
import KaiServices

/// Owns a quiz session. The quiz is a **double-check** run after reviewing a group:
/// the review already graded each word, so a correct answer is a no-op here, while a
/// wrong answer re-grades the word as "again" (reschedule + `ReviewLog`) — catching a
/// word you thought you knew but didn't.
@MainActor
@Observable
final class QuizStore {
    private let repository: VocabularyRepository
    private let scheduler: ReviewScheduler
    private let generator = QuizGenerator()
    private let logger = AppLog.shared

    private var entriesByID: [UUID: VocabularyEntry] = [:]

    /// The questions for the current session — a snapshot of the due deck at `load()`.
    private(set) var questions: [QuizQuestion] = []

    init(context: ModelContext) {
        self.repository = VocabularyRepository(context: context)
        self.scheduler = ReviewScheduler(requestRetention: AppSettings.requestRetention)
    }

    /// Builds a quiz from the due deck, using the whole deck as the distractor pool.
    func load(now: Date = .now) {
        do {
            let all = try repository.entries(for: .english)
            let due = try repository.dueEntries(for: .english, asOf: now)
            build(targets: due, pool: all)
        } catch {
            logger.error("Failed to build quiz: \(error.localizedDescription)", category: "quiz")
            questions = []
            entriesByID = [:]
        }
    }

    /// Builds a quiz over a specific set of entries (e.g. the words just reviewed),
    /// still using the whole deck as the distractor pool.
    func load(entryIDs: [UUID], now: Date = .now) {
        do {
            let all = try repository.entries(for: .english)
            let byID = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            build(targets: entryIDs.compactMap { byID[$0] }, pool: all)
        } catch {
            logger.error("Failed to build quiz: \(error.localizedDescription)", category: "quiz")
            questions = []
            entriesByID = [:]
        }
    }

    private func build(targets: [VocabularyEntry], pool: [VocabularyEntry]) {
        entriesByID = Dictionary(pool.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var rng = SystemRandomNumberGenerator()
        questions = generator.makeQuiz(due: targets, pool: pool, using: &rng)
    }

    /// Grades a response and returns whether it was correct. A correct answer is a no-op
    /// (the preceding review already scheduled the word); a wrong answer re-grades the
    /// word as "again" and logs it, so the miss feeds spaced repetition exactly once.
    @discardableResult
    func submit(_ question: QuizQuestion, _ response: QuizResponse, now: Date = .now) -> Bool {
        let correct: Bool
        switch response {
        case .choice(let index): correct = question.isCorrect(choiceIndex: index)
        case .text(let text): correct = question.isCorrect(text: text)
        }
        guard !correct, let entry = entriesByID[question.id] else { return correct }

        entry.reschedule(scheduler.next(entry.scheduling, rating: .again, now: now))
        let log = ReviewLog(
            entryID: entry.id,
            rating: .again,
            quizType: question.type,
            elapsedMs: 0,
            isCorrect: false,
            timestamp: now
        )
        do {
            try repository.logReview(log)
        } catch {
            logger.error("Failed to persist quiz answer for '\(entry.lemma)': \(error.localizedDescription)", category: "quiz")
        }
        return correct
    }
}
