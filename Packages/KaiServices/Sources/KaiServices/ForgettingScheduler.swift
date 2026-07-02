import Foundation
import KaiFSRS

/// Computes when to remind the learner about each item, using FSRS to find the
/// moment recall probability falls to the retention threshold (the Ebbinghaus point).
public struct ForgettingScheduler: Sendable {
    private let scheduler: FSRSScheduler

    /// - Parameter retentionThreshold: recall probability at which to remind (e.g. 0.9).
    public init(parameters: FSRSParameters = .fsrs6Default, retentionThreshold: Double = 0.9) {
        // Reuse FSRS's interval math: nextInterval at requestRetention == threshold
        // is exactly the number of days until retrievability decays to that threshold.
        self.scheduler = FSRSScheduler(parameters: parameters, requestRetention: retentionThreshold)
    }

    public func reminders(for items: [ReviewableItem], now: Date) -> [ForgettingReminder] {
        let secondsPerDay: TimeInterval = 86_400
        var result: [ForgettingReminder] = []
        for item in items {
            guard let lastReview = item.lastReview, item.stability > 0 else { continue }
            let days = scheduler.nextInterval(stability: item.stability)
            let due = lastReview.addingTimeInterval(Double(days) * secondsPerDay)
            let fireDate = max(due, now)   // never schedule in the past
            result.append(ForgettingReminder(id: item.id, fireDate: fireDate))
        }
        return result.sorted { $0.fireDate < $1.fireDate }
    }
}
