import SwiftUI

/// The signature study card in the "Ink & Paper" aesthetic: a washi-paper card
/// showing a word with a vermilion brush underline; flipping springs it over in
/// 3D to reveal the meaning. A vermilion hanko seal stamps it once learned.
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

    @Binding private var isRevealed: Bool

    public init(
        word: String,
        phonetic: String,
        explanation: String,
        example: String,
        translation: String,
        isLearned: Bool = false,
        isRevealed: Binding<Bool>
    ) {
        self.word = word
        self.phonetic = phonetic
        self.explanation = explanation
        self.example = example
        self.translation = translation
        self.isLearned = isLearned
        self._isRevealed = isRevealed
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
            // Only on the front: the seal must not be mirrored by the card's flip.
            if isLearned && !isRevealed {
                SealBadge().padding(KaiSpacing.m)
            }
        }
        .rotation3DEffect(.degrees(isRevealed ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: isRevealed)
        .contentShape(Rectangle())
        .onTapGesture { isRevealed.toggle() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isRevealed ? explanation : word)
        .accessibilityHint("Double-tap to flip the card")
    }

    // MARK: Faces

    private var front: some View {
        VStack(spacing: KaiSpacing.s) {
            Text(word)
                .font(KaiFont.display(46, weight: .bold))
                .foregroundStyle(KaiColor.sumi)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            InkBrushUnderline()
                .fill(KaiColor.vermilion)
                .frame(width: 120, height: 9)
            Text(phonetic)
                .font(KaiFont.phonetic(17))
                .foregroundStyle(KaiColor.inkSecondary)
                .padding(.top, KaiSpacing.xs)
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
            Text(word)
                .font(KaiFont.display(22, weight: .semibold))
                .foregroundStyle(KaiColor.sumi)
            Text(explanation)
                .font(KaiFont.display(20, weight: .regular))
                .foregroundStyle(KaiColor.sumi)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle()
                .fill(KaiColor.hairline)
                .frame(height: 1)
                .padding(.vertical, KaiSpacing.xs)
            Text(example)
                .font(KaiFont.body(16, weight: .regular))
                .foregroundStyle(KaiColor.sumi)
                .fixedSize(horizontal: false, vertical: true)
            Text(translation)
                .font(KaiFont.body(15, weight: .regular))
                .foregroundStyle(KaiColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
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

/// A tapered horizontal brush stroke (thicker in the middle, thin at the ends),
/// evoking a single vermilion brush mark.
struct InkBrushUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let capL = rect.minX
        let capR = rect.maxX
        let thin = rect.height * 0.18
        let thick = rect.height * 0.5
        path.move(to: CGPoint(x: capL, y: midY))
        path.addQuadCurve(
            to: CGPoint(x: capR, y: midY - thin),
            control: CGPoint(x: rect.midX, y: midY - thick)
        )
        path.addQuadCurve(
            to: CGPoint(x: capL, y: midY),
            control: CGPoint(x: rect.midX, y: midY + thick)
        )
        path.closeSubpath()
        return path
    }
}

/// A vermilion hanko-style seal reading 判 (a mark of judgement/mastery),
/// slightly rotated as if hand-stamped.
struct SealBadge: View {
    var body: some View {
        Text("判")
            .font(.system(size: 18, weight: .heavy, design: .serif))
            .foregroundStyle(KaiColor.cardFace)
            .frame(width: 38, height: 38)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(KaiColor.vermilion.opacity(0.9))
            )
            .rotationEffect(.degrees(-7))
            .shadow(color: KaiColor.vermilion.opacity(0.22), radius: 4, x: 0, y: 2)
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
