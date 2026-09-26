import Foundation

/// Remembers which book was opened in the Bilibili app and when, so the main
/// app can offer to advance the saved progress when the user comes back.
///
/// Recorded by `BilibiliLauncher.open(book:)` right before handing off to the
/// Bilibili app; consumed exactly once by `ContentView` on next activation.
struct PlaySession {
    let bookId: UUID
    let date: Date

    private static let key = "lastPlaySession.v1"

    static var current: PlaySession? {
        guard let dict = SharedStore.defaults.dictionary(forKey: key),
              let idString = dict["bookId"] as? String,
              let id = UUID(uuidString: idString),
              let timestamp = dict["date"] as? Double else { return nil }
        return PlaySession(bookId: id, date: Date(timeIntervalSince1970: timestamp))
    }

    static func record(bookId: UUID) {
        SharedStore.defaults.set(
            ["bookId": bookId.uuidString, "date": Date().timeIntervalSince1970],
            forKey: key
        )
    }

    static func clear() {
        SharedStore.defaults.removeObject(forKey: key)
    }
}
