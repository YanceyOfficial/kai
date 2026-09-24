import SwiftUI

/// Kai's mark: the "sliced sun" of the app icon — a sun in the accent colour cut
/// by four widening lines, over a horizon in the primary text colour. Use it where
/// the app names itself (onboarding, the widget). It follows the accent and the
/// colour scheme, and is hidden from VoiceOver: it sits next to the name.
public struct KaiMark: View {
    private let height: CGFloat

    /// - Parameter height: the mark's height in points; its width follows the icon's proportions.
    public init(height: CGFloat) {
        self.height = height
    }

    public var body: some View {
        ZStack {
            KaiMarkSun().fill(KaiColor.accent)
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

    /// The sun above the horizon, minus the cuts.
    static func sunPath() -> Path {
        let circle = Path(ellipseIn: CGRect(
            x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2
        ))
        var sun = circle.intersection(Path(CGRect(x: 0, y: 0, width: 1024, height: horizon.minY)))
        for cut in cuts {
            sun = sun.subtracting(Path(CGRect(x: 0, y: cut.y, width: 1024, height: cut.height)))
        }
        return sun
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
    func path(in rect: CGRect) -> Path {
        KaiMarkGeometry.sunPath().applying(KaiMarkGeometry.transform(into: rect))
    }
}

struct KaiMarkHorizon: Shape {
    func path(in rect: CGRect) -> Path {
        KaiMarkGeometry.horizonPath().applying(KaiMarkGeometry.transform(into: rect))
    }
}
