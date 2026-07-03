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
                explanationEn: "unconventional or slightly strange in behaviour",
                examples: [Example(sentence: "My uncle is something of an eccentric.", translation: "我叔叔有点古怪。")],
                etymology: "源自希腊语 ekkentros —— 偏离中心",
                roots: "ec-（出）+ centr（中心）+ -ic（形容词）→ 偏离中心",
                synonymGroups: [
                    SynonymGroup(sense: "古怪的", words: ["odd", "quirky", "peculiar"]),
                    SynonymGroup(sense: "标新立异的", words: ["unconventional", "idiosyncratic"]),
                ],
                collocations: [
                    Collocation(phrase: "eccentric behaviour", meaning: "古怪的行为",
                                example: "His eccentric behaviour amused everyone.", exampleTranslation: "他古怪的行为把大家都逗乐了。"),
                ],
                now: now
            ),
            VocabularyEntry(
                lemma: "obsession", kind: .word, language: .english,
                phonetic: "/əbˈsɛʃ.ən/", explanation: "n. 痴迷；萦绕于心的念头",
                explanationEn: "an idea or feeling that continually preoccupies the mind",
                examples: [Example(sentence: "Finding his birth mother became an obsession.", translation: "找到生母成了他挥之不去的执念。")],
                roots: "ob-（朝向）+ sess（坐）+ -ion（名词）→ 盘踞在心头",
                synonymGroups: [
                    SynonymGroup(sense: "痴迷", words: ["fixation", "preoccupation"]),
                    SynonymGroup(sense: "执念", words: ["compulsion", "fixation"]),
                ],
                collocations: [
                    Collocation(phrase: "an obsession with", meaning: "对……的痴迷",
                                example: "She has an obsession with cleanliness.", exampleTranslation: "她对干净有着近乎痴迷的执着。"),
                ],
                now: now
            ),
            VocabularyEntry(
                lemma: "meticulous", kind: .word, language: .english,
                phonetic: "/məˈtɪk.jə.ləs/", explanation: "adj. 一丝不苟的，极为细致的",
                explanationEn: "showing great attention to detail; very careful and precise",
                examples: [Example(sentence: "She kept meticulous records of every review.", translation: "她把每次复习都记录得一丝不苟。")],
                roots: "meticul-（拉丁语 metus，恐惧）+ -ous（形容词）→ 因怕出错而格外谨慎",
                synonymGroups: [
                    SynonymGroup(sense: "一丝不苟的", words: ["thorough", "scrupulous", "fastidious"]),
                ],
                collocations: [
                    Collocation(phrase: "meticulous attention to detail", meaning: "对细节一丝不苟",
                                example: "The work requires meticulous attention to detail.", exampleTranslation: "这项工作要求对细节一丝不苟。"),
                ],
                now: now
            ),
        ]
    }
}
