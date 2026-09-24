import SwiftUI

/// Kai's motion, in one place: the springs every view uses, and the gesture math
/// behind the card's drag-to-flip and swipe-to-rate.
///
/// Springs follow Apple's fluid-interface guidance: critically damped (no bounce) by
/// default, a little bounce only where the user's own gesture carried momentum, and
/// a release always hands the finger's velocity to the animation.
public enum KaiMotion {
    // MARK: Springs

    /// The default for anything the app moves by itself: settles without overshoot.
    public static let standard = Animation.spring(duration: 0.4, bounce: 0)
    /// Small, quick changes: a pressed control, a progress step.
    public static let snappy = Animation.spring(duration: 0.25, bounce: 0)
    /// After a flick: the gesture carried momentum, so a little overshoot reads right.
    public static let momentum = Animation.spring(duration: 0.4, bounce: 0.15)

    /// A spring that starts at the finger's velocity. `velocity` and `remaining` are in
    /// the same units (points, degrees…): SwiftUI wants velocity relative to the distance
    /// still to travel.
    public static func handoff(velocity: Double, remaining: Double, bounce: Double = 0) -> Animation {
        let relative = abs(remaining) < 0.001 ? 0 : velocity / remaining
        return .interpolatingSpring(duration: 0.4, bounce: bounce, initialVelocity: relative)
    }

    // MARK: Gesture math

    /// How far a release at `velocity` (points per second) carries on, with a scroll-like
    /// deceleration — Apple's projection from *Designing Fluid Interfaces* (d ≈ 0.998).
    public static func project(velocity: Double, decelerationRate: Double = 0.998) -> Double {
        (velocity / 1000) * decelerationRate / (1 - decelerationRate)
    }

    /// Progressive resistance past an edge: the further the drag overshoots, the less the
    /// element follows. Symmetric in sign.
    public static func rubberband(overshoot: Double, dimension: Double, constant: Double = 0.55) -> Double {
        let magnitude = abs(overshoot)
        let resisted = (magnitude * dimension * constant) / (dimension + constant * magnitude)
        return overshoot < 0 ? -resisted : resisted
    }

    public enum SwipeDirection: Equatable, Sendable { case left, right }
    public enum SwipeOutcome: Equatable, Sendable { case commit(SwipeDirection), cancel }

    /// Whether a horizontal swipe on a revealed card is a rating. It commits when the
    /// *projected* resting point is past a third of the width — so a quick flick counts
    /// as much as a long drag — and only in the direction the card was dragged: a throw
    /// back the other way is a change of mind, and cancels.
    public static func swipeOutcome(translation: Double, velocity: Double, width: Double) -> SwipeOutcome {
        let projected = translation + project(velocity: velocity)
        guard abs(projected) > width * 0.35, reversal(translation: translation, projected: projected) == false else {
            return .cancel
        }
        return .commit(projected > 0 ? .right : .left)
    }

    /// Whether a drag on the card's face turns it over: projected past half the width,
    /// in the direction it was dragged.
    public static func flips(translation: Double, velocity: Double, width: Double) -> Bool {
        let projected = translation + project(velocity: velocity)
        return abs(projected) > width * 0.5 && !reversal(translation: translation, projected: projected)
    }

    /// A release thrown back across its starting point (beyond a small dead zone).
    private static func reversal(translation: Double, projected: Double) -> Bool {
        abs(translation) > 12 && (translation > 0) != (projected > 0)
    }
}

// MARK: - Shake

/// "Not that one": a short, decaying side-to-side shake, the way iOS rejects a wrong
/// passcode. Fire it on the same frame as the error haptic so sight and touch agree.
/// With Reduce Motion it does nothing (the haptic carries the message).
struct KaiShake: ViewModifier {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.keyframeAnimator(initialValue: 0.0, trigger: trigger) { view, x in
                view.offset(x: x)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-10, duration: 0.06)
                    CubicKeyframe(8, duration: 0.08)
                    CubicKeyframe(-5, duration: 0.08)
                    CubicKeyframe(2, duration: 0.08)
                    SpringKeyframe(0, duration: 0.16, spring: .init(duration: 0.16, bounce: 0))
                }
            }
        }
    }
}

public extension View {
    /// Shakes the view each time `trigger` changes (see `KaiShake`).
    func kaiShake(trigger: Int) -> some View {
        modifier(KaiShake(trigger: trigger))
    }
}
