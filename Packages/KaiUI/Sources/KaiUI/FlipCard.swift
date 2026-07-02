import SwiftUI

/// The signature study card in the "Ink & Paper" aesthetic: a washi-paper card
/// showing a word with a vermilion brush underline; tapping springs it over in 3D
/// to reveal the meaning. A vermilion hanko seal stamps the card once it is learned.
public struct FlipCard: View {
    private let word: String
    private let phonetic: String
    private let explanation: String
    private let example: String
    private let translation: String
    private let isLearned: Bool

    @State private var showBack = false

    public init(
        word: String,
        phonetic: String,
        explanation: String,
        example: String,
        translation: String,
        isLearned: Bool = false
    ) {
        self.word = word
        self.phonetic = phonetic
        self.explanation = explanation
        self.example = example
        self.translation = translation
        self.isLearned = isLearned
    }

    public var body: some View {
        ZStack {
            if showBack {
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
            if isLearned {
                SealBadge().padding(KaiSpacing.m)
            }
        }
        .rotation3DEffect(.degrees(showBack ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.55, dampingFraction: 0.72), value: showBack)
        .contentShape(Rectangle())
        .onTapGesture { showBack.toggle() }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(showBack ? explanation : word)
        .accessibilityHint("Double-tap to flip the card")
    }

    // MARK: Faces

    private var front: some View {
        VStack(spacing: KaiSpacing.m) {
            Spacer()
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
            Spacer()
            Text("tap to reveal")
                .font(KaiFont.body(13, weight: .medium))
                .foregroundStyle(KaiColor.inkSecondary.opacity(0.7))
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
            .fill(KaiColor.cardFace)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(KaiColor.hairline, lineWidth: 1)
            )
            .shadow(color: KaiColor.shadow, radius: 18, x: 0, y: 12)
    }
}

// MARK: - Details

/// A tapered horizontal brush stroke (thicker in the middle, thin at the ends),
/// evoking a single sumi/vermilion brush mark.
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
            .font(.system(size: 22, weight: .heavy, design: .serif))
            .foregroundStyle(KaiColor.cardFace)
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(KaiColor.vermilion)
            )
            .rotationEffect(.degrees(-8))
            .shadow(color: KaiColor.vermilion.opacity(0.35), radius: 6, x: 0, y: 3)
            .accessibilityLabel("Learned")
    }
}

#Preview {
    ZStack {
        KaiColor.washi.ignoresSafeArea()
        FlipCard(
            word: "eccentric",
            phonetic: "/ɪkˈsɛntrɪk/",
            explanation: "adj. 古怪的，异乎寻常的",
            example: "My uncle is something of an eccentric.",
            translation: "我叔叔有点古怪。",
            isLearned: true
        )
        .padding(KaiSpacing.l)
    }
}
