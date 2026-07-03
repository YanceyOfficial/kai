import Foundation

/// Captures log records for the in-app Diagnostics screen. Conforms to `LogSink` so it
/// can sit behind `AppLogger` (usually via `FanoutLogSink` alongside `OSLogSink`).
///
/// Keeps the last `capacity` records in memory (the source of truth for the viewer) and
/// mirrors them to a line-delimited JSON file so they survive app restarts. Thread-safe
/// via an internal lock; `write` may be called from any queue.
public final class LogCollector: LogSink, @unchecked Sendable {
    /// Shared instance used by `AppLog.shared`.
    public static let shared = LogCollector()

    private let capacity: Int
    private let fileURL: URL?
    private let lock = NSLock()

    /// Newest-last ring buffer. Access only under `lock`.
    private var records: [LogRecord] = []
    /// Number of lines currently in the file; lets us rewrite lazily instead of per-write.
    private var fileLineCount = 0

    /// Designated init. `directory` defaults to Application Support/Kai; tests pass a temp dir.
    public init(capacity: Int = 1000, directory: URL? = LogCollector.defaultDirectory) {
        self.capacity = max(1, capacity)
        self.fileURL = directory.map { $0.appendingPathComponent("diagnostics.log") }
        if let directory {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        loadFromFile()
    }

    // MARK: LogSink

    public func write(_ level: LogLevel, category: String, message: String) {
        let record = LogRecord(level: level, category: category, message: message)
        lock.lock(); defer { lock.unlock() }
        append(record)
        appendToFile(record)
    }

    // MARK: Reading

    /// Records at or above `minLevel`, newest-first.
    public func snapshot(minLevel: LogLevel = .debug) -> [LogRecord] {
        lock.lock(); defer { lock.unlock() }
        return records.filter { $0.level >= minLevel }.reversed()
    }

    /// All buffered records as formatted text, oldest-first, for Share/export.
    public func exportText() -> String {
        lock.lock(); defer { lock.unlock() }
        return records.map(\.formatted).joined(separator: "\n")
    }

    /// Empties the in-memory buffer and the backing file.
    public func clear() {
        lock.lock(); defer { lock.unlock() }
        records.removeAll()
        fileLineCount = 0
        if let fileURL { try? Data().write(to: fileURL) }
    }

    // MARK: Internals (call under lock)

    private func append(_ record: LogRecord) {
        records.append(record)
        if records.count > capacity { records.removeFirst(records.count - capacity) }
    }

    private func appendToFile(_ record: LogRecord) {
        guard let fileURL else { return }
        guard let line = try? JSONEncoder().encode(record) else { return }
        var data = line
        data.append(0x0A) // newline
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: fileURL)
        }
        fileLineCount += 1
        // Rewrite lazily once the file has grown well past the ring, to bound its size.
        if fileLineCount > capacity * 2 { rewriteFile() }
    }

    private func rewriteFile() {
        guard let fileURL else { return }
        let lines = records.compactMap { try? JSONEncoder().encode($0) }
        var blob = Data()
        for line in lines { blob.append(line); blob.append(0x0A) }
        try? blob.write(to: fileURL)
        fileLineCount = records.count
    }

    private func loadFromFile() {
        guard let fileURL, let data = try? Data(contentsOf: fileURL), !data.isEmpty else { return }
        let decoder = JSONDecoder()
        let loaded = data.split(separator: 0x0A).compactMap { try? decoder.decode(LogRecord.self, from: Data($0)) }
        records = loaded.suffix(capacity)
        fileLineCount = loaded.count
    }

    /// Application Support/Kai — the on-disk home for the rolling log file.
    public static var defaultDirectory: URL? {
        try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                     appropriateFor: nil, create: true)
            .appendingPathComponent("Kai", isDirectory: true)
    }
}
