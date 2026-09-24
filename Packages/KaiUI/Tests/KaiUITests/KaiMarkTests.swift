import SwiftUI
import Testing
@testable import KaiUI

@Test("The sun runs from its top down to the horizon, in icon coordinates")
func sunSpansTopToHorizon() {
    let bounds = KaiMarkGeometry.sunPath().boundingRect
    #expect(abs(bounds.minY - 298) < 0.5)
    #expect(abs(bounds.maxY - 804) < 0.5)
    #expect(abs(bounds.midX - 512) < 0.5)
}

@Test("Each cut leaves a gap across the middle of the sun")
func cutsAreEmpty() {
    let sun = KaiMarkGeometry.sunPath()
    for cut in KaiMarkGeometry.cuts {
        #expect(!sun.contains(CGPoint(x: 512, y: cut.y + cut.height / 2)))
    }
    // …and the bands between them are filled.
    #expect(sun.contains(CGPoint(x: 512, y: 420)))
    #expect(sun.contains(CGPoint(x: 512, y: 587)))
}

@Test("Scaled into a view, the mark keeps its proportions")
func markScalesIntoRect() {
    let rect = CGRect(x: 0, y: 0, width: 684, height: 522).applying(.init(scaleX: 0.1, y: 0.1))
    let horizon = KaiMarkGeometry.horizonPath().applying(KaiMarkGeometry.transform(into: rect)).boundingRect
    #expect(abs(horizon.width - rect.width) < 0.01)
    #expect(abs(horizon.maxY - rect.maxY) < 0.01)
    #expect(abs(KaiMarkGeometry.aspectRatio - 684.0 / 522.0) < 1e-9)
}

@Test("Lowering the sun keeps it cut off at the horizon")
func sunSinksBehindHorizon() {
    let lowered = KaiMarkGeometry.sunPath(sunk: 100).boundingRect
    #expect(abs(lowered.minY - 398) < 0.5)
    // Never below the horizon (the lowest band showing may end at a cut, above it).
    #expect(lowered.maxY <= 804 + 0.5)
    #expect(lowered.maxY > 700)
    // Sunk by more than its full height, nothing is left above the horizon.
    #expect(KaiMarkGeometry.sunPath(sunk: 600).isEmpty)
}
