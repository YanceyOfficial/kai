import SwiftUI
import SwiftData
import KaiCore
import KaiUI

/// App root: seeds the starter deck once, then hosts the tab shell. Real navigation
/// (decks, entry authoring, stats) lives inside the tabs.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var seeded = false
    /// App-wide toast presenter, injected into the environment for every screen.
    @State private var toast = ToastCenter()

    var body: some View {
        ZStack(alignment: .top) {
            KaiColor.washi.ignoresSafeArea()
            if seeded {
                MainTabView()
            } else {
                ProgressView().tint(KaiColor.vermilion)
            }
            if let item = toast.current {
                KaiToast(item.message, style: item.style)
                    .padding(.top, KaiSpacing.xl)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .environment(toast)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast.current?.id)
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
