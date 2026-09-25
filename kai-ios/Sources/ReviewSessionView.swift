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
    /// How far the card in hand has been swiped towards a rating (0…1); the next card
    /// rises to meet it.
    @State private var swipeProgress: Double = 0
    /// A rating chosen with a button: the card is thrown off in its direction (`fling`)
    /// and the rating is applied once it has left, as a swipe's would be.
    @State private var pendingRating: KaiUI.ReviewRating?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
    /// The language being studied; the header's menu switches it (which rebuilds the tabs).
    @AppStorage(AppSettings.studyLanguageKey) private var studyLanguageRaw = LanguageDomain.english.rawValue

    private var accent: Accent { Accent(rawValue: accentRaw) ?? .us }
    private var language: LanguageDomain { LanguageDomain(rawValue: studyLanguageRaw) ?? .english }

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
    /// and collocations — scrollable — plus a link to the full detail page. Its text is
    /// `RubyText`, so a long press selects it for Copy, Look Up, Translate.
    @ViewBuilder
    private func cardBack(_ card: ReviewCardData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KaiSpacing.m) {
                VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                    RubyText(card.word, size: 24, weight: .semibold, design: .serif)
                    if !card.phonetic.isEmpty {
                        Text(card.phonetic)
                            .font(KaiFont.phonetic(14))
                            .foregroundStyle(KaiColor.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                RubyText(card.explanation, size: 21, design: .serif)
                if let en = card.explanationEn, !en.isEmpty {
                    RubyText(en, size: 16, color: KaiColor.inkSecondary)
                }

                if !card.examples.isEmpty {
                    backDivider
                    backLabel("Examples")
                    ForEach(Array(card.examples.enumerated()), id: \.offset) { _, ex in
                        VStack(alignment: .leading, spacing: 2) {
                            RubyText(ex.sentence, size: 17)
                            if !ex.translation.isEmpty {
                                RubyText(ex.translation, size: 15, color: KaiColor.inkSecondary)
                            }
                        }
                    }
                }

                if !card.synonymGroups.isEmpty {
                    backDivider
                    backLabel("Similar words")
                    ForEach(Array(card.synonymGroups.enumerated()), id: \.offset) { _, group in
                        RubyText("\(group.sense) · \(group.words.joined(separator: ", "))", size: 15)
                    }
                }

                if !card.collocations.isEmpty {
                    backDivider
                    backLabel("Collocations")
                    ForEach(Array(card.collocations.enumerated()), id: \.offset) { _, c in
                        // Bottom-aligned: a phrase with furigana is taller than its gloss.
                        HStack(alignment: .bottom, spacing: KaiSpacing.s) {
                            RubyText(c.phrase, size: 16, weight: .semibold)
                                .fixedSize()
                            RubyText(c.meaning, size: 14, color: KaiColor.inkSecondary)
                        }
                    }
                }

                Button { detailEntry = store.entry(for: card) } label: {
                    HStack(spacing: 4) {
                        Text("Full details")
                        Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                    }
                    .font(KaiFont.body(14, weight: .semibold))
                    .foregroundStyle(KaiColor.accent)
                }
                .buttonStyle(.plain)
                .padding(.top, KaiSpacing.xs)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // iOS 26 blurs content scrolling under a scroll view's edge — meant for bars, not a
        // card, and inside the card's 3D turn the blur spreads over most of the back.
        .withoutScrollEdgeEffect()
    }

    private func backLabel(_ text: String) -> some View {
        Text(text)
            .font(KaiFont.body(11, weight: .semibold))
            .foregroundStyle(KaiColor.accent)
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
                ZStack {
                    // The next card rises into place only as this one is swiped or thrown
                    // away. At rest it is not there at all: the card in hand turns edge-on
                    // as it flips, and nothing may show through behind it.
                    if index + 1 < cards.count {
                        let next = cards[index + 1]
                        FlipCardFace(word: next.word, phonetic: next.phonetic)
                            .scaleEffect(0.94 + 0.06 * swipeProgress)
                            .offset(y: 16 * (1 - swipeProgress))
                            .opacity(swipeProgress)
                    }
                    FlipCard(
                        word: card.word,
                        phonetic: card.phonetic,
                        isLearned: card.isLearned,
                        autoPlays: autoPlayPronunciation,
                        isRevealed: $revealed,
                        onSpeak: { pronouncer.say(card.word, phonetic: card.phonetic, language: language, accent: accent) },
                        // Right is Good, left is Again; Hard and Easy stay on the buttons.
                        // A swipe rates Good (right) or Again (left); a thrown card carries
                        // the rating its button chose.
                        onSwipe: { direction in
                            let rating = pendingRating ?? (direction == .right ? .good : .again)
                            pendingRating = nil
                            rate(card, rating, swiped: !reduceMotion)
                        },
                        onSwipeProgress: { swipeProgress = $0 },
                        fling: pendingRating.map { $0 == .again || $0 == .hard ? .left : .right }
                    ) {
                        cardBack(card)
                    }
                    .id(card.id)   // a fresh card (and turn state) per word
                }

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
                    .tracking(-0.6)
                    .foregroundStyle(KaiColor.sumi)
                languageMenu
            }
            Spacer()
            Button { showingStory = true } label: {
                Image(systemName: "book.pages")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(KaiColor.accent)
            }
            .buttonStyle(KaiPressStyle())
            .padding(.trailing, KaiSpacing.s)
            Text("\(min(index + 1, cards.count)) / \(cards.count)")
                .font(KaiFont.phonetic(16))
                .foregroundStyle(KaiColor.inkSecondary)
        }
    }

    /// Which deck is being studied, and the switch between them.
    private var languageMenu: some View {
        Menu {
            Picker("Studying", selection: $studyLanguageRaw) {
                ForEach(LanguageDomain.allCases, id: \.self) { language in
                    Text(language.displayName).tag(language.rawValue)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("甲斐 · \(language.displayName)")
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .font(KaiFont.body(14, weight: .medium))
            .foregroundStyle(KaiColor.inkSecondary)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Studying \(language.displayName)")
        .accessibilityHint("Switches to another language's deck")
    }

    @ViewBuilder
    private func controls(for card: ReviewCardData) -> some View {
        if revealed {
            RatingBar(interval: { store.previewInterval(for: card, rating: $0.core) }) { rating in
                // Again and Hard throw the card left, Good and Easy right — the same way
                // the swipes go — and the next card rises as it leaves.
                guard pendingRating == nil else { return }
                pendingRating = rating
            }
            .allowsHitTesting(pendingRating == nil)
        } else {
            KaiPrimaryButton("Show answer") {
                withAnimation(KaiMotion.flip) { revealed = true }
            }
        }
    }

    /// Records a rating (from a button or a swipe) and moves to the next card.
    private func rate(_ card: ReviewCardData, _ rating: KaiUI.ReviewRating, swiped: Bool = false) {
        // On a replay pass, just advance — don't re-rate or re-feed FSRS.
        if !isReplay {
            store.rate(card, rating.core)
            // A re-drilled (lapsed) card can be rated more than once; count it once.
            if !reviewedIDs.contains(card.id) { reviewedIDs.append(card.id) }
        }
        advance(swiped: swiped)
    }

    private var completed: some View {
        VStack(spacing: KaiSpacing.m) {
            Spacer()
            Text("Done")
                .font(KaiFont.display(48, weight: .bold))
                .foregroundStyle(KaiColor.accent)
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

    /// Moves to the next card. After a swipe the card in hand has already left and the
    /// next one has risen into its place, so the swap is instant: animating it faded the
    /// new card in over the one after it, which flashed through for a few frames.
    private func advance(swiped: Bool = false) {
        var transaction = Transaction(animation: swiped ? nil : KaiMotion.standard)
        transaction.disablesAnimations = swiped
        withTransaction(transaction) {
            revealed = false
            swipeProgress = 0
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
        withAnimation(KaiMotion.standard) {
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
        withAnimation(KaiMotion.standard) {
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
        withAnimation(KaiMotion.standard) { phase = .quiz }
    }

    private func endQuiz() {
        quizStore = nil
        withAnimation(KaiMotion.standard) { phase = .review }
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

private extension View {
    /// Turns off the iOS 26 scroll edge effect; earlier systems have none.
    @ViewBuilder
    func withoutScrollEdgeEffect() -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectHidden(true, for: .all)
        } else {
            self
        }
    }
}
