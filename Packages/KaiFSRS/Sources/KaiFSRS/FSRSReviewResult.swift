import Foundation

/// The outcome of scheduling a review: the new memory state and the next interval.
public struct FSRSReviewResult: Equatable, Sendable {
    public let state: FSRSMemoryState
    public let intervalDays: Int

    public init(state: FSRSMemoryState, intervalDays: Int) {
        self.state = state
        self.intervalDays = intervalDays
    }
}
