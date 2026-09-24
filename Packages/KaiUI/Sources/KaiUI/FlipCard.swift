import SwiftUI

/// The signature study card: a word (with its pronunciation) on the face, the meaning
/// on the back, and one continuous physical object between the two.
///
/// - **Turn it over** by tapping, or by dragging it sideways: the card follows the
///   finger 1:1, and on release the finger's velocity is handed to the spring — it
///   completes the turn if the projected motion passes halfway, and falls back
///   otherwise.
/// - **Rate it** once revealed by swiping: right for Good, left for Again. The card
///   tracks the finger, a hint for the rating grows in the direction of travel, and a
///   release commits only if the throw is projected past a third of the width in the
///   direction it was dragged (`KaiMotion.swipeOutcome`); otherwise it springs home.
///   Drags lock to one axis first, so the back still scrolls vertically, and the card
///   holds still while text on its back is selected (see `textSelectionChanged`).
/// - **Throw it** from outside with `fling` (a rating button does): the card leaves
///   the same way a committed swipe does, so buttons and swipes read as one gesture.
/// - With Reduce Motion the card cross-fades instead of turning, and swipes are off
///   (the rating buttons remain).
///
/// The reveal state is external (`isRevealed`) so a session can coordinate the card
/// with its controls; set it inside `withAnimation(KaiMotion.flip)`.
public struct FlipCard<Back: View>: View {
    private let word: String
    private let phonetic: String
    private let isLearned: Bool
    /// Whether to fire `onSpeak` automatically when the card appears. The speaker
    /// button always plays regardless of this flag.
    private let autoPlays: Bool
    /// Plays the word's pronunciation: once on appear (if `autoPlays`), and on every tap
    /// of the speaker. Injected so KaiUI stays free of any audio framework.
    private let onSpeak: () -> Void
    /// Called once a swipe on the revealed card commits, after it has left the screen.
    private let onSwipe: ((KaiMotion.SwipeDirection) -> Void)?
    /// How far a swipe has gone towards committing (0…1), for the card waiting behind.
    private let onSwipeProgress: (Double) -> Void
    /// Set by the owner to throw the revealed card off the screen, as a swipe would —
    /// how a rating button carries it away. `onSwipe` follows once it has left.
    private let fling: KaiMotion.SwipeDirection?
    /// The revealed side: rich, domain-specific content supplied by the app.
    private let back: Back

    @Binding private var isRevealed: Bool

    /// Extra turn (degrees) while the face is being dragged; 0 at rest.
    @State private var dragAngle: Double = 0
    /// Which way the card turned over (+1 / −1), so the back rests where it landed.
    @State private var turnSide: Double = 1
    /// Horizontal offset while a revealed card is being swiped.
    @State private var swipe: Double = 0
    /// The axis the current drag locked to, once it has moved far enough to tell.
    @State private var dragAxis: Axis?
    /// Whether the current swipe has crossed the commit distance (for one haptic tick).
    @State private var pastThreshold = false
    /// True once the card is on its way out (a committed swipe or a fling).
    @State private var leaving = false
    /// Text views on the back that hold a selection. While any does, the card stays
    /// put: dragging a selection handle must not swipe the card away.
    @State private var selections: Set<AnyHashable> = []
    @State private var width: Double = 350
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        word: String,
        phonetic: String,
        isLearned: Bool = false,
        autoPlays: Bool = true,
        isRevealed: Binding<Bool>,
        onSpeak: @escaping () -> Void = {},
        onSwipe: ((KaiMotion.SwipeDirection) -> Void)? = nil,
        onSwipeProgress: @escaping (Double) -> Void = { _ in },
        fling: KaiMotion.SwipeDirection? = nil,
        @ViewBuilder back: () -> Back
    ) {
        self.word = word
        self.phonetic = phonetic
        self.isLearned = isLearned
        self.autoPlays = autoPlays
        self._isRevealed = isRevealed
        self.onSpeak = onSpeak
        self.onSwipe = onSwipe
        self.onSwipeProgress = onSwipeProgress
        self.fling = fling
        self.back = back()
    }

    /// The card's turn: where the reveal state puts it, plus the finger's drag.
    private var angle: Double { (isRevealed ? 180 * turnSide : 0) + dragAngle }

    public var body: some View {
        faces
            .offset(x: swipe)
            .rotationEffect(.degrees(swipe / width * 8), anchor: .bottom)
            .overlay(alignment: swipe > 0 ? .topLeading : .topTrailing) { swipeHint }
            .onGeometryChange(for: Double.self) { $0.size.width } action: { width = max($0, 1) }
            .contentShape(Rectangle())
            .onTapGesture {
                // Tap reveals; the revealed side scrolls freely, and the rating controls
                // (or a swipe) carry the session forward from there.
                guard !isRevealed else { return }
                KaiHaptics.impact(.light)
                turnSide = 1
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : KaiMotion.flip) { isRevealed = true }
            }
            .simultaneousGesture(drag, including: reduceMotion ? .subviews : .all)
            .onAppear { if autoPlays { onSpeak() } }   // auto-play once per card
            .onChange(of: fling) { _, direction in
                if let direction { leave(direction, velocity: 0) }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(word)
            .accessibilityHint(isRevealed ? "" : "Double-tap to reveal the meaning")
    }

    // MARK: Faces

    @ViewBuilder
    private var faces: some View {
        if reduceMotion {
            ZStack {
                if isRevealed {
                    card(backWithSelectionLock).transition(.opacity)
                } else {
                    card(front).transition(.opacity)
                }
            }
        } else {
            FlipFaces(angle: angle, front: card(front), back: card(backWithSelectionLock))
        }
    }

    /// The back, telling the card when its text is being selected.
    private var backWithSelectionLock: some View {
        back.environment(\.textSelectionChanged) { id, selected in
            if selected { selections.insert(id) } else { selections.remove(id) }
        }
    }

    private var front: some View {
        VStack(spacing: KaiSpacing.m) {
            Text(word)
                .font(KaiFont.display(46, weight: .bold))
                .tracking(-0.8)
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
            Text("Tap or drag to reveal")
                .font(KaiFont.body(13, weight: .medium))
                .foregroundStyle(KaiColor.inkSecondary.opacity(0.7))
        }
        .overlay(alignment: .topTrailing) {
            if isLearned { LearnedMark() }
        }
    }

    /// A face on the card's surface: the same size, padding and material both sides.
    private func card(_ content: some View) -> some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 380)
            .padding(KaiSpacing.l)
            .background(cardSurface)
    }

    private var cardSurface: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(KaiColor.cardFace)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(KaiColor.hairline, lineWidth: 1)
            )
            .shadow(color: KaiColor.shadow, radius: 18, x: 0, y: 12)
    }

    /// The rating a swipe is heading for, growing with the swipe — the motion hints at
    /// its outcome before the finger lifts.
    @ViewBuilder
    private var swipeHint: some View {
        // Only while a finger is on it: a thrown card has already been rated.
        if swipe != 0, !leaving {
            let rating: ReviewRating = swipe > 0 ? .good : .again
            let progress = min(1, abs(swipe) / (width * 0.35))
            Text(rating.label)
                .font(KaiFont.body(17, weight: .semibold))
                .foregroundStyle(rating.tint)
                .padding(.horizontal, KaiSpacing.m)
                .padding(.vertical, KaiSpacing.s)
                .background(Capsule().fill(rating.tint.opacity(0.14)))
                .overlay(Capsule().strokeBorder(rating.tint.opacity(0.3), lineWidth: 1))
                .padding(KaiSpacing.l)
                .opacity(progress)
                .scaleEffect(0.85 + 0.15 * progress)
                .accessibilityHidden(true)
        }
    }

    // MARK: Gestures

    private var drag: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard selections.isEmpty else { return }   // selecting text: the card holds still
                if dragAxis == nil {
                    dragAxis = abs(value.translation.width) > abs(value.translation.height) ? .horizontal : .vertical
                }
                guard dragAxis == .horizontal else { return }
                if isRevealed {
                    trackSwipe(value.translation.width)
                } else {
                    // Left turns the card one way, right the other; past a half-turn
                    // either way it resists.
                    let raw = -value.translation.width / width * 180
                    let excess = abs(raw) - 180
                    dragAngle = excess > 0
                        ? (raw > 0 ? 1 : -1) * (180 + KaiMotion.rubberband(overshoot: excess, dimension: 180))
                        : raw
                }
            }
            .onEnded { value in
                defer { dragAxis = nil }
                guard dragAxis == .horizontal else { return }
                if isRevealed {
                    endSwipe(velocity: value.velocity.width)
                } else {
                    endTurn(translation: value.translation.width, velocity: value.velocity.width)
                }
            }
    }

    private func endTurn(translation: Double, velocity: Double) {
        // In degrees per second, the way the angle moves.
        let angularVelocity = -velocity / width * 180
        if KaiMotion.flips(translation: translation, velocity: velocity, width: width) {
            let side: Double = translation < 0 ? 1 : -1
            let remaining = 180 * side - dragAngle
            turnSide = side
            KaiHaptics.impact(.light)
            withAnimation(KaiMotion.handoff(velocity: angularVelocity, remaining: remaining)) {
                isRevealed = true
                dragAngle = 0
            }
        } else {
            withAnimation(KaiMotion.handoff(velocity: angularVelocity, remaining: -dragAngle)) {
                dragAngle = 0
            }
        }
    }

    private func trackSwipe(_ translation: Double) {
        guard onSwipe != nil else { return }
        swipe = translation
        let progress = min(1, abs(translation) / (width * 0.35))
        onSwipeProgress(progress)
        // One tick as the swipe crosses the commit distance, either way.
        if (progress >= 1) != pastThreshold {
            pastThreshold = progress >= 1
            KaiHaptics.selection()
        }
    }

    /// Sends the card off the screen towards `direction`, carrying `velocity` (points per
    /// second; 0 for a fling), while the card behind rises to take its place; then
    /// reports the swipe. With Reduce Motion it reports at once (the owner crossfades).
    private func leave(_ direction: KaiMotion.SwipeDirection, velocity: Double) {
        guard let onSwipe, !leaving else { return }
        leaving = true
        guard !reduceMotion else { onSwipe(direction); return }
        let target = (direction == .right ? 1.0 : -1.0) * width * 1.4
        withAnimation(KaiMotion.handoff(velocity: velocity, remaining: target - swipe)) {
            swipe = target
            onSwipeProgress(1)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            onSwipe(direction)
        }
    }

    private func endSwipe(velocity: Double) {
        guard let onSwipe else { return }
        pastThreshold = false
        switch KaiMotion.swipeOutcome(translation: swipe, velocity: velocity, width: width) {
        case .commit(let direction):
            if direction == .left { KaiHaptics.impact(.rigid) } else { KaiHaptics.impact(.medium) }
            leave(direction, velocity: velocity)
        case .cancel:
            onSwipeProgress(0)
            withAnimation(KaiMotion.handoff(velocity: velocity, remaining: -swipe, bounce: 0.15)) { swipe = 0 }
        }
    }
}

public extension KaiMotion {
    /// Turning a card over when the app does it (a tap, "Show answer"): no bounce.
    static let flip = Animation.spring(duration: 0.5, bounce: 0)
}

/// Both faces of a card and the turn between them. The face shown follows the
/// *animated* angle — the back appears only once the card is past edge-on — so a
/// turn released at 60° never shows the back early. Mid-turn the card frosts over
/// (a veil and a blur, strongest edge-on), which softens the turn.
// `@preconcurrency`: View is main-actor isolated and Animatable is not; SwiftUI only
// reads and writes `animatableData` on the main actor.
private struct FlipFaces<Front: View, Back: View>: View, @preconcurrency Animatable {
    var angle: Double
    let front: Front
    let back: Back

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    /// Peak blur, edge-on (points).
    private var maxFrost: CGFloat { 9 }

    var body: some View {
        let turned = abs(angle.truncatingRemainder(dividingBy: 360))
        let showsBack = turned > 90 && turned < 270
        // How far the card is from lying flat: 0 face-on (either side), 1 edge-on. It
        // follows the animated angle, so the frost tracks a drag as well as a spring.
        let frost = abs(sin(angle * .pi / 180))
        ZStack {
            if showsBack {
                back.rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                front
            }
        }
        // Frosted glass while it turns: the face mists over and softens towards the
        // edge, so the swap of faces at 90° happens under the frost instead of as a cut.
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(KaiColor.cardFace)
                .opacity(0.45 * frost)
                .allowsHitTesting(false)
        }
        .blur(radius: maxFrost * frost)
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}

/// The face of a card, still — for the next card waiting under the one in hand. It
/// matches `FlipCard`'s face so the hand-off is seamless.
public struct FlipCardFace: View {
    private let word: String
    private let phonetic: String

    public init(word: String, phonetic: String) {
        self.word = word
        self.phonetic = phonetic
    }

    public var body: some View {
        // Everything the live face shows — speaker, hint, shadow — so nothing pops in
        // when it takes this card's place.
        VStack(spacing: KaiSpacing.m) {
            Text(word)
                .font(KaiFont.display(46, weight: .bold))
                .tracking(-0.8)
                .foregroundStyle(KaiColor.sumi)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            HStack(spacing: KaiSpacing.s) {
                Text(phonetic)
                    .font(KaiFont.phonetic(17))
                    .foregroundStyle(KaiColor.inkSecondary)
                SpeakerButton(action: {})
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            Text("Tap or drag to reveal")
                .font(KaiFont.body(13, weight: .medium))
                .foregroundStyle(KaiColor.inkSecondary.opacity(0.7))
        }
        .frame(height: 380)
        .padding(KaiSpacing.l)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(KaiColor.cardFace)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(KaiColor.hairline, lineWidth: 1)
                )
                .shadow(color: KaiColor.shadow, radius: 18, x: 0, y: 12)
        )
        .accessibilityHidden(true)
    }
}

// MARK: - Details

/// A small accent speaker that replays the word's pronunciation on tap.
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
                .foregroundStyle(KaiColor.accent)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(KaiPressStyle())
        .accessibilityLabel("Play pronunciation")
    }
}

/// A simple accent checkmark marking a card as learned — no badge, just the tick.
struct LearnedMark: View {
    var body: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(KaiColor.accent)
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
            isRevealed: $revealed,
            onSwipe: { _ in revealed = false }
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
