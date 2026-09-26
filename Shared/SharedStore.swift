import Foundation

/// Code shared between the main app and the Share extension.
///
/// Both processes read/write through the App Group container
/// (`group.com.example.BilibiliAudiobookManager`), which is declared in the
/// entitlements of both targets. If the App Group is not available (e.g. the
/// capability was never enabled), `defaults` falls back to `.standard` so
/// nothing crashes — the share handoff just will not transfer.
enum SharedStore {
    /// Must match the App Group identifier in both `.entitlements` files.
    static let appGroupID = "group.com.example.BilibiliAudiobookManager"

    /// Shared defaults across app + extension, with a safe fallback.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    private static let pendingShareKey = "pendingShareBvId.v1"

    /// BV id stashed by the Share extension, awaiting pickup by the main app.
    /// The main app consumes it exactly once on becoming active.
    static var pendingShareBvId: String? {
        get { defaults.string(forKey: pendingShareKey) }
        set {
            if let value = newValue {
                defaults.set(value, forKey: pendingShareKey)
            } else {
                defaults.removeObject(forKey: pendingShareKey)
            }
        }
    }
}
