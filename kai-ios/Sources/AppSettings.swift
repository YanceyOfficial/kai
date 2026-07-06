import Foundation

/// Non-view access to a few `@AppStorage`-backed settings, for stores that construct
/// schedulers outside SwiftUI.
enum AppSettings {
    /// FSRS target retention (recall probability at which a word becomes due). Default 0.9.
    static var requestRetention: Double {
        (UserDefaults.standard.object(forKey: "requestRetention") as? Double) ?? 0.9
    }
}
