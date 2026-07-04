import Foundation
import KaiCore

/// A learner's response to a quiz question.
enum QuizResponse {
    case choice(Int)
    case text(String)
}

/// A quiz question shown in a session. An empty `choices` means the answer is typed.
struct QuizQuestion: Identifiable {
    /// The backing entry's id (one question per reviewed word; also resets the view).
    let id: UUID
    let type: QuizType
    let word: String
    let phonetic: String
    /// The prompt/sentence shown under the word (may be empty for a plain meaning quiz).
    let question: String
    let choices: [String]
    let answers: [String]
    let translation: String

    /// No choices ⇒ the learner types the answer (fill-in-blank, listening-spelling).
    var isTextEntry: Bool { choices.isEmpty }
    /// True when the word itself is the answer, so the prompt hides it until answered
    /// (cloze/fill/listening); false when the meaning is the answer (single-choice/match).
    var hidesWord: Bool { type == .contextCloze || isTextEntry }
    /// Listening-spelling plays the pronunciation as the prompt.
    var playsAudio: Bool { type == .listeningSpelling }

    func isCorrect(choiceIndex: Int) -> Bool {
        choices.indices.contains(choiceIndex) && answers.contains(choices[choiceIndex])
    }

    func isCorrect(text: String) -> Bool {
        let norm = Self.normalize(text)
        return answers.contains { Self.normalize($0) == norm }
    }

    private static func normalize(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

/// Builds one question per target word: prefers an AI-generated quiz (varied types),
/// falling back to a single-choice meaning question. Pure/deterministic given an RNG.
struct QuizGenerator {
    var optionCount = 4

    /// Types not rendered yet.
    private static let unsupported: Set<QuizType> = [.splitCombine]
    /// Types answered by typing rather than tapping.
    private static let textTypes: Set<QuizType> = [.fillInBlank, .listeningSpelling]

    func makeQuestion<G: RandomNumberGenerator>(
        for target: VocabularyEntry, pool: [VocabularyEntry], using rng: inout G
    ) -> QuizQuestion? {
        aiQuestion(for: target, using: &rng) ?? meaningQuestion(for: target, pool: pool, using: &rng)
    }

    /// A question built from one of the entry's AI-generated quizzes, if any is usable.
    private func aiQuestion<G: RandomNumberGenerator>(
        for target: VocabularyEntry, using rng: inout G
    ) -> QuizQuestion? {
        let candidates = target.quizzes.filter { quiz in
            guard !Self.unsupported.contains(quiz.type), !quiz.answers.isEmpty else { return false }
            if Self.textTypes.contains(quiz.type) { return true }
            // Choice types need options that include a correct answer.
            return !quiz.choices.isEmpty && quiz.choices.contains { quiz.answers.contains($0) }
        }
        guard let quiz = candidates.randomElement(using: &rng) else { return nil }
        let choices = Self.textTypes.contains(quiz.type) ? [] : quiz.choices
        return QuizQuestion(
            id: target.id, type: quiz.type, word: target.lemma, phonetic: target.phonetic,
            question: quiz.question, choices: choices, answers: quiz.answers, translation: quiz.translation)
    }

    /// The classic fallback: pick the correct meaning among distractors from the deck.
    private func meaningQuestion<G: RandomNumberGenerator>(
        for target: VocabularyEntry, pool: [VocabularyEntry], using rng: inout G
    ) -> QuizQuestion? {
        let correct = target.explanation.trimmingCharacters(in: .whitespaces)
        guard !correct.isEmpty else { return nil }

        var seen: Set<String> = [correct.lowercased()]
        var distractors: [String] = []
        for entry in pool where entry.id != target.id {
            let meaning = entry.explanation.trimmingCharacters(in: .whitespaces)
            guard !meaning.isEmpty, seen.insert(meaning.lowercased()).inserted else { continue }
            distractors.append(meaning)
        }
        guard !distractors.isEmpty else { return nil }

        distractors.shuffle(using: &rng)
        var options = Array(distractors.prefix(optionCount - 1))
        options.append(correct)
        options.shuffle(using: &rng)
        return QuizQuestion(
            id: target.id, type: .singleChoice, word: target.lemma, phonetic: target.phonetic,
            question: "", choices: options, answers: [correct], translation: "")
    }

    func makeQuiz<G: RandomNumberGenerator>(
        due: [VocabularyEntry], pool: [VocabularyEntry], using rng: inout G
    ) -> [QuizQuestion] {
        due.compactMap { makeQuestion(for: $0, pool: pool, using: &rng) }
    }
}
