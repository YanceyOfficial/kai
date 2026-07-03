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

    @State private var index = 0
    @State private var revealed = false
    @State private var showDone = false

    /// Plays word pronunciations via Youdao's dictvoice audio (US accent for now).
    @State private var pronouncer = PronunciationPlayer()
    /// User setting: auto-play the pronunciation when each card appears.
    @AppStorage("autoPlayPronunciation") private var autoPlayPronunciation = true

    private var cards: [ReviewCardData] { store.cards }

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()

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
                        onSpeak: { pronouncer.play(card.word, accent: .us) }
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
        .kaiToast("Nice — deck complete", isPresented: $showDone)
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
                store.rate(card, rating.core)
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
            Text("完")
                .font(KaiFont.display(64, weight: .bold))
                .foregroundStyle(KaiColor.vermilion)
            Text("All caught up for now.")
                .font(KaiFont.body(17, weight: .medium))
                .foregroundStyle(KaiColor.sumi)
            KaiPrimaryButton("Review again") { restart() }
                .padding(.top, KaiSpacing.m)
                .frame(maxWidth: 220)
            Spacer()
        }
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

    private func restart() {
        store.load()
        withAnimation {
            index = 0
            revealed = false
        }
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
