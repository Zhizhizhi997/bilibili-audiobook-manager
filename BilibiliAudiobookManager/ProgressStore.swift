import Foundation
import Combine

/// Owns the list of `BookProgress` records and persists them to `UserDefaults`
/// as JSON. The in-memory list is the source of truth; a failed save/load is
/// logged and never crashes the app.
final class ProgressStore: ObservableObject {
    /// Records sorted most-recently-updated first.
    @Published private(set) var books: [BookProgress] = []

    private let storageKey = "com.bilibili-audiobook-manager.bookProgress.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    // MARK: - Mutations

    /// Adds a new record and re-sorts.
    func add(_ book: BookProgress) {
        var newBook = book
        newBook.lastUpdated = Date()
        books.append(newBook)
        sortAndSave()
    }

    /// Replaces the record with the same `id`, stamps `lastUpdated`, and re-sorts.
    /// Silently ignores unknown ids.
    func update(_ book: BookProgress) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        var updated = book
        updated.lastUpdated = Date()
        books[index] = updated
        sortAndSave()
    }

    /// Deletes records at the given list offsets (swipe-to-delete).
    func delete(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
        save()
    }

    /// Deletes a single record by identity.
    func delete(_ book: BookProgress) {
        books.removeAll { $0.id == book.id }
        save()
    }

    // MARK: - Persistence

    private func sortAndSave() {
        books.sort { $0.lastUpdated > $1.lastUpdated }
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(books)
            defaults.set(data, forKey: storageKey)
        } catch {
            // Never crash on a persistence failure; the in-memory list stays valid.
            print("[ProgressStore] Failed to encode books: \(error)")
        }
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey) else { return } // first launch
        do {
            books = try JSONDecoder().decode([BookProgress].self, from: data)
        } catch {
            // Corrupted data: start fresh rather than crashing.
            print("[ProgressStore] Failed to decode books, starting empty: \(error)")
            books = []
        }
    }
}
