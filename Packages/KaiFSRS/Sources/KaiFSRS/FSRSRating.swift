import Foundation

/// A review grade in the FSRS model. Raw values follow the FSRS convention
/// (1 = again/lapse … 4 = easy).
public enum FSRSRating: Int, Codable, CaseIterable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4
}
