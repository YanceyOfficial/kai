import Foundation
import SwiftData

/// A cached daily study passage that weaves together a day's review words.
/// One per (day, language); regenerating replaces it. CloudKit-safe: defaulted
/// attributes, no `.unique` (dedupe is done at the repository layer).
@Model
public final class DailyStory {
    public var id: UUID = UUID()
    /// Start of the day this story belongs to (used as the dedupe key with language).
    public var day: Date = Date()
    public var languageRaw: String = LanguageDomain.english.rawValue
    /// The English passage.
    public var text: String = ""
    /// Chinese translation of the passage.
    public var translation: String = ""
    /// The words the story was built from, so the view can highlight/link them.
    public var wordLemmas: [String] = []
    public var createdAt: Date = Date()

    public var language: LanguageDomain {
        get { LanguageDomain(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }

    public init(
        day: Date,
        language: LanguageDomain,
        text: String,
        translation: String,
        wordLemmas: [String],
        now: Date = .now
    ) {
        self.day = Calendar.current.startOfDay(for: day)
        self.languageRaw = language.rawValue
        self.text = text
        self.translation = translation
        self.wordLemmas = wordLemmas
        self.createdAt = now
    }
}
