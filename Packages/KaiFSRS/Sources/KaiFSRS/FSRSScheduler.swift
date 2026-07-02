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

    /// Clamps a difficulty value to the valid 1...10 range.
    private func clampDifficulty(_ d: Double) -> Double {
        min(max(d, 1.0), 10.0)
    }

    /// Initial stability for a first review with the given rating: S0(G) = w[G-1].
    public func initialStability(_ rating: FSRSRating) -> Double {
        w[rating.rawValue - 1]
    }

    /// Initial difficulty for a first review: D0(G) = w[4] - e^(w[5]*(G-1)) + 1, clamped to 1...10.
    public func initialDifficulty(_ rating: FSRSRating) -> Double {
        let g = Double(rating.rawValue)
        return clampDifficulty(w[4] - exp(w[5] * (g - 1.0)) + 1.0)
    }

    /// The memory state produced by a first review with the given rating.
    public func initialState(_ rating: FSRSRating) -> FSRSMemoryState {
        FSRSMemoryState(stability: initialStability(rating), difficulty: initialDifficulty(rating))
    }
}
