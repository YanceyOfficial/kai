import Foundation

/// Turns recognized text lines into de-duplicated single-word candidates.
public struct WordCandidateExtractor: Sendable {
    private let minLength: Int
    public init(minLength: Int = 2) { self.minLength = minLength }

    public func candidates(from lines: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for line in lines {
            for rawToken in line.split(whereSeparator: { $0.isWhitespace }) {
                let token = rawToken.trimmingCharacters(in: .punctuationCharacters)
                guard token.count >= minLength, token.allSatisfy({ $0.isLetter }) else { continue }
                let lower = token.lowercased()
                if seen.insert(lower).inserted { result.append(lower) }
            }
        }
        return result
    }
}
