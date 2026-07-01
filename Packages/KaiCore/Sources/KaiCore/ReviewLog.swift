import Foundation
import SwiftData

/// 一次作答记录。既用于 FSRS 参数优化,也用于统计看板。
@Model
public final class ReviewLog {
    public var id: UUID = UUID()
    /// 关联词条的 id(弱引用,避免 CloudKit 关系约束)。
    public var entryID: UUID = UUID()
    public var timestamp: Date = Date()
    public var ratingRaw: Int = ReviewRating.good.rawValue
    public var quizTypeRaw: String = QuizType.singleChoice.rawValue
    public var elapsedMs: Int = 0
    public var isCorrect: Bool = true

    public var rating: ReviewRating {
        get { ReviewRating(rawValue: ratingRaw) ?? .good }
        set { ratingRaw = newValue.rawValue }
    }
    public var quizType: QuizType {
        get { QuizType(rawValue: quizTypeRaw) ?? .singleChoice }
        set { quizTypeRaw = newValue.rawValue }
    }

    public init(
        entryID: UUID,
        rating: ReviewRating,
        quizType: QuizType,
        elapsedMs: Int,
        isCorrect: Bool,
        timestamp: Date = .now
    ) {
        self.id = UUID()
        self.entryID = entryID
        self.ratingRaw = rating.rawValue
        self.quizTypeRaw = quizType.rawValue
        self.elapsedMs = elapsedMs
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }
}
