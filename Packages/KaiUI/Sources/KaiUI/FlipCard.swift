import SwiftUI

/// The signature study card in the "Ink & Paper" aesthetic: a washi-paper card
/// showing a word with a vermilion brush underline; flipping springs it over in
/// 3D to reveal the meaning. A small vermilion checkmark marks it once learned.
///
/// The reveal state is externally controlled via `isRevealed` so a review session
/// can coordinate the card with its rating controls.
public struct FlipCard: View {
    private let word: String
    private let phonetic: String
    private let explanation: String
    private let example: String
    private let translation: String
    private let isLearned: Bool
    /// Whether to fire `onSpeak` automatically when the card appears. The speaker
    /// button always plays regardless of this flag.
    private let autoPlays: Bool
    /// Fired to play the word's pronunciation: once automatically when the card
    /// appears (if `autoPlays`), and again whenever the speaker button is tapped.
    /// Injected by the app so KaiUI stays free of any audio framework.
    private let onSpeak: () -> Void

    @Binding private var isRevealed: Bool

    public init(
        word: String,
        phonetic: String,
        explanation: String,
        example: String,
        translation: String,
        isLearned: Bool = false,
        autoPlays: Bool = true,
        isRevealed: Binding<Bool>,
        onSpeak: @escaping () -> Void = {}
    ) {
        self.word = word
        self.phonetic = phonetic
        self.explanation = explanation
        self.example = example
        self.translation = translation
        self.isLearned = isLearned
        self.autoPlays = autoPlays
        self._isRevealed = isRevealed
        self.onSpeak = onSpeak
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
            KaiHaptics.impact(.light)
            isRevealed.toggle()
        }
        .onAppear { if autoPlays { onSpeak() } }   // auto-play once per card
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isRevealed ? explanation : word)
        .accessibilityHint("Double-tap to flip the card")
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

    private var back: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.m) {
            HStack(alignment: .firstTextBaseline, spacing: KaiSpacing.s) {
                Text(word)
                    .font(KaiFont.display(23, weight: .semibold))
                    .foregroundStyle(KaiColor.sumi)
                Text(phonetic)
                    .font(KaiFont.phonetic(13))
                    .foregroundStyle(KaiColor.inkSecondary)
            }
            Text(explanation)
                .font(KaiFont.display(22, weight: .regular))
                .foregroundStyle(KaiColor.sumi)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(KaiColor.hairline)
                .frame(height: 1)
                .padding(.vertical, KaiSpacing.xs)

            VStack(alignment: .leading, spacing: KaiSpacing.s) {
                Text("Example")
                    .font(KaiFont.body(11, weight: .semibold))
                    .foregroundStyle(KaiColor.vermilion)
                    .textCase(.uppercase)
                    .tracking(1.5)
                Text(example)
                    .font(KaiFont.body(16, weight: .regular))
                    .foregroundStyle(KaiColor.sumi)
                    .fixedSize(horizontal: false, vertical: true)
                Text(translation)
                    .font(KaiFont.body(15, weight: .regular))
                    .foregroundStyle(KaiColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Surface

    private var cardSurface: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                // A whisper of a top-to-bottom warm gradient gives the paper depth.
                LinearGradient(
                    colors: [KaiColor.cardFace, Color(hex: 0xF5EDDC)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
            explanation: "adj. 古怪的，异乎寻常的",
            example: "My uncle is something of an eccentric.",
            translation: "我叔叔有点古怪。",
            isLearned: true,
            isRevealed: $revealed
        )
        .padding(KaiSpacing.l)
    }
}
