import SwiftUI
import SwiftData
import KaiCore
import KaiUI

/// App root: seeds the starter deck once, then hosts the tab shell. Real navigation
/// (decks, entry authoring, stats) lives inside the tabs.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var seeded = false

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()
            if seeded {
                MainTabView()
            } else {
                ProgressView().tint(KaiColor.vermilion)
            }
        }
        .task {
            guard !seeded else { return }
            try? StarterSeed.seedIfEmpty(VocabularyRepository(context: modelContext))
            seeded = true
        }
    }
}

#Preview {
    RootView()
        .modelContainer(try! KaiModelContainer.inMemory())
}
