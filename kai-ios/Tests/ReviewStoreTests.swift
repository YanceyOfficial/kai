import Testing
import Foundation
import SwiftData
@testable import kai_ios
import KaiCore

/// End-to-end checks for the review loop's data path, on an in-memory container.
/// Runs on the iOS simulator (SwiftData `#Predicate` fetches require it).
@MainActor
@Suite(.serialized)
struct ReviewStoreTests {
    /// Fresh store + a seeded starter deck, plus the repository for assertions.
    private func makeSeededStore() throws -> (ReviewStore, VocabularyRepository) {
        let container = try KaiModelContainer.inMemory()
        let context = ModelContext(container)
        let repository = VocabularyRepository(context: context)
        try StarterSeed.seedIfEmpty(repository)
        return (ReviewStore(context: context), repository)
    }

    @Test("StarterSeed fills an empty deck and is idempotent")
    func seedIsIdempotent() throws {
        let container = try KaiModelContainer.inMemory()
        let repository = VocabularyRepository(context: ModelContext(container))
        try StarterSeed.seedIfEmpty(repository)
        try StarterSeed.seedIfEmpty(repository)
        #expect(try repository.entries(for: .english).count == 3)
    }

    @Test("load() snapshots the due deck")
    func loadSnapshotsDue() throws {
        let (store, _) = try makeSeededStore()
        store.load()
        #expect(store.cards.count == 3)
        #expect(store.cards.contains { $0.word == "eccentric" })
    }

    @Test("load(newLimit:) caps how many new words enter the session")
    func loadRespectsNewLimit() throws {
        let (store, _) = try makeSeededStore()   // 3 new seeded words
        store.load(newLimit: 2)
        #expect(store.cards.count == 2)
    }

    @Test("Rating every card writes a log per card and clears the due deck")
    func ratingPersistsAndClearsDue() throws {
        let (store, repo) = try makeSeededStore()
        store.load()

        for card in store.cards {
            store.rate(card, .good)
        }

        // Each rating pushes its card's due date into the future, so nothing is due now.
        let due = try repo.dueEntries(for: .english, asOf: .now)
        #expect(due.isEmpty)

        // Every card produced exactly one review log.
        for entry in try repo.entries(for: .english) {
            let logs = try repo.reviewLogs(entryID: entry.id)
            #expect(logs.count == 1)
            #expect(logs.first?.rating == .good)
            #expect(entry.scheduling.reps == 1)
            #expect(entry.scheduling.state == .review)
        }

        // allReviewLogs sees every log across entries (used by the stats dashboard).
        #expect(try repo.allReviewLogs().count == 3)
    }

    @Test("An 'again' rating records a lapse and relearning state")
    func againRecordsLapse() throws {
        let (store, repo) = try makeSeededStore()
        store.load()
        let card = try #require(store.cards.first)

        store.rate(card, .again)

        let entry = try #require(repo.entries(for: .english).first { $0.id == card.id })
        #expect(entry.scheduling.lapses == 1)
        #expect(entry.scheduling.state == .relearning)
        #expect(try repo.reviewLogs(entryID: entry.id).first?.rating == .again)
    }
}
