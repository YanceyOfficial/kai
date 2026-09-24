import Foundation
import KaiCore

/// Builds prompts for card generation. Encodes the word/phrase rule and the literary-example option.
///
/// Both languages share one card schema (`CardSchema`); the Japanese prompt says what
/// each field means for Japanese (a kana reading with its pitch accent as the
/// "phonetic", morae as the "syllables", a kanji breakdown as the "roots") and asks
/// for ruby markup — `{漢字|かんじ}` — on the Japanese sentences, which the app renders
/// as furigana.
public struct PromptBuilder: Sendable {
    private let language: LanguageDomain
    private let literaryExamples: Bool

    public init(language: LanguageDomain, literaryExamples: Bool) {
        self.language = language
        self.literaryExamples = literaryExamples
    }

    private var languageName: String {
        switch language {
        case .english: return "English"
        case .japanese: return "Japanese"
        }
    }

    /// The system prompt: role, per-field expectations, and the word/phrase quiz rule.
    /// Explanatory glosses are written in the learner's native language (Chinese) while
    /// the target-language content (the word, examples, synonyms, collocation phrases)
    /// stays in the target language.
    public func systemPrompt() -> String {
        var lines = switch language {
        case .english: englishCardLines
        case .japanese: japaneseCardLines
        }
        if literaryExamples {
            lines.append("Prefer example sentences written in a literary style, evoking passages from classic literature, while remaining natural.")
        }
        return lines.joined(separator: "\n")
    }

    private var englishCardLines: [String] {
        [
            "You are a lexicographer generating study flashcards for English vocabulary, aimed at native Chinese speakers.",
            "Write `explanation` as a CONCISE CHINESE gloss: part of speech + short meaning, like a dictionary headword (e.g. \"vt. 保证；使确信\"). Keep it short — it is used as a quiz option.",
            "Write `explanationEn` as a fuller English definition (English-to-English study). If you have none, return an empty string.",
            "Also produce: phonetic notation, syllable breakdown, parts of speech, at least 3 example sentences (each `sentence` in English with a Chinese `translation`), a memorable mnemonic (in Chinese), a brief etymology (in Chinese), and easily-confused words.",
            "For `synonyms`, group similar words BY SENSE like a bilingual dictionary: each group has `sense` (the shared meaning, in CHINESE) and `words` (the English words carrying that sense). Use a separate group per distinct meaning.",
            "Produce a `roots` morpheme analysis: break the word into prefix/root/suffix, keeping the English morpheme forms but giving each part's meaning IN CHINESE (e.g. \"ec-（出）+ centr（中心）+ -ic → 偏离中心\"). If the word has no identifiable roots, return an empty string for `roots`.",
            "Produce `collocations`: fixed collocations / common phrases the word forms (e.g. for \"use\": \"used to\", \"make use of\"). Each has `phrase` (English), `meaning` (Chinese gloss), `example` (one English sentence) and `exampleTranslation` (its Chinese translation). Return an empty array if the word forms no notable collocations.",
            "Also produce at least 3 quiz items. Quiz `type` must be one of: singleChoice, splitCombine, fillInBlank, listeningSpelling, meaningMatch, contextCloze.",
            "IMPORTANT: if an item is a multi-word phrase, set its kind to \"phrase\" and DO NOT emit splitCombine or listeningSpelling quizzes for it (those apply to single words only). Single words use kind \"word\".",
        ]
    }

    private var japaneseCardLines: [String] {
        [
            "You are a lexicographer generating study flashcards for Japanese vocabulary, aimed at native Chinese speakers.",
            Self.rubyRule,
            "`lemma`: the item exactly as requested, in its dictionary form, as plain text — never with ruby markup.",
            "`phonetic`: the reading in hiragana (katakana for a loanword), then a space and its pitch accent as a circled number, as in NHK/大辞林 (e.g. \"なつかしい ④\", \"あいまい ⓪\", \"コーヒー ③\"). No markup.",
            "`syllables`: the reading split into morae (e.g. [\"な\", \"つ\", \"か\", \"し\", \"い\"]).",
            "`partsOfSpeech`: Japanese grammatical categories (e.g. \"い形容詞\", \"名詞\", \"動詞（五段・自）\").",
            "Write `explanation` as a CONCISE CHINESE gloss: a bracketed part of speech + short meaning, like a dictionary headword (e.g. \"[形] 令人怀念的；眷恋的\"). Keep it short — it is used as a quiz option. When the word is written with kanji that mean something different in Chinese (同形異義, e.g. 勉強, 手紙, 大丈夫), the gloss gives the JAPANESE meaning.",
            "Write `explanationEn` as a fuller Japanese definition in the style of a 国語辞典 (Japanese-to-Japanese study), with ruby markup. If you have none, return an empty string.",
            "Also produce at least 3 example sentences (each `sentence` in natural Japanese WITH ruby markup, and a Chinese `translation`), a memorable mnemonic (in Chinese — if the kanji mislead a Chinese reader, say so), a brief etymology in Chinese (和語 / 漢語 / 外来語, and where it comes from), and easily-confused words.",
            "Produce `roots` as a kanji breakdown IN CHINESE: each kanji of the word with its on/kun reading and meaning, then how they combine (e.g. \"木（き，树）+ 漏れ（もれ，漏出）+ 日（び，阳光）→ 从树叶间漏下的阳光\"). Return an empty string for a word with no kanji.",
            "For `synonyms`, group similar words BY SENSE like a bilingual dictionary: each group has `sense` (the shared meaning, in CHINESE) and `words` (Japanese words in dictionary form, plain text, no markup). Use a separate group per distinct meaning. `confusables` are Japanese words in plain text too — words easily mixed up with this one in meaning, reading or kanji.",
            "Produce `collocations`: set phrases the word commonly forms (e.g. for 気: 気が置けない, 気を配る). Each has `phrase` (Japanese, with ruby markup), `meaning` (Chinese gloss), `example` (one Japanese sentence, with ruby markup) and `exampleTranslation` (its Chinese translation). Return an empty array if the word forms no notable collocations.",
            "Also produce at least 3 quiz items. Quiz `type` must be one of: singleChoice, fillInBlank, listeningSpelling, meaningMatch, contextCloze. `question` may carry ruby markup; `choices` and `answers` are plain text (they are compared with what the learner picks or types). A listeningSpelling answer is the reading in hiragana.",
            "Never emit splitCombine for Japanese. IMPORTANT: if an item is a multi-word expression (e.g. 気が置けない, 猫の手も借りたい), set its kind to \"phrase\" and DO NOT emit listeningSpelling quizzes for it. Single words use kind \"word\".",
        ]
    }

    /// How Japanese text carries its readings. The app parses exactly this shape
    /// (KaiUI `Ruby`), so it is spelled out with examples of every case that matters.
    static let rubyRule = """
    RUBY MARKUP: in every field this prompt says is Japanese "with ruby markup", annotate EVERY word that contains kanji as {kanji|hiragana reading} — the reading of exactly the kanji inside the braces.
    - A compound takes one annotation over the whole compound: {勉強|べんきょう}する, {木漏|こも}れ{日|び}.
    - Okurigana stays outside the braces: {食|た}べる, {懐|なつ}かしい, {美|うつく}しい.
    - Never annotate kana, punctuation or Latin letters, and never nest braces.
    - Use the reading the word has in THIS sentence (e.g. {今日|きょう}, {一人|ひとり}, {生物|なまもの} when it means raw food).
    Example: {彼|かれ}は{曖昧|あいまい}な{返事|へんじ}しかしなかった。
    """

    /// The user prompt listing the lemmas to generate cards for.
    public func cardUserPrompt(lemmas: [String]) -> String {
        let cleaned = lemmas.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return "Generate cards for these items:\n" + cleaned.map { "- \($0)" }.joined(separator: "\n")
    }

    /// The system prompt for the daily story: a short passage using the review words,
    /// with a Chinese translation.
    public func storySystemPrompt() -> String {
        switch language {
        case .english:
            return [
                "You are a language teacher writing a short study passage for native Chinese speakers learning English.",
                "Write a SHORT, natural, coherent English passage of about 80–120 words that uses every given word at least once, in a way that makes each word's meaning clear from context.",
                "Keep the language simple and memorable. Then provide a faithful Chinese translation of the whole passage in the `translation` field.",
            ].joined(separator: "\n")
        case .japanese:
            return [
                "You are a language teacher writing a short study passage for native Chinese speakers learning Japanese.",
                "Write a SHORT, natural, coherent Japanese passage of about 200–300 characters (です・ます style) that uses every given word at least once, in its dictionary form or a natural conjugation, in a way that makes each word's meaning clear from context.",
                "The `story` field is Japanese with ruby markup.",
                Self.rubyRule,
                "Keep the language simple and memorable. Then provide a faithful Chinese translation of the whole passage in the `translation` field (plain text).",
            ].joined(separator: "\n")
        }
    }

    /// The user prompt listing the words the story must include.
    public func storyUserPrompt(words: [String]) -> String {
        let cleaned = words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return "Use all of these words in one short passage:\n" + cleaned.map { "- \($0)" }.joined(separator: "\n")
    }
}
