import Testing
@testable import KaiCore

@Test("KaiCore schema 版本可读取")
func schemaVersionIsPositive() {
    #expect(KaiCoreInfo.schemaVersion >= 1)
}
