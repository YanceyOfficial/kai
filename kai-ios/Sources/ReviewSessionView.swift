import SwiftUI
import KaiUI
import KaiServices
import KaiCore

/// One card's display content for a review session, projected from a `VocabularyEntry`.
struct ReviewCardData: Identifiable {
    /// Matches the backing entry's id so the store can apply ratings to it.
    let id: UUID
    let word: String
    let phonetic: String
    let explanation: String
    let example: String
    let translation: String
    var isLearned: Bool

    init(
        id: UUID = UUID(),
        word: String,
        phonetic: String,
        explanation: String,
        example: String,
        translation: String,
        isLearned: Bool = false
    ) {
        self.id = id
        self.word = word
        self.phonetic = phonetic
        self.explanation = explanation
        self.example = example
        self.translation = translation
        self.isLearned = isLearned
    }

    /// Projects a persisted entry into display data, using its first example sentence.
    init(entry: VocabularyEntry) {
        let example = entry.examples.first
        self.init(
            id: entry.id,
            word: entry.lemma,
            phonetic: entry.phonetic,
            explanation: entry.explanation,
            example: example?.sentence ?? "",
            translation: example?.translation ?? "",
            isLearned: entry.scheduling.state == .review
        )
    }
}

/// The core learning loop: flip a card, reveal the meaning, self-rate, advance.
/// Ratings flow to `ReviewStore`, which reschedules via FSRS and persists.
struct ReviewSessionView: View {
    let store: ReviewStore

    @Environment(\.modelContext) private var modelContext

    private enum Phase { case review, quiz }
    @State private var phase: Phase = .review
    @State private var quizStore: QuizStore?
    /// The words rated in this group, offered as a follow-up quiz on completion.
    @State private var reviewedIDs: [UUID] = []
    /// True while re-playing the just-completed cards ("Review again"): a pure practice
    /// pass that advances without rating, so it doesn't re-feed FSRS.
    @State private var isReplay = false

    @State private var index = 0
    @State private var revealed = false
    @State private var showDone = false

    /// Plays word pronunciations via Youdao's dictvoice audio.
    @State private var pronouncer = PronunciationPlayer()
    /// User setting: auto-play the pronunciation when each card appears.
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = true
    /// User setting: which accent to pronounce in.
    @AppStorage("pronunciationAccent") private var accentRaw = Accent.us.rawValue
    /// User setting: how many new words to introduce per session.
    @AppStorage("newWordsPerDay") private var newWordsPerDay = 10

    private var accent: Accent { Accent(rawValue: accentRaw) ?? .us }

    private var cards: [ReviewCardData] { store.cards }

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()

            if phase == .quiz, let quizStore {
                QuizSessionView(store: quizStore, onClose: endQuiz)
            } else {
                reviewContent
            }
        }
        .kaiToast("Nice — deck complete", isPresented: $showDone)
    }

    private var reviewContent: some View {
        VStack(spacing: KaiSpacing.l) {
            header
            SessionProgressBar(progress: cards.isEmpty ? 0 : Double(index) / Double(cards.count))

            if index < cards.count {
                let card = cards[index]
                FlipCard(
                    word: card.word,
                    phonetic: card.phonetic,
                    explanation: card.explanation,
                    example: card.example,
                    translation: card.translation,
                    isLearned: card.isLearned,
                    autoPlays: autoPlayPronunciation,
                    isRevealed: $revealed,
                    onSpeak: { pronouncer.play(card.word, accent: accent) }
                )
                .id(card.id)   // reset flip animation per card

                Spacer()
                controls(for: card)
                    .padding(.bottom, KaiSpacing.s)
            } else {
                completed
            }
        }
        .padding(KaiSpacing.l)
    }

    // MARK: Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                Text("Kai")
                    .font(KaiFont.display(34, weight: .bold))
                    .foregroundStyle(KaiColor.sumi)
                Text("甲斐 · review")
                    .font(KaiFont.body(14, weight: .medium))
                    .foregroundStyle(KaiColor.inkSecondary)
            }
            Spacer()
            Text("\(min(index + 1, cards.count)) / \(cards.count)")
                .font(KaiFont.phonetic(16))
                .foregroundStyle(KaiColor.inkSecondary)
        }
    }

    @ViewBuilder
    private func controls(for card: ReviewCardData) -> some View {
        if revealed {
            RatingBar { rating in
                // On a replay pass, just advance — don't re-rate or re-feed FSRS.
                if !isReplay {
                    store.rate(card, rating.core)
                    reviewedIDs.append(card.id)
                }
                advance()
            }
        } else {
            KaiPrimaryButton("Show answer") {
                withAnimation { revealed = true }
            }
        }
    }

    private var completed: some View {
        VStack(spacing: KaiSpacing.m) {
            Spacer()
            Text("Done")
                .font(KaiFont.display(48, weight: .bold))
                .foregroundStyle(KaiColor.vermilion)
            if reviewedIDs.isEmpty {
                // Nothing was due, so there is nothing to replay — no button here.
                Text("All caught up for now.")
                    .font(KaiFont.body(17, weight: .medium))
                    .foregroundStyle(KaiColor.sumi)
            } else {
                Text("Reviewed \(reviewedIDs.count) — lock it in with a quick quiz.")
                    .font(KaiFont.body(17, weight: .medium))
                    .foregroundStyle(KaiColor.sumi)
                    .multilineTextAlignment(.center)
                KaiPrimaryButton("Start quiz") { startQuiz() }
                    .padding(.top, KaiSpacing.s)
                    .frame(maxWidth: 240)
                Button("Review again") { replay() }
                    .font(KaiFont.body(15, weight: .medium))
                    .foregroundStyle(KaiColor.inkSecondary)
                    .padding(.top, KaiSpacing.xs)
            }
            Spacer()
        }
        .padding(.horizontal, KaiSpacing.l)
    }

    private func advance() {
        withAnimation {
            revealed = false
            index += 1
            if index >= cards.count {
                showDone = true
                KaiHaptics.success()
            }
        }
    }

    /// Re-plays the just-completed cards for another practice pass over the same
    /// snapshot. Keeps `reviewedIDs` so a quiz is still offered; `isReplay` makes the
    /// pass advance without re-rating.
    private func replay() {
        isReplay = true
        withAnimation {
            index = 0
            revealed = false
        }
    }

    /// Loads a fresh due session from the store (used after a follow-up quiz), resetting
    /// replay state so ratings feed FSRS again.
    private func loadFreshSession() {
        store.load(newLimit: newWordsPerDay)
        reviewedIDs = []
        isReplay = false
        withAnimation {
            index = 0
            revealed = false
        }
    }

    /// Chains a quiz over the words just reviewed. Falls back to a replay pass if none
    /// of them can form a question (e.g. missing meanings).
    private func startQuiz() {
        let quiz = QuizStore(context: modelContext)
        quiz.load(entryIDs: reviewedIDs)
        guard !quiz.questions.isEmpty else { replay(); return }
        quizStore = quiz
        withAnimation { phase = .quiz }
    }

    private func endQuiz() {
        quizStore = nil
        withAnimation { phase = .review }
        loadFreshSession()
    }
}

/// Maps the UI's rating (KaiUI) to the domain rating (KaiCore). The two enums are
/// deliberately separate so the design system carries no domain dependency.
private extension KaiUI.ReviewRating {
    var core: KaiCore.ReviewRating {
        switch self {
        case .again: return .again
        case .hard: return .hard
        case .good: return .good
        case .easy: return .easy
        }
    }
}
