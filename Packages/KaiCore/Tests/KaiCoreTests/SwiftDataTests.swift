import Foundation
import SwiftData
import Testing
@testable import KaiCore

/// All SwiftData-backed tests (persistence + repository).
///
/// Two constraints drive this structure:
/// 1. SwiftData `#Predicate` fetches trap (SIGTRAP) on the macOS test host but
///    work on iOS. This target therefore runs on the **iOS Simulator** via
///    `xcodebuild test`, iOS being the app's real target platform.
/// 2. SwiftData is unstable when many in-memory `ModelContainer` instances are
///    created concurrently in one process. So this suite is `.serialized` and
///    every test shares a single process-wide container, wiping it for a clean
///    slate at the start of each test.
@Suite(.serialized)
@MainActor
struct SwiftDataTests {

    /// One in-memory container for the whole test process (see note above).
    static let container: ModelContainer = {
        // Force-unwrap is acceptable in tests: a container that cannot be
        // created is an unrecoverable setup failure, not a test condition.
        try! KaiModelContainer.inMemory()
    }()

    /// Returns a context on the shared container with all data removed, so each
    /// test starts from an empty store despite sharing one container.
    private func cleanContext() throws -> ModelContext {
        let ctx = ModelContext(Self.container)
        try ctx.delete(model: VocabularyEntry.self)
        try ctx.delete(model: ReviewLog.self)
        try ctx.save()
        return ctx
    }

    // MARK: - Persistence (Task 4)

    @Test("Vocabulary entry persists and reads back with consistent enum accessors")
    func entryPersistsAndReadsBack() throws {
        let ctx = try cleanContext()

        let entry = VocabularyEntry(
            lemma: "Eccentric",
            kind: .word,
            language: .english,
            explanation: "adj. odd, peculiar",
            examples: [Example(sentence: "He is eccentric.", translation: "He behaves oddly.")]
        )
        ctx.insert(entry)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<VocabularyEntry>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.lemma == "Eccentric")
        #expect(fetched.first?.lemmaKey == "eccentric")
        #expect(fetched.first?.kind == .word)
        #expect(fetched.first?.language == .english)
        #expect(fetched.first?.scheduling.state == .new)
        #expect(fetched.first?.examples.count == 1)
    }

    @Test("Review log persists and reads back")
    func reviewLogPersists() throws {
        let ctx = try cleanContext()

        let log = ReviewLog(entryID: UUID(), rating: .good, quizType: .singleChoice, elapsedMs: 1200, isCorrect: true)
        ctx.insert(log)
        try ctx.save()

        let fetched = try ctx.fetch(FetchDescriptor<ReviewLog>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.rating == .good)
        #expect(fetched.first?.quizType == .singleChoice)
        #expect(fetched.first?.isCorrect == true)
    }

    // MARK: - Repository (Task 5)

    @Test("Same language + same lemma is deduped (case-insensitive)")
    func dedupeSameLanguageCaseInsensitive() throws {
        let repo = VocabularyRepository(context: try cleanContext())
        let first = try repo.insertIfAbsent(VocabularyEntry(lemma: "Eccentric", kind: .word, language: .english))
        let second = try repo.insertIfAbsent(VocabularyEntry(lemma: "eccentric", kind: .word, language: .english))
        #expect(first == true)
        #expect(second == false)
        #expect(try repo.entries(for: .english).count == 1)
    }

    @Test("Same lemma in different languages can coexist")
    func sameLemmaDifferentLanguageAllowed() throws {
        let repo = VocabularyRepository(context: try cleanContext())
        _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "kanji", kind: .word, language: .english))
        let jp = try repo.insertIfAbsent(VocabularyEntry(lemma: "kanji", kind: .word, language: .japanese))
        #expect(jp == true)
        #expect(try repo.entries(for: .english).count == 1)
        #expect(try repo.entries(for: .japanese).count == 1)
    }

    @Test("Queries are isolated by language")
    func entriesFilteredByLanguage() throws {
        let repo = VocabularyRepository(context: try cleanContext())
        _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "apple", kind: .word, language: .english))
        _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "banana", kind: .word, language: .english))
        #expect(try repo.entries(for: .japanese).isEmpty)
        #expect(try repo.entries(for: .english).count == 2)
        #expect(try repo.entry(lemma: "APPLE", language: .english)?.lemma == "apple")
    }

    @Test("entries(for:) returns entries in createdAt ascending order")
    func entriesSortedByCreatedAt() throws {
        let repo = VocabularyRepository(context: try cleanContext())
        let base = Date(timeIntervalSince1970: 1_000_000)
        _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "second", kind: .word, language: .english, now: base.addingTimeInterval(100)))
        _ = try repo.insertIfAbsent(VocabularyEntry(lemma: "first", kind: .word, language: .english, now: base))
        #expect(try repo.entries(for: .english).map(\.lemma) == ["first", "second"])
    }

    @Test("delete removes an entry")
    func deleteRemovesEntry() throws {
        let repo = VocabularyRepository(context: try cleanContext())
        let entry = VocabularyEntry(lemma: "temp", kind: .word, language: .english)
        _ = try repo.insertIfAbsent(entry)
        #expect(try repo.entries(for: .english).count == 1)
        try repo.delete(entry)
        #expect(try repo.entries(for: .english).isEmpty)
    }

    // MARK: - Review log + due-date query (Task 6)

    @Test("Due entries: due <= now matches, future due does not, isolated by language")
    func dueEntriesFiltering() throws {
        let repo = VocabularyRepository(context: try cleanContext())
        let now = Date(timeIntervalSince1970: 2_000_000)

        let dueWord = VocabularyEntry(lemma: "due", kind: .word, language: .english)
        var dueScheduling = dueWord.scheduling
        dueScheduling.due = now.addingTimeInterval(-60) // already due
        dueWord.reschedule(dueScheduling)

        let futureWord = VocabularyEntry(lemma: "future", kind: .word, language: .english)
        var futureScheduling = futureWord.scheduling
        futureScheduling.due = now.addingTimeInterval(3600) // due in the future
        futureWord.reschedule(futureScheduling)

        let jpWord = VocabularyEntry(lemma: "kana", kind: .word, language: .japanese)
        var jpScheduling = jpWord.scheduling
        jpScheduling.due = now.addingTimeInterval(-60)
        jpWord.reschedule(jpScheduling)

        _ = try repo.insertIfAbsent(dueWord)
        _ = try repo.insertIfAbsent(futureWord)
        _ = try repo.insertIfAbsent(jpWord)

        // The mirrored top-level `dueAt` property must stay in sync with
        // `scheduling.due`. `@Model` does not honor `didSet` observers on stored
        // properties, so both fields are set together via `reschedule(_:)`,
        // since SwiftData `#Predicate` cannot filter on a sub-field of an
        // embedded Codable struct.
        #expect(dueWord.dueAt == dueWord.scheduling.due)

        let due = try repo.dueEntries(for: .english, asOf: now)
        #expect(due.map(\.lemma) == ["due"])
    }

    @Test("Review log is written and read back by entry ID")
    func logAndFetchReviewLogs() throws {
        let repo = VocabularyRepository(context: try cleanContext())
        let entryID = UUID()

        try repo.logReview(ReviewLog(entryID: entryID, rating: .again, quizType: .fillInBlank, elapsedMs: 800, isCorrect: false))
        try repo.logReview(ReviewLog(entryID: entryID, rating: .good, quizType: .singleChoice, elapsedMs: 1500, isCorrect: true))
        try repo.logReview(ReviewLog(entryID: UUID(), rating: .easy, quizType: .singleChoice, elapsedMs: 500, isCorrect: true))

        let logs = try repo.reviewLogs(entryID: entryID)
        #expect(logs.count == 2)
    }
}
