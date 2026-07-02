import Foundation
import Security

/// Production secret store backed by the Keychain (generic password items).
/// Compiled for the app; exercised at runtime, not in unit tests.
public struct KeychainSecretStore: SecretStore {
    private let service: String
    public init(service: String = "app.yancey.kai.secrets") { self.service = service }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    public func set(_ value: String, for key: String) throws {
        let data = Data(value.utf8)
        // Delete any existing item, then add fresh (upsert).
        SecItemDelete(baseQuery(for: key) as CFDictionary)
        var attributes = baseQuery(for: key)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw SecretStoreError.unexpectedStatus(status) }
    }

    public func string(for key: String) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw SecretStoreError.unexpectedStatus(status) }
        guard let data = result as? Data else { return nil }
        return String(decoding: data, as: UTF8.self)
    }

    public func removeValue(for key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecretStoreError.unexpectedStatus(status)
        }
    }
}
