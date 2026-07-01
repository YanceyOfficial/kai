import Foundation

/// 一条例句:英文原句 + 中文翻译 + 来源风格。作为 Codable 值类型嵌入词条。
public struct Example: Codable, Hashable, Sendable {
    public var sentence: String
    public var translation: String
    public var source: ExampleSource

    public init(sentence: String, translation: String, source: ExampleSource = .plain) {
        self.sentence = sentence
        self.translation = translation
        self.source = source
    }
}
