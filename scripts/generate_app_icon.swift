// Generates Kai's app icon and launch screen assets from one geometry:
//
// - `AppIcon.icon` — an Icon Composer document (SVG layers + `icon.json`). Xcode 26
//   compiles it (Liquid Glass on iOS 26+, the flat PNGs older iOS needs).
// - `Assets.xcassets/LaunchMark.imageset` — the mark on its own, flat, as @2x/@3x PNGs
//   (light and dark; actool cannot read these SVGs), which `UILaunchScreen` shows
//   centred; `LaunchSplash` in the app picks up from that exact frame.
// - `Assets.xcassets/LaunchBackground.colorset` — the launch screen's background, the
//   app's own (`KaiColor.washi`).
//
// The mark is a "sliced sun": a Tokiwa-green (常磐色) sun cut by four widening
// lines above a horizon — the effort, and the result coming up over it (甲斐,
// "worth it"). Every band is a plain path (the circle clipped between two
// horizontals, computed below), not an SVG mask, so Icon Composer can render
// each layer. `KaiMark` in KaiUI draws the same geometry in SwiftUI; keep the two
// in step.
//
// Usage: swift scripts/generate_app_icon.swift kai-ios/Resources

import AppKit
import Foundation

// MARK: Geometry (a 1024 × 1024 canvas)

let cx = 512.0, cy = 560.0, r = 262.0
/// The four cuts through the sun, top to bottom, as (y, height); each wider than the last.
let cuts: [(y: Double, h: Double)] = [(548, 18), (608, 24), (672, 32), (744, 42)]
/// The horizon: the sun is cut off where it starts.
let horizon = (x: 170.0, y: 804.0, width: 684.0, height: 16.0)

/// The y-ranges of the visible bands, from the top of the sun down to the horizon.
func bands() -> [(top: Double, bottom: Double)] {
    var result: [(Double, Double)] = []
    var top = cy - r
    for cut in cuts {
        result.append((top, cut.y))
        top = cut.y + cut.h
    }
    result.append((top, horizon.y))
    return result
}

func fmt(_ v: Double) -> String { String(format: "%.2f", v) }

/// The part of the circle between two horizontals, as one closed path: across
/// the top chord, down the right-hand arc, back along the bottom chord, and up the
/// left-hand arc. A chord at the very top of the circle is a single point.
func bandPath(top: Double, bottom: Double) -> String {
    func half(_ y: Double) -> Double { (max(0, r * r - (y - cy) * (y - cy))).squareRoot() }
    let (t, b) = (half(top), half(bottom))
    return "M\(fmt(cx - t)) \(fmt(top))L\(fmt(cx + t)) \(fmt(top))"
        + "A\(fmt(r)) \(fmt(r)) 0 0 1 \(fmt(cx + b)) \(fmt(bottom))"
        + "L\(fmt(cx - b)) \(fmt(bottom))"
        + "A\(fmt(r)) \(fmt(r)) 0 0 1 \(fmt(cx - t)) \(fmt(top))Z"
}

// MARK: Palette

struct Scheme {
    let background: (String, String)
    let sun: (String, String)
    let horizon: String
}

let light = Scheme(background: ("#F8F8FA", "#E9E9EE"), sun: ("#2DAA57", "#136A30"), horizon: "#1A1A1E")
let dark = Scheme(background: ("#1D1D1E", "#0A0A0A"), sun: ("#43C774", "#1B813E"), horizon: "#F3F3F6")

// MARK: Layers

func svg(_ body: String) -> String {
    #"<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">"#
        + body + "</svg>\n"
}

func verticalGradient(_ id: String, _ stops: (String, String), from y1: Double, to y2: Double) -> String {
    #"<defs><linearGradient id="\#(id)" gradientUnits="userSpaceOnUse" x1="0" y1="\#(fmt(y1))" x2="0" y2="\#(fmt(y2))">"#
        + #"<stop offset="0" stop-color="\#(stops.0)"/><stop offset="1" stop-color="\#(stops.1)"/></linearGradient></defs>"#
}

func backgroundLayer(_ s: Scheme) -> String {
    svg(verticalGradient("g", s.background, from: 0, to: 1024) + #"<rect width="1024" height="1024" fill="url(#g)"/>"#)
}

func sunLayer(_ s: Scheme) -> String {
    let paths = bands().map { #"<path d="\#(bandPath(top: $0.top, bottom: $0.bottom))"/>"# }.joined()
    return svg(verticalGradient("g", s.sun, from: cy - r, to: horizon.y) + #"<g fill="url(#g)">\#(paths)</g>"#)
}

func horizonLayer(_ s: Scheme) -> String {
    svg(#"<rect x="\#(fmt(horizon.x))" y="\#(fmt(horizon.y))" width="\#(fmt(horizon.width))" height="\#(fmt(horizon.height))" rx="\#(fmt(horizon.height / 2))" fill="\#(s.horizon)"/>"#)
}

// MARK: Document

/// A layer shown in one appearance only: the light one is hidden in dark, and the
/// dark one everywhere else (the same swap the Exodus icon uses; actool honours it).
func layer(_ name: String, darkOnly: Bool) -> [String: Any] {
    [
        "image-name": "\(name).svg",
        "name": name,
        "hidden-specializations": [
            ["value": darkOnly],
            ["appearance": "dark", "value": !darkOnly],
        ],
    ]
}

let resources = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let out = resources.appendingPathComponent("AppIcon.icon")
let assets = out.appendingPathComponent("Assets")
try? FileManager.default.removeItem(at: out)
try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)

let files: [(String, String)] = [
    ("background", backgroundLayer(light)), ("background-dark", backgroundLayer(dark)),
    ("sun", sunLayer(light)), ("sun-dark", sunLayer(dark)),
    ("horizon", horizonLayer(light)), ("horizon-dark", horizonLayer(dark)),
]
for (name, body) in files {
    try body.write(to: assets.appendingPathComponent("\(name).svg"), atomically: true, encoding: .utf8)
}

// Top to bottom, as Icon Composer lists layers.
let document: [String: Any] = [
    "groups": [[
        "layers": [
            layer("horizon", darkOnly: false), layer("horizon-dark", darkOnly: true),
            layer("sun", darkOnly: false), layer("sun-dark", darkOnly: true),
            layer("background", darkOnly: false), layer("background-dark", darkOnly: true),
        ],
        "shadow": ["kind": "neutral", "opacity": 0.5],
        "translucency": ["enabled": true, "value": 0.3],
    ]],
    "supported-platforms": ["circles": ["watchOS"], "squares": "shared"],
]
let json = try JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
try json.write(to: out.appendingPathComponent("icon.json"))
print("wrote \(out.path)")

// MARK: Launch screen

/// The launch mark's point size: `LaunchSplash` draws `KaiMark(height:)` at the same height.
let launchHeight = 84.0
let markBox = (x: 170.0, y: 298.0, width: 684.0, height: 522.0)

/// The mark alone, flat (the accent and the text colour, as `KaiMark` draws it), cropped
/// to its own bounds, as a transparent PNG `launchHeight` points tall at `scale`.
func launchMarkPNG(sun: NSColor, horizonColour: NSColor, scale: Double) -> Data {
    let unit = launchHeight * scale / markBox.height
    let size = NSSize(width: (markBox.width * unit).rounded(), height: (markBox.height * unit).rounded())
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let cg = NSGraphicsContext.current!.cgContext
    // Canvas units, y down, origin at the mark's top-left.
    cg.translateBy(x: 0, y: size.height)
    cg.scaleBy(x: unit, y: -unit)
    cg.translateBy(x: -markBox.x, y: -markBox.y)
    let circle = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
    for band in bands() {
        cg.saveGState()
        cg.clip(to: CGRect(x: 0, y: band.top, width: 1024, height: band.bottom - band.top))
        cg.addEllipse(in: circle)
        cg.setFillColor(sun.cgColor)
        cg.fillPath()
        cg.restoreGState()
    }
    let bar = CGRect(x: horizon.x, y: horizon.y, width: horizon.width, height: horizon.height)
    cg.addPath(CGPath(roundedRect: bar, cornerWidth: horizon.height / 2, cornerHeight: horizon.height / 2, transform: nil))
    cg.setFillColor(horizonColour.cgColor)
    cg.fillPath()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

func srgb(_ hex: UInt32) -> NSColor {
    NSColor(srgbRed: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255, alpha: 1)
}

let catalog = resources.appendingPathComponent("Assets.xcassets")
let imageset = catalog.appendingPathComponent("LaunchMark.imageset")
try? FileManager.default.removeItem(at: imageset)
try FileManager.default.createDirectory(at: imageset, withIntermediateDirectories: true)
// KaiColor.accent and KaiColor.sumi, light and dark.
let darkAppearance: [[String: String]] = [["appearance": "luminosity", "value": "dark"]]
var images: [[String: Any]] = []
for (suffix, sun, line, dark) in [("", srgb(0x1B813E), srgb(0x1A1A1E), false), ("-dark", srgb(0x23A750), srgb(0xF3F3F6), true)] {
    for scale in [2, 3] {
        let name = "launch-mark\(suffix)@\(scale)x.png"
        try launchMarkPNG(sun: sun, horizonColour: line, scale: Double(scale))
            .write(to: imageset.appendingPathComponent(name))
        var entry: [String: Any] = ["filename": name, "idiom": "universal", "scale": "\(scale)x"]
        if dark { entry["appearances"] = darkAppearance }
        images.append(entry)
    }
}
let imagesetJSON: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: imagesetJSON, options: [.prettyPrinted, .sortedKeys])
    .write(to: imageset.appendingPathComponent("Contents.json"))

/// An sRGB colour entry for a colorset, from a 24-bit hex.
func colourEntry(_ hex: UInt32, dark: Bool) -> [String: Any] {
    let c = ["red": (hex >> 16) & 0xFF, "green": (hex >> 8) & 0xFF, "blue": hex & 0xFF]
        .mapValues { String(format: "%.3f", Double($0) / 255) }
    var entry: [String: Any] = [
        "color": ["color-space": "srgb", "components": c.merging(["alpha": "1.000"]) { $1 }],
        "idiom": "universal",
    ]
    if dark { entry["appearances"] = darkAppearance }
    return entry
}
let colorset = catalog.appendingPathComponent("LaunchBackground.colorset")
try FileManager.default.createDirectory(at: colorset, withIntermediateDirectories: true)
// KaiColor.washi.
let colorsetJSON: [String: Any] = [
    "colors": [colourEntry(0xF2F2F6, dark: false), colourEntry(0x111113, dark: true)],
    "info": ["author": "xcode", "version": 1],
]
try JSONSerialization.data(withJSONObject: colorsetJSON, options: [.prettyPrinted, .sortedKeys])
    .write(to: colorset.appendingPathComponent("Contents.json"))
print("wrote \(imageset.path) and \(colorset.path)")
