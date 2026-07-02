import Testing
@testable import Kai

/// Smoke test for the app target. Real feature tests live in each package;
/// this target is the host for tests that need the app runtime later.
@Test("App target builds and hosts tests")
func appTargetHostsTests() {
    #expect(Bool(true))
}
