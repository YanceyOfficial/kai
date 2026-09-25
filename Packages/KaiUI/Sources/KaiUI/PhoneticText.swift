import SwiftUI

/// A word's phonetic line: IPA for English, a kana reading for Japanese — where a
/// trailing pitch-accent mark (`なつかしい ④`, the circled number of dictionaries such as
/// NHK's) is set at the reading's size in the system face: in the phonetic face a circled
/// digit comes out much smaller than the kana beside it.
public struct PhoneticText: View {
    private let phonetic: String
    private let size: CGFloat

    public init(_ phonetic: String, size: CGFloat) {
        self.phonetic = phonetic
        self.size = size
    }

    public var body: some View {
        let parts = Self.split(phonetic)
        if let accent = parts.accent {
            Text("\(Text(parts.reading).font(KaiFont.phonetic(size))) \(Text(accent).font(.system(size: size)))")
        } else {
            Text(phonetic).font(KaiFont.phonetic(size))
        }
    }

    /// The reading and, when the last space-separated token is a pitch-accent mark (one
    /// or more circled digits), that mark.
    nonisolated static func split(_ phonetic: String) -> (reading: String, accent: String?) {
        let trimmed = phonetic.trimmingCharacters(in: .whitespaces)
        guard let space = trimmed.lastIndex(where: \.isWhitespace) else { return (trimmed, nil) }
        let token = trimmed[trimmed.index(after: space)...]
        guard !token.isEmpty, token.unicodeScalars.allSatisfy(isCircledDigit) else { return (trimmed, nil) }
        return (trimmed[..<space].trimmingCharacters(in: .whitespaces), String(token))
    }

    /// ⓪ and ①–⑳, the marks pitch-accent dictionaries use.
    private nonisolated static func isCircledDigit(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value == 0x24EA || (0x2460...0x2473).contains(scalar.value)
    }
}
