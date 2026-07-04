import SwiftUI
import KaiUI
import KaiServices

/// A quiz session over the just-reviewed words. Questions vary by type: tap a choice, or
/// type the answer (fill-in-blank / listening). A wrong answer re-grades the word as
/// "again" via `QuizStore` (the double-check); a correct answer is a no-op.
struct QuizSessionView: View {
    let store: QuizStore
    /// When set (the quiz was chained after a review), completion offers "Back to
    /// review" and calls this instead of restarting.
    var onClose: (() -> Void)? = nil

    @State private var index = 0
    @State private var selected: Int?          // chosen option (choice mode)
    @State private var textInput = ""          // typed answer (text mode)
    @State private var responded = false       // this question has been answered
    @State private var wasCorrect = false
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
                    ScrollView {
                        VStack(spacing: KaiSpacing.l) {
                            promptCard(question)
                            if question.isTextEntry {
                                textEntry(question)
                            } else {
                                optionsList(question)
                            }
                        }
                        .id(question.id)   // reset per question
                    }
                    Spacer(minLength: 0)
                } else {
                    completed
                }
            }
            .padding(KaiSpacing.l)
        }
        .kaiToast("Quiz complete", isPresented: $showDone)
        .task(id: index) {
            // Auto-play the pronunciation for a listening question.
            guard index < questions.count, questions[index].playsAudio else { return }
            pronouncer.play(questions[index].word, accent: accent)
        }
    }

    // MARK: Header

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

    // MARK: Prompt

    private func promptCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: KaiSpacing.s) {
            if question.hidesWord && !responded {
                if question.playsAudio {
                    Button { pronouncer.play(question.word, accent: accent) } label: {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(KaiColor.vermilion)
                    }
                    .buttonStyle(KaiPressStyle())
                    Text("Spell what you hear")
                        .font(KaiFont.body(14, weight: .medium))
                        .foregroundStyle(KaiColor.inkSecondary)
                } else {
                    Text("? ? ?")
                        .font(KaiFont.display(34, weight: .bold))
                        .foregroundStyle(KaiColor.inkSecondary.opacity(0.35))
                }
            } else {
                Text(question.word)
                    .font(KaiFont.display(38, weight: .bold))
                    .foregroundStyle(KaiColor.sumi)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                HStack(spacing: KaiSpacing.s) {
                    if !question.phonetic.isEmpty {
                        Text(question.phonetic)
                            .font(KaiFont.phonetic(14))
                            .foregroundStyle(KaiColor.inkSecondary)
                    }
                    Button {
                        KaiHaptics.impact(.light)
                        pronouncer.play(question.word, accent: accent)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(KaiColor.vermilion)
                    }
                    .buttonStyle(KaiPressStyle())
                }
            }

            if !question.question.isEmpty {
                Text(question.question)
                    .font(KaiFont.body(16))
                    .foregroundStyle(KaiColor.sumi)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, KaiSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, KaiSpacing.xl)
        .padding(.horizontal, KaiSpacing.m)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(KaiColor.cardFace)
                .shadow(color: KaiColor.shadow, radius: 14, x: 0, y: 8)
        )
    }

    // MARK: Choice mode

    private func optionsList(_ question: QuizQuestion) -> some View {
        VStack(spacing: KaiSpacing.s) {
            ForEach(Array(question.choices.enumerated()), id: \.offset) { pair in
                optionButton(question, index: pair.offset, text: pair.element)
            }
        }
    }

    private func optionButton(_ question: QuizQuestion, index optionIndex: Int, text: String) -> some View {
        let isCorrect = question.isCorrect(choiceIndex: optionIndex)
        let isChosen = optionIndex == selected

        let tint: Color = !responded ? KaiColor.hairline
            : isCorrect ? pine
            : isChosen ? KaiColor.vermilion
            : KaiColor.hairline
        let fill: Color = responded && isCorrect ? pine.opacity(0.12)
            : responded && isChosen ? KaiColor.vermilion.opacity(0.10)
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
                if responded && isCorrect {
                    Image(systemName: "checkmark").foregroundStyle(pine)
                } else if responded && isChosen {
                    Image(systemName: "xmark").foregroundStyle(KaiColor.vermilion)
                }
            }
            .padding(.horizontal, KaiSpacing.m)
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(tint, lineWidth: 1.5)
            )
            .opacity(responded && !isCorrect && !isChosen ? 0.5 : 1)
        }
        .buttonStyle(KaiPressStyle())
        .disabled(responded)
    }

    // MARK: Text mode

    private func textEntry(_ question: QuizQuestion) -> some View {
        VStack(spacing: KaiSpacing.m) {
            TextField("Type the word", text: $textInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(KaiFont.body(18))
                .multilineTextAlignment(.center)
                .padding(.vertical, KaiSpacing.m)
                .padding(.horizontal, KaiSpacing.m)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous).fill(KaiColor.cardFace)
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(textFieldTint, lineWidth: 1.5))
                )
                .disabled(responded)
                .onSubmit { submitText(question) }

            if responded {
                HStack(spacing: KaiSpacing.s) {
                    Image(systemName: wasCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(wasCorrect ? pine : KaiColor.vermilion)
                    Text(wasCorrect ? "Correct" : "Answer: \(question.answers.first ?? question.word)")
                        .font(KaiFont.body(15, weight: .medium))
                        .foregroundStyle(KaiColor.sumi)
                }
            } else {
                KaiPrimaryButton("Check") { submitText(question) }
                    .frame(maxWidth: 200)
                    .opacity(textInput.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    .disabled(textInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var textFieldTint: Color {
        guard responded else { return KaiColor.hairline }
        return wasCorrect ? pine : KaiColor.vermilion
    }

    // MARK: Completion

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
                KaiPrimaryButton("Back to review", action: onClose)
                    .padding(.top, KaiSpacing.m)
                    .frame(maxWidth: 220)
            } else if !questions.isEmpty {
                KaiPrimaryButton("Quiz again") { restart() }
                    .padding(.top, KaiSpacing.m)
                    .frame(maxWidth: 220)
            }
            Spacer()
        }
    }

    // MARK: Actions

    private func choose(_ question: QuizQuestion, _ optionIndex: Int) {
        guard !responded else { return }
        withAnimation(.easeOut(duration: 0.2)) { selected = optionIndex }
        grade(question, .choice(optionIndex))
    }

    private func submitText(_ question: QuizQuestion) {
        guard !responded, !textInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        grade(question, .text(textInput))
    }

    private func grade(_ question: QuizQuestion, _ response: QuizResponse) {
        responded = true
        let correct = store.submit(question, response)
        wasCorrect = correct
        if correct {
            correctCount += 1
            KaiHaptics.impact(.light)
        } else {
            KaiHaptics.impact(.rigid)
        }
        Task { @MainActor in
            // Linger a little longer on a miss so the answer registers.
            try? await Task.sleep(for: .seconds(correct ? 0.9 : 1.6))
            advance()
        }
    }

    private func advance() {
        withAnimation {
            selected = nil
            textInput = ""
            responded = false
            wasCorrect = false
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
            textInput = ""
            responded = false
            correctCount = 0
        }
    }
}
