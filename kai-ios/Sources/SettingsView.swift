import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import KaiCore
import KaiServices
import KaiAI
import KaiUI

/// App settings. Pronunciation preferences are persisted via `@AppStorage` and read
/// directly by the review loop, so no wiring or observers are needed. The AI API key
/// is kept in the Keychain via `AIConfigStore`.
struct SettingsView: View {
    @AppStorage("appearance") private var appearanceRaw = AppAppearance.system.rawValue
    @AppStorage("autoPlayPronunciation") private var autoPlay = true
    @AppStorage("pronunciationAccent") private var accentRaw = Accent.us.rawValue
    @AppStorage("newWordsPerDay") private var newWordsPerDay = 10
    @AppStorage("aiProvider") private var aiProviderRaw = LLMProviderKind.claude.rawValue

    @Environment(\.modelContext) private var modelContext
    @Environment(ToastCenter.self) private var toast

    @State private var apiKey = ""
    @State private var model = ""
    @State private var exportDocument: BackupDocument?
    @State private var showingExporter = false
    @State private var showingImporter = false

    private let newWordOptions = [5, 10, 15, 20, 30]
    private var aiKind: LLMProviderKind { LLMProviderKind(rawValue: aiProviderRaw) ?? .claude }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
              Text("Settings")
                .font(KaiFont.display(34, weight: .bold))
                .foregroundStyle(KaiColor.sumi)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, KaiSpacing.l)
                .padding(.top, KaiSpacing.s)
              Form {
                Section {
                    Picker("Appearance", selection: $appearanceRaw) {
                        ForEach(AppAppearance.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                } header: {
                    Text("Appearance")
                }

                Section {
                    Picker("New words per session", selection: $newWordsPerDay) {
                        ForEach(newWordOptions, id: \.self) { Text("\($0)").tag($0) }
                    }
                } header: {
                    Text("Review")
                } footer: {
                    Text("Each session introduces up to this many new words, mixed with words that are due for review.")
                }

                Section {
                    Toggle("Auto-play on each card", isOn: $autoPlay)
                    Picker("Accent", selection: $accentRaw) {
                        Text("American").tag(Accent.us.rawValue)
                        Text("British").tag(Accent.uk.rawValue)
                    }
                } header: {
                    Text("Pronunciation")
                } footer: {
                    Text("Audio is from Youdao dictvoice and plays even when the ringer is silenced.")
                }

                Section {
                    Picker("Provider", selection: $aiProviderRaw) {
                        Text("Claude").tag(LLMProviderKind.claude.rawValue)
                        Text("OpenAI").tag(LLMProviderKind.openai.rawValue)
                    }
                    SecureField("API key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Picker("Model", selection: $model) {
                        ForEach(AIModelCatalog.models(for: aiKind), id: \.self) { Text($0).tag($0) }
                    }
                } header: {
                    Text("AI enrichment")
                } footer: {
                    Text(apiKey.isEmpty
                         ? "Add an API key to auto-generate phonetics, meanings, and examples when adding words. Stored in the Keychain."
                         : "Key stored in the Keychain.")
                }

                Section {
                    Button { makeExport() } label: {
                        Label("Export backup", systemImage: "square.and.arrow.up")
                    }
                    Button { showingImporter = true } label: {
                        Label("Import backup", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("Backup & Restore")
                } footer: {
                    Text("Export a JSON backup to Files or iCloud Drive, and import it after reinstalling or on a new device. Everything stays on your device.")
                }

                Section {
                    NavigationLink {
                        LogsView()
                    } label: {
                        Label("Diagnostics", systemImage: "stethoscope")
                    }
                } header: {
                    Text("Troubleshooting")
                } footer: {
                    Text("View, share, or clear collected logs to diagnose issues.")
                }

                Section {
                    LabeledContent("Version", value: Self.appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("Kai · 甲斐 — local English review with FSRS spaced repetition.")
                }

                Section {} footer: {
                    Text(Self.copyright)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
              .scrollContentBackground(.hidden)
            }
            .background(KaiColor.washi)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear(perform: loadAIFields)
            .onChange(of: aiProviderRaw) { loadAIFields() }
            .onChange(of: apiKey) { AIConfigStore.setApiKey(apiKey, for: aiKind) }
            .onChange(of: model) { AIConfigStore.setModel(model, for: aiKind) }
            .fileExporter(isPresented: $showingExporter, document: exportDocument,
                          contentType: .json, defaultFilename: Self.backupFilename) { result in
                if case .failure = result { toast.error("Export failed", category: "backup") }
            }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
        }
        .tint(KaiColor.vermilion)
    }

    // MARK: Backup & restore

    private func makeExport() {
        do {
            let snapshot = try VocabularyRepository(context: modelContext).exportSnapshot()
            exportDocument = BackupDocument(data: try JSONEncoder().encode(snapshot))
            showingExporter = true
        } catch {
            toast.error("Couldn't create backup", category: "backup")
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(BackupSnapshot.self, from: data)
            let count = try VocabularyRepository(context: modelContext)
                .importSnapshot(snapshot, strategy: .mergeBackupWins)
            toast.show("Imported \(count) word\(count == 1 ? "" : "s")")
        } catch {
            toast.error("Couldn't read that backup", category: "backup")
        }
    }

    private static var backupFilename: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return "kai-backup-\(f.string(from: Date()))"
    }

    /// Loads the stored key/model for the currently selected provider into the fields,
    /// resolving the model to a valid catalog entry so the picker has a selection.
    private func loadAIFields() {
        apiKey = AIConfigStore.apiKey(for: aiKind)
        model = AIModelCatalog.resolved(AIConfigStore.model(for: aiKind), for: aiKind)
    }

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    /// Copyright line with the current year computed at runtime.
    private static var copyright: String {
        "Copyright © \(Calendar.current.component(.year, from: Date())) Yancey Inc."
    }
}
