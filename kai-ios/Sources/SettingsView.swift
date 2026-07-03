import SwiftUI
import KaiServices
import KaiAI
import KaiUI

/// App settings. Pronunciation preferences are persisted via `@AppStorage` and read
/// directly by the review loop, so no wiring or observers are needed. The AI API key
/// is kept in the Keychain via `AIConfigStore`.
struct SettingsView: View {
    @AppStorage("autoPlayPronunciation") private var autoPlay = true
    @AppStorage("pronunciationAccent") private var accentRaw = Accent.us.rawValue
    @AppStorage("newWordsPerDay") private var newWordsPerDay = 10
    @AppStorage("aiProvider") private var aiProviderRaw = LLMProviderKind.claude.rawValue

    @State private var apiKey = ""
    @State private var model = ""

    private let newWordOptions = [5, 10, 15, 20, 30]
    private var aiKind: LLMProviderKind { LLMProviderKind(rawValue: aiProviderRaw) ?? .claude }

    var body: some View {
        NavigationStack {
            Form {
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
                    TextField("Model (optional)", text: $model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("AI enrichment")
                } footer: {
                    Text(apiKey.isEmpty
                         ? "Add an API key to auto-generate phonetics, meanings, and examples when adding words. Stored in the Keychain."
                         : "Key stored in the Keychain. Leave the model blank to use the provider default.")
                }

                Section {
                    LabeledContent("Version", value: Self.appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("Kai · 甲斐 — local English review with FSRS spaced repetition.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(KaiColor.washi)
            .navigationTitle("Settings")
            .onAppear(perform: loadAIFields)
            .onChange(of: aiProviderRaw) { loadAIFields() }
            .onChange(of: apiKey) { AIConfigStore.setApiKey(apiKey, for: aiKind) }
            .onChange(of: model) { AIConfigStore.setModel(model, for: aiKind) }
        }
        .tint(KaiColor.vermilion)
    }

    /// Loads the stored key/model for the currently selected provider into the fields.
    private func loadAIFields() {
        apiKey = AIConfigStore.apiKey(for: aiKind)
        model = AIConfigStore.model(for: aiKind)
    }

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
