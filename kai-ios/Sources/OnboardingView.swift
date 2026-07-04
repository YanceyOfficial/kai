import SwiftUI
import KaiAI
import KaiUI

/// First-run setup: a light welcome that gets the API key + daily goal in place, so a
/// real user isn't dropped cold into an app that can't generate words yet.
struct OnboardingView: View {
    @Binding var hasOnboarded: Bool

    @AppStorage("aiProvider") private var aiProviderRaw = LLMProviderKind.claude.rawValue
    @AppStorage("newWordsPerDay") private var newWordsPerDay = 10
    @State private var apiKey = ""

    private var aiKind: LLMProviderKind { LLMProviderKind(rawValue: aiProviderRaw) ?? .claude }
    private let newWordOptions = [5, 10, 15, 20, 30]

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: KaiSpacing.xl) {
                    brand
                    bullets
                    aiSetup
                    goal
                    KaiPrimaryButton("Start learning") { finish() }
                }
                .padding(KaiSpacing.l)
                .padding(.top, KaiSpacing.l)
            }
        }
    }

    private var brand: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.s) {
            Text("甲")
                .font(KaiFont.display(56, weight: .bold))
                .foregroundStyle(KaiColor.vermilion)
            Text("Welcome to Kai")
                .font(KaiFont.display(30, weight: .bold))
                .foregroundStyle(KaiColor.sumi)
            Text("Memorize hard vocabulary with AI-built cards and scientific spaced repetition.")
                .font(KaiFont.body(16))
                .foregroundStyle(KaiColor.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bullets: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.m) {
            bullet("sparkles", "AI-enriched cards",
                   "Meanings, examples, mnemonics, and quizzes — generated for each word.")
            bullet("brain.head.profile", "Scientific memory",
                   "FSRS schedules every word right before you'd forget it.")
            bullet("bell.badge", "Daily nudge",
                   "An optional reminder keeps your streak alive.")
        }
    }

    private func bullet(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: KaiSpacing.m) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(KaiColor.vermilion)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(KaiFont.body(16, weight: .semibold)).foregroundStyle(KaiColor.sumi)
                Text(subtitle).font(KaiFont.body(14)).foregroundStyle(KaiColor.inkSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var aiSetup: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.s) {
            Text("Connect AI (optional)")
                .font(KaiFont.body(15, weight: .semibold))
                .foregroundStyle(KaiColor.sumi)
            Picker("Provider", selection: $aiProviderRaw) {
                Text("Claude").tag(LLMProviderKind.claude.rawValue)
                Text("OpenAI").tag(LLMProviderKind.openai.rawValue)
            }
            .pickerStyle(.segmented)
            SecureField("API key", text: $apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, KaiSpacing.m)
                .padding(.vertical, KaiSpacing.s)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(KaiColor.cardFace))
            Text("Stored in your Keychain. You can add or change it later in Settings.")
                .font(KaiFont.body(12))
                .foregroundStyle(KaiColor.inkSecondary)
        }
    }

    private var goal: some View {
        VStack(alignment: .leading, spacing: KaiSpacing.s) {
            Text("New words per session")
                .font(KaiFont.body(15, weight: .semibold))
                .foregroundStyle(KaiColor.sumi)
            Picker("New words per session", selection: $newWordsPerDay) {
                ForEach(newWordOptions, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func finish() {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty { AIConfigStore.setApiKey(key, for: aiKind) }
        hasOnboarded = true
    }
}
