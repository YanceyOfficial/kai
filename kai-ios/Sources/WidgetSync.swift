import Foundation
import WidgetKit
import KaiCore
import KaiServices

/// Publishes the review snapshot the home-screen widget reads, and asks WidgetKit to
/// refresh. Call whenever the due count may have changed (launch, backgrounding).
enum WidgetSync {
    static func update(repository: VocabularyRepository, now: Date = .now) {
        let entries = (try? repository.entries(for: .english)) ?? []
        let due = entries.filter { $0.dueAt <= now }.count
        WidgetSnapshotStore().write(
            ReviewWidgetSnapshot(dueCount: due, totalWords: entries.count, updatedAt: now))
        WidgetCenter.shared.reloadAllTimelines()
    }
}
