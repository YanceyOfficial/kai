import SwiftUI
import SwiftData
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
    @AppStorage("requestRetention") private var requestRetention = 0.9
    @AppStorage("aiProvider") private var aiProviderRaw = LLMProviderKind.claude.rawValue
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 540   // 09:00
    @AppStorage(AppSettings.studyLanguageKey) private var studyLanguageRaw = LanguageDomain.english.rawValue
    @AppStorage("showFurigana") private var showFurigana = true

    private var language: LanguageDomain { LanguageDomain(rawValue: studyLanguageRaw) ?? .english }

    @Environment(\.modelContext) private var modelContext
    @Environment(ToastCenter.self) private var toast

    @State private var apiKey = ""
    @State private var model = ""
    /// The provider's models, live from its list API (cached between launches).
    @State private var models: [ModelInfo] = []
    @State private var modelCheck: ModelCheck = .idle

    /// Fetching the model list is also how the key is checked.
    private enum ModelCheck: Equatable {
        case idle, checking, connected, failed(String)
    }

    private let newWordOptions = [5, 10, 15, 20, 30]
    private var aiKind: LLMProviderKind { LLMProviderKind(rawValue: aiProviderRaw) ?? .claude }

    /// Bridges the stored minutes-since-midnight to the DatePicker's Date.
    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents(); c.hour = reminderMinutes / 60; c.minute = reminderMinutes % 60
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                reminderMinutes = (c.hour ?? 9) * 60 + (c.minute ?? 0)
            }
        )
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
              Text("Settings")
                .font(KaiFont.display(34, weight: .bold))
                .foregroundStyle(KaiColor.sumi)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, KaiSpacing.l)
                .padding(.top, KaiSpacing.l)
              Form {
                Section {
                    Picker("Appearance", selection: $appearanceRaw) {
                        ForEach(AppAppearance.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                } header: {
                    Text("Appearance")
                }

                Section {
                    Picker("Studying", selection: $studyLanguageRaw) {
                        ForEach(LanguageDomain.allCases, id: \.self) { language in
                            Text(language.displayName).tag(language.rawValue)
                        }
                    }
                    if language == .japanese {
                        Toggle("Show furigana", isOn: $showFurigana)
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text(language == .japanese
                         ? "Each language keeps its own deck, reviews and stories. Furigana are the kana readings printed over kanji."
                         : "Each language keeps its own deck, reviews and stories.")
                }

                Section {
                    Picker("New words per session", selection: $newWordsPerDay) {
                        ForEach(newWordOptions, id: \.self) { Text("\($0)").tag($0) }
                    }
                    Picker("Target retention", selection: $requestRetention) {
                        ForEach([0.8, 0.85, 0.9, 0.95], id: \.self) { r in
                            Text("\(Int(r * 100))%").tag(r)
                        }
                    }
                } header: {
                    Text("Review")
                } footer: {
                    Text("New words per session mixes with due reviews. Target retention is how well you want to remember — higher means shorter intervals and more frequent reviews.")
                }

                Section {
                    Toggle("Daily review reminder", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Time", selection: reminderTime, displayedComponents: .hourAndMinute)
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("A daily nudge at your chosen time, when you have words to review. Requires notification permission.")
                }

                Section {
                    Toggle("Auto-play on each card", isOn: $autoPlay)
                    if language == .english {
                        Picker("Accent", selection: $accentRaw) {
                            Text("American").tag(Accent.us.rawValue)
                            Text("British").tag(Accent.uk.rawValue)
                        }
                    }
                } header: {
                    Text("Pronunciation")
                } footer: {
                    Text(language == .japanese
                         ? "Words are read by their kana reading, from Youdao dictvoice; anything it has no audio for is spoken by the system's Japanese voice. Plays even when the ringer is silenced."
                         : "Audio is from Youdao dictvoice and plays even when the ringer is silenced.")
                }

                Section {
                    Picker("Provider", selection: $aiProviderRaw) {
                        Text("Claude").tag(LLMProviderKind.claude.rawValue)
                        Text("OpenAI").tag(LLMProviderKind.openai.rawValue)
                    }
                    SecureField("API key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !apiKey.isEmpty, !models.isEmpty {
                        Picker("Model", selection: $model) {
                            ForEach(models) { Text($0.displayName).tag($0.id) }
                        }
                    }
                    if !apiKey.isEmpty {
                        Button { Task { await checkKey() } } label: {
                            HStack {
                                Text(models.isEmpty ? "Check key & load models" : "Reload models")
                                Spacer()
                                if modelCheck == .checking { ProgressView() }
                            }
                        }
                        .disabled(modelCheck == .checking)
                    }
                } header: {
                    Text("AI enrichment")
                } footer: {
                    aiFooter
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
                    Text("Kai · 甲斐 — local English and Japanese review with FSRS spaced repetition.")
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
            // A key typed or pasted is checked once typing pauses: its model list loads,
            // or the provider's refusal shows.
            .task(id: "\(aiProviderRaw)|\(apiKey)") {
                guard !apiKey.isEmpty else { modelCheck = .idle; return }
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled else { return }
                await checkKey()
            }
            .onChange(of: model) { AIConfigStore.setModel(model, for: aiKind) }
            .onChange(of: reminderEnabled) { _, enabled in Task { await reminderToggled(enabled) } }
            .onChange(of: reminderMinutes) { Task { await applyReminder() } }
        }
        .tint(KaiColor.vermilion)
    }

    // MARK: Reminders

    /// On enable, request permission first; if denied, revert the toggle.
    private func reminderToggled(_ enabled: Bool) async {
        if enabled {
            let granted = await UNDailyReminderScheduler().requestAuthorization()
            guard granted else {
                reminderEnabled = false
                toast.error("Allow notifications in iOS Settings to get reminders", category: "reminder")
                return
            }
        }
        await applyReminder()
    }

    private func applyReminder() async {
        let hasWords = !(((try? VocabularyRepository(context: modelContext).entries(for: AppSettings.studyLanguage)) ?? []).isEmpty)
        await ReviewReminder.apply(enabled: reminderEnabled, minutes: reminderMinutes, hasWords: hasWords)
    }

    /// Loads the stored key, model and cached model list for the selected provider.
    private func loadAIFields() {
        apiKey = AIConfigStore.apiKey(for: aiKind)
        models = AIConfigStore.cachedModels(for: aiKind)
        model = AIConfigStore.model(for: aiKind)
        modelCheck = .idle
    }

    /// Fetches the provider's model list with the key — which is also the check that the
    /// key works — and keeps the chosen model if it is still offered, else the newest.
    private func checkKey() async {
        let kind = aiKind
        modelCheck = .checking
        do {
            let fetched = try await ModelListing.models(for: kind, apiKey: apiKey)
            guard kind == aiKind else { return }   // the provider changed meanwhile
            models = fetched
            AIConfigStore.setCachedModels(fetched, for: kind)
            if !fetched.contains(where: { $0.id == model }), let first = fetched.first {
                model = first.id
            }
            modelCheck = fetched.isEmpty ? .failed("The key works, but no models were listed.") : .connected
        } catch {
            guard kind == aiKind else { return }
            modelCheck = .failed(error.localizedDescription)
        }
    }

    @ViewBuilder
    private var aiFooter: some View {
        switch modelCheck {
        case .failed(let message):
            Text(message).foregroundStyle(KaiColor.danger)
        case .connected:
            let limit = models.first { $0.id == model }?.maxOutputTokens
            Text("Connected — \(models.count) models. " + (limit.map { "This one writes up to \($0.formatted()) tokens per reply. " } ?? "") + "Key stored in the Keychain.")
        default:
            Text(apiKey.isEmpty
                 ? "Add an API key to auto-generate readings, meanings, and examples when adding words. The key is checked by loading its models, and stored in the Keychain."
                 : "Key stored in the Keychain.")
        }
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
