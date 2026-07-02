import Foundation
import SwiftData

/// A single review response record. Used for both FSRS parameter optimization and statistics dashboard.
@Model
public final class ReviewLog {
    public var id: UUID = UUID()
    /// Associated entry's ID (weak reference to avoid CloudKit relationship constraints).
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
        self.entryID = entryID
        self.ratingRaw = rating.rawValue
        self.quizTypeRaw = quizType.rawValue
        self.elapsedMs = elapsedMs
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }
}
