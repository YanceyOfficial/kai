import Testing
@testable import KaiServices

@Test("In-memory secret store round-trips, overwrites, and deletes")
func inMemoryRoundTrip() throws {
    let store = InMemorySecretStore()
    #expect(try store.string(for: "claudeKey") == nil)
    try store.set("sk-1", for: "claudeKey")
    #expect(try store.string(for: "claudeKey") == "sk-1")
    try store.set("sk-2", for: "claudeKey")           // overwrite
    #expect(try store.string(for: "claudeKey") == "sk-2")
    try store.removeValue(for: "claudeKey")
    #expect(try store.string(for: "claudeKey") == nil)
}

@Test("Deleting a missing key is a no-op")
func deleteMissingKey() throws {
    let store = InMemorySecretStore()
    try store.removeValue(for: "absent")               // must not throw
}
