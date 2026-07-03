import Foundation
import SwiftData

/// All persistent models that compose the Kai schema. Register new models here.
public let kaiSchemaModels: [any PersistentModel.Type] = [
    VocabularyEntry.self,
    ReviewLog.self,
    DailyStory.self
]

/// SwiftData container factory.
public enum KaiModelContainer {
    /// In-memory container for testing (not persisted to disk).
    public static func inMemory() throws -> ModelContainer {
        let schema = Schema(kaiSchemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// On-disk container for app use (CloudKit sync not enabled in this phase).
    public static func onDisk() throws -> ModelContainer {
        let schema = Schema(kaiSchemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
