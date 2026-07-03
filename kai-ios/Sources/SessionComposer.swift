import Foundation

/// Composes a study session from new and due-old items. New items are capped (the
/// per-session budget) and interleaved with the old ones, so freshly introduced words
/// are spread among review words — better for retention than a block of all-new cards.
/// Pure and generic, so it is tested with plain values.
enum SessionComposer {
    /// - Parameters:
    ///   - newLimit: cap on freshly introduced words (the per-session new budget).
    ///   - oldLimit: cap on due review words, so a large backlog doesn't produce one
    ///     giant session (the most-overdue are taken first; the rest roll to next time).
    static func compose<T>(new: [T], old: [T], newLimit: Int, oldLimit: Int = .max) -> [T] {
        let capped = Array(new.prefix(max(0, newLimit)))
        let cappedOld = Array(old.prefix(max(0, oldLimit)))
        var result: [T] = []
        result.reserveCapacity(capped.count + cappedOld.count)
        var oldIndex = 0
        var newIndex = 0
        // Alternate old, new, old, new… appending whatever remains once one runs out.
        while oldIndex < cappedOld.count || newIndex < capped.count {
            if oldIndex < cappedOld.count {
                result.append(cappedOld[oldIndex]); oldIndex += 1
            }
            if newIndex < capped.count {
                result.append(capped[newIndex]); newIndex += 1
            }
        }
        return result
    }
}
