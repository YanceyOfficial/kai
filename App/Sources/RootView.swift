import SwiftUI
import KaiCore
import KaiFSRS
import KaiAI
import KaiServices

/// Temporary root view that proves the four local packages link and their public
/// API is reachable from the app target. Replaced by the real UI in a later plan.
struct RootView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Kai 甲斐")
                .font(.largeTitle.bold())
            Text("Core schema v\(KaiCoreInfo.schemaVersion)")
                .foregroundStyle(.secondary)
            Text("FSRS-6 weights: \(FSRSParameters.fsrs6Default.weights.count)")
                .foregroundStyle(.secondary)
            Text("Quiz types: \(QuizType.allCases.count)")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    RootView()
}
