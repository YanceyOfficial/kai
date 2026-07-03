import SwiftUI
import SwiftData
import KaiCore
import KaiUI

/// Authoring sheet with two modes: a full single-word form, and a batch paste that
/// creates one entry per line. Content-rich fields (AI phonetic/examples) come later.
struct AddWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private enum Mode: String, CaseIterable, Identifiable {
        case single = "Single"
        case batch = "Batch"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .single

    // Single-entry fields.
    @State private var lemma = ""
    @State private var phonetic = ""
    @State private var explanation = ""
    @State private var exampleSentence = ""
    @State private var exampleTranslation = ""
    @State private var kind: EntryKind = .word

    // Batch field.
    @State private var pasted = ""

    private var repository: VocabularyRepository { VocabularyRepository(context: modelContext) }

    private var batchLemmas: [String] { PastedWordsParser.lemmas(from: pasted) }

    private var canSave: Bool {
        switch mode {
        case .single: return !lemma.trimmingCharacters(in: .whitespaces).isEmpty
        case .batch: return !batchLemmas.isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                switch mode {
                case .single: singleFields
                case .batch: batchFields
                }
            }
            .navigationTitle("Add words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
        }
        .tint(KaiColor.vermilion)
    }

    @ViewBuilder
    private var singleFields: some View {
        Section("Word") {
            TextField("Lemma (e.g. eccentric)", text: $lemma)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            TextField("Phonetic (optional)", text: $phonetic)
                .autocorrectionDisabled()
            Picker("Kind", selection: $kind) {
                Text("Word").tag(EntryKind.word)
                Text("Phrase").tag(EntryKind.phrase)
            }
        }
        Section("Meaning") {
            TextField("Explanation", text: $explanation, axis: .vertical)
        }
        Section("Example (optional)") {
            TextField("Sentence", text: $exampleSentence, axis: .vertical)
            TextField("Translation", text: $exampleTranslation, axis: .vertical)
        }
    }

    @ViewBuilder
    private var batchFields: some View {
        Section {
            TextField("One word per line", text: $pasted, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(minHeight: 160, alignment: .topLeading)
        } header: {
            Text("Paste words")
        } footer: {
            Text("\(batchLemmas.count) word\(batchLemmas.count == 1 ? "" : "s") · duplicates are skipped.")
        }
    }

    private func save() {
        switch mode {
        case .single:
            let examples = exampleSentence.trimmingCharacters(in: .whitespaces).isEmpty
                ? []
                : [Example(sentence: exampleSentence, translation: exampleTranslation)]
            let entry = VocabularyEntry(
                lemma: lemma.trimmingCharacters(in: .whitespaces),
                kind: kind,
                language: .english,
                phonetic: phonetic.trimmingCharacters(in: .whitespaces),
                explanation: explanation.trimmingCharacters(in: .whitespaces),
                examples: examples,
                source: .single
            )
            try? repository.insertIfAbsent(entry)
        case .batch:
            for lemma in batchLemmas {
                let entry = VocabularyEntry(lemma: lemma, kind: .word, language: .english, source: .batch)
                try? repository.insertIfAbsent(entry)
            }
        }
        dismiss()
    }
}
