import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Lightweight, platform-guarded haptic feedback for the review loop. On non-UIKit
/// platforms (e.g. macOS previews or tests) every call is a no-op so callers never
/// need their own `#if` guards.
public enum KaiHaptics {
    /// The strength of a physical "tap" impact.
    public enum Impact {
        case light, medium, rigid, soft
    }

    /// A short impact — used when a card flips or a button is committed.
    public static func impact(_ style: Impact) {
        #if canImport(UIKit)
        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:  generator = UIImpactFeedbackGenerator(style: .light)
        case .medium: generator = UIImpactFeedbackGenerator(style: .medium)
        case .rigid:  generator = UIImpactFeedbackGenerator(style: .rigid)
        case .soft:   generator = UIImpactFeedbackGenerator(style: .soft)
        }
        generator.impactOccurred()
        #endif
    }

    /// A crisp selection tick — used when moving between discrete choices.
    public static func selection() {
        #if canImport(UIKit)
        UISelectionFeedbackGenerator().selectionChanged()
        #endif
    }

    /// A semantic notification buzz — used to celebrate completion.
    public static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
}

/// The press feedback every Kai control shares: it answers the moment a finger lands
/// (not on release), sinks slightly, and comes back without bounce — a press carries
/// no momentum. The action and its haptic still commit on release.
public struct KaiPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(configuration.isPressed ? .easeOut(duration: 0.1) : KaiMotion.snappy, value: configuration.isPressed)
    }
}
