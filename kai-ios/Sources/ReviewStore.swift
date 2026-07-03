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

    /// Loads the due English deck, seeding a small starter set on first run so the
    /// loop has something to show before real entry-authoring exists.
    func load(now: Date = .now) {
        do {
            try seedIfEmpty(now: now)
            let due = try repository.dueEntries(for: .english, asOf: now)
            entriesByID = Dictionary(due.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            cards = due.map(ReviewCardData.init(entry:))
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

    // MARK: Seeding

    /// Inserts a handful of starter words when the English deck is empty. Temporary
    /// until entry authoring (batch paste / share / OCR) lands.
    private func seedIfEmpty(now: Date) throws {
        guard try repository.entries(for: .english).isEmpty else { return }
        for entry in Self.starterEntries(now: now) {
            try repository.insertIfAbsent(entry)
        }
    }

    private static func starterEntries(now: Date) -> [VocabularyEntry] {
        [
            VocabularyEntry(
                lemma: "eccentric", kind: .word, language: .english,
                phonetic: "/ɪkˈsɛntrɪk/", explanation: "adj. 古怪的，异乎寻常的",
                examples: [Example(sentence: "My uncle is something of an eccentric.", translation: "我叔叔有点古怪。")],
                now: now
            ),
            VocabularyEntry(
                lemma: "obsession", kind: .word, language: .english,
                phonetic: "/əbˈsɛʃ.ən/", explanation: "n. 痴迷；萦绕于心的念头",
                examples: [Example(sentence: "Finding his birth mother became an obsession.", translation: "找到生母成了他挥之不去的执念。")],
                now: now
            ),
            VocabularyEntry(
                lemma: "meticulous", kind: .word, language: .english,
                phonetic: "/məˈtɪk.jə.ləs/", explanation: "adj. 一丝不苟的，极为细致的",
                examples: [Example(sentence: "She kept meticulous records of every review.", translation: "她把每次复习都记录得一丝不苟。")],
                now: now
            ),
        ]
    }
}
