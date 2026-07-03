import Foundation
import SwiftData
import KaiCore
import KaiServices

/// Owns the data for a review session: it loads the due English deck, applies
/// ratings through FSRS, and persists the results. The view observes it and stays
/// free of any persistence or scheduling logic.
@MainActor
@Observable
final class ReviewStore {
    private let repository: VocabularyRepository
    private let scheduler = ReviewScheduler()
    private let logger = AppLogger(sink: OSLogSink())

    /// Display cards for the current session — a snapshot of the entries that were
    /// due when `load()` ran.
    private(set) var cards: [ReviewCardData] = []

    /// The underlying entries keyed by id, so a rating can be applied to the right one.
    private var entriesByID: [UUID: VocabularyEntry] = [:]

    init(context: ModelContext) {
        self.repository = VocabularyRepository(context: context)
    }

    /// Loads the due English deck as a session snapshot: at most `newLimit` new words,
    /// interleaved with all due review words. Seeding happens once at app launch (see
    /// `StarterSeed`), so this only fetches.
    func load(newLimit: Int = .max, now: Date = .now) {
        do {
            let due = try repository.dueEntries(for: .english, asOf: now)
            let new = due.filter { $0.scheduling.state == .new }
            let old = due.filter { $0.scheduling.state != .new }
            let session = SessionComposer.compose(new: new, old: old, newLimit: newLimit)
            entriesByID = Dictionary(session.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            cards = session.map(ReviewCardData.init(entry:))
        } catch {
            logger.error("Failed to load review deck: \(error.localizedDescription)", category: "review")
            cards = []
            entriesByID = [:]
        }
    }

    /// Applies a rating to a card: reschedules it via FSRS, persists the new state,
    /// and writes a `ReviewLog`. Unknown cards are ignored.
    func rate(_ card: ReviewCardData, _ rating: ReviewRating, now: Date = .now) {
        guard let entry = entriesByID[card.id] else { return }
        entry.reschedule(scheduler.next(entry.scheduling, rating: rating, now: now))
        let log = ReviewLog(
            entryID: entry.id,
            rating: rating,
            quizType: .singleChoice,
            elapsedMs: 0,
            isCorrect: rating != .again,
            timestamp: now
        )
        do {
            // logReview saves the context, persisting the reschedule above along with it.
            try repository.logReview(log)
        } catch {
            logger.error("Failed to persist review for '\(entry.lemma)': \(error.localizedDescription)", category: "review")
        }
    }
}
