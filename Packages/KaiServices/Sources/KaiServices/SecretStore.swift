import Foundation

/// Errors from the secret store.
public enum SecretStoreError: Error, Equatable, Sendable {
    /// An unexpected OSStatus from the Keychain.
    case unexpectedStatus(Int32)
}

/// A secure key/value store for secrets such as API keys.
public protocol SecretStore: Sendable {
    func set(_ value: String, for key: String) throws
    func string(for key: String) throws -> String?
    func removeValue(for key: String) throws
}

/// In-memory secret store for tests and SwiftUI previews. Thread-safe.
public final class InMemorySecretStore: SecretStore, @unchecked Sendable {
    private var storage: [String: String] = [:]
    private let lock = NSLock()

    public init() {}

    public func set(_ value: String, for key: String) throws {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }

    public func string(for key: String) throws -> String? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    public func removeValue(for key: String) throws {
        lock.lock(); defer { lock.unlock() }
        storage[key] = nil
    }
}
