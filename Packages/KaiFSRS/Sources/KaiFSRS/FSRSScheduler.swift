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

    /// Updates difficulty after a review: grade delta, linear damping toward 10,
    /// then mean reversion toward the Easy-grade initial difficulty. Clamped to 1...10.
    public func nextDifficulty(_ difficulty: Double, rating: FSRSRating) -> Double {
        let g = Double(rating.rawValue)
        let deltaD = -w[6] * (g - 3.0)
        let damped = difficulty + (10.0 - difficulty) * deltaD / 9.0
        let reverted = w[7] * initialDifficulty(.easy) + (1.0 - w[7]) * damped
        return clampDifficulty(reverted)
    }

    /// New stability after a successful recall (rating hard/good/easy).
    public func stabilityAfterRecall(
        difficulty: Double, stability: Double, retrievability: Double, rating: FSRSRating
    ) -> Double {
        let hardPenalty = rating == .hard ? w[15] : 1.0
        let easyBonus = rating == .easy ? w[16] : 1.0
        let sInc = exp(w[8])
            * (11.0 - difficulty)
            * pow(stability, -w[9])
            * (exp((1.0 - retrievability) * w[10]) - 1.0)
            * hardPenalty
            * easyBonus
        return stability * (1.0 + sInc)
    }

    /// New stability after a lapse (rating again). Capped so it cannot exceed
    /// the pre-lapse stability adjusted by the short-term factor.
    public func stabilityAfterLapse(
        difficulty: Double, stability: Double, retrievability: Double
    ) -> Double {
        let sf = w[11]
            * pow(difficulty, -w[12])
            * (pow(stability + 1.0, w[13]) - 1.0)
            * exp((1.0 - retrievability) * w[14])
        let cap = stability / exp(w[17] * w[18])
        return min(sf, cap)
    }

    /// New stability for a same-day (short-term) review. Good/Easy never reduce stability.
    public func shortTermStability(stability: Double, rating: FSRSRating) -> Double {
        let g = Double(rating.rawValue)
        var sInc = exp(w[17] * (g - 3.0 + w[18])) * pow(stability, -w[19])
        if rating.rawValue >= 3 { sInc = max(sInc, 1.0) }
        return stability * sInc
    }

    /// Schedules a review. Pass `state: nil` for a brand-new card. `elapsedDays`
    /// is the time since the last review (0 for a same-day review).
    public func review(state: FSRSMemoryState?, rating: FSRSRating, elapsedDays: Double) -> FSRSReviewResult {
        // New card: use the initial state directly.
        guard let state else {
            let initial = initialState(rating)
            return FSRSReviewResult(state: initial, intervalDays: nextInterval(stability: initial.stability))
        }

        let newDifficulty = nextDifficulty(state.difficulty, rating: rating)
        let newStability: Double

        if elapsedDays <= 0 {
            // Same-day review: short-term stability path.
            newStability = shortTermStability(stability: state.stability, rating: rating)
        } else {
            let r = retrievability(elapsedDays: elapsedDays, stability: state.stability)
            newStability = rating == .again
                ? stabilityAfterLapse(difficulty: state.difficulty, stability: state.stability, retrievability: r)
                : stabilityAfterRecall(difficulty: state.difficulty, stability: state.stability, retrievability: r, rating: rating)
        }

        let newState = FSRSMemoryState(stability: newStability, difficulty: newDifficulty)
        return FSRSReviewResult(state: newState, intervalDays: nextInterval(stability: newStability))
    }
}
