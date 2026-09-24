import SwiftUI

/// Kai's mark: the "sliced sun" of the app icon — a sun in the accent colour cut
/// by four widening lines, over a horizon in the primary text colour. Use it where
/// the app names itself (onboarding, the widget). It follows the accent and the
/// colour scheme, and is hidden from VoiceOver: it sits next to the name.
public struct KaiMark: View {
    private let height: CGFloat
    private let sunk: CGFloat

    /// - Parameters:
    ///   - height: the mark's height in points; its width follows the icon's proportions.
    ///   - sunk: how far the sun has gone down behind the horizon, in the icon's 1024-point
    ///     units (0 = risen; negative lifts it higher). Animatable — the launch splash uses
    ///     it for a sunrise.
    public init(height: CGFloat, sunk: CGFloat = 0) {
        self.height = height
        self.sunk = sunk
    }

    public var body: some View {
        ZStack {
            KaiMarkSun(sunk: sunk).fill(KaiColor.accent)
            KaiMarkHorizon().fill(KaiColor.sumi)
        }
        .frame(width: height * KaiMarkGeometry.aspectRatio, height: height)
        .accessibilityHidden(true)
    }
}

/// The mark's geometry, on the app icon's 1024-point canvas. It must match
/// `scripts/generate_app_icon.swift`, which draws the icon from the same numbers.
enum KaiMarkGeometry {
    static let center = CGPoint(x: 512, y: 560)
    static let radius: CGFloat = 262
    /// The cuts through the sun, top to bottom, each wider than the last.
    static let cuts: [(y: CGFloat, height: CGFloat)] = [(548, 18), (608, 24), (672, 32), (744, 42)]
    static let horizon = CGRect(x: 170, y: 804, width: 684, height: 16)
    /// The part of the canvas the mark occupies: the horizon's width, the sun's top to the horizon's foot.
    static let bounds = CGRect(x: 170, y: 298, width: 684, height: 522)
    static let aspectRatio = bounds.width / bounds.height

    /// The sun with its cuts, lowered by `sunk`, then cut off at the horizon. The clip
    /// happens in the sun's own frame (the horizon raised by `sunk`) before the cuts
    /// and the move — the order of Path's boolean operations that holds up.
    static func sunPath(sunk: CGFloat = 0) -> Path {
        let circle = Path(ellipseIn: CGRect(
            x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2
        ))
        let visibleHeight = horizon.minY - sunk
        // Entirely below the horizon: an empty path. (Path's intersection of shapes that
        // don't overlap is not reliably empty, so it is never asked for.)
        guard visibleHeight > center.y - radius else { return Path() }
        var sun = circle.intersection(Path(CGRect(x: 0, y: 0, width: 1024, height: visibleHeight)))
        for cut in cuts {
            sun = sun.subtracting(Path(CGRect(x: 0, y: cut.y, width: 1024, height: cut.height)))
        }
        return sun.applying(CGAffineTransform(translationX: 0, y: sunk))
    }

    static func horizonPath() -> Path {
        Path(roundedRect: horizon, cornerRadius: horizon.height / 2)
    }

    /// Maps the canvas's `bounds` onto `rect`.
    static func transform(into rect: CGRect) -> CGAffineTransform {
        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        return CGAffineTransform(translationX: rect.minX, y: rect.minY)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -bounds.minX, y: -bounds.minY)
    }
}

struct KaiMarkSun: Shape {
    var sunk: CGFloat

    var animatableData: CGFloat {
        get { sunk }
        set { sunk = newValue }
    }

    func path(in rect: CGRect) -> Path {
        KaiMarkGeometry.sunPath(sunk: sunk).applying(KaiMarkGeometry.transform(into: rect))
    }
}

struct KaiMarkHorizon: Shape {
    func path(in rect: CGRect) -> Path {
        KaiMarkGeometry.horizonPath().applying(KaiMarkGeometry.transform(into: rect))
    }
}
