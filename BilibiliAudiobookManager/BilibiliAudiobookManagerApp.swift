import SwiftUI

/// App entry point. Owns the single shared `ProgressStore` and injects it
/// into the view hierarchy as an `EnvironmentObject`.
@main
struct BilibiliAudiobookManagerApp: App {
    @StateObject private var store = ProgressStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
