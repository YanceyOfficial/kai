import SwiftUI
import KaiUI

/// Temporary showcase root: the "Ink & Paper" home surface with the signature
/// FlipCard. Replaced by the real navigation and screens in a later plan.
struct RootView: View {
    var body: some View {
        ZStack {
            KaiColor.washi.ignoresSafeArea()

            VStack(spacing: KaiSpacing.xl) {
                header

                FlipCard(
                    word: "eccentric",
                    phonetic: "/ɪkˈsɛntrɪk/",
                    explanation: "adj. 古怪的，异乎寻常的",
                    example: "My uncle is something of an eccentric.",
                    translation: "我叔叔有点古怪。",
                    isLearned: true
                )

                Spacer()
            }
            .padding(KaiSpacing.l)
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: KaiSpacing.xs) {
                Text("Kai")
                    .font(KaiFont.display(40, weight: .bold))
                    .foregroundStyle(KaiColor.sumi)
                Text("甲斐 · today's words")
                    .font(KaiFont.body(15, weight: .medium))
                    .foregroundStyle(KaiColor.inkSecondary)
            }
            Spacer()
            Text("3")
                .font(KaiFont.display(34, weight: .bold))
                .foregroundStyle(KaiColor.vermilion)
                + Text(" due")
                .font(KaiFont.body(15, weight: .medium))
                .foregroundStyle(KaiColor.inkSecondary)
        }
        .padding(.top, KaiSpacing.s)
    }
}

#Preview {
    RootView()
}
