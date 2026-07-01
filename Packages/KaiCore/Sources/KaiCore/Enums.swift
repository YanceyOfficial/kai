import Foundation

/// Learning language domain. Core field for English/Japanese language isolation; currently only English is used.
public enum LanguageDomain: String, Codable, CaseIterable, Sendable {
    case english
    case japanese
}

/// Entry kind. Distinguishes words from phrases; determines applicable question types (fixes legacy phrase bug).
public enum EntryKind: String, Codable, Sendable {
    case word
    case phrase
}

/// Entry source entry point.
public enum EntrySource: String, Codable, Sendable {
    case manual   // Fallback / unknown
    case single   // Single quick add
    case share    // System share extension
    case ocr      // Clipboard / photo OCR
    case batch    // Batch paste
}

/// FSRS learning stage.
public enum LearningState: String, Codable, Sendable {
    case new
    case learning
    case review
    case relearning
}

/// Example source style.
public enum ExampleSource: String, Codable, Sendable {
    case plain     // Plain example sentence
    case literary  // Literary work style short text / passage
}

/// Review rating, raw value aligned with FSRS convention (1=again … 4=easy).
public enum ReviewRating: Int, Codable, CaseIterable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

/// Quiz question type.
public enum QuizType: String, Codable, CaseIterable, Sendable {
    case singleChoice       // Single choice
    case splitCombine       // Syllable fragment combination (words only)
    case fillInBlank        // Fill in the blank with example
    case listeningSpelling  // Listening and spelling (words only)
    case meaningMatch       // Meaning matching
    case contextCloze       // Context cloze

    /// Whether this question type is applicable to the given entry kind.
    /// Syllable combining and listening-spelling depend on syllable segmentation; only applicable to words; phrases are always excluded.
    public func isApplicable(to kind: EntryKind) -> Bool {
        switch self {
        case .splitCombine, .listeningSpelling:
            return kind == .word
        case .singleChoice, .fillInBlank, .meaningMatch, .contextCloze:
            return true
        }
    }
}
