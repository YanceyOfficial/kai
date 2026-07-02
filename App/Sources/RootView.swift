import SwiftUI

/// Temporary showcase root hosting the review loop with a sample deck.
/// Replaced by real navigation + data-driven decks in a later plan.
struct RootView: View {
    private let sampleDeck: [ReviewCardData] = [
        ReviewCardData(
            word: "eccentric",
            phonetic: "/ɪkˈsɛntrɪk/",
            explanation: "adj. 古怪的，异乎寻常的",
            example: "My uncle is something of an eccentric.",
            translation: "我叔叔有点古怪。",
            isLearned: true
        ),
        ReviewCardData(
            word: "obsession",
            phonetic: "/əbˈsɛʃ.ən/",
            explanation: "n. 痴迷；萦绕于心的念头",
            example: "Finding his birth mother became an obsession.",
            translation: "找到生母成了他挥之不去的执念。"
        ),
        ReviewCardData(
            word: "meticulous",
            phonetic: "/məˈtɪk.jə.ləs/",
            explanation: "adj. 一丝不苟的，极为细致的",
            example: "She kept meticulous records of every review.",
            translation: "她把每次复习都记录得一丝不苟。"
        ),
    ]

    var body: some View {
        ReviewSessionView(deck: sampleDeck)
    }
}

#Preview {
    RootView()
}
