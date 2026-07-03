import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Palette

/// A neutral, mainstream palette with one vermilion accent, adapting to light and
/// dark mode. Names are kept from the earlier "Ink & Paper" system for stability,
/// but map to semantic roles: `washi` = app background, `cardFace` = surface,
/// `sumi` = primary text, `inkSecondary` = secondary text, `vermilion` = accent.
public enum KaiColor {
    /// App background — light neutral gray / near-black.
    public static let washi = adaptive(light: 0xF2F2F6, dark: 0x111113)
    /// Card / grouped surface — white / elevated dark.
    public static let cardFace = adaptive(light: 0xFFFFFF, dark: 0x1D1D21)
    /// Primary text.
    public static let sumi = adaptive(light: 0x1A1A1E, dark: 0xF3F3F6)
    /// Secondary / muted text.
    public static let inkSecondary = adaptive(light: 0x6C6C74, dark: 0x9A9AA2)
    /// The brand accent — a touch brighter in dark mode for contrast.
    public static let vermilion = adaptive(light: 0xC8402F, dark: 0xE45A44)
    /// Error/destructive signal — distinct from the vermilion accent.
    public static let danger = adaptive(light: 0xB3261E, dark: 0xE5584B)
    /// Soft elevation shadow.
    public static let shadow = adaptiveTranslucent(light: (0x000000, 0.10), dark: (0x000000, 0.55))
    /// Hairline separator.
    public static let hairline = adaptiveTranslucent(light: (0x000000, 0.10), dark: (0xFFFFFF, 0.14))
}

// MARK: Adaptive color helpers

/// A color that resolves differently in light vs. dark mode (UIKit); falls back to
/// the light value where UIKit is unavailable.
func adaptive(light: UInt, dark: UInt) -> Color {
    #if canImport(UIKit)
    Color(UIColor { $0.userInterfaceStyle == .dark ? uiColor(dark, 1) : uiColor(light, 1) })
    #else
    Color(hex: light)
    #endif
}

/// Like `adaptive`, but each mode carries its own opacity (for hairlines/shadows).
func adaptiveTranslucent(light: (hex: UInt, alpha: Double), dark: (hex: UInt, alpha: Double)) -> Color {
    #if canImport(UIKit)
    Color(UIColor { $0.userInterfaceStyle == .dark ? uiColor(dark.hex, dark.alpha) : uiColor(light.hex, light.alpha) })
    #else
    Color(hex: light.hex, alpha: light.alpha)
    #endif
}

#if canImport(UIKit)
private func uiColor(_ hex: UInt, _ alpha: Double) -> UIColor {
    let c = KaiColor.rgbComponents(hex: hex)
    return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: alpha)
}
#endif

public extension Color {
    /// Creates a color from a 24-bit hex value, e.g. `Color(hex: 0xC8402F)`.
    init(hex: UInt, alpha: Double = 1) {
        let c = KaiColor.rgbComponents(hex: hex)
        self.init(.sRGB, red: c.red, green: c.green, blue: c.blue, opacity: alpha)
    }
}

public extension KaiColor {
    /// Pure helper: splits a 24-bit hex into 0...1 sRGB components (testable without a renderer).
    static func rgbComponents(hex: UInt) -> (red: Double, green: Double, blue: Double) {
        (
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

// MARK: - Typography

/// Kai's type ramp: a characterful serif (New York) for display, SF for body.
public enum KaiFont {
    /// Serif display face (iOS "New York") — used for words and titles.
    public static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Body/UI face (SF).
    public static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    /// Monospaced-ish label for phonetics.
    public static func phonetic(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}

// MARK: - Spacing

/// A 4pt spacing scale.
public enum KaiSpacing {
    public static let xs: CGFloat = 4
    public static let s: CGFloat = 8
    public static let m: CGFloat = 16
    public static let l: CGFloat = 24
    public static let xl: CGFloat = 32
}
