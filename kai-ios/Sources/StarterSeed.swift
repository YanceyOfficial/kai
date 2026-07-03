import Foundation
import KaiCore

/// Seeds a small starter English deck the first time the app runs, so the review
/// loop and word list have content before real entry authoring is used. Temporary
/// scaffolding — safe to remove once users import their own words.
enum StarterSeed {
    /// Inserts the starter entries when the English deck is empty. Idempotent.
    static func seedIfEmpty(_ repository: VocabularyRepositoryProtocol, now: Date = .now) throws {
        guard try repository.entries(for: .english).isEmpty else { return }
        for entry in entries(now: now) {
            try repository.insertIfAbsent(entry)
        }
    }

    static func entries(now: Date = .now) -> [VocabularyEntry] {
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
