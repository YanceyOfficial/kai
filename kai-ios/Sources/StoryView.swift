import SwiftUI
import KaiCore
import KaiUI

/// The daily story: a short AI passage using today's review words. Target words are
/// highlighted and tappable (→ their card); a toggle reveals the Chinese translation.
struct StoryView: View {
    let store: StoryStore

    @Environment(\.dismiss) private var dismiss
    @AppStorage("newWordsPerDay") private var newWordsPerDay = 10

    @State private var showTranslation = false
    @State private var selectedLemma: String?

    var body: some View {
        NavigationStack {
            ZStack {
                KaiColor.washi.ignoresSafeArea()
                content
            }
            .navigationTitle("Today's story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    if store.state == .ready {
                        Button {
                            withAnimation { showTranslation.toggle() }
                        } label: {
                            Image(systemName: showTranslation ? "character.book.closed" : "character.book.closed.fill")
                        }
                        Button { regenerate() } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                guard url.scheme == "kai", url.host == "word" else { return .systemAction }
                selectedLemma = url.lastPathComponent
                return .handled
            })
            .navigationDestination(item: $selectedLemma) { lemma in
                if let entry = store.entry(forLemma: lemma) {
                    WordDetailView(entry: entry)
                } else {
                    ContentUnavailableView("Not found", systemImage: "questionmark")
                }
            }
        }
        .tint(KaiColor.vermilion)
        .task { store.load(newLimit: newWordsPerDay) }
    }

    @ViewBuilder
    private var content: some View {
        switch store.state {
        case .loading:
            ProgressView("Writing your story…").tint(KaiColor.vermilion)
        case .ready:
            storyScroll
        case .idle:
            prompt(title: "Today's story",
                   message: "Weave today's review words into a short passage to lock them in.",
                   button: "Generate")
        case .empty:
            info(title: "Nothing due", message: "Come back once you have words to review today.")
        case .needsKey:
            info(title: "No API key", message: "Add an API key in Settings to generate stories.")
        case .failed(let msg):
            prompt(title: "Couldn’t generate", message: msg, button: "Try again")
        }
    }

    private var storyScroll: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: KaiSpacing.l) {
                Text(attributedStory)
                    .lineSpacing(6)
                if showTranslation {
                    Divider()
                    Text(store.translation)
                        .font(KaiFont.body(15))
                        .foregroundStyle(KaiColor.inkSecondary)
                        .lineSpacing(5)
                }
                Text("Tap a highlighted word to open its card.")
                    .font(KaiFont.body(12))
                    .foregroundStyle(KaiColor.inkSecondary)
                    .padding(.top, KaiSpacing.s)
            }
            .padding(KaiSpacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Builds the passage with each target word styled and linked to `kai://word/<lemma>`.
    private var attributedStory: AttributedString {
        var result = AttributedString()
        for segment in StoryHighlighter.segments(text: store.text, words: store.words) {
            var piece = AttributedString(segment.text)
            if let lemma = segment.lemma {
                piece.foregroundColor = KaiColor.vermilion
                piece.font = KaiFont.body(17, weight: .semibold)
                piece.link = URL(string: "kai://word/\(lemma)")
            } else {
                piece.foregroundColor = KaiColor.sumi
                piece.font = KaiFont.body(17)
            }
            result.append(piece)
        }
        return result
    }

    private func prompt(title: String, message: String, button: String) -> some View {
        VStack(spacing: KaiSpacing.m) {
            Text(title).font(KaiFont.display(22, weight: .bold)).foregroundStyle(KaiColor.sumi)
            Text(message)
                .font(KaiFont.body(15))
                .foregroundStyle(KaiColor.inkSecondary)
                .multilineTextAlignment(.center)
            KaiPrimaryButton(button) { regenerate() }
                .frame(maxWidth: 220)
                .padding(.top, KaiSpacing.s)
        }
        .padding(KaiSpacing.xl)
    }

    private func info(title: String, message: String) -> some View {
        VStack(spacing: KaiSpacing.s) {
            Text(title).font(KaiFont.display(22, weight: .bold)).foregroundStyle(KaiColor.sumi)
            Text(message)
                .font(KaiFont.body(15))
                .foregroundStyle(KaiColor.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(KaiSpacing.xl)
    }

    private func regenerate() {
        Task { await store.generate(newLimit: newWordsPerDay) }
    }
}
