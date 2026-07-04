import Foundation
import Testing
@testable import KaiServices

@Test("Widget snapshot round-trips through the store")
func widgetSnapshotRoundTrips() throws {
    let suite = "test-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }

    let store = WidgetSnapshotStore(defaults: defaults)
    #expect(store.read() == nil)

    let snapshot = ReviewWidgetSnapshot(dueCount: 7, totalWords: 20,
                                        updatedAt: Date(timeIntervalSince1970: 1_700_000_000))
    store.write(snapshot)
    #expect(store.read() == snapshot)
}
