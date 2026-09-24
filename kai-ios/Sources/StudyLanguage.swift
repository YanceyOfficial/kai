import Foundation
import KaiCore
import KaiServices

/// The language being studied. Kai keeps one deck per language (`LanguageDomain`
/// isolates entries, logs and stories); the setting picks which deck every tab shows.
/// Changing it rebuilds the tab shell (`MainTabView`), so views read it once when they
/// load rather than observing it.
extension AppSettings {
    static let studyLanguageKey = "studyLanguage"

    static var studyLanguage: LanguageDomain {
        LanguageDomain(rawValue: UserDefaults.standard.string(forKey: studyLanguageKey) ?? "") ?? .english
    }
}

extension LanguageDomain {
    /// The language's own name, as a learner would look for it in a picker.
    var displayName: String {
        switch self {
        case .english: "English"
        case .japanese: "日本語"
        }
    }
}

extension PronunciationPlaying {
    /// Says a headword in its language: English in the chosen accent; Japanese by its
    /// kana reading when the entry has one (see `JapaneseSpeech`).
    func say(_ word: String, phonetic: String, language: LanguageDomain, accent: Accent) {
        switch language {
        case .english:
            play(word, voice: .english(accent))
        case .japanese:
            play(JapaneseSpeech.text(word: word, phonetic: phonetic), voice: .japanese)
        }
    }
}
