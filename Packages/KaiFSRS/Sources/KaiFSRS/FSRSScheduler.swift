import Foundation

/// An FSRS-6 scheduler. Pure and deterministic: given a memory state, a rating,
/// and elapsed time, it computes the next memory state, retrievability, and
/// interval. Holds no mutable state.
public struct FSRSScheduler: Sendable {
    public let parameters: FSRSParameters
    /// Target recall probability used to compute intervals (e.g. 0.9).
    public let requestRetention: Double
    /// Upper bound on any scheduled interval, in days.
    public let maximumInterval: Int

    public init(
        parameters: FSRSParameters = .fsrs6Default,
        requestRetention: Double = 0.9,
        maximumInterval: Int = 36500
    ) {
        self.parameters = parameters
        self.requestRetention = requestRetention
        self.maximumInterval = maximumInterval
    }

    private var w: [Double] { parameters.weights }

    /// The forgetting-curve decay exponent (negative).
    private var decay: Double { -w[20] }

    /// Curve factor chosen so retrievability is exactly 0.9 when elapsed == stability.
    private var factor: Double { pow(0.9, 1.0 / decay) - 1.0 }

    /// Probability of recall after `elapsedDays` given `stability` (power forgetting curve).
    public func retrievability(elapsedDays: Double, stability: Double) -> Double {
        pow(1.0 + factor * elapsedDays / stability, decay)
    }

    /// The next interval (whole days) that reaches `requestRetention`, clamped to [1, maximumInterval].
    public func nextInterval(stability: Double) -> Int {
        let raw = (stability / factor) * (pow(requestRetention, 1.0 / decay) - 1.0)
        let rounded = Int(raw.rounded())
        return min(max(rounded, 1), maximumInterval)
    }
}
