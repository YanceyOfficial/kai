import Foundation

/// The 21 FSRS-6 model weights that drive scheduling.
public struct FSRSParameters: Equatable, Sendable {
    /// Exactly 21 weights, index 0...20.
    public let weights: [Double]

    /// Creates a parameter set. Traps if the count is not exactly 21.
    public init(weights: [Double]) {
        precondition(weights.count == 21, "FSRS-6 requires exactly 21 weights, got \(weights.count)")
        self.weights = weights
    }

    /// The FSRS-6 default weights.
    public static let fsrs6Default = FSRSParameters(weights: [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001,
        1.8722, 0.1666, 0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014,
        1.8729, 0.5425, 0.0912, 0.0658, 0.1542
    ])
}
