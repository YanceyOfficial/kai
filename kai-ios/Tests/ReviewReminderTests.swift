import Testing
@testable import kai_ios

@Suite("ReviewReminder")
struct ReviewReminderTests {
    @Test("Schedules only when enabled and there are words")
    func rule() {
        #expect(ReviewReminder.shouldSchedule(enabled: true, hasWords: true) == true)
        #expect(ReviewReminder.shouldSchedule(enabled: true, hasWords: false) == false)
        #expect(ReviewReminder.shouldSchedule(enabled: false, hasWords: true) == false)
        #expect(ReviewReminder.shouldSchedule(enabled: false, hasWords: false) == false)
    }
}
