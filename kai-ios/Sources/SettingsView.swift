import SwiftUI
import KaiUI

/// App settings. Fleshed out in the settings feature commit.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                KaiColor.washi.ignoresSafeArea()
                ProgressView().tint(KaiColor.vermilion)
            }
            .navigationTitle("Settings")
        }
    }
}
