import SwiftUI
import SwiftData
import KaiCore
import KaiUI

/// Lists every English entry and is the entry point for authoring new words.
/// Reads/writes through `VocabularyRepository` built from the shared context.
struct WordsListView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var entries: [VocabularyEntry] = []
    @State private var showingAdd = false

    private var repository: VocabularyRepository { VocabularyRepository(context: modelContext) }

    var body: some View {
        NavigationStack {
            ZStack {
                KaiColor.washi.ignoresSafeArea()
                content
            }
            .navigationTitle("Words")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Image(systemName: "plus")
                    }
                    .tint(KaiColor.vermilion)
                }
            }
            .sheet(isPresented: $showingAdd, onDismiss: reload) {
                AddWordsView()
            }
        }
        .task { reload() }
    }

    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            ContentUnavailableView {
                Label("No words yet", systemImage: "text.book.closed")
            } description: {
                Text("Tap + to add words to study.")
            }
        } else {
            List {
                ForEach(entries) { entry in
                    row(entry)
                        .listRowBackground(KaiColor.cardFace)
                }
                .onDelete(perform: delete)
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func row(_ entry: VocabularyEntry) -> some View {
        VStack(alignment: .leading, spacing: KaiSpacing.xs) {
            HStack(spacing: KaiSpacing.s) {
                Text(entry.lemma)
                    .font(KaiFont.display(19, weight: .semibold))
                    .foregroundStyle(KaiColor.sumi)
                if !entry.phonetic.isEmpty {
                    Text(entry.phonetic)
                        .font(KaiFont.phonetic(12))
                        .foregroundStyle(KaiColor.inkSecondary)
                }
            }
            if !entry.explanation.isEmpty {
                Text(entry.explanation)
                    .font(KaiFont.body(14, weight: .regular))
                    .foregroundStyle(KaiColor.inkSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private func reload() {
        entries = (try? repository.entries(for: .english)) ?? []
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            try? repository.delete(entries[index])
        }
        reload()
    }
}
