import Testing
@testable import KaiUI

@Test("Hex splits into normalized sRGB components")
func hexComponents() {
    let vermilion = KaiColor.rgbComponents(hex: 0xC8402F)
    #expect(abs(vermilion.red - 200.0 / 255.0) < 1e-9)
    #expect(abs(vermilion.green - 64.0 / 255.0) < 1e-9)
    #expect(abs(vermilion.blue - 47.0 / 255.0) < 1e-9)

    let white = KaiColor.rgbComponents(hex: 0xFFFFFF)
    #expect(white.red == 1.0 && white.green == 1.0 && white.blue == 1.0)

    let black = KaiColor.rgbComponents(hex: 0x000000)
    #expect(black.red == 0.0 && black.green == 0.0 && black.blue == 0.0)
}
