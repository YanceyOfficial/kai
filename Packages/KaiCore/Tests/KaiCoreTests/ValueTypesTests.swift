import Foundation
import Testing
@testable import KaiCore

@Test("New entry SchedulingState initializes to new and due immediately")
func newSchedulingDefaults() {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let s = SchedulingState.new(now: now)
    #expect(s.state == .new)
    #expect(s.reps == 0)
    #expect(s.lapses == 0)
    #expect(s.stability == 0)
    #expect(s.difficulty == 0)
    #expect(s.due == now)
    #expect(s.lastReview == nil)
}

@Test("Example roundtrips through Codable encoding/decoding")
func exampleCodableRoundTrip() throws {
    let ex = Example(sentence: "He is eccentric.", translation: "He is very eccentric.", source: .plain)
    let data = try JSONEncoder().encode(ex)
    let decoded = try JSONDecoder().decode(Example.self, from: data)
    #expect(decoded == ex)
}
