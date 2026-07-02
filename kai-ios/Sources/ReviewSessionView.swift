import SwiftUI
import KaiUI

/// One card's display content for a review session. The app maps KaiCore entries
/// into this value type; wiring to the real repository + FSRS comes in a later plan.
struct ReviewCardData: Identifiable {
    let id = UUID()
    let word: String
    let phonetic: String
    let explanation: String
    let example: String
    let translation: String
    var isLearned: Bool = false
}

/// The core learning loop: flip a card, reveal the meaning, self-rate, advance.
/// Progress is shown at the top; a toast celebrates completion.
struct ReviewSessionView: View {
    let deck: [ReviewCardData]

    @State private var index = 0
    @State private var revealed = false
    @State private var showDone = false

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()

            VStack(spacing: KaiSpacing.l) {
                header
                SessionProgressBar(progress: deck.isEmpty ? 0 : Double(index) / Double(deck.count))

                if index < deck.count {
                    let card = deck[index]
                    FlipCard(
                        word: card.word,
                        phonetic: card.phonetic,
                        explanation: card.explanation,
                        example: card.example,
                        translation: card.translation,
                        isLearned: card.isLearned,
                        isRevealed: $revealed
                    )
                    .id(card.id)   // reset flip animation per card

                    Spacer()
                    controls
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
            Text("\(min(index + 1, deck.count)) / \(deck.count)")
                .font(KaiFont.phonetic(16))
                .foregroundStyle(KaiColor.inkSecondary)
        }
    }

    @ViewBuilder
    private var controls: some View {
        if revealed {
            RatingBar { _ in advance() }
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
            if index >= deck.count { showDone = true }
        }
    }

    private func restart() {
        withAnimation {
            index = 0
            revealed = false
        }
    }
}
