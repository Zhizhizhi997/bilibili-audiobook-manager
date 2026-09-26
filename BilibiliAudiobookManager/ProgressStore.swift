import Foundation
import Combine

/// In-memory list of `BookProgress` entries with JSON persistence.
///
/// Conforms to `ObservableObject` so SwiftUI views refresh automatically via
/// `@EnvironmentObject`. Entries are sorted most-recently-updated first.
final class ProgressStore: ObservableObject {
    @Published private(set) var books: [BookProgress] = []

    private let storageKey = "com.bilibili-audiobook-manager.bookProgress.v1"
    private let defaults: UserDefaults

    /// Uses the App Group container when available so the Share extension and
    /// the main app see the same library; falls back to `.standard` otherwise.
    init(defaults: UserDefaults = SharedStore.defaults) {
        self.defaults = defaults
        self.books = load()
    }

    // MARK: - Mutations

    /// Adds a new entry and re-sorts by most recent update.
    func add(_ book: BookProgress) {
        books.append(book)
        sortAndPersist()
    }

    /// Replaces the entry with the same `id`. Unknown ids are ignored.
    func update(_ book: BookProgress) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        var updated = book
        updated.lastUpdated = Date()
        books[index] = updated
        sortAndPersist()
    }

    /// Deletes entries at the given offsets (used by `List.onDelete`).
    func delete(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
        persist()
    }

    // MARK: - Persistence

    private func sortAndPersist() {
        books.sort { $0.lastUpdated > $1.lastUpdated }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(books) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func load() -> [BookProgress] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([BookProgress].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.lastUpdated > $1.lastUpdated }
    }
}
