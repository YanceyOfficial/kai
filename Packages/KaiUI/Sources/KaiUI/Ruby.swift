import Foundation

/// Ruby (furigana) markup: the readings printed above kanji in Japanese text.
///
/// Kai stores it inline, in the text itself, as `{base|reading}` — `{曖昧|あいまい}な{返事|へんじ}`
/// — so every field the AI writes in Japanese carries its readings without a parallel
/// structure, and text with no braces (all English content) is simply plain. A brace
/// that does not close into this shape is kept as literal text. A full-width `｜` is
/// accepted as the separator too, since models sometimes write one.
public enum Ruby {
    /// A run of text, or a base with its reading.
    public enum Segment: Equatable, Sendable {
        case text(String)
        case ruby(base: String, reading: String)
    }

    /// Splits markup into plain runs and annotated bases, in order.
    public static func parse(_ markup: String) -> [Segment] {
        var segments: [Segment] = []
        var text = ""
        var rest = Substring(markup)

        while let open = rest.firstIndex(of: "{") {
            text += rest[..<open]
            let afterOpen = rest.index(after: open)
            if let close = rest[afterOpen...].firstIndex(of: "}"),
               let annotation = annotation(in: rest[afterOpen..<close]) {
                if !text.isEmpty { segments.append(.text(text)); text = "" }
                segments.append(annotation)
                rest = rest[rest.index(after: close)...]
            } else {
                text.append("{")
                rest = rest[afterOpen...]
            }
        }
        text += rest
        if !text.isEmpty { segments.append(.text(text)) }
        return segments
    }

    /// `base|reading` with both sides non-empty and no nested brace; nil otherwise.
    private static func annotation(in body: Substring) -> Segment? {
        guard !body.contains("{"),
              let bar = body.firstIndex(where: { $0 == "|" || $0 == "｜" }) else { return nil }
        let base = String(body[..<bar]).trimmingCharacters(in: .whitespaces)
        let reading = String(body[body.index(after: bar)...]).trimmingCharacters(in: .whitespaces)
        guard !base.isEmpty, !reading.isEmpty else { return nil }
        return .ruby(base: base, reading: reading)
    }

    /// The text as it reads without annotations: `{曖昧|あいまい}な` → `曖昧な`. For search,
    /// matching, copying and VoiceOver.
    public static func plain(_ markup: String) -> String {
        parse(markup).map { segment in
            switch segment {
            case .text(let text): text
            case .ruby(let base, _): base
            }
        }.joined()
    }

    /// The text with each annotated base replaced by its reading: `{曖昧|あいまい}な` →
    /// `あいまいな`. Unambiguous input for speech.
    public static func reading(_ markup: String) -> String {
        parse(markup).map { segment in
            switch segment {
            case .text(let text): text
            case .ruby(_, let reading): reading
            }
        }.joined()
    }

    /// Whether the markup carries at least one annotation.
    public static func hasRuby(_ markup: String) -> Bool {
        parse(markup).contains { if case .ruby = $0 { true } else { false } }
    }
}
