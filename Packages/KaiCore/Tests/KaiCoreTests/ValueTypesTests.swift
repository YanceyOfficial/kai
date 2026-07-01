import Foundation
import Testing
@testable import KaiCore

@Test("新词 SchedulingState 初始为 new 且到期即刻")
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

@Test("Example 可 Codable 往返")
func exampleCodableRoundTrip() throws {
    let ex = Example(sentence: "He is eccentric.", translation: "他很古怪。", source: .plain)
    let data = try JSONEncoder().encode(ex)
    let decoded = try JSONDecoder().decode(Example.self, from: data)
    #expect(decoded == ex)
}
