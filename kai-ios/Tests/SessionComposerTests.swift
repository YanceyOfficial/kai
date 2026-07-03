import Testing
@testable import kai_ios

@Suite("SessionComposer")
struct SessionComposerTests {
    @Test("Caps new items and interleaves them with old ones")
    func capsAndInterleaves() {
        let result = SessionComposer.compose(new: [1, 2, 3, 4], old: [10, 20], newLimit: 2)
        // 2 new kept, interleaved old-first: old, new, old, new
        #expect(result == [10, 1, 20, 2])
    }

    @Test("Keeps all old when there are more old than new")
    func moreOldThanNew() {
        let result = SessionComposer.compose(new: [1], old: [10, 20, 30], newLimit: 5)
        #expect(result == [10, 1, 20, 30])
    }

    @Test("A zero budget yields only the old items")
    func zeroBudget() {
        #expect(SessionComposer.compose(new: [1, 2], old: [10, 20], newLimit: 0) == [10, 20])
    }

    @Test("Handles empty inputs")
    func empties() {
        #expect(SessionComposer.compose(new: [Int](), old: [], newLimit: 3).isEmpty)
        #expect(SessionComposer.compose(new: [1, 2], old: [], newLimit: 5) == [1, 2])
    }
}
