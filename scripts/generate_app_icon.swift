// Generates Kai's app icon as an Icon Composer document: `AppIcon.icon`, a folder
// of SVG layers plus `icon.json`. Xcode 26 compiles it (Liquid Glass on iOS 26+,
// and the flat PNGs older iOS needs), so no bitmaps are written here.
//
// The mark is a "sliced sun": a Tokiwa-green (常磐色) sun cut by four widening
// lines above a horizon — the effort, and the result coming up over it (甲斐,
// "worth it"). Every band is a plain path (the circle clipped between two
// horizontals, computed below), not an SVG mask, so Icon Composer can render
// each layer. `KaiMark` in KaiUI draws the same geometry in SwiftUI; keep the two
// in step.
//
// Usage: swift scripts/generate_app_icon.swift kai-ios/Resources/AppIcon.icon

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

let out = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.icon")
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
