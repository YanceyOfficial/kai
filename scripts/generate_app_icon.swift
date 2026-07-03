import AppKit

let vermilion = NSColor(srgbRed: 0xC8/255.0, green: 0x40/255.0, blue: 0x2F/255.0, alpha: 1)
let white = NSColor(srgbRed: 0xFA/255.0, green: 0xF7/255.0, blue: 0xF2/255.0, alpha: 1)

/// Render the glyph into an exact pixel-size, alpha-backed bitmap (a 4-sample context is
/// valid, unlike a 3-sample one; drawing at native size avoids lockFocus's 2x scaling).
func renderRGBA(size: Int, text: String, bg: NSColor?, fg: NSColor, weightFraction: CGFloat) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let s = CGFloat(size)
    if let bg { bg.setFill(); NSBezierPath(rect: NSRect(x: 0, y: 0, width: s, height: s)).fill() }
    let font = NSFont.systemFont(ofSize: s * weightFraction, weight: .heavy)
    let para = NSMutableParagraphStyle(); para.alignment = .center
    let attr = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: fg, .paragraphStyle: para])
    let ts = attr.size()
    attr.draw(in: NSRect(x: (s - ts.width) / 2, y: (s - ts.height) / 2 + s * 0.01, width: ts.width, height: ts.height))
    ctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep
}

/// Copy an RGBA rep into a true 24-bit RGB rep (PNG color type 2, no alpha channel) —
/// what actool requires for app icons.
func toOpaqueRGB(_ src: NSBitmapImageRep) -> NSBitmapImageRep {
    let w = src.pixelsWide, h = src.pixelsHigh
    let dst = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: w, pixelsHigh: h,
                               bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: w * 3, bitsPerPixel: 24)!
    let s = src.bitmapData!, d = dst.bitmapData!
    let sSpp = src.samplesPerPixel, sRow = src.bytesPerRow
    for y in 0..<h {
        for x in 0..<w {
            let si = y * sRow + x * sSpp
            let di = y * (w * 3) + x * 3
            d[di] = s[si]; d[di + 1] = s[si + 1]; d[di + 2] = s[si + 2]
        }
    }
    return dst
}

func writePNG(_ rep: NSBitmapImageRep, to path: String) {
    try? rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: path))
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
for px in [20, 29, 40, 58, 60, 76, 80, 87, 120, 152, 167, 180, 1024] {
    let rgba = renderRGBA(size: px, text: "甲", bg: vermilion, fg: white, weightFraction: 0.66)
    writePNG(toOpaqueRGB(rgba), to: "\(out)/Icon-\(px).png")
}
// Launch logo keeps transparency (imageset, not an app icon).
for (name, px) in [("LaunchLogo", 360), ("LaunchLogo@2x", 720), ("LaunchLogo@3x", 1080)] {
    writePNG(renderRGBA(size: px, text: "甲", bg: nil, fg: vermilion, weightFraction: 0.9), to: "\(out)/\(name).png")
}
print("done")
