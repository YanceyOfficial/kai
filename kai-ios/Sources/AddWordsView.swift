import SwiftUI
import SwiftData
import PhotosUI
import KaiCore
import KaiAI
import KaiUI
import KaiServices

/// Authoring sheet. Every mode generates everything with AI — the user only supplies
/// the word(s); the model fills in phonetics, meanings, examples, and notes.
/// "Single" adds one word; "Batch" adds one per line; "Scan" reads words from a photo.
struct AddWordsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(ToastCenter.self) private var toast

    private enum Mode: String, CaseIterable, Identifiable {
        case single = "Single"
        case batch = "Batch"
        case scan = "Scan"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .single
    @State private var single = ""
    @State private var pasted = ""
    @State private var generating = false
    @State private var errorMessage: String?

    // Scan mode
    @State private var candidates: [String] = []
    @State private var selectedCandidates: Set<String> = []
    @State private var recognizing = false
    @State private var pickedItem: PhotosPickerItem?
    @State private var showingCamera = false

    private var repository: VocabularyRepository { VocabularyRepository(context: modelContext) }

    /// The word(s) to generate, depending on the mode.
    private var lemmas: [String] {
        switch mode {
        case .single:
            let word = single.trimmingCharacters(in: .whitespacesAndNewlines)
            return word.isEmpty ? [] : [word]
        case .batch:
            return PastedWordsParser.lemmas(from: pasted)
        case .scan:
            return candidates.filter { selectedCandidates.contains($0) }
        }
    }

    /// Records where an entry came from, for provenance.
    private var entrySource: EntrySource { mode == .scan ? .ocr : .single }

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
                case .scan: scanField
                }
            }
            .navigationTitle("Add words")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: pickedItem) { _, item in
                guard let item else { return }
                Task { await loadAndRecognize(item) }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { data in
                    showingCamera = false
                    if let data { Task { await recognize(data) } }
                }
                .ignoresSafeArea()
            }
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
    private var scanField: some View {
        Section {
            HStack(spacing: KaiSpacing.m) {
                PhotosPicker(selection: $pickedItem, matching: .images) {
                    Label("Choose photo", systemImage: "photo.on.rectangle")
                }
                .disabled(generating || recognizing)
                if CameraPicker.isAvailable {
                    Spacer()
                    Button { showingCamera = true } label: {
                        Label("Take photo", systemImage: "camera")
                    }
                    .disabled(generating || recognizing)
                }
            }
        } header: {
            Text("Scan text")
        } footer: {
            statusFooter
        }

        if recognizing {
            Section {
                HStack(spacing: KaiSpacing.s) {
                    ProgressView()
                    Text("Recognizing text…").foregroundStyle(KaiColor.inkSecondary)
                }
            }
        } else if !candidates.isEmpty {
            Section {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
                    ForEach(candidates, id: \.self) { chip($0) }
                }
                .padding(.vertical, 4)
            } header: {
                Text("\(selectedCandidates.count) selected")
            }
        }
    }

    private func chip(_ word: String) -> some View {
        let isOn = selectedCandidates.contains(word)
        return Button {
            if isOn { selectedCandidates.remove(word) } else { selectedCandidates.insert(word) }
        } label: {
            Text(word)
                .font(KaiFont.body(14, weight: .medium))
                .foregroundStyle(isOn ? KaiColor.cardFace : KaiColor.sumi)
                .lineLimit(1)
                .padding(.horizontal, KaiSpacing.m)
                .padding(.vertical, KaiSpacing.s)
                .frame(maxWidth: .infinity)
                .background(Capsule().fill(isOn ? KaiColor.vermilion : KaiColor.washi))
        }
        .buttonStyle(.plain)
        .disabled(generating)
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

    // MARK: Scan (OCR)

    @MainActor
    private func loadAndRecognize(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else { return }
            await recognize(data)
        } catch {
            AppLog.shared.error("Failed to load image: \(error.localizedDescription)", category: "ocr")
            toast.error("Couldn't load that image", category: "ocr")
        }
    }

    @MainActor
    private func recognize(_ data: Data) async {
        recognizing = true
        defer { recognizing = false }
        do {
            let lines = try await VisionTextRecognizer().recognizeLines(in: data)
            let found = WordCandidateExtractor().candidates(from: lines)
            candidates = found
            selectedCandidates = Set(found)   // all selected by default
            if found.isEmpty { toast.error("No words found in that image", category: "ocr") }
        } catch {
            AppLog.shared.error("OCR failed: \(error.localizedDescription)", category: "ocr")
            toast.error("Couldn't read that image", category: "ocr")
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
            if (try? repository.insertIfAbsent(AICardMapper.entry(from: card, source: entrySource))) == true { added += 1 }
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
