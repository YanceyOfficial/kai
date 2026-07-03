import SwiftUI
import KaiUI
import KaiServices

/// App-wide transient feedback. Inject once at the root; any view reads it from the
/// environment and calls `show`/`error` to confirm actions or surface failures.
/// A single toast is shown at a time and auto-dismisses.
@MainActor
@Observable
final class ToastCenter {
    struct Item: Identifiable {
        let id = UUID()
        let message: String
        let style: KaiToastStyle
    }

    private(set) var current: Item?
    private var dismissTask: Task<Void, Never>?

    /// Confirms a successful action.
    func show(_ message: String) {
        present(Item(message: message, style: .success))
    }

    /// Surfaces a failure to the user AND records it via `AppLog.shared` so it lands in
    /// the Diagnostics log.
    func error(_ message: String, category: String = "ui") {
        AppLog.shared.error(message, category: category)
        present(Item(message: message, style: .error))
    }

    private func present(_ item: Item, duration: Double = 1.9) {
        current = item
        dismissTask?.cancel()
        dismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut) { self?.current = nil }
        }
    }
}
