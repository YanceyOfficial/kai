import SwiftUI
import KaiUI
import KaiServices

/// A single-choice quiz session: read the word, pick its meaning. Answers feed FSRS
/// through `QuizStore` (correct → good, wrong → again).
struct QuizSessionView: View {
    let store: QuizStore
    /// When set (the quiz was chained after a review), completion offers "Back to
    /// review" and calls this instead of restarting.
    var onClose: (() -> Void)? = nil

    @State private var index = 0
    @State private var selected: Int?
    @State private var correctCount = 0
    @State private var showDone = false

    @State private var pronouncer = PronunciationPlayer()
    @AppStorage("pronunciationAccent") private var accentRaw = Accent.us.rawValue
    private var accent: Accent { Accent(rawValue: accentRaw) ?? .us }

    private let pine = Color(hex: 0x3E7C63)
    private var questions: [QuizQuestion] { store.questions }

    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()

            VStack(spacing: KaiSpacing.l) {
                header
                SessionProgressBar(progress: questions.isEmpty ? 0 : Double(index) / Double(questions.count))

                if index < questions.count {
                    let question = questions[index]
                    promptCard(question)
                    optionsList(question)
                        .id(question.id)   // reset selection styling per question
                    Spacer()
                } else {
                    completed
                }
            }
            .padding(KaiSpacing.l)
        }
        .kaiToast("Quiz complete", isPresented: $showDone)
    }

    // MARK: Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                Text("Kai")
                    .font(KaiFont.display(34, weight: .bold))
                    .foregroundStyle(KaiColor.sumi)
                Text("甲斐 · quiz")
                    .font(KaiFont.body(14, weight: .medium))
                    .foregroundStyle(KaiColor.inkSecondary)
            }
            Spacer()
            Text("\(min(index + 1, questions.count)) / \(questions.count)")
                .font(KaiFont.phonetic(16))
                .foregroundStyle(KaiColor.inkSecondary)
        }
    }

    private func promptCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: KaiSpacing.s) {
            Text(question.prompt)
                .font(KaiFont.display(40, weight: .bold))
                .foregroundStyle(KaiColor.sumi)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            HStack(spacing: KaiSpacing.s) {
                if !question.phonetic.isEmpty {
                    Text(question.phonetic)
                        .font(KaiFont.phonetic(15))
                        .foregroundStyle(KaiColor.inkSecondary)
                }
                Button {
                    KaiHaptics.impact(.light)
                    pronouncer.play(question.prompt, accent: accent)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KaiColor.vermilion)
                }
                .buttonStyle(KaiPressStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KaiSpacing.xl)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(KaiColor.cardFace)
                .shadow(color: KaiColor.shadow, radius: 14, x: 0, y: 8)
        )
    }

    private func optionsList(_ question: QuizQuestion) -> some View {
        VStack(spacing: KaiSpacing.s) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { pair in
                optionButton(question, index: pair.offset, text: pair.element)
            }
        }
    }

    private func optionButton(_ question: QuizQuestion, index optionIndex: Int, text: String) -> some View {
        let answered = selected != nil
        let isCorrect = optionIndex == question.correctIndex
        let isChosen = optionIndex == selected

        // Reveal correctness once answered: the right option turns pine, a wrong pick
        // turns vermilion, everything else dims.
        let tint: Color = !answered ? KaiColor.hairline
            : isCorrect ? pine
            : isChosen ? KaiColor.vermilion
            : KaiColor.hairline
        let fill: Color = answered && isCorrect ? pine.opacity(0.12)
            : answered && isChosen ? KaiColor.vermilion.opacity(0.10)
            : KaiColor.cardFace

        return Button {
            choose(question, optionIndex)
        } label: {
            HStack(spacing: KaiSpacing.s) {
                Text(text)
                    .font(KaiFont.body(16, weight: .medium))
                    .foregroundStyle(KaiColor.sumi)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: KaiSpacing.s)
                if answered && isCorrect {
                    Image(systemName: "checkmark").foregroundStyle(pine)
                } else if answered && isChosen {
                    Image(systemName: "xmark").foregroundStyle(KaiColor.vermilion)
                }
            }
            .padding(.horizontal, KaiSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(tint, lineWidth: 1.5)
            )
            .opacity(answered && !isCorrect && !isChosen ? 0.5 : 1)
        }
        .buttonStyle(KaiPressStyle())
        .disabled(answered)
    }

    private var completed: some View {
        VStack(spacing: KaiSpacing.m) {
            Spacer()
            Text("Done")
                .font(KaiFont.display(48, weight: .bold))
                .foregroundStyle(KaiColor.vermilion)
            Text(questions.isEmpty
                 ? "Nothing to quiz right now."
                 : "\(correctCount) of \(questions.count) correct.")
                .font(KaiFont.body(17, weight: .medium))
                .foregroundStyle(KaiColor.sumi)
            if let onClose {
                // Chained after a review: always offer an exit, even if empty.
                KaiPrimaryButton("Back to review", action: onClose)
                    .padding(.top, KaiSpacing.m)
                    .frame(maxWidth: 220)
            } else if !questions.isEmpty {
                // Standalone: only offer "Quiz again" when there was something to quiz —
                // otherwise the reload would just land on this empty screen again.
                KaiPrimaryButton("Quiz again") { restart() }
                    .padding(.top, KaiSpacing.m)
                    .frame(maxWidth: 220)
            }
            Spacer()
        }
    }

    // MARK: Actions

    private func choose(_ question: QuizQuestion, _ optionIndex: Int) {
        guard selected == nil else { return }
        withAnimation(.easeOut(duration: 0.2)) { selected = optionIndex }

        let correct = store.answer(question, selectedIndex: optionIndex)
        if correct {
            correctCount += 1
            KaiHaptics.impact(.light)
        } else {
            KaiHaptics.impact(.rigid)
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            advance()
        }
    }

    private func advance() {
        withAnimation {
            selected = nil
            index += 1
            if index >= questions.count {
                showDone = true
                KaiHaptics.success()
            }
        }
    }

    private func restart() {
        store.load()
        withAnimation {
            index = 0
            selected = nil
            correctCount = 0
        }
    }
}
