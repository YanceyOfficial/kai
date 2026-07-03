import Testing
import Foundation
@testable import kai_ios

@Suite("IntervalFormatter")
struct IntervalFormatterTests {
    @Test("Formats durations into compact SRS captions")
    func formats() {
        #expect(IntervalFormatter.short(30) == "<1m")
        #expect(IntervalFormatter.short(10 * 60) == "10m")
        #expect(IntervalFormatter.short(3 * 3600) == "3h")
        #expect(IntervalFormatter.short(5 * 86_400) == "5d")
        #expect(IntervalFormatter.short(60 * 86_400) == "2mo")
        #expect(IntervalFormatter.short(400 * 86_400) == "1y")
        #expect(IntervalFormatter.short(-100) == "<1m")
    }
}
