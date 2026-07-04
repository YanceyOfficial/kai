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
    let explanationEn: String?
    let examples: [Example]
    let synonymGroups: [SynonymGroup]
    let collocations: [Collocation]
    var isLearned: Bool

    init(
        id: UUID = UUID(),
        word: String,
        phonetic: String,
        explanation: String,
        explanationEn: String? = nil,
        examples: [Example] = [],
        synonymGroups: [SynonymGroup] = [],
        collocations: [Collocation] = [],
        isLearned: Bool = false
    ) {
        self.id = id
        self.word = word
        self.phonetic = phonetic
        self.explanation = explanation
        self.explanationEn = explanationEn
        self.examples = examples
        self.synonymGroups = synonymGroups
        self.collocations = collocations
        self.isLearned = isLearned
    }

    /// Projects a persisted entry into rich display data for the revealed card.
    init(entry: VocabularyEntry) {
        self.init(
            id: entry.id,
            word: entry.lemma,
            phonetic: entry.phonetic,
            explanation: entry.explanation,
            explanationEn: entry.explanationEn,
            examples: entry.examples,
            synonymGroups: entry.synonymGroups,
            collocations: entry.collocations,
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
    @State private var showingStory = false
    /// The entry shown in the full-details sheet (opened from the revealed card).
    @State private var detailEntry: VocabularyEntry?

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
        .sheet(isPresented: $showingStory) {
            StoryView(store: StoryStore(context: modelContext))
        }
        .sheet(isPresented: Binding(get: { detailEntry != nil }, set: { if !$0 { detailEntry = nil } })) {
            if let detailEntry {
                NavigationStack { WordDetailView(entry: detailEntry) }
            }
        }
    }

    /// The revealed side of the card: meaning (bilingual), every example, similar words,
    /// and collocations — scrollable — plus a link to the full detail page.
    @ViewBuilder
    private func cardBack(_ card: ReviewCardData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KaiSpacing.m) {
                HStack(alignment: .firstTextBaseline, spacing: KaiSpacing.s) {
                    Text(card.word)
                        .font(KaiFont.display(22, weight: .semibold))
                        .foregroundStyle(KaiColor.sumi)
                    Text(card.phonetic)
                        .font(KaiFont.phonetic(13))
                        .foregroundStyle(KaiColor.inkSecondary)
                }

                Text(card.explanation)
                    .font(KaiFont.display(20, weight: .regular))
                    .foregroundStyle(KaiColor.sumi)
                    .fixedSize(horizontal: false, vertical: true)
                if let en = card.explanationEn, !en.isEmpty {
                    Text(en)
                        .font(KaiFont.body(14))
                        .foregroundStyle(KaiColor.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !card.examples.isEmpty {
                    backDivider
                    backLabel("Examples")
                    ForEach(Array(card.examples.enumerated()), id: \.offset) { _, ex in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ex.sentence)
                                .font(KaiFont.body(15))
                                .foregroundStyle(KaiColor.sumi)
                                .fixedSize(horizontal: false, vertical: true)
                            if !ex.translation.isEmpty {
                                Text(ex.translation)
                                    .font(KaiFont.body(14))
                                    .foregroundStyle(KaiColor.inkSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }

                if !card.synonymGroups.isEmpty {
                    backDivider
                    backLabel("Similar words")
                    ForEach(Array(card.synonymGroups.enumerated()), id: \.offset) { _, group in
                        Text("\(group.sense) · \(group.words.joined(separator: ", "))")
                            .font(KaiFont.body(14))
                            .foregroundStyle(KaiColor.sumi)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if !card.collocations.isEmpty {
                    backDivider
                    backLabel("Collocations")
                    ForEach(Array(card.collocations.enumerated()), id: \.offset) { _, c in
                        HStack(alignment: .firstTextBaseline, spacing: KaiSpacing.s) {
                            Text(c.phrase)
                                .font(KaiFont.body(14, weight: .semibold))
                                .foregroundStyle(KaiColor.sumi)
                            Text(c.meaning)
                                .font(KaiFont.body(12))
                                .foregroundStyle(KaiColor.inkSecondary)
                        }
                    }
                }

                Button { detailEntry = store.entry(for: card) } label: {
                    HStack(spacing: 4) {
                        Text("Full details")
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                    }
                    .font(KaiFont.body(14, weight: .semibold))
                    .foregroundStyle(KaiColor.vermilion)
                }
                .buttonStyle(.plain)
                .padding(.top, KaiSpacing.xs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func backLabel(_ text: String) -> some View {
        Text(text)
            .font(KaiFont.body(11, weight: .semibold))
            .foregroundStyle(KaiColor.vermilion)
            .textCase(.uppercase)
            .tracking(1.5)
    }

    private var backDivider: some View {
        Rectangle().fill(KaiColor.hairline).frame(height: 1).padding(.vertical, 2)
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
                    isLearned: card.isLearned,
                    autoPlays: autoPlayPronunciation,
                    isRevealed: $revealed,
                    onSpeak: { pronouncer.play(card.word, accent: accent) }
                ) {
                    cardBack(card)
                }
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
            Button { showingStory = true } label: {
                Image(systemName: "book.pages")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(KaiColor.vermilion)
            }
            .buttonStyle(KaiPressStyle())
            .padding(.trailing, KaiSpacing.s)
            Text("\(min(index + 1, cards.count)) / \(cards.count)")
                .font(KaiFont.phonetic(16))
                .foregroundStyle(KaiColor.inkSecondary)
        }
    }

    @ViewBuilder
    private func controls(for card: ReviewCardData) -> some View {
        if revealed {
            RatingBar(interval: { store.previewInterval(for: card, rating: $0.core) }) { rating in
                // On a replay pass, just advance — don't re-rate or re-feed FSRS.
                if !isReplay {
                    store.rate(card, rating.core)
                    // A re-drilled (lapsed) card can be rated more than once; count it once.
                    if !reviewedIDs.contains(card.id) { reviewedIDs.append(card.id) }
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
