import Foundation
import Testing
@testable import KaiServices

@Suite("LogCollector")
struct LogCollectorTests {
    private func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("kai-logtests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("Records are returned newest-first and filtered by level")
    func snapshotOrderAndFilter() {
        let c = LogCollector(capacity: 100, directory: tempDir())
        c.write(.info, category: "a", message: "one")
        c.write(.warning, category: "a", message: "two")
        c.write(.error, category: "a", message: "three")

        let all = c.snapshot()
        #expect(all.map(\.message) == ["three", "two", "one"])   // newest-first

        let warnPlus = c.snapshot(minLevel: .warning)
        #expect(warnPlus.map(\.message) == ["three", "two"])
    }

    @Test("Ring buffer is capped at capacity, dropping oldest")
    func capacityCap() {
        let c = LogCollector(capacity: 3, directory: tempDir())
        for i in 1...5 { c.write(.info, category: "c", message: "\(i)") }
        #expect(c.snapshot().map(\.message) == ["5", "4", "3"])
    }

    @Test("clear() empties the buffer")
    func clearEmpties() {
        let c = LogCollector(capacity: 10, directory: tempDir())
        c.write(.error, category: "c", message: "boom")
        c.clear()
        #expect(c.snapshot().isEmpty)
        #expect(c.exportText().isEmpty)
    }

    @Test("exportText contains the messages, oldest-first")
    func exportContainsMessages() {
        let c = LogCollector(capacity: 10, directory: tempDir())
        c.write(.info, category: "c", message: "first")
        c.write(.error, category: "c", message: "second")
        let text = c.exportText()
        #expect(text.contains("first"))
        #expect(text.contains("second"))
        #expect(text.range(of: "first")!.lowerBound < text.range(of: "second")!.lowerBound)
    }

    @Test("Records persist to disk and reload in a new collector")
    func persistsAcrossReinit() {
        let dir = tempDir()
        do {
            let c = LogCollector(capacity: 10, directory: dir)
            c.write(.warning, category: "persist", message: "kept")
        }
        let reopened = LogCollector(capacity: 10, directory: dir)
        #expect(reopened.snapshot().map(\.message) == ["kept"])
    }
}

@Suite("FanoutLogSink")
struct FanoutLogSinkTests {
    private final class Capturing: LogSink, @unchecked Sendable {
        var messages: [String] = []
        func write(_ level: LogLevel, category: String, message: String) { messages.append(message) }
    }

    @Test("Forwards every record to all downstream sinks")
    func forwardsToAll() {
        let a = Capturing(); let b = Capturing()
        let fanout = FanoutLogSink([a, b])
        fanout.write(.info, category: "x", message: "hi")
        #expect(a.messages == ["hi"])
        #expect(b.messages == ["hi"])
    }
}
