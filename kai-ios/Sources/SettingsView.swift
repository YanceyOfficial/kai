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
    @AppStorage("aiProvider") private var aiProviderRaw = LLMProviderKind.claude.rawValue
    @AppStorage("reminderEnabled") private var reminderEnabled = false
    @AppStorage("reminderMinutes") private var reminderMinutes = 540   // 09:00

    @Environment(\.modelContext) private var modelContext
    @Environment(ToastCenter.self) private var toast

    @State private var apiKey = ""
    @State private var model = ""

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
                    Picker("New words per session", selection: $newWordsPerDay) {
                        ForEach(newWordOptions, id: \.self) { Text("\($0)").tag($0) }
                    }
                } header: {
                    Text("Review")
                } footer: {
                    Text("Each session introduces up to this many new words, mixed with words that are due for review.")
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
        let hasWords = !(((try? VocabularyRepository(context: modelContext).entries(for: .english)) ?? []).isEmpty)
        await ReviewReminder.apply(enabled: reminderEnabled, minutes: reminderMinutes, hasWords: hasWords)
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
