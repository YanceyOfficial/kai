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

    // MARK: Line breaking

    /// A piece of a line-breaking unit: a base, with its reading when annotated.
    struct Part: Equatable, Hashable {
        let base: String
        let reading: String?
    }

    /// The smallest pieces a line may break between. An annotated base never splits from
    /// its reading; a Latin word keeps its letters (and trailing space) together; any
    /// other character stands alone, as Japanese text breaks anywhere. Closing
    /// punctuation and small kana never begin a line (they join the unit before), and
    /// opening brackets never end one (they join the unit after) — the core of the
    /// Japanese line-breaking rules (kinsoku).
    static func units(_ segments: [Segment]) -> [[Part]] {
        var units: [[Part]] = []
        var pendingOpeners = ""

        func append(_ part: Part) {
            var part = part
            if !pendingOpeners.isEmpty {
                // Openers ride with what they open; a reading stays over its own base.
                if part.reading == nil {
                    part = Part(base: pendingOpeners + part.base, reading: nil)
                } else {
                    units.append([Part(base: pendingOpeners, reading: nil), part])
                    pendingOpeners = ""
                    return
                }
                pendingOpeners = ""
            }
            units.append([part])
        }

        for segment in segments {
            switch segment {
            case .ruby(let base, let reading):
                append(Part(base: base, reading: reading))
            case .text(let text):
                var word = ""
                func flushWord() {
                    guard !word.isEmpty else { return }
                    append(Part(base: word, reading: nil))
                    word = ""
                }
                for character in text {
                    if isLatin(character) {
                        word.append(character)
                    } else if character == " " {
                        word.append(character)
                        flushWord()
                    } else if noLineStart.contains(character), !units.isEmpty || !word.isEmpty {
                        flushWord()
                        attachToLast(character, in: &units)
                    } else if noLineEnd.contains(character) {
                        flushWord()
                        pendingOpeners.append(character)
                    } else {
                        flushWord()
                        append(Part(base: String(character), reading: nil))
                    }
                }
                flushWord()
            }
        }
        if !pendingOpeners.isEmpty { units.append([Part(base: pendingOpeners, reading: nil)]) }
        return units
    }

    /// How far a part's reading hangs past each side of it, laid out by `RubyText`:
    /// the part is as wide as its base, or the reading less one base character (the
    /// overhang a reading may take over its neighbours), and the reading is centred.
    /// Estimated from character counts — kana and kanji are full-width, a reading is
    /// set at half the base size — so a layout can use it before anything is measured.
    static func hang(of part: Part, size: CGFloat) -> CGFloat {
        guard let reading = part.reading else { return 0 }
        let readingWidth = CGFloat(reading.count) * size * 0.5
        let baseWidth = CGFloat(part.base.count) * size
        let partWidth = max(baseWidth, readingWidth - size)
        return max(0, (readingWidth - partWidth) / 2)
    }

    private static func attachToLast(_ character: Character, in units: inout [[Part]]) {
        guard var last = units.popLast() else { return }
        if let tail = last.last, tail.reading == nil {
            last[last.count - 1] = Part(base: tail.base + String(character), reading: nil)
        } else {
            last.append(Part(base: String(character), reading: nil))
        }
        units.append(last)
    }

    private static func isLatin(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber || character == "'" || character == "-")
    }

    /// Characters that must not begin a line.
    private static let noLineStart: Set<Character> = Set(
        "、。，．,.!?！？)）]」』】〕〉》〙〗ー～…‥・：；:;ぁぃぅぇぉっゃゅょゎァィゥェォッャュョヮヵヶ々"
    )
    /// Characters that must not end a line.
    private static let noLineEnd: Set<Character> = Set("(（[「『【〔〈《〘〖")
}
