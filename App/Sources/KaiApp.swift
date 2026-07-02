import SwiftUI
import SwiftData
import KaiCore

/// The application entry point. Wires the shared SwiftData container into the
/// environment so views and repositories can read/write vocabulary data.
@main
struct KaiApp: App {
    /// The on-disk SwiftData container backing the app (CloudKit sync off for now).
    private let container: ModelContainer

    init() {
        do {
            container = try KaiModelContainer.onDisk()
        } catch {
            // A container that cannot be created is an unrecoverable launch failure.
            fatalError("Failed to create the SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
