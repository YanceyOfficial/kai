import SwiftUI
import KaiServices
import KaiUI

/// App settings. Pronunciation preferences are persisted via `@AppStorage` and read
/// directly by the review loop, so no wiring or observers are needed.
struct SettingsView: View {
    @AppStorage("autoPlayPronunciation") private var autoPlay = true
    @AppStorage("pronunciationAccent") private var accentRaw = Accent.us.rawValue

    var body: some View {
        NavigationStack {
            Form {
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
        }
        .tint(KaiColor.vermilion)
    }

    private static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
