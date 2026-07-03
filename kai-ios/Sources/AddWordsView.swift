import SwiftUI
import SwiftData
import KaiCore
import KaiAI
import KaiUI
import KaiServices

/// Authoring sheet: type or paste words (one per line) and AI generates full cards.
/// A single word is just a one-line entry — no mode switch needed.
struct AddWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast

    @State private var pasted = ""
    @State private var generating = false
    @State private var errorMessage: String?

    private var repository: VocabularyRepository { VocabularyRepository(context: modelContext) }

    /// One lemma per non-empty line.
    private var lemmas: [String] { PastedWordsParser.lemmas(from: pasted) }

    private var hasKey: Bool { AIConfigStore.configuration() != nil }
    private var canGenerate: Bool { !generating && hasKey && !lemmas.isEmpty }
    private var providerName: String { AIConfigStore.currentKind() == .openai ? "OpenAI" : "Claude" }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("One word per line", text: $pasted, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .frame(minHeight: 160, alignment: .topLeading)
                        .disabled(generating)
                } header: {
                    Text("Words")
                } footer: {
                    statusFooter
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
