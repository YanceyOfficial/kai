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
    private let logger = AppLogger(sink: OSLogSink())

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
            entriesByID = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var rng = SystemRandomNumberGenerator()
            questions = generator.makeQuiz(due: due, pool: all, using: &rng)
        } catch {
            logger.error("Failed to build quiz: \(error.localizedDescription)", category: "quiz")
            questions = []
            entriesByID = [:]
        }
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
