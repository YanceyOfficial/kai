import Foundation

/// 学习语种。中/日双语隔离的核心字段,本期只用 english。
public enum LanguageDomain: String, Codable, CaseIterable, Sendable {
    case english
    case japanese
}

/// 词条类型。区分单词与短语,决定题型适用性(修复老版短语 bug)。
public enum EntryKind: String, Codable, Sendable {
    case word
    case phrase
}

/// 词条来源入口。
public enum EntrySource: String, Codable, Sendable {
    case manual   // 兜底/未知
    case single   // 单个快捷添加
    case share    // 系统分享扩展
    case ocr      // 剪贴板 / 拍照 OCR
    case batch    // 批量粘贴
}

/// FSRS 学习阶段。
public enum LearningState: String, Codable, Sendable {
    case new
    case learning
    case review
    case relearning
}

/// 例句来源风格。
public enum ExampleSource: String, Codable, Sendable {
    case plain     // 普通例句
    case literary  // 名著风短文/语段
}

/// 复习评级,raw 值对齐 FSRS 约定(1=again … 4=easy)。
public enum ReviewRating: Int, Codable, CaseIterable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}

/// 小测验题型。
public enum QuizType: String, Codable, CaseIterable, Sendable {
    case singleChoice       // 单选
    case splitCombine       // 音节碎片拼词(仅单词)
    case fillInBlank        // 例句填空
    case listeningSpelling  // 听音拼写(仅单词)
    case meaningMatch       // 释义匹配
    case contextCloze       // 上下文完形

    /// 该题型是否适用于给定词条类型。
    /// 音节拼词与听音拼写依赖音节切分,只对单词有意义,短语一律排除。
    public func isApplicable(to kind: EntryKind) -> Bool {
        switch self {
        case .splitCombine, .listeningSpelling:
            return kind == .word
        case .singleChoice, .fillInBlank, .meaningMatch, .contextCloze:
            return true
        }
    }
}
