import Foundation
import SwiftData
import KaiCore
import KaiAI
import KaiServices

/// Owns the daily story: composes today's review words, caches one story per day, and
/// generates it via the AI provider on demand. The view observes it.
@MainActor
@Observable
final class StoryStore {
    enum State: Equatable {
        case idle          // words available, no story yet — offer to generate
        case loading
        case ready
        case empty         // nothing due today and no cached story
        case needsKey      // no API key configured
        case failed(String)
    }

    private(set) var state: State = .idle
    private(set) var text = ""
    private(set) var translation = ""
    private(set) var words: [String] = []

    private let repository: VocabularyRepository
    /// The deck the story is written for, and the language it is written in.
    let language: LanguageDomain
    private let logger = AppLog.shared

    init(context: ModelContext, language: LanguageDomain = AppSettings.studyLanguage) {
        self.repository = VocabularyRepository(context: context)
        self.language = language
    }

    /// Resolves state from cache/due words without hitting the network. Shows a cached
    /// story if one exists for today; otherwise offers to generate (or reports empty).
    func load(newLimit: Int, now: Date = .now) {
        if let cached = try? repository.dailyStory(for: language, on: now) {
            populate(cached)
            state = .ready
            return
        }
        state = todayWords(newLimit: newLimit, now: now).isEmpty ? .empty : .idle
    }

    /// Generates today's story from the current due words and caches it.
    func generate(newLimit: Int, now: Date = .now) async {
        let lemmas = todayWords(newLimit: newLimit, now: now)
        guard !lemmas.isEmpty else { state = .empty; return }
        guard let config = AIConfigStore.configuration() else { state = .needsKey; return }

        state = .loading
        do {
            let provider = ProviderFactory.make(config)
            let story = try await provider.generateStory(words: lemmas, language: language)
            let model = DailyStory(day: now, language: language,
                                   text: story.story, translation: story.translation, wordLemmas: lemmas)
            try repository.upsertDailyStory(model)
            populate(model)
            state = .ready
        } catch {
            logger.error("Story generation failed: \(error.localizedDescription)", category: "story")
            state = .failed(error.localizedDescription)
        }
    }

    /// Resolves a tapped word to its entry, if it exists in the deck.
    func entry(forLemma lemma: String) -> VocabularyEntry? {
        try? repository.entry(lemma: lemma, language: language)
    }

    // MARK: Internals

    /// The lemmas of today's review session (up to `newLimit` new words + due words).
    private func todayWords(newLimit: Int, now: Date) -> [String] {
        let due = (try? repository.dueEntries(for: language, asOf: now)) ?? []
        let new = due.filter { $0.scheduling.state == .new }
        let old = due.filter { $0.scheduling.state != .new }
        return SessionComposer.compose(new: new, old: old, newLimit: newLimit).map(\.lemma)
    }

    private func populate(_ story: DailyStory) {
        text = story.text
        translation = story.translation
        words = story.wordLemmas
    }
}
