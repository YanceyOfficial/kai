import Foundation
import KaiCore

/// A single-choice quiz question: show the word, pick its meaning from four options.
struct QuizQuestion: Identifiable {
    /// The backing entry's id (also used to reset the view per question).
    let id: UUID
    let prompt: String
    let phonetic: String
    let options: [String]
    let correctIndex: Int
}

/// Builds single-choice questions for due entries, drawing distractor meanings from
/// the rest of the deck. Pure and deterministic given an RNG, so it is fully testable.
struct QuizGenerator {
    var optionCount = 4

    /// A question for `target`, or `nil` if it has no meaning or there are no other
    /// meanings to use as distractors.
    func makeQuestion<G: RandomNumberGenerator>(
        for target: VocabularyEntry,
        pool: [VocabularyEntry],
        using rng: inout G
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
            id: target.id,
            prompt: target.lemma,
            phonetic: target.phonetic,
            options: options,
            correctIndex: options.firstIndex(of: correct)!
        )
    }

    /// Builds a question per due entry, skipping any that cannot form one.
    func makeQuiz<G: RandomNumberGenerator>(
        due: [VocabularyEntry],
        pool: [VocabularyEntry],
        using rng: inout G
    ) -> [QuizQuestion] {
        due.compactMap { makeQuestion(for: $0, pool: pool, using: &rng) }
    }
}
