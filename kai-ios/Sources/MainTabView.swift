import SwiftUI
import SwiftData
import KaiUI

/// The app's tab shell: review, word list, stats, and settings. Each tab builds its
/// own repository from the shared SwiftData context.
struct MainTabView: View {
    /// The selected tab. Seeded from a `-startTab` launch argument so a specific tab
    /// can be opened directly (used for UI screenshots); defaults to Review.
    @State private var selection = Self.initialSelection()

    var body: some View {
        TabView(selection: $selection) {
            ReviewTab()
                .tag(0)
                .tabItem { Label("Review", systemImage: "rectangle.on.rectangle.angled") }

            WordsListView()
                .tag(1)
                .tabItem { Label("Words", systemImage: "text.book.closed") }

            StatsView()
                .tag(2)
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            SettingsView()
                .tag(3)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(KaiColor.vermilion)
    }

    private static func initialSelection() -> Int {
        switch UserDefaults.standard.string(forKey: "startTab") {
        case "Words": return 1
        case "Stats": return 2
        case "Settings": return 3
        default: return 0
        }
    }
}

/// Hosts the review session, rebuilding its store from the context and reloading the
/// due deck each time the tab appears (so newly added words show up).
private struct ReviewTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store: ReviewStore?

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()
            if let store {
                ReviewSessionView(store: store)
            } else {
                ProgressView().tint(KaiColor.vermilion)
            }
        }
        .task {
            let store = store ?? ReviewStore(context: modelContext)
            store.load()
            self.store = store
        }
    }
}
