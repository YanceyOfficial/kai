import SwiftUI
import KaiCore
import KaiServices
import KaiUI

/// A word's detail page: the same flip card used in review (tap to flip), plus any
/// extra AI-generated notes (mnemonic / etymology / synonyms) below.
struct WordDetailView: View {
    let entry: VocabularyEntry

    @State private var revealed = false
    @State private var pronouncer = PronunciationPlayer()
    @AppStorage("pronunciationAccent") private var accentRaw = Accent.us.rawValue
    private var accent: Accent { Accent(rawValue: accentRaw) ?? .us }

    private var card: ReviewCardData { ReviewCardData(entry: entry) }

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()
            ScrollView {
                VStack(spacing: KaiSpacing.l) {
                    FlipCard(
                        word: card.word,
                        phonetic: card.phonetic,
                        explanation: card.explanation,
                        example: card.example,
                        translation: card.translation,
                        isLearned: card.isLearned,
                        autoPlays: false,
                        isRevealed: $revealed,
                        onSpeak: { pronouncer.play(entry.lemma, accent: accent) }
                    )
                    extras
                }
                .padding(KaiSpacing.l)
            }
        }
        .navigationTitle(entry.lemma)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var extras: some View {
        let mnemonic = entry.mnemonic ?? ""
        let etymology = entry.etymology ?? ""
        if !mnemonic.isEmpty || !etymology.isEmpty || !entry.synonyms.isEmpty {
            VStack(alignment: .leading, spacing: KaiSpacing.m) {
                if !mnemonic.isEmpty { note("Mnemonic", mnemonic) }
                if !etymology.isEmpty { note("Etymology", etymology) }
                if !entry.synonyms.isEmpty { note("Synonyms", entry.synonyms.joined(separator: ", ")) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(KaiSpacing.l)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(KaiColor.cardFace)
                    .shadow(color: KaiColor.shadow, radius: 10, x: 0, y: 6)
            )
        }
    }

    private func note(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: KaiSpacing.xs) {
            Text(title)
                .font(KaiFont.body(11, weight: .semibold))
                .foregroundStyle(KaiColor.vermilion)
                .textCase(.uppercase)
                .tracking(1.5)
            Text(body)
                .font(KaiFont.body(15, weight: .regular))
                .foregroundStyle(KaiColor.sumi)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
