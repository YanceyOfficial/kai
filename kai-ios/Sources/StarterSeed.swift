import Foundation
import KaiCore

/// Seeds a small starter deck per language the first time the app runs, so the review
/// loop and word list have content before real entry authoring is used. Temporary
/// scaffolding — safe to remove once users import their own words.
enum StarterSeed {
    /// Inserts the starter entries when that language's deck is empty. Idempotent.
    static func seedIfEmpty(_ repository: VocabularyRepositoryProtocol, language: LanguageDomain = .english, now: Date = .now) throws {
        guard try repository.entries(for: language).isEmpty else { return }
        for entry in entries(for: language, now: now) {
            try repository.insertIfAbsent(entry)
        }
    }

    static func entries(for language: LanguageDomain = .english, now: Date = .now) -> [VocabularyEntry] {
        switch language {
        case .english: english(now: now)
        case .japanese: japanese(now: now)
        }
    }

    /// Three words a Chinese reader gets wrong or cannot guess from the kanji. Japanese
    /// sentences carry ruby markup (`{漢字|かんじ}`, see KaiUI `Ruby`).
    private static func japanese(now: Date) -> [VocabularyEntry] {
        [
            VocabularyEntry(
                lemma: "懐かしい", kind: .word, language: .japanese,
                phonetic: "なつかしい ④", syllables: ["な", "つ", "か", "し", "い"],
                explanation: "[形] 令人怀念的；眷恋的",
                explanationEn: "{昔|むかし}のことが{思|おも}い{出|だ}されて、{心|こころ}が{引|ひ}かれる{様子|ようす}だ。",
                partsOfSpeech: ["い形容詞"],
                examples: [
                    Example(sentence: "{故郷|ふるさと}の{味|あじ}が{懐|なつ}かしい。", translation: "怀念故乡的味道。"),
                    Example(sentence: "この{歌|うた}を{聞|き}くと、{学生|がくせい}{時代|じだい}が{懐|なつ}かしくなる。", translation: "一听到这首歌，就怀念起学生时代。"),
                ],
                mnemonic: "懐＝怀：把旧时光揣在怀里，所以令人怀念",
                etymology: "和語。源自动词「なつく」（亲近、依恋）",
                roots: "懐（カイ／なつ-かしい，怀抱）→ 把往事抱在心里",
                synonymGroups: [SynonymGroup(sense: "怀念的", words: ["恋しい"])],
                collocations: [
                    Collocation(phrase: "{懐|なつ}かしい{思|おも}い{出|で}", meaning: "令人怀念的回忆",
                                example: "{写真|しゃしん}を{見|み}て、{懐|なつ}かしい{思|おも}い{出|で}がよみがえった。",
                                exampleTranslation: "看着照片，令人怀念的回忆浮现出来。"),
                ],
                confusables: ["恋しい"],
                now: now
            ),
            VocabularyEntry(
                lemma: "木漏れ日", kind: .word, language: .japanese,
                phonetic: "こもれび", syllables: ["こ", "も", "れ", "び"],
                explanation: "[名] 从树叶间洒下的阳光",
                explanationEn: "{木|き}の{葉|は}の{間|あいだ}から{漏|も}れて{差|さ}し{込|こ}む{日|ひ}の{光|ひかり}。",
                partsOfSpeech: ["名詞"],
                examples: [
                    Example(sentence: "{公園|こうえん}のベンチで{木漏|こも}れ{日|び}を{浴|あ}びながら{本|ほん}を{読|よ}んだ。",
                            translation: "在公园的长椅上，沐浴着林间洒下的阳光读书。"),
                ],
                mnemonic: "字面就是「树·漏·日」：阳光从树缝里漏下来",
                etymology: "和語。由「木」「漏れる」「日」复合而成，常被举作难以译成外语的日语词",
                roots: "木（き，树）+ 漏れ（もれ，漏出）+ 日（ひ→び，阳光）→ 从树间漏下的阳光",
                collocations: [
                    Collocation(phrase: "{木漏|こも}れ{日|び}が{差|さ}す", meaning: "阳光透过树叶洒下",
                                example: "{森|もり}の{小道|こみち}に{木漏|こも}れ{日|び}が{差|さ}している。",
                                exampleTranslation: "林间小路上洒着斑驳的阳光。"),
                ],
                now: now
            ),
            VocabularyEntry(
                lemma: "気が置けない", kind: .phrase, language: .japanese,
                phonetic: "きがおけない",
                explanation: "[惯] 无需客气的；可以推心置腹的",
                explanationEn: "{遠慮|えんりょ}したり{気|き}を{遣|つか}ったりする{必要|ひつよう}がない。",
                partsOfSpeech: ["連語"],
                examples: [
                    Example(sentence: "{彼|かれ}とは{学生|がくせい}{時代|じだい}からの{気|き}が{置|お}けない{仲|なか}だ。",
                            translation: "我和他是从学生时代起就无话不谈的朋友。"),
                ],
                mnemonic: "常被误解为「不能放心」，其实正相反：心里用不着「搁置」戒备，所以相处轻松",
                etymology: "惯用语。「気を置く」意为有所顾虑、客气；否定形表示毫无顾虑",
                roots: "気（き，心思）+ 置く（おく，搁置）→ 不必把心思搁在对方身上",
                synonymGroups: [SynonymGroup(sense: "亲密无间的", words: ["心安い", "親しい"])],
                collocations: [
                    Collocation(phrase: "{気|き}が{置|お}けない{友人|ゆうじん}", meaning: "可以推心置腹的朋友",
                                example: "{気|き}が{置|お}けない{友人|ゆうじん}と{飲|の}む{酒|さけ}はうまい。",
                                exampleTranslation: "和知心朋友喝的酒最好喝。"),
                ],
                confusables: ["気が許せない"],
                now: now
            ),
        ]
    }

    private static func english(now: Date) -> [VocabularyEntry] {
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
