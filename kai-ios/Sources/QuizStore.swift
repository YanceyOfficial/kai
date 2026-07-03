import Foundation
import SwiftData
import KaiCore
import KaiServices

/// Owns a quiz session. Like `ReviewStore`, it feeds spaced repetition: a correct
/// answer grades the card "good", a wrong answer grades it "again", and either way
/// the card is rescheduled through FSRS and a `ReviewLog` is written.
@MainActor
@Observable
final class QuizStore {
    private let repository: VocabularyRepository
    private let scheduler = ReviewScheduler()
    private let generator = QuizGenerator()
    private let logger = AppLog.shared

    private var entriesByID: [UUID: VocabularyEntry] = [:]

    /// The questions for the current session — a snapshot of the due deck at `load()`.
    private(set) var questions: [QuizQuestion] = []

    init(context: ModelContext) {
        self.repository = VocabularyRepository(context: context)
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

    /// Grades an answer: reschedules via FSRS, persists, logs, and returns whether it
    /// was correct so the view can show feedback.
    @discardableResult
    func answer(_ question: QuizQuestion, selectedIndex: Int, now: Date = .now) -> Bool {
        let correct = selectedIndex == question.correctIndex
        guard let entry = entriesByID[question.id] else { return correct }

        let rating: ReviewRating = correct ? .good : .again
        entry.reschedule(scheduler.next(entry.scheduling, rating: rating, now: now))
        let log = ReviewLog(
            entryID: entry.id,
            rating: rating,
            quizType: .singleChoice,
            elapsedMs: 0,
            isCorrect: correct,
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
