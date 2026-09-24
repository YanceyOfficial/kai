import Foundation
import Testing
@testable import KaiServices

@Suite("PronunciationURL")
struct PronunciationURLTests {
    @Test("Builds a Youdao dictvoice URL with the US type for a plain word")
    func usWord() throws {
        let url = try #require(PronunciationURL.youdao(for: "eccentric", accent: .us))
        #expect(url.scheme == "https")
        #expect(url.host == "dict.youdao.com")
        #expect(url.path == "/dictvoice")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "audio", value: "eccentric")))
        #expect(items.contains(URLQueryItem(name: "type", value: "2")))
    }

    @Test("Uses type=1 for the UK accent")
    func ukType() throws {
        let url = try #require(PronunciationURL.youdao(for: "colour", accent: .uk))
        let type = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "type" }?.value
        #expect(type == "1")
    }

    @Test("Percent-encodes phrases so spaces survive")
    func phraseEncoding() throws {
        let url = try #require(PronunciationURL.youdao(for: "nice to meet you", accent: .us))
        // The raw URL must not contain literal spaces.
        #expect(!url.absoluteString.contains(" "))
        // But decoding the query item recovers the original phrase.
        let audio = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "audio" }?.value
        #expect(audio == "nice to meet you")
    }

    @Test("Trims surrounding whitespace before building the URL")
    func trimsWhitespace() throws {
        let url = try #require(PronunciationURL.youdao(for: "  hello \n", accent: .us))
        let audio = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "audio" }?.value
        #expect(audio == "hello")
    }

    @Test("Returns nil for blank input")
    func blankReturnsNil() {
        #expect(PronunciationURL.youdao(for: "   ", accent: .us) == nil)
        #expect(PronunciationURL.youdao(for: "", accent: .uk) == nil)
    }

    @Test("Japanese uses le=jap instead of an accent type")
    func japanese() throws {
        let url = try #require(PronunciationURL.youdao(for: "懐かしい", voice: .japanese))
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(items.contains(URLQueryItem(name: "audio", value: "懐かしい")))
        #expect(items.contains(URLQueryItem(name: "le", value: "jap")))
        #expect(!items.contains { $0.name == "type" })
        #expect(!url.absoluteString.contains("懐"))   // percent-encoded on the wire
    }
}

@Suite("JapaneseSpeech")
struct JapaneseSpeechTests {
    @Test("Speaks the kana reading, without its pitch-accent mark")
    func speaksReading() {
        #expect(JapaneseSpeech.text(word: "懐かしい", phonetic: "なつかしい ④") == "なつかしい")
        #expect(JapaneseSpeech.text(word: "生物", phonetic: "せいぶつ") == "せいぶつ")
        #expect(JapaneseSpeech.text(word: "コーヒー", phonetic: "コーヒー ③") == "コーヒー")
    }

    @Test("Falls back to the word when there is no kana reading")
    func fallsBackToWord() {
        #expect(JapaneseSpeech.text(word: "曖昧", phonetic: "") == "曖昧")
        #expect(JapaneseSpeech.text(word: "曖昧", phonetic: "aimai") == "曖昧")
    }
}

