import Foundation

/// Composes a study session from new and due-old items. New items are capped (the
/// per-session budget) and interleaved with the old ones, so freshly introduced words
/// are spread among review words — better for retention than a block of all-new cards.
/// Pure and generic, so it is tested with plain values.
enum SessionComposer {
    static func compose<T>(new: [T], old: [T], newLimit: Int) -> [T] {
        let capped = Array(new.prefix(max(0, newLimit)))
        var result: [T] = []
        result.reserveCapacity(capped.count + old.count)
        var oldIndex = 0
        var newIndex = 0
        // Alternate old, new, old, new… appending whatever remains once one runs out.
        while oldIndex < old.count || newIndex < capped.count {
            if oldIndex < old.count {
                result.append(old[oldIndex]); oldIndex += 1
            }
            if newIndex < capped.count {
                result.append(capped[newIndex]); newIndex += 1
            }
        }
        return result
    }
}
