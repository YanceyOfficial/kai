import SwiftUI
import SwiftData
import KaiCore
import KaiUI

/// App root: seeds the starter deck once, then hosts the tab shell. Real navigation
/// (decks, entry authoring, stats) lives inside the tabs.
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
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
            let repository = VocabularyRepository(context: modelContext)
            try? StarterSeed.seedIfEmpty(repository)
            seeded = true
            // Keep the daily reminder in sync with settings + deck state on launch.
            let enabled = UserDefaults.standard.bool(forKey: "reminderEnabled")
            let minutes = UserDefaults.standard.object(forKey: "reminderMinutes") as? Int ?? 540
            let hasWords = !(((try? repository.entries(for: .english)) ?? []).isEmpty)
            await ReviewReminder.apply(enabled: enabled, minutes: minutes, hasWords: hasWords)
            WidgetSync.update(repository: repository)
        }
        .onChange(of: scenePhase) { _, phase in
            // Refresh the widget's due count as the app leaves the foreground.
            if phase != .active {
                WidgetSync.update(repository: VocabularyRepository(context: modelContext))
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(try! KaiModelContainer.inMemory())
}
