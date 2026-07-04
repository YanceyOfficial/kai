import SwiftUI
import KaiCore
import KaiAI
import KaiServices
import KaiUI

/// A word's detail page: every field laid out directly (no flip card — the list row
/// already shows the word and meaning, so this is the full reference).
struct WordDetailView: View {
    let entry: VocabularyEntry

    @Environment(\.modelContext) private var modelContext
    @Environment(ToastCenter.self) private var toast
    @State private var pronouncer = PronunciationPlayer()
    @AppStorage("pronunciationAccent") private var accentRaw = Accent.us.rawValue
    private var accent: Accent { Accent(rawValue: accentRaw) ?? .us }

    /// Presents the "add note" sheet and holds its draft text.
    @State private var showingAddNote = false
    @State private var newNoteText = ""

    /// Add-tag alert state.
    @State private var showingAddTag = false
    @State private var newTag = ""

    /// Tap-through: navigate to a related word, or offer to add one that's not in the deck.
    @State private var linkedLemma: String?
    @State private var addCandidate: String?
    @State private var adding = false

    private var repository: VocabularyRepository { VocabularyRepository(context: modelContext) }

    var body: some View {
        List {
            headerSection
            meaningSection

            if !entry.examples.isEmpty {
                Section("Examples") {
                    ForEach(Array(entry.examples.enumerated()), id: \.offset) { _, example in
                        VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                            Text(example.sentence)
                                .font(KaiFont.body(15))
                                .foregroundStyle(KaiColor.sumi)
                            if !example.translation.isEmpty {
                                Text(example.translation)
                                    .font(KaiFont.body(14))
                                    .foregroundStyle(KaiColor.inkSecondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listRowBackground(KaiColor.cardFace)
            }

            similarWordsSection
            collocationsSection
            notesSection
            tagsSection
            annotationsSection
            schedulingSection
        }
        .scrollContentBackground(.hidden)
        .background(KaiColor.washi)
        .navigationTitle(entry.lemma)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddNote) { addNoteSheet }
        .alert("Add tag", isPresented: $showingAddTag) {
            TextField("e.g. GRE", text: $newTag)
                .textInputAutocapitalization(.never)
            Button("Add") { addTag() }
            Button("Cancel", role: .cancel) { newTag = "" }
        }
        .overlay {
            if adding {
                ProgressView().tint(KaiColor.vermilion)
                    .padding(KaiSpacing.l)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .navigationDestination(item: $linkedLemma) { lemma in
            if let entry = lookup(lemma) {
                WordDetailView(entry: entry)
            } else {
                ContentUnavailableView("Not found", systemImage: "questionmark")
            }
        }
        .confirmationDialog(
            addCandidate.map { "Add “\($0)” to your deck?" } ?? "",
            isPresented: Binding(get: { addCandidate != nil }, set: { if !$0 { addCandidate = nil } }),
            titleVisibility: .visible
        ) {
            if let word = addCandidate {
                Button("Generate & add") { addWord(word) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    /// Editable tags for grouping words into simple decks.
    private var tagsSection: some View {
        Section("Tags") {
            if !entry.tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(entry.tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(KaiFont.body(14, weight: .medium))
                                .foregroundStyle(KaiColor.sumi)
                            Button { removeTag(tag) } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(KaiColor.inkSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, KaiSpacing.s)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(KaiColor.washi))
                    }
                }
                .padding(.vertical, 2)
            }
            Button { newTag = ""; showingAddTag = true } label: {
                Label("Add tag", systemImage: "tag")
                    .font(KaiFont.body(15, weight: .medium))
                    .foregroundStyle(KaiColor.vermilion)
            }
        }
        .listRowBackground(KaiColor.cardFace)
    }

    private func addTag() {
        let tag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        newTag = ""
        guard !tag.isEmpty, !entry.tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) else { return }
        entry.tags.append(tag)
        save()
    }

    private func removeTag(_ tag: String) {
        entry.tags.removeAll { $0 == tag }
        save()
    }

    /// A tappable related word: opens it if it's in the deck, else offers to add it.
    private func wordChip(_ word: String) -> some View {
        Button { tapWord(word) } label: {
            Text(word)
                .font(KaiFont.body(15, weight: .medium))
                .foregroundStyle(KaiColor.vermilion)
                .padding(.horizontal, KaiSpacing.s)
                .padding(.vertical, 4)
                .background(Capsule().fill(KaiColor.vermilion.opacity(0.12)))
        }
        .buttonStyle(.plain)
    }

    private func tapWord(_ raw: String) {
        let word = raw.trimmingCharacters(in: .whitespaces)
        guard !word.isEmpty else { return }
        if lookup(word) != nil {
            linkedLemma = word
        } else {
            addCandidate = word
        }
    }

    private func lookup(_ lemma: String) -> VocabularyEntry? {
        (try? repository.entry(lemma: lemma, language: .english)) ?? nil
    }

    private func addWord(_ word: String) {
        guard let config = AIConfigStore.configuration() else {
            toast.error("Add an API key in Settings first", category: "words")
            return
        }
        Task { @MainActor in
            adding = true
            defer { adding = false }
            let outcome = await ProviderFactory.make(config)
                .generateCards(lemmas: [word], language: .english, literaryExamples: false, chunkSize: 1)
            guard let card = outcome.cards.first else {
                toast.error("Couldn't add “\(word)”", category: "words")
                return
            }
            _ = try? repository.insertIfAbsent(AICardMapper.entry(from: card))
            toast.show("Added “\(card.lemma)”")
            linkedLemma = card.lemma
        }
    }

    // MARK: Sections

    @ViewBuilder
    private var meaningSection: some View {
        let en = entry.explanationEn ?? ""
        if !entry.explanation.isEmpty || !en.isEmpty {
            Section("Meaning") {
                VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                    if !entry.explanation.isEmpty {
                        Text(entry.explanation)
                            .font(KaiFont.body(16))
                            .foregroundStyle(KaiColor.sumi)
                    }
                    if !en.isEmpty {
                        Text(en)
                            .font(KaiFont.body(14))
                            .foregroundStyle(KaiColor.inkSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 2)
            }
            .listRowBackground(KaiColor.cardFace)
        }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: KaiSpacing.s) {
                HStack(alignment: .firstTextBaseline, spacing: KaiSpacing.s) {
                    Text(entry.lemma)
                        .font(KaiFont.display(30, weight: .bold))
                        .foregroundStyle(KaiColor.sumi)
                    if !entry.phonetic.isEmpty {
                        Text(entry.phonetic)
                            .font(KaiFont.phonetic(14))
                            .foregroundStyle(KaiColor.inkSecondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        KaiHaptics.impact(.light)
                        pronouncer.play(entry.lemma, accent: accent)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(KaiColor.vermilion)
                    }
                    .buttonStyle(KaiPressStyle())
                }
                if !entry.partsOfSpeech.isEmpty {
                    Text(entry.partsOfSpeech.joined(separator: " · "))
                        .font(KaiFont.body(13, weight: .medium))
                        .foregroundStyle(KaiColor.inkSecondary)
                }
                if !entry.syllables.isEmpty {
                    Text(entry.syllables.joined(separator: " · "))
                        .font(KaiFont.phonetic(13))
                        .foregroundStyle(KaiColor.inkSecondary)
                }
            }
            .padding(.vertical, 2)
        }
        .listRowBackground(KaiColor.cardFace)
    }

    @ViewBuilder
    private var similarWordsSection: some View {
        if !entry.synonymGroups.isEmpty {
            Section("Similar words") {
                ForEach(Array(entry.synonymGroups.enumerated()), id: \.offset) { _, group in
                    VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                        Text(group.sense)
                            .font(KaiFont.body(13, weight: .semibold))
                            .foregroundStyle(KaiColor.inkSecondary)
                        FlowLayout(spacing: 6) {
                            ForEach(group.words, id: \.self) { wordChip($0) }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listRowBackground(KaiColor.cardFace)
        }
    }

    @ViewBuilder
    private var collocationsSection: some View {
        if !entry.collocations.isEmpty {
            Section("Collocations") {
                ForEach(Array(entry.collocations.enumerated()), id: \.offset) { _, c in
                    VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                        HStack(alignment: .firstTextBaseline, spacing: KaiSpacing.s) {
                            Text(c.phrase)
                                .font(KaiFont.body(15, weight: .semibold))
                                .foregroundStyle(KaiColor.sumi)
                            Text(c.meaning)
                                .font(KaiFont.body(13))
                                .foregroundStyle(KaiColor.inkSecondary)
                        }
                        if !c.example.isEmpty {
                            Text(c.example)
                                .font(KaiFont.body(14))
                                .foregroundStyle(KaiColor.sumi)
                            if !c.exampleTranslation.isEmpty {
                                Text(c.exampleTranslation)
                                    .font(KaiFont.body(13))
                                    .foregroundStyle(KaiColor.inkSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listRowBackground(KaiColor.cardFace)
        }
    }

    @ViewBuilder
    private var notesSection: some View {
        let mnemonic = entry.mnemonic ?? ""
        let etymology = entry.etymology ?? ""
        let roots = entry.roots ?? ""
        if !mnemonic.isEmpty || !etymology.isEmpty || !roots.isEmpty || !entry.confusables.isEmpty {
            Section("Notes") {
                if !roots.isEmpty { labeled("Roots", roots) }
                if !mnemonic.isEmpty { labeled("Mnemonic", mnemonic) }
                if !etymology.isEmpty { labeled("Etymology", etymology) }
                if !entry.confusables.isEmpty {
                    VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                        Text("Confusables")
                            .font(KaiFont.body(11, weight: .semibold))
                            .foregroundStyle(KaiColor.vermilion)
                            .textCase(.uppercase)
                            .tracking(1.2)
                        FlowLayout(spacing: 6) {
                            ForEach(entry.confusables, id: \.self) { wordChip($0) }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .listRowBackground(KaiColor.cardFace)
        }
    }

    /// User-authored notes. Always shown (even when empty) so the "Add note" action is
    /// discoverable. Notes are sorted newest-first and deletable.
    private var annotationsSection: some View {
        Section("Annotations") {
            ForEach(sortedAnnotations) { note in
                VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                    Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(KaiFont.body(11, weight: .semibold))
                        .foregroundStyle(KaiColor.inkSecondary)
                    Text(note.text)
                        .font(KaiFont.body(15))
                        .foregroundStyle(KaiColor.sumi)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 2)
            }
            .onDelete(perform: deleteAnnotations)

            Button {
                newNoteText = ""
                showingAddNote = true
            } label: {
                Label("Add note", systemImage: "plus.circle")
                    .font(KaiFont.body(15, weight: .medium))
                    .foregroundStyle(KaiColor.vermilion)
            }
        }
        .listRowBackground(KaiColor.cardFace)
    }

    private var addNoteSheet: some View {
        NavigationStack {
            Form {
                Section("New note") {
                    TextField("e.g. in slang this means…", text: $newNoteText, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAddNote = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addNote() }
                        .disabled(newNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var schedulingSection: some View {
        Section("Scheduling") {
            row("Status", entry.scheduling.state.rawValue.capitalized)
            row("Reviews", "\(entry.scheduling.reps)")
            row("Lapses", "\(entry.scheduling.lapses)")
            row("Due", entry.dueAt.formatted(date: .abbreviated, time: .shortened))
        }
        .listRowBackground(KaiColor.cardFace)
    }

    // MARK: Annotations

    private var sortedAnnotations: [Annotation] {
        entry.annotations.sorted { $0.createdAt > $1.createdAt }
    }

    private func addNote() {
        let text = newNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        entry.annotations.append(Annotation(text: text))
        showingAddNote = false
        if save() { toast.show("Note added") }
    }

    private func deleteAnnotations(at offsets: IndexSet) {
        let ids = Set(offsets.map { sortedAnnotations[$0].id })
        entry.annotations.removeAll { ids.contains($0.id) }
        if save() { toast.show("Note deleted") }
    }

    /// Saves and reports failures; returns whether it succeeded.
    @discardableResult
    private func save() -> Bool {
        do { try modelContext.save(); return true }
        catch {
            toast.error("Couldn't save — see Diagnostics", category: "words")
            return false
        }
    }

    // MARK: Row builders

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: KaiSpacing.xs) {
            Text(title)
                .font(KaiFont.body(11, weight: .semibold))
                .foregroundStyle(KaiColor.vermilion)
                .textCase(.uppercase)
                .tracking(1.2)
            Text(value)
                .font(KaiFont.body(15))
                .foregroundStyle(KaiColor.sumi)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(KaiFont.body(15))
                .foregroundStyle(KaiColor.sumi)
            Spacer()
            Text(value)
                .font(KaiFont.body(15))
                .foregroundStyle(KaiColor.inkSecondary)
        }
    }
}
