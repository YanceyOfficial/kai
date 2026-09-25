import Testing
@testable import KaiUI

@Test("A trailing circled number is split off as the pitch accent")
func phoneticSplitsAccent() {
    for (input, reading, accent) in [("なつかしい ④", "なつかしい", "④"), ("あいまい ⓪", "あいまい", "⓪"), ("コーヒー  ③ ", "コーヒー", "③")] {
        let parts = PhoneticText.split(input)
        #expect(parts.reading == reading)
        #expect(parts.accent == accent)
    }
}

@Test("Anything else is left whole")
func phoneticWithoutAccent() {
    for input in ["/ɪkˈsɛntrɪk/", "きがおけない", "/ˈjuː.nɪ vɜːs/"] {
        let parts = PhoneticText.split(input)
        #expect(parts.reading == input)
        #expect(parts.accent == nil)
    }
}
