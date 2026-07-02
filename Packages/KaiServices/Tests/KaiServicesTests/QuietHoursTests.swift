import Foundation
import Testing
@testable import KaiServices

private func utcCalendar() -> Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "UTC")!
    return c
}

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int) -> Date {
    let c = utcCalendar()
    return c.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

@Test("A time inside a midnight-wrapping quiet window is pushed to the window end")
func wrappingWindowShift() {
    let qh = QuietHours(startHour: 22, endHour: 7)   // 22:00–07:00
    let cal = utcCalendar()
    // 02:00 is inside the window -> shifted to 07:00 the same morning.
    let shifted = qh.adjusted(date(2026, 1, 2, 2), calendar: cal)
    #expect(shifted == date(2026, 1, 2, 7))
    // 23:00 is inside the window -> shifted to 07:00 the NEXT morning.
    let shiftedLate = qh.adjusted(date(2026, 1, 2, 23), calendar: cal)
    #expect(shiftedLate == date(2026, 1, 3, 7))
}

@Test("A time outside the quiet window is unchanged")
func outsideWindowUnchanged() {
    let qh = QuietHours(startHour: 22, endHour: 7)
    let cal = utcCalendar()
    let noon = date(2026, 1, 2, 12)
    #expect(qh.adjusted(noon, calendar: cal) == noon)
}
