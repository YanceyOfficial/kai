import Foundation
import SwiftData

/// 组成 Kai schema 的全部持久模型。新增模型时在此登记。
public let kaiSchemaModels: [any PersistentModel.Type] = [
    VocabularyEntry.self,
    ReviewLog.self
]

/// SwiftData 容器工厂。
public enum KaiModelContainer {
    /// 内存容器,供测试使用(不落盘)。
    public static func inMemory() throws -> ModelContainer {
        let schema = Schema(kaiSchemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    /// 落盘容器,供 App 使用(本期不开 CloudKit 同步)。
    public static func onDisk() throws -> ModelContainer {
        let schema = Schema(kaiSchemaModels)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
