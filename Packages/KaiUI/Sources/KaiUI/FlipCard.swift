import SwiftUI

/// The signature study card in the "Ink & Paper" aesthetic: a washi-paper card
/// showing a word with a vermilion brush underline; flipping springs it over in
/// 3D to reveal the meaning. A small vermilion checkmark marks it once learned.
///
/// The reveal state is externally controlled via `isRevealed` so a review session
/// can coordinate the card with its rating controls.
public struct FlipCard<Back: View>: View {
    private let word: String
    private let phonetic: String
    private let isLearned: Bool
    /// Whether to fire `onSpeak` automatically when the card appears. The speaker
    /// button always plays regardless of this flag.
    private let autoPlays: Bool
    /// Fired to play the word's pronunciation: once automatically when the card
    /// appears (if `autoPlays`), and again whenever the speaker button is tapped.
    /// Injected by the app so KaiUI stays free of any audio framework.
    private let onSpeak: () -> Void
    /// The revealed side, supplied by the app so it can embed rich, domain-specific
    /// content (examples, similar words, collocations, a link to full details).
    private let back: Back

    @Binding private var isRevealed: Bool

    public init(
        word: String,
        phonetic: String,
        isLearned: Bool = false,
        autoPlays: Bool = true,
        isRevealed: Binding<Bool>,
        onSpeak: @escaping () -> Void = {},
        @ViewBuilder back: () -> Back
    ) {
        self.word = word
        self.phonetic = phonetic
        self.isLearned = isLearned
        self.autoPlays = autoPlays
        self._isRevealed = isRevealed
        self.onSpeak = onSpeak
        self.back = back()
    }

    public var body: some View {
        ZStack {
            if isRevealed {
                back.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                front
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 380)
        .padding(KaiSpacing.l)
        .background(cardSurface)
        .overlay(alignment: .topTrailing) {
            // Only on the front: the mark must not be mirrored by the card's flip.
            if isLearned && !isRevealed {
                LearnedMark().padding(KaiSpacing.m)
            }
        }
        .rotation3DEffect(.degrees(isRevealed ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.68), value: isRevealed)
        .contentShape(Rectangle())
        .onTapGesture {
            // Tap reveals; the revealed side scrolls freely (no flip-back to steal the
            // scroll gesture). The rating controls carry the session forward from there.
            guard !isRevealed else { return }
            KaiHaptics.impact(.light)
            isRevealed = true
        }
        .onAppear { if autoPlays { onSpeak() } }   // auto-play once per card
        .accessibilityElement(children: .combine)
        .accessibilityLabel(word)
        .accessibilityHint("Double-tap to reveal the meaning")
    }

    // MARK: Faces

    private var front: some View {
        VStack(spacing: KaiSpacing.m) {
            Text(word)
                .font(KaiFont.display(46, weight: .bold))
                .foregroundStyle(KaiColor.sumi)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            HStack(spacing: KaiSpacing.s) {
                Text(phonetic)
                    .font(KaiFont.phonetic(17))
                    .foregroundStyle(KaiColor.inkSecondary)
                SpeakerButton(action: onSpeak)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)   // truly center the word block
        .overlay(alignment: .bottom) {
            Text("tap to reveal")
                .font(KaiFont.body(13, weight: .medium))
                .foregroundStyle(KaiColor.inkSecondary.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1.5)
        }
    }

    // MARK: Surface

    private var cardSurface: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(KaiColor.cardFace)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(KaiColor.hairline, lineWidth: 1)
            )
            .shadow(color: KaiColor.shadow, radius: 18, x: 0, y: 12)
    }
}

// MARK: - Details

/// A small vermilion speaker that replays the word's pronunciation on tap.
/// Its own tap is consumed here, so it never flips the card underneath.
struct SpeakerButton: View {
    let action: () -> Void

    var body: some View {
        Button {
            KaiHaptics.impact(.light)
            action()
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(KaiColor.vermilion)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(KaiPressStyle())
        .accessibilityLabel("Play pronunciation")
    }
}

/// A simple vermilion checkmark marking a card as learned — no badge, just the tick.
struct LearnedMark: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(KaiColor.vermilion)
            .accessibilityLabel("Learned")
    }
}

#Preview {
    @Previewable @State var revealed = false
    ZStack {
        KaiColor.washi.ignoresSafeArea()
        FlipCard(
            word: "eccentric",
            phonetic: "/ɪkˈsɛntrɪk/",
            isLearned: true,
            isRevealed: $revealed
        ) {
            VStack(alignment: .leading) {
                Text("adj. 古怪的，异乎寻常的").font(KaiFont.display(22))
                Text("My uncle is something of an eccentric.").font(KaiFont.body(16))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(KaiSpacing.l)
    }
}
