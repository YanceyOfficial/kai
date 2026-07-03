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

            QuizTab()
                .tag(1)
                .tabItem { Label("Quiz", systemImage: "questionmark.circle") }

            WordsListView()
                .tag(2)
                .tabItem { Label("Words", systemImage: "text.book.closed") }

            StatsView()
                .tag(3)
                .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }

            SettingsView()
                .tag(4)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(KaiColor.vermilion)
    }

    private static func initialSelection() -> Int {
        switch UserDefaults.standard.string(forKey: "startTab") {
        case "Quiz": return 1
        case "Words": return 2
        case "Stats": return 3
        case "Settings": return 4
        default: return 0
        }
    }
}

/// Hosts the review session, rebuilding its store from the context and reloading the
/// due deck each time the tab appears (so newly added words show up).
private struct ReviewTab: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("newWordsPerDay") private var newWordsPerDay = 10
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
            store.load(newLimit: newWordsPerDay)
            self.store = store
        }
    }
}

/// Hosts the quiz session, rebuilding its store and regenerating questions each time
/// the tab appears.
private struct QuizTab: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store: QuizStore?

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()
            if let store {
                QuizSessionView(store: store)
            } else {
                ProgressView().tint(KaiColor.vermilion)
            }
        }
        .task {
            let store = store ?? QuizStore(context: modelContext)
            store.load()
            self.store = store
        }
    }
}
