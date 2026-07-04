import SwiftUI
import SwiftData
import KaiCore
import KaiUI

/// Lists every English entry and is the entry point for authoring new words.
/// Reads/writes through `VocabularyRepository` built from the shared context.
struct WordsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ToastCenter.self) private var toast

    @State private var entries: [VocabularyEntry] = []
    @State private var showingAdd = false
    @State private var searchText = ""

    private var repository: VocabularyRepository { VocabularyRepository(context: modelContext) }

    /// Entries filtered by the search field (matches lemma or meaning, case-insensitive).
    private var filteredEntries: [VocabularyEntry] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return entries }
        // Match the word itself only — not its meaning — so searching "th" finds "thick",
        // not every entry whose definition happens to contain "th".
        return entries.filter { $0.lemma.lowercased().contains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                KaiColor.washi.ignoresSafeArea()
                VStack(alignment: .leading, spacing: KaiSpacing.s) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Words")
                            .font(KaiFont.display(34, weight: .bold))
                            .foregroundStyle(KaiColor.sumi)
                        Spacer()
                        Button { showingAdd = true } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(KaiColor.vermilion)
                        }
                        .buttonStyle(KaiPressStyle())
                    }
                    .padding(.horizontal, KaiSpacing.l)

                    searchField
                        .padding(.horizontal, KaiSpacing.l)

                    content
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.top, KaiSpacing.l)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAdd, onDismiss: reload) {
                AddWordsView()
            }
        }
        .task { reload() }
    }

    private var searchField: some View {
        HStack(spacing: KaiSpacing.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundStyle(KaiColor.inkSecondary)
            TextField("Search words", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(KaiColor.inkSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, KaiSpacing.m)
        .padding(.vertical, KaiSpacing.s)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(KaiColor.cardFace))
    }

    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            ContentUnavailableView {
                Label("No words yet", systemImage: "text.book.closed")
            } description: {
                Text("Tap + to add words to study.")
            }
        } else if filteredEntries.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List {
                ForEach(filteredEntries) { entry in
                    NavigationLink { WordDetailView(entry: entry) } label: { row(entry) }
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
        let visible = filteredEntries
        let removed = offsets.map { visible[$0] }
        for entry in removed {
            try? repository.delete(entry)
        }
        reload()
        if let first = removed.first {
            toast.show(removed.count == 1 ? "Deleted ‘\(first.lemma)’" : "Deleted \(removed.count) words")
        }
    }
}
