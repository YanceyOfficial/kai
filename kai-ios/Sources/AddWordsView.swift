import SwiftUI
import SwiftData
import KaiCore
import KaiAI
import KaiUI

/// Authoring sheet with three modes: a full single-word form, a batch paste that
/// creates one bare entry per line, and AI generation that fills in phonetics,
/// meanings, and examples for pasted words.
struct AddWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private enum Mode: String, CaseIterable, Identifiable {
        case single = "Single"
        case batch = "Batch"
        case ai = "AI"
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

    // AI field + status.
    @State private var aiText = ""
    @State private var generating = false
    @State private var errorMessage: String?

    private var repository: VocabularyRepository { VocabularyRepository(context: modelContext) }

    private var batchLemmas: [String] { PastedWordsParser.lemmas(from: pasted) }
    private var aiLemmas: [String] { PastedWordsParser.lemmas(from: aiText) }

    private var canSave: Bool {
        guard !generating else { return false }
        switch mode {
        case .single: return !lemma.trimmingCharacters(in: .whitespaces).isEmpty
        case .batch: return !batchLemmas.isEmpty
        case .ai: return !aiLemmas.isEmpty
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
                case .ai: aiFields
                }
            }
            .navigationTitle("Add words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(generating)
                }
                ToolbarItem(placement: .confirmationAction) {
                    if generating {
                        ProgressView()
                    } else {
                        Button(mode == .ai ? "Generate" : "Save", action: save).disabled(!canSave)
                    }
                }
            }
            .alert("Couldn’t generate", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
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

    @ViewBuilder
    private var aiFields: some View {
        Section {
            TextField("One word per line", text: $aiText, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(minHeight: 140, alignment: .topLeading)
                .disabled(generating)
        } header: {
            Text("Generate with AI")
        } footer: {
            if AIConfigStore.configuration() == nil {
                Text("Add an API key in Settings to enable AI generation.")
            } else {
                Text("\(aiLemmas.count) word\(aiLemmas.count == 1 ? "" : "s") · \(AIConfigStore.currentKind() == .openai ? "OpenAI" : "Claude") will fill in phonetics, meanings, and examples.")
            }
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
            dismiss()
        case .batch:
            for lemma in batchLemmas {
                let entry = VocabularyEntry(lemma: lemma, kind: .word, language: .english, source: .batch)
                try? repository.insertIfAbsent(entry)
            }
            dismiss()
        case .ai:
            Task { await generateAndSave() }
        }
    }

    /// Calls the configured provider to enrich the pasted words, then inserts them.
    @MainActor
    private func generateAndSave() async {
        guard let config = AIConfigStore.configuration() else {
            errorMessage = "Add an API key in Settings first."
            return
        }
        let lemmas = aiLemmas
        guard !lemmas.isEmpty else { return }

        generating = true
        defer { generating = false }
        do {
            let provider = ProviderFactory.make(config)
            let cards = try await provider.generateCards(lemmas: lemmas, language: .english, literaryExamples: false)
            for card in cards {
                try? repository.insertIfAbsent(AICardMapper.entry(from: card))
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
