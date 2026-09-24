import Testing
@testable import KaiUI

@Test("Momentum projection matches Apple's deceleration model")
func momentumProjection() {
    // (v / 1000) · d / (1 − d) with d = 0.998: 1000 pt/s travels ~499 pt further.
    #expect(abs(KaiMotion.project(velocity: 1000) - 499) < 0.5)
    #expect(abs(KaiMotion.project(velocity: -1000) + 499) < 0.5)
    #expect(KaiMotion.project(velocity: 0) == 0)
}

@Test("Rubber-banding resists more the further past the edge")
func rubberBanding() {
    let near = KaiMotion.rubberband(overshoot: 20, dimension: 300)
    let far = KaiMotion.rubberband(overshoot: 200, dimension: 300)
    #expect(near > 0 && near < 20)
    #expect(far < 200 && far > near)
    // Each extra point of pull moves the element less than the one before.
    #expect(far - near < 180 * (near / 20))
    #expect(KaiMotion.rubberband(overshoot: -50, dimension: 300) == -KaiMotion.rubberband(overshoot: 50, dimension: 300))
}

@Test("A swipe commits in its direction when it is thrown far enough")
func swipeCommits() {
    // A short drag with a fast flick is thrown past the threshold.
    #expect(KaiMotion.swipeOutcome(translation: 40, velocity: 1200, width: 350) == .commit(.right))
    #expect(KaiMotion.swipeOutcome(translation: -30, velocity: -1500, width: 350) == .commit(.left))
    // A long, slow drag past the threshold commits too.
    #expect(KaiMotion.swipeOutcome(translation: 200, velocity: 0, width: 350) == .commit(.right))
}

@Test("A swipe springs back when short, or when it is thrown back the other way")
func swipeCancels() {
    #expect(KaiMotion.swipeOutcome(translation: 60, velocity: 50, width: 350) == .cancel)
    // Dragged right, then flicked back left: that is a change of mind, not "Again".
    #expect(KaiMotion.swipeOutcome(translation: 150, velocity: -900, width: 350) == .cancel)
}

@Test("A flip completes past halfway, projected, and not otherwise")
func flipOutcome() {
    #expect(KaiMotion.flips(translation: -200, velocity: 0, width: 350))
    #expect(KaiMotion.flips(translation: -60, velocity: -1000, width: 350))
    #expect(!KaiMotion.flips(translation: -60, velocity: 0, width: 350))
    #expect(!KaiMotion.flips(translation: -200, velocity: 900, width: 350))
}
