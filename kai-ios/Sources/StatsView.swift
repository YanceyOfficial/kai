import SwiftUI
import KaiUI

/// Statistics dashboard. Fleshed out in the stats feature commit.
struct StatsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                KaiColor.washi.ignoresSafeArea()
                ProgressView().tint(KaiColor.vermilion)
            }
            .navigationTitle("Stats")
        }
    }
}
