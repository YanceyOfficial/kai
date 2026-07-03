import SwiftUI
import SwiftData
import KaiCore
import KaiAI
import KaiUI
import KaiServices

/// Authoring sheet. Both modes generate everything with AI — the user only supplies
/// the word(s); the model fills in phonetics, meanings, examples, and notes.
/// "Single" adds one word; "Batch" adds one per line.
struct AddWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast

    private enum Mode: String, CaseIterable, Identifiable {
        case single = "Single"
        case batch = "Batch"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .single
    @State private var single = ""
    @State private var pasted = ""
    @State private var generating = false
    @State private var errorMessage: String?

    private var repository: VocabularyRepository { VocabularyRepository(context: modelContext) }

    /// The word(s) to generate, depending on the mode.
    private var lemmas: [String] {
        switch mode {
        case .single:
            let word = single.trimmingCharacters(in: .whitespacesAndNewlines)
            return word.isEmpty ? [] : [word]
        case .batch:
            return PastedWordsParser.lemmas(from: pasted)
        }
    }

    private var hasKey: Bool { AIConfigStore.configuration() != nil }
    private var canGenerate: Bool { !generating && hasKey && !lemmas.isEmpty }
    private var providerName: String { AIConfigStore.currentKind() == .openai ? "OpenAI" : "Claude" }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(generating)

                switch mode {
                case .single: singleField
                case .batch: batchField
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
                        Button("Generate") { generate() }.disabled(!canGenerate)
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

    // MARK: Fields

    @ViewBuilder
    private var singleField: some View {
        Section {
            TextField("Word (e.g. eccentric)", text: $single)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(generating)
                .onSubmit { if canGenerate { generate() } }
        } footer: {
            statusFooter
        }
    }

    @ViewBuilder
    private var batchField: some View {
        Section {
            TextField("One word per line", text: $pasted, axis: .vertical)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .frame(minHeight: 160, alignment: .topLeading)
                .disabled(generating)
        } header: {
            Text("Paste words")
        } footer: {
            statusFooter
        }
    }

    @ViewBuilder
    private var statusFooter: some View {
        if !hasKey {
            Text("Add an API key in Settings to generate words.")
        } else if generating {
            Text("Generating \(lemmas.count) word\(lemmas.count == 1 ? "" : "s") with \(providerName)…")
        } else {
            Text("\(providerName) fills in phonetics, meanings, and examples. \(lemmas.count) word\(lemmas.count == 1 ? "" : "s").")
        }
    }

    // MARK: Generation

    private func generate() {
        Task { await run() }
    }

    @MainActor
    private func run() async {
        guard let config = AIConfigStore.configuration() else {
            errorMessage = "Add an API key in Settings first."
            return
        }
        let words = lemmas
        guard !words.isEmpty else { return }

        generating = true
        defer { generating = false }

        // Chunked so a large batch can't blow the model's token budget; best-effort so a
        // failed chunk doesn't lose the words that did generate.
        let provider = ProviderFactory.make(config)
        let outcome = await provider.generateCards(
            lemmas: words, language: .english, literaryExamples: false, chunkSize: Self.aiChunkSize)

        var added = 0
        for card in outcome.cards {
            if (try? repository.insertIfAbsent(AICardMapper.entry(from: card))) == true { added += 1 }
        }

        // Nothing generated at all — surface the first error and stay on the form.
        if outcome.cards.isEmpty {
            let message = outcome.failures.first ?? "Generation failed."
            AppLog.shared.error("Generation failed: \(message)", category: "ai")
            errorMessage = message
            return
        }

        if outcome.hasFailures {
            AppLog.shared.warning("Batch generation: \(outcome.failures.count) chunk(s) failed", category: "ai")
            toast.show("Added \(added) · \(outcome.failures.count) batch\(outcome.failures.count == 1 ? "" : "es") failed")
        } else {
            toast.show("Added \(added) word\(added == 1 ? "" : "s")")
        }
        dismiss()
    }

    /// Words per AI request. Cards are content-rich (bilingual, collocations, quizzes),
    /// so keep chunks small to stay well under output-token limits.
    private static let aiChunkSize = 8
}
