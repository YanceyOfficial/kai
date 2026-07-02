import SwiftUI

// MARK: - Palette

/// The "Ink & Paper" (墨) palette: warm washi paper, sumi ink, one vermilion accent.
public enum KaiColor {
    /// Warm washi-paper background.
    public static let washi = Color(hex: 0xF3EBDD)
    /// A slightly lighter paper for card faces, to lift them off the background.
    public static let cardFace = Color(hex: 0xFBF4E6)
    /// Sumi ink — primary text and strokes.
    public static let sumi = Color(hex: 0x1C1A17)
    /// Muted warm ink for secondary text.
    public static let inkSecondary = Color(hex: 0x6B6357)
    /// Vermilion — the single accent (brush strokes, the hanko seal).
    public static let vermilion = Color(hex: 0xC8402F)
    /// Soft paper shadow.
    public static let shadow = Color(hex: 0x1C1A17).opacity(0.14)
    /// Hairline ink border.
    public static let hairline = Color(hex: 0x1C1A17).opacity(0.12)
}

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
