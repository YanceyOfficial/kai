import SwiftUI
import SwiftData
import KaiCore
import KaiUI

/// App root: builds the review store from the shared SwiftData context and hosts
/// the review loop. Real navigation (decks, entry authoring, stats) comes later.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store: ReviewStore?

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()
            if let store {
                ReviewSessionView(store: store)
            } else {
                ProgressView()
                    .tint(KaiColor.vermilion)
            }
        }
        .task {
            guard store == nil else { return }
            let store = ReviewStore(context: modelContext)
            store.load()
            self.store = store
        }
    }
}

#Preview {
    RootView()
        .modelContainer(try! KaiModelContainer.inMemory())
}
