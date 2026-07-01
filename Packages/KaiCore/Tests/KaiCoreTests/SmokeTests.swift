import Testing
@testable import KaiCore

@Test("KaiCore schema version is readable")
func schemaVersionIsPositive() {
    #expect(KaiCoreInfo.schemaVersion >= 1)
}
