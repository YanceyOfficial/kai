import Testing
@testable import KaiServices

/// Captures log records for assertions.
private final class CapturingSink: LogSink, @unchecked Sendable {
    private(set) var records: [(LogLevel, String, String)] = []
    func write(_ level: LogLevel, category: String, message: String) {
        records.append((level, category, message))
    }
}

@Test("Logger forwards records at or above the minimum level")
func loggerRespectsMinimumLevel() {
    let sink = CapturingSink()
    let logger = AppLogger(sink: sink, minimumLevel: .info)
    logger.debug("dropped", category: "test")
    logger.info("kept", category: "net")
    logger.error("kept2", category: "net")
    #expect(sink.records.count == 2)
    #expect(sink.records[0].0 == .info)
    #expect(sink.records[0].2 == "kept")
    #expect(sink.records[1].0 == .error)
}

@Test("Log levels order debug < info < warning < error")
func logLevelOrder() {
    #expect(LogLevel.debug < LogLevel.info)
    #expect(LogLevel.warning < LogLevel.error)
}
