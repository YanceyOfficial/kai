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
    private func makeStore() throws -> (ReviewStore, ModelContext) {
        let container = try KaiModelContainer.inMemory()
        let context = ModelContext(container)
        return (ReviewStore(context: context), context)
    }

    @Test("load() seeds a starter deck on an empty store")
    func loadSeeds() throws {
        let (store, _) = try makeStore()
        store.load()
        #expect(store.cards.count == 3)
        #expect(store.cards.contains { $0.word == "eccentric" })
    }

    @Test("Seeding runs only once — a second load does not duplicate entries")
    func seedIsIdempotent() throws {
        let (store, context) = try makeStore()
        store.load()
        store.load()
        let all = try VocabularyRepository(context: context).entries(for: .english)
        #expect(all.count == 3)
    }

    @Test("Rating every card writes a log per card and clears the due deck")
    func ratingPersistsAndClearsDue() throws {
        let (store, context) = try makeStore()
        store.load()
        let repo = VocabularyRepository(context: context)

        for card in store.cards {
            store.rate(card, .good)
        }

        // Each rating pushes its card's due date into the future, so nothing is due now.
        let due = try repo.dueEntries(for: .english, asOf: .now)
        #expect(due.isEmpty)

        // Every card produced exactly one review log.
        let allEntries = try repo.entries(for: .english)
        for entry in allEntries {
            let logs = try repo.reviewLogs(entryID: entry.id)
            #expect(logs.count == 1)
            #expect(logs.first?.rating == .good)
            #expect(entry.scheduling.reps == 1)
            #expect(entry.scheduling.state == .review)
        }
    }

    @Test("An 'again' rating records a lapse and relearning state")
    func againRecordsLapse() throws {
        let (store, context) = try makeStore()
        store.load()
        let repo = VocabularyRepository(context: context)
        let card = try #require(store.cards.first)

        store.rate(card, .again)

        let entry = try #require(repo.entries(for: .english).first { $0.id == card.id })
        #expect(entry.scheduling.lapses == 1)
        #expect(entry.scheduling.state == .relearning)
        #expect(try repo.reviewLogs(entryID: entry.id).first?.rating == .again)
    }
}
