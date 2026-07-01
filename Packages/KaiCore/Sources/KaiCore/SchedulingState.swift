import Foundation

/// 词条的 FSRS 调度状态。作为 Codable 值类型嵌入词条。
/// stability/difficulty 的具体演化由 KaiFSRS 包负责(后续 Plan)。
public struct SchedulingState: Codable, Hashable, Sendable {
    /// 记忆稳定度 S(天)。新词为 0。
    public var stability: Double
    /// 记忆难度 D(FSRS 内部量,约 1...10)。新词为 0(待首次评级初始化)。
    public var difficulty: Double
    /// 下次到期时间。
    public var due: Date
    /// 上次复习时间。
    public var lastReview: Date?
    /// 累计复习次数。
    public var reps: Int
    /// 累计遗忘(lapse)次数。
    public var lapses: Int
    /// 学习阶段。
    public var state: LearningState

    public init(
        stability: Double,
        difficulty: Double,
        due: Date,
        lastReview: Date?,
        reps: Int,
        lapses: Int,
        state: LearningState
    ) {
        self.stability = stability
        self.difficulty = difficulty
        self.due = due
        self.lastReview = lastReview
        self.reps = reps
        self.lapses = lapses
        self.state = state
    }

    /// 新词的初始状态:立即到期(可马上学),尚无稳定度/难度。
    public static func new(now: Date = .now) -> SchedulingState {
        SchedulingState(
            stability: 0,
            difficulty: 0,
            due: now,
            lastReview: nil,
            reps: 0,
            lapses: 0,
            state: .new
        )
    }
}
