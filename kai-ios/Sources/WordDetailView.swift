import SwiftUI
import KaiCore
import KaiServices
import KaiUI

/// A word's detail page: every field laid out directly (no flip card — the list row
/// already shows the word and meaning, so this is the full reference).
struct WordDetailView: View {
    let entry: VocabularyEntry

    @State private var pronouncer = PronunciationPlayer()
    @AppStorage("pronunciationAccent") private var accentRaw = Accent.us.rawValue
    private var accent: Accent { Accent(rawValue: accentRaw) ?? .us }

    var body: some View {
        List {
            headerSection

            if !entry.explanation.isEmpty {
                Section("Meaning") {
                    Text(entry.explanation)
                        .font(KaiFont.body(16))
                        .foregroundStyle(KaiColor.sumi)
                }
                .listRowBackground(KaiColor.cardFace)
            }

            if !entry.examples.isEmpty {
                Section("Examples") {
                    ForEach(Array(entry.examples.enumerated()), id: \.offset) { _, example in
                        VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                            Text(example.sentence)
                                .font(KaiFont.body(15))
                                .foregroundStyle(KaiColor.sumi)
                            if !example.translation.isEmpty {
                                Text(example.translation)
                                    .font(KaiFont.body(14))
                                    .foregroundStyle(KaiColor.inkSecondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .listRowBackground(KaiColor.cardFace)
            }

            notesSection
            schedulingSection
        }
        .scrollContentBackground(.hidden)
        .background(KaiColor.washi)
        .navigationTitle(entry.lemma)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Sections

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: KaiSpacing.s) {
                HStack(alignment: .firstTextBaseline, spacing: KaiSpacing.s) {
                    Text(entry.lemma)
                        .font(KaiFont.display(30, weight: .bold))
                        .foregroundStyle(KaiColor.sumi)
                    if !entry.phonetic.isEmpty {
                        Text(entry.phonetic)
                            .font(KaiFont.phonetic(14))
                            .foregroundStyle(KaiColor.inkSecondary)
                    }
                    Spacer(minLength: 0)
                    Button {
                        KaiHaptics.impact(.light)
                        pronouncer.play(entry.lemma, accent: accent)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(KaiColor.vermilion)
                    }
                    .buttonStyle(KaiPressStyle())
                }
                if !entry.partsOfSpeech.isEmpty {
                    Text(entry.partsOfSpeech.joined(separator: " · "))
                        .font(KaiFont.body(13, weight: .medium))
                        .foregroundStyle(KaiColor.inkSecondary)
                }
                if !entry.syllables.isEmpty {
                    Text(entry.syllables.joined(separator: " · "))
                        .font(KaiFont.phonetic(13))
                        .foregroundStyle(KaiColor.inkSecondary)
                }
            }
            .padding(.vertical, 2)
        }
        .listRowBackground(KaiColor.cardFace)
    }

    @ViewBuilder
    private var notesSection: some View {
        let mnemonic = entry.mnemonic ?? ""
        let etymology = entry.etymology ?? ""
        if !mnemonic.isEmpty || !etymology.isEmpty || !entry.synonyms.isEmpty || !entry.confusables.isEmpty {
            Section("Notes") {
                if !mnemonic.isEmpty { labeled("Mnemonic", mnemonic) }
                if !etymology.isEmpty { labeled("Etymology", etymology) }
                if !entry.synonyms.isEmpty { labeled("Synonyms", entry.synonyms.joined(separator: ", ")) }
                if !entry.confusables.isEmpty { labeled("Confusables", entry.confusables.joined(separator: ", ")) }
            }
            .listRowBackground(KaiColor.cardFace)
        }
    }

    private var schedulingSection: some View {
        Section("Scheduling") {
            row("Status", entry.scheduling.state.rawValue.capitalized)
            row("Reviews", "\(entry.scheduling.reps)")
            row("Lapses", "\(entry.scheduling.lapses)")
            row("Due", entry.dueAt.formatted(date: .abbreviated, time: .shortened))
        }
        .listRowBackground(KaiColor.cardFace)
    }

    // MARK: Row builders

    private func labeled(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: KaiSpacing.xs) {
            Text(title)
                .font(KaiFont.body(11, weight: .semibold))
                .foregroundStyle(KaiColor.vermilion)
                .textCase(.uppercase)
                .tracking(1.2)
            Text(value)
                .font(KaiFont.body(15))
                .foregroundStyle(KaiColor.sumi)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(KaiFont.body(15))
                .foregroundStyle(KaiColor.sumi)
            Spacer()
            Text(value)
                .font(KaiFont.body(15))
                .foregroundStyle(KaiColor.inkSecondary)
        }
    }
}
